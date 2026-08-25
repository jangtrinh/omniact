#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/scripts/signing_identity_helpers.sh"
cd "$DIR"

CUSTOM_OUTPUT="${OMNIACT_APP_OUTPUT:-}"
SIGNING_IDENTITY="${OMNIACT_CODESIGN_IDENTITY:--}"
REQUIRE_STABLE_SIGNING="${OMNIACT_REQUIRE_STABLE_SIGNING:-0}"

if [[ -z "$CUSTOM_OUTPUT" ]]; then
    APP_DIR="$DIR/OmniAct.app"
elif [[ "$CUSTOM_OUTPUT" == .build/*/OmniAct.app && "$CUSTOM_OUTPUT" != *".."* ]]; then
    APP_DIR="$DIR/$CUSTOM_OUTPUT"
else
    echo "Refusing app output outside the repo-owned .build directory: $CUSTOM_OUTPUT" >&2
    exit 2
fi

OUTPUT_PARENT="$(dirname "$APP_DIR")"
if [[ -n "$CUSTOM_OUTPUT" ]]; then
    if [[ -L "$DIR/.build" || ! -d "$OUTPUT_PARENT" ]]; then
        echo "Custom app output must use an existing, non-symlink directory under .build." >&2
        exit 2
    fi
    BUILD_ROOT="$(cd "$DIR/.build" && pwd -P)"
    PHYSICAL_PARENT="$(cd "$OUTPUT_PARENT" && pwd -P)"
    if [[ "$PHYSICAL_PARENT/" != "$BUILD_ROOT/"* ]]; then
        echo "Refusing app output whose physical path escapes .build: $CUSTOM_OUTPUT" >&2
        exit 2
    fi
fi

if [[ "$REQUIRE_STABLE_SIGNING" == "1" && "$SIGNING_IDENTITY" == "-" ]]; then
    echo "Stable signing required. Set OMNIACT_CODESIGN_IDENTITY to a valid code-signing identity." >&2
    exit 2
fi

RESOLVED_IDENTITY="-"
if [[ "$SIGNING_IDENTITY" != "-" ]]; then
    if ! RESOLVED_IDENTITY="$(resolve_signing_identity "$SIGNING_IDENTITY")"; then
        echo "Code-signing identity not found: $SIGNING_IDENTITY" >&2
        echo "Run: security find-identity -v -p codesigning" >&2
        exit 2
    fi
fi

if [[ -L "$APP_DIR" ]]; then
    echo "Refusing to replace a symbolic-link app output: $APP_DIR" >&2
    exit 2
fi
if [[ -e "$APP_DIR" ]]; then
    EXISTING_IDENTIFIER="$(plutil -extract CFBundleIdentifier raw -o - "$APP_DIR/Contents/Info.plist" 2>/dev/null || true)"
    if [[ "$EXISTING_IDENTIFIER" != "com.omniact.macos" ]]; then
        echo "Refusing to replace a bundle not owned by OmniAct: $APP_DIR" >&2
        exit 2
    fi
fi

echo "Building release binary..."
swift build -c release

mkdir -p "$OUTPUT_PARENT"
STAGING_ROOT="$(mktemp -d "$OUTPUT_PARENT/.omniact-bundle-stage.XXXXXX")"
STAGED_APP="$STAGING_ROOT/OmniAct.app"
BACKUP_ROOT="$(mktemp -d "$OUTPUT_PARENT/.omniact-bundle-backup.XXXXXX")"
BACKUP_APP="$BACKUP_ROOT/OmniAct.app"

cleanup() {
    rm -rf "$STAGING_ROOT"
    if [[ -e "$BACKUP_APP" && ! -e "$APP_DIR" ]]; then
        mv "$BACKUP_APP" "$APP_DIR"
    fi
    rm -rf "$BACKUP_ROOT"
}
trap cleanup EXIT

mkdir -p "$STAGED_APP/Contents/MacOS" "$STAGED_APP/Contents/Resources"
cp ".build/release/OmniAct" "$STAGED_APP/Contents/MacOS/OmniAct"
cp "Packaging/Info.plist" "$STAGED_APP/Contents/Info.plist"
chmod +x "$STAGED_APP/Contents/MacOS/OmniAct"

if [[ "$RESOLVED_IDENTITY" == "-" ]]; then
    codesign --force --sign - --options runtime --timestamp=none "$STAGED_APP"
    echo "Warning: ad-hoc signing is valid for launch but unstable for Accessibility/TCC across rebuilds." >&2
    echo "Set OMNIACT_CODESIGN_IDENTITY to an Apple Development or Developer ID identity for stable grants." >&2
else
    codesign --force --sign "$RESOLVED_IDENTITY" --options runtime --timestamp=none "$STAGED_APP"
    echo "Signed with stable identity: $SIGNING_IDENTITY"
fi

codesign --verify --deep --strict --verbose=2 "$STAGED_APP"

if [[ -e "$APP_DIR" ]]; then
    mv "$APP_DIR" "$BACKUP_APP"
fi
if ! mv "$STAGED_APP" "$APP_DIR"; then
    echo "Failed to install the verified bundle; restoring the previous OmniAct.app." >&2
    exit 1
fi
rm -rf "$BACKUP_ROOT"

echo "OmniAct.app bundled and verified at $APP_DIR"
