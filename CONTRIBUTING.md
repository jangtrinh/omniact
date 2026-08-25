# Contributing to OmniAct

## Setup

- Use macOS 14 or newer with Xcode command-line tools or a compatible Swift
  toolchain.
- Build and run from the repository root with `swift run OmniAct`.
- Use an isolated test store. Never run tests against a live Keychain or the
  standard preferences domain.

## Changes

- Branch from the current default branch and keep each pull request focused.
- Describe the user-visible behavior, validation performed, and any remaining
  limitations in the pull request.
- Do not claim a provider or cross-app behavior as supported unless its native
  contract is verified.

## Verification

Run the full gate from the repository root before opening a pull request:

```bash
swift test && swift build -c release && swift build -c release -Xswiftc -strict-concurrency=complete -Xswiftc -warnings-as-errors
```

Unit tests do not establish cross-app behavior. Any pull request that changes
Accessibility reads, synthetic input, or insertion behavior also needs an
owner-visible smoke test on macOS before those claims are made.
