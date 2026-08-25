# OmniAct

OmniAct is a pre-alpha, source-only native macOS menu-bar assistant. It opens a
floating AI prompt near the active text caret, sends a requested transformation
to a local or user-configured provider, and attempts to insert the result back
into the active app.

## Safety and current limits

- OmniAct needs macOS Accessibility permission to read selected text and attempt
  replacement in other apps. Grant that permission only after reviewing the source.
- When you choose a cloud provider, selected text and prompts are disclosed to
  that provider under its terms. Local Ollama use avoids that cloud disclosure.
- Replacement is best effort and unvalidated across third-party applications;
  verify the resulting text before relying on it.
- The current client implements only the OpenAI-compatible HTTP transport.
  The Anthropic UI entry is not a supported Anthropic integration.

## Requirements

- macOS 14 or newer
- Xcode 26 command-line tools or a compatible Swift toolchain
- Accessibility permission for cross-app text reading and replacement
- A local Ollama endpoint or a user-supplied API key for an OpenAI-compatible endpoint

## Build and test

```bash
swift test
swift build -c release
```

Run the app during local development with:

```bash
swift run OmniAct
```

## Custom commands

Open **Preferences → Commands** to edit every factory prompt, add a reusable
command, or manage its enabled state and order. Changes save locally and update
the open HUD's autocomplete immediately; no account, sync, telemetry, or
provider key is stored with a command.

Commands live in `~/.config/omniact/commands/`. OmniAct loads the six factory
definitions first, then overlays one deterministic, pretty-printed JSON file
per factory override or custom command. A malformed file produces a warning
without preventing the remaining valid files from loading. Resetting a factory
removes only that factory override; **Reset All Factory** preserves custom
commands.

The v1 JSON schema is a single object with these fields:

```json
{
  "id": "stable-command-id",
  "command": "/release-notes",
  "aliases": ["release notes"],
  "title": "Release Notes",
  "description": "Draft concise release notes",
  "icon": "doc.text",
  "systemPrompt": "You write concise product release notes.",
  "promptTemplate": "Notes for: {text}\nFocus: {arg}",
  "enabled": true,
  "origin": "custom",
  "order": 6
}
```

`id` is stable even when `command` changes. Slash tokens must start with `/`
and use lowercase letters, numbers, and hyphens; tokens and aliases are unique
without regard to case. Only `{text}` (selected text, or typed text when none
is selected) and `{arg}` (the text after the resolved command token) are valid
placeholders. Disabled commands are not suggested or executed.

For safe local loading, OmniAct considers at most 64 non-hidden command JSON
files (in deterministic filename order), each up to 64 KiB. Symlinks,
directories, oversized files, and invalid files are skipped individually with a
local warning; stable IDs are limited to 100 UTF-8 bytes so their encoded file
names remain portable.

## Package

```bash
bash scripts/bundle_app.sh
```

The default bundle is ad-hoc signed and passes structural signature verification,
but macOS may treat each rebuild as a new Accessibility identity. For a stable
local identity, select an installed Apple Development or Developer ID Application
certificate. Prefer its 40-character hash because certificate names can repeat:

```bash
security find-identity -v -p codesigning
OMNIACT_CODESIGN_IDENTITY="<certificate hash>" bash scripts/bundle_app.sh
OMNIACT_CODESIGN_IDENTITY="<same certificate hash>" bash scripts/signing_identity_kill_test.sh
```

The kill-test builds twice and compares designated requirements. Reuse the same
resolved identity and `com.omniact.macos` bundle identifier for continuity. It never
resets, reads, or modifies the TCC database. After it passes, build the canonical
bundle with that identity, grant Accessibility once, rebuild and replace it, then
manually verify TextEdit capture and replacement. This owner-visible check is not
automated.

The local bundle is not a public distribution artifact: Developer ID signing with
a secure timestamp and Apple notarization are still required.

## Source

- [Package manifest](Package.swift)
- [Application entry point](Sources/OmniAct/App/OmniActApp.swift)
- [Tests](Tests/OmniActTests/OmniActTests.swift)
- [Bundle script](scripts/bundle_app.sh)
- [Signing identity kill-test](scripts/signing_identity_kill_test.sh)

## License

OmniAct is available under the [MIT License](LICENSE). Its pre-alpha status and
the safety limitations above still apply.
