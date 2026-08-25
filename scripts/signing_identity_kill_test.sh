#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/scripts/signing_identity_helpers.sh"
IDENTITY="${OMNIACT_CODESIGN_IDENTITY:-}"

if [[ -z "$IDENTITY" || "$IDENTITY" == "-" ]]; then
    echo "BLOCKED: no stable signing identity selected." >&2
    echo "Run: security find-identity -v -p codesigning" >&2
    echo "Then rerun with OMNIACT_CODESIGN_IDENTITY set to the certificate hash or full name." >&2
    echo "No Accessibility/TCC state was changed." >&2
    exit 2
fi

if ! RESOLVED_IDENTITY="$(resolve_signing_identity "$IDENTITY")"; then
    echo "BLOCKED: exact code-signing identity not found: $IDENTITY" >&2
    echo "No Accessibility/TCC state was changed." >&2
    exit 2
fi

mkdir -p "$DIR/.build"
TEST_ROOT="$(mktemp -d "$DIR/.build/signing-kill-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

build_bundle() {
    local relative_destination="$1"
    OMNIACT_APP_OUTPUT="$relative_destination" \
    OMNIACT_CODESIGN_IDENTITY="$RESOLVED_IDENTITY" \
    OMNIACT_REQUIRE_STABLE_SIGNING=1 \
        bash "$DIR/scripts/bundle_app.sh" >/dev/null
    local destination="$DIR/$relative_destination"
    codesign --verify --deep --strict --verbose=2 "$destination"
    read_designated_requirement "$destination"
}

TEST_ROOT_RELATIVE="${TEST_ROOT#"$DIR/"}"
FIRST_APP="$TEST_ROOT_RELATIVE/first/OmniAct.app"
SECOND_APP="$TEST_ROOT_RELATIVE/second/OmniAct.app"
mkdir -p "$DIR/$(dirname "$FIRST_APP")" "$DIR/$(dirname "$SECOND_APP")"

FIRST_REQUIREMENT="$(build_bundle "$FIRST_APP" | tail -n 1)"
SECOND_REQUIREMENT="$(build_bundle "$SECOND_APP" | tail -n 1)"

if [[ -z "$FIRST_REQUIREMENT" || "$FIRST_REQUIREMENT" != "$SECOND_REQUIREMENT" ]]; then
    echo "FAIL: designated requirement changed across identical rebuilds." >&2
    exit 1
fi

if [[ "$FIRST_REQUIREMENT" == cdhash* ]]; then
    echo "FAIL: designated requirement is CDHash-only and cannot preserve TCC identity." >&2
    exit 1
fi

echo "PASS: two signed bundles share one stable designated requirement."
echo "Requirement: $FIRST_REQUIREMENT"
echo "LIVE OWNER GATE REMAINS: grant Accessibility once, replace the canonical bundle, then verify TextEdit capture and replacement."
echo "This script did not read, reset, or modify TCC."
