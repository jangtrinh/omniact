#!/bin/bash

resolve_signing_identity() {
    local requested="$1"
    local line
    local hash
    local name

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*[0-9]+\)[[:space:]]+([0-9A-Fa-f]{40})[[:space:]]+\"(.*)\"$ ]]; then
            hash="${BASH_REMATCH[1]}"
            name="${BASH_REMATCH[2]}"
            if [[ "$requested" == "$hash" || "$requested" == "$name" ]]; then
                printf '%s\n' "$hash"
                return 0
            fi
        fi
    done < <(security find-identity -v -p codesigning)

    return 1
}

read_designated_requirement() {
    local app_path="$1"
    local output
    local requirement

    output="$(codesign -d -r- "$app_path" 2>&1)" || return 1
    requirement="$(printf '%s\n' "$output" | sed -nE 's/^#?[[:space:]]*designated =>[[:space:]]*//p')"
    if [[ -z "$requirement" || "$(printf '%s\n' "$requirement" | wc -l | tr -d ' ')" != "1" ]]; then
        return 1
    fi
    printf '%s\n' "$requirement"
}
