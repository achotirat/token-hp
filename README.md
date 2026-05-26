# Token Cat

Token Cat is a native macOS menu-bar app for tracking Claude and Codex usage before reset.

The menu-bar cat reflects the most urgent provider:

- Sitting: all tracked providers are above 30%.
- Lying down: the lowest provider is greater than 5% and up to 30%.
- Sleeping: the lowest provider is 5% or below, exhausted, or blocked.

## Provider Support

| Provider | V1 Status | Notes |
| --- | --- | --- |
| Claude | Adapter scaffolded | Shows `Unknown` until local detection is implemented. |
| Codex | Adapter scaffolded | Shows `Unknown` until local detection is implemented. |
| Minimax | Deferred | Future adapter. |
| Qwen | Deferred | Future adapter. |
| Kimi | Deferred | Future adapter. |

## Development

```bash
swift build
swift run TokenCatCoreTests
swift run TokenCatApp
```

## Release Packaging

The current implementation is a Swift Package Manager development build. A future release pass should add a bundled macOS `.app` target with menu-bar-only packaging, including `LSUIElement`, app identity, signing, and distribution notes.

## Design

See `docs/superpowers/specs/2026-05-26-token-cat-design.md`.
