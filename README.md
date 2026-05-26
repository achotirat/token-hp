# Token Cat

Token Cat is a native macOS menu-bar app for tracking Claude and Codex usage before reset.

The menu-bar cat reflects the most urgent provider:

- Sitting: all tracked providers are above 30%.
- Lying down: the lowest provider is greater than 5% and up to 30%.
- Sleeping: the lowest provider is 5% or below, exhausted, or blocked.

## Provider Support

| Provider | V1 Status | Notes |
| --- | --- | --- |
| Claude | Planned | Adapter boundary exists first; local detection is added behind it. |
| Codex | Planned | Adapter boundary exists first; local detection is added behind it. |
| Minimax | Deferred | Future adapter. |
| Qwen | Deferred | Future adapter. |
| Kimi | Deferred | Future adapter. |

## Development

```bash
swift build
swift run TokenCatCoreTests
swift run TokenCatApp
```

## Design

See `docs/superpowers/specs/2026-05-26-token-cat-design.md`.
