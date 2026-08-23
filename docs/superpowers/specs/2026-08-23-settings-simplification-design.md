# Settings Simplification Design

## Goal
Reduce CodeIsland Settings from ten mixed-purpose destinations to a focused configuration surface. Remove controls that no longer affect the live UI, group real configuration by user task, and leave support-only recovery controls accessible without making them primary navigation.

## Product direction
Settings should answer four recurring questions: where CodeIsland appears, what appears in the session list, which agents/devices it connects to, and which notifications it emits. The default path must not expose provider mascots, raw hook schema fields, or hardware tuning.

## Information architecture

| Destination | Contents |
|---|---|
| General | Language, launch at login, display selection and placement, global shortcuts. |
| Display | Visibility/collapse behavior, completion behavior, session-list density/content. Advanced display holds haptics, font size, width scaling, notch-height overrides, and smart suppression. |
| Integrations | Agent hooks, remote hosts, Buddy/Apple Companion. Agent/remote/device configuration remains separate sections within this task area. |
| Notifications | Sound enablement, volume, quiet hours, completion and approval events. Per-event custom audio stays behind a Customize sounds disclosure. |
| Advanced | Hook approval policy, Claude config-directory override, hook CWD exclusion, webhook forwarding, update checks, diagnostics. |

The About sidebar page disappears. Update and diagnostic actions move to Advanced support controls. The Mascots page disappears.

## Removals

1. Remove `showAgentDetails`: the session-card subagent gutter was removed; this preference and preview argument have no current UI consumer.
2. Remove the Mascots page, its 25-item catalog, `MascotView`/`CodexStatusIcon`, `mascotSpeed`, and related tests. Provider mascots are no longer rendered by the macOS panel.
3. Remove the user-facing default mascot selection. Preserve the existing internal `defaultSource` fallback only for companion/device payload compatibility; it is not configured from Settings.
4. Remove the empty `PageHeader` view.

## Interaction rules

- Existing persisted values for retained controls keep their keys and semantics.
- Existing default `pluginSessionMode` remains `separate`; the user may choose Merge in Advanced approval/session handling. Do not silently change session folding behavior.
- Advanced disclosures are collapsed by default. Security-affecting auto-approval copy explicitly says that it bypasses permission prompts.
- Companion controls remain available only in Integrations; device-specific tuning is disabled or hidden until its companion is enabled.
- All moves retain the native SwiftUI Form, Section, Toggle, Picker, Slider, DatePicker, Button, and accessibility labels already used by the current page.

## Verification

- Unit tests cover settings navigation cases and deleted preference cleanup where behavior is independently testable.
- `swift build` and the settings/relevant existing XCTest suite pass.
- Launch the built app, open every remaining settings destination, exercise collapsed/expanded Advanced and Customize sounds disclosures, test shortcut capture/cancel, and confirm no Mascots or obsolete Agent Details UI remains.
