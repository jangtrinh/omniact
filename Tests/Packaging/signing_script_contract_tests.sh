#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$DIR/scripts/signing_identity_helpers.sh"

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

security() {
    printf '  1) AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA "Apple Development: OmniAct"\n'
    printf '     1 valid identities found\n'
}

[[ "$(resolve_signing_identity "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")" == "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ]] \
    || fail "exact certificate hash was not resolved"
[[ "$(resolve_signing_identity "Apple Development: OmniAct")" == "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ]] \
    || fail "exact certificate name was not resolved"
if resolve_signing_identity "valid identities" >/dev/null; then
    fail "identity substring was accepted"
fi

codesign() {
    printf '# designated => cdhash H"fixture"\n' >&2
}
[[ "$(read_designated_requirement "/fixture/OmniAct.app")" == 'cdhash H"fixture"' ]] \
    || fail "designated requirement prefix was not normalized"

set +e
UNSAFE_OUTPUT="$(OMNIACT_APP_OUTPUT="/Applications/Safari.app" bash "$DIR/scripts/bundle_app.sh" 2>&1)"
UNSAFE_STATUS=$?
SUBSTRING_OUTPUT="$(OMNIACT_CODESIGN_IDENTITY="0" bash "$DIR/scripts/bundle_app.sh" 2>&1)"
SUBSTRING_STATUS=$?

mkdir -p "$DIR/.build"
SYMLINK_ROOT="$(mktemp -d "$DIR/.build/signing-script-contract.XXXXXX")"
trap 'rm -rf "$SYMLINK_ROOT"' EXIT
ln -s /tmp "$SYMLINK_ROOT/escape"
SYMLINK_OUTPUT="$(
    OMNIACT_APP_OUTPUT="${SYMLINK_ROOT#"$DIR/"}/escape/OmniAct.app" \
        bash "$DIR/scripts/bundle_app.sh" 2>&1
)"
SYMLINK_STATUS=$?
set -e

[[ "$UNSAFE_STATUS" == "2" ]] || fail "unsafe output path did not exit 2"
[[ "$UNSAFE_OUTPUT" != *"Building release binary"* ]] || fail "unsafe output reached the build step"
[[ "$SUBSTRING_STATUS" == "2" ]] || fail "identity substring did not exit 2"
[[ "$SUBSTRING_OUTPUT" != *"Building release binary"* ]] || fail "invalid identity reached the build step"
[[ "$SYMLINK_STATUS" == "2" ]] || fail "symlink output escape did not exit 2"
[[ "$SYMLINK_OUTPUT" != *"Building release binary"* ]] || fail "symlink output escape reached the build step"

echo "PASS: signing script contracts"
