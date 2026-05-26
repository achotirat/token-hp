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
| Codex | Local adapter | Reads the latest `rate_limits` event from `~/.codex/sessions/**/*.jsonl`. |
| Minimax | Deferred | Future adapter. |
| Qwen | Deferred | Future adapter. |
| Kimi | Deferred | Future adapter. |

## Development

```bash
swift build
swift run TokenCatCoreTests
swift run TokenCatApp
```

`swift run TokenCatApp` is useful for compile checks, but macOS menu-bar behavior is more reliable from an installed app bundle.

For a RunCat-style local install, build the app, replace any running copy, copy it to `/Applications`, and launch it:

```bash
./scripts/install-local.sh
```

For build-only packaging:

```bash
./scripts/build-app.sh
open ".build/Token Cat.app"
```

If you do not see it immediately, check the right side of the macOS menu bar for `Token Cat`, `Cat low`, or `Cat Zz`.

## Release Packaging

The current implementation includes a local unsigned `.app` packaging script for development. A future release pass should add signing, notarization, app icon assets, and distribution notes.

## Design

See `docs/superpowers/specs/2026-05-26-token-cat-design.md`.
