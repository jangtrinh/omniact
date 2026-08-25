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

## Package

```bash
bash scripts/bundle_app.sh
```

The script creates an **unsigned** local `OmniAct.app` bundle. It is not a
public distribution artifact: Developer ID signing, hardened runtime, and Apple
notarization are still required.

## Source

- [Package manifest](Package.swift)
- [Application entry point](Sources/OmniAct/App/OmniActApp.swift)
- [Tests](Tests/OmniActTests/OmniActTests.swift)
- [Bundle script](scripts/bundle_app.sh)

## License

OmniAct is available under the [MIT License](LICENSE). Its pre-alpha status and
the safety limitations above still apply.
