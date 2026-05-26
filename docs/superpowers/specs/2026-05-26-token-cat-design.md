# Token Cat Design

Date: 2026-05-26
Target repository: `achotirat/token-hp`
Local workspace: `/Users/temtem/projects/Token-HP`

## Goal

Build an open-source native macOS menu-bar app that shows how much Claude and Codex usage remains before reset. The app should be lightweight enough to live in the menu bar all day, friendly enough to share publicly, and honest about the confidence of locally detected provider data.

The primary ambient signal is a graphic cat in the macOS menu bar. Clicking the cat opens a compact SwiftUI panel with readable provider cards.

## V1 Scope

V1 supports Claude and Codex only.

The app shows percent remaining first and reset time second:

- `Claude 72% · resets in 3h 12m`
- `Codex 18% · resets in 41m`

V1 includes:

- Native Swift/SwiftUI macOS menu-bar app.
- Friendly provider-card panel.
- Claude and Codex provider adapters.
- Normalized provider status model.
- Cat state derived from the worst provider.
- Low and exhausted notifications.
- Expandable card details.
- Settings for refresh interval, notifications, and thresholds.
- Original graphic cat assets suitable for a public GitHub repo.

V1 excludes:

- Minimax, Qwen, and Kimi adapters.
- Manual/custom provider cards.
- Reset notifications.
- Weekly session-limit drilldown.
- Usage history charts.
- Advanced analytics.

## Cat States

The menu-bar cat reflects the worst current provider state.

- Sitting, tilted, and staring at the user: all tracked providers are above `30%`.
- Lying down: the worst provider is greater than `5%` and up to `30%`.
- Sleeping with `ZzZ`: the worst provider is `<=5%`, exhausted, or blocked.

Unknown provider data should not force the cat into the sleeping state. Unknown or error states should be visible in the panel details without creating false exhausted alarms.

## UI Design

The app uses the Friendly Provider Cards direction.

The menu-bar icon should be small, readable, animated, and original. The cat style should feel like a simple hand-drawn line animation: black outline, minimal fill, rounded body, expressive tail, and no stock imagery.

Cat animation direction:

- Healthy/sitting state should animate as a small walking cat when there is plenty of quota.
- Low/lying state should animate as the cat sitting and yawning.
- Exhausted/sleeping state should animate as the cat lying down and sleeping, with a subtle `ZzZ` cue when there is enough room.

The animation should stay subtle enough for a macOS menu bar. The app can use SwiftUI `TimelineView` or simple state-driven vector frames rather than bitmap sprites in v1.

The opened panel contains:

- Header with app name and current cat state.
- Claude card.
- Codex card.
- Refresh now action.
- Settings action.
- Quit action.

Each provider card shows:

- Provider name.
- Large percent remaining.
- Reset time or reset estimate.
- Status label.
- Compact progress bar.

Clicking a card expands details:

- Data source.
- Last refresh time.
- Confidence.
- Error or warning text when applicable.

In a later version, this same click/drilldown pattern should be extended to show weekly or session-limit information when a provider exposes it. V1 should keep the card expansion structure flexible enough to add this without redesigning the panel.

Settings contain:

- Enable or disable notifications.
- Refresh interval.
- Low threshold, default `30%`.
- Sleep threshold, default `5%`.
- Provider enable or disable toggles.

## Architecture

The app is a native macOS Swift/SwiftUI app.

Core units:

- `TokenCatApp`: app entry point, owns the menu-bar extra and settings scene.
- `StatusController`: refreshes provider data, computes worst-provider state, and publishes UI-ready state.
- `ProviderAdapter`: protocol implemented by each provider-specific adapter.
- `ClaudeAdapter`: detects Claude usage and reset status.
- `CodexAdapter`: detects Codex usage and reset status.
- `ProviderStatus`: normalized data model shared by all adapters.
- `CatState`: derived menu-bar icon state.
- `NotificationController`: sends low and exhausted notifications once per threshold crossing.
- `SettingsStore`: stores refresh interval, notification preference, provider toggles, and thresholds.

Adapters are responsible for provider-specific detection and parsing. SwiftUI views receive normalized `ProviderStatus` values and do not know how each provider is detected.

This boundary keeps the app useful for Claude and Codex first while leaving a clean path for later adapters such as Minimax, Qwen, and Kimi.

## Data Model

`ProviderStatus` should include:

- Provider id.
- Display name.
- Percent remaining, when known.
- Reset date or reset duration estimate, when known.
- Provider state: healthy, low, exhausted, blocked, unknown, or error.
- Source description.
- Confidence: high, medium, low, or unknown.
- Last refresh time.
- Optional error message.

`CatState` should include:

- `sitting`
- `lyingDown`
- `sleeping`

The state mapping uses settings thresholds so the defaults can change without rewriting UI code.

## Data Flow

On launch:

1. Load settings.
2. Create Claude and Codex adapters.
3. Perform an immediate refresh.
4. Start a refresh timer.

On each refresh:

1. `StatusController` asks every enabled `ProviderAdapter` for a status.
2. Each adapter returns a normalized `ProviderStatus`.
3. `StatusController` selects the worst provider by provider state and percent remaining.
4. The worst provider determines the menu-bar `CatState`.
5. The SwiftUI panel renders provider cards from the normalized statuses.
6. `NotificationController` compares current and previous states and sends a notification only when crossing into low or exhausted/sleeping.

If a provider cannot be detected, the card remains visible and shows `Unknown` or `Error` with details.

## Notifications

V1 sends notifications only when a provider first crosses into a low or exhausted/sleeping state.

Notifications should not repeat on every refresh. They should reset only after the provider recovers above the relevant threshold and then crosses the threshold again.

Reset notifications are out of scope for v1.

## Reliability

Provider detection should be honest over magical. If local usage or reset data cannot be read confidently, the app should show the limitation clearly instead of inventing precision.

Rules:

- Unknown data does not become `0%`.
- Unknown data does not trigger sleeping cat state.
- Adapter errors are visible in expanded card details.
- The panel should show the source and confidence for every provider.
- The app should keep running if one provider adapter fails.

## Testing

Testing should focus on behavior that can quietly regress:

- Threshold mapping for sitting, lying down, and sleeping.
- Worst-provider selection.
- Notification threshold crossings.
- Provider adapter parsing using fixtures or sample command output.
- Unknown and error provider states.
- UI preview states for healthy, low, exhausted, unknown, and error.

## GitHub Sharing

The repository should be structured for public contribution:

- Clear README with screenshots or mockups.
- Explicit provider-support table.
- Contributor notes explaining provider adapters.
- Original app icon and cat assets.
- No bundled stock imagery or copyrighted reference images.
- No secrets or local usage logs committed.

The initial repository target is `https://github.com/achotirat/token-hp`.

## Future Versions

Future versions may add a provider-card drilldown for weekly session limits. When supported by a provider, clicking Claude or Codex should reveal the weekly/session limit, current weekly/session usage, reset timing, and source confidence.

This should remain provider-adapter driven. The UI should render weekly/session-limit details only when an adapter reports them, and should avoid showing fake precision when the local data source cannot distinguish daily, session, weekly, or plan-level limits.
