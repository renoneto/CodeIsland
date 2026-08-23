# Settings Simplification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove dead provider-mascot and agent-detail settings, then reorganize Settings around general use, display, integrations, notifications, and advanced recovery controls.

**Architecture:** Keep SwiftUI `Form` and `Section` primitives. Extract reusable section content from the current page-local views so General, Display, Integrations, Notifications, and Advanced can compose settings without nested Forms. Retain every non-dead preference key and move its existing control to a task-appropriate destination; only delete unused mascot/agent-detail state.

**Tech Stack:** Swift 6, SwiftUI, AppKit, XCTest, Swift Package Manager.

## Global Constraints

- Do not change the semantics or persistence keys of retained preferences.
- Keep `pluginSessionMode` defaulting to `separate`.
- Do not add dependencies.
- Preserve native accessibility labels, disabled states, and keyboard shortcut capture/cancel behavior.
- Delete the whole dead branch; do not leave aliases, hidden tabs, or unreferenced preference keys.

---

### Task 1: Delete dead mascot and agent-detail configuration

**Files:**
- Modify: `Sources/CodeIsland/Settings.swift`
- Modify: `Sources/CodeIsland/SettingsView.swift`
- Rename: `Sources/CodeIsland/MascotView.swift` to `Sources/CodeIsland/ModelNameLabel.swift`
- Modify: `Sources/CodeIsland/NotchPanelView.swift`
- Modify: `Sources/CodeIsland/DiagnosticsExporter.swift`
- Delete: `Tests/CodeIslandTests/MascotViewTests.swift`
- Test: `Tests/CodeIslandTests/NotchPanelViewTests.swift`

**Interfaces:**
- Removes `SettingsKey.showAgentDetails` and `SettingsKey.mascotSpeed` plus defaults and default registration.
- Retains `ModelNameLabel(model:fallback:status:size:)` as the sole view in the renamed source file.

- [ ] Remove `showAgentDetails` from `SettingsKey`, `SettingsDefaults`, default registration, `AppearancePage`, `AppearancePreview`, and all panel storage declarations.
- [ ] Remove the Mascots navigation case, page, gallery list, `MascotRow`, `MascotView`, `CodexStatusIcon`, mascot speed setting, mascot diagnostics export, and mascot unit test.
- [ ] Retain `defaultSource` internally for companion/device fallbacks, but remove its user-facing picker.
- [ ] Rename the surviving model label source to match its responsibility.
- [ ] Run `swift test --filter "NotchPanelViewTests"`.
- [ ] Commit: `git commit -m "Remove obsolete mascot settings"`.

### Task 2: Collapse General and Shortcuts

**Files:**
- Modify: `Sources/CodeIsland/SettingsView.swift`
- Test: `Tests/CodeIslandTests/SettingsViewTests.swift` if navigation rendering tests exist; otherwise no source-text tests.

**Interfaces:**
- `GeneralPage` owns language, startup, placement, and shortcut capture state.
- `ShortcutsPage` is removed after its capture/clear implementation is incorporated into General.

- [ ] Move the existing shortcut recorder state and `startRecording`, `clearBinding`, `stopRecording`, and `notifyChange` methods into `GeneralPage`.
- [ ] Append the existing `ShortcutRow` list as a General Form section named Shortcuts; preserve Escape-to-cancel and modifier-key validation.
- [ ] Group display choice, horizontal drag, and menu-bar avoidance under Placement.
- [ ] Remove `.shortcuts` from `SettingsPage`, the sidebar group, and `SettingsView` switch.
- [ ] Run shortcut-related tests, then `swift build`.
- [ ] Commit: `git commit -m "Move shortcuts into general settings"`.

### Task 3: Merge normal display preferences and demote tuning

**Files:**
- Modify: `Sources/CodeIsland/SettingsView.swift`
- Test: `Tests/CodeIslandTests/NotchPanelViewTests.swift`

**Interfaces:**
- `DisplayPage` replaces `BehaviorPage` and `AppearancePage`.
- Day-to-day controls remain visible; technical tuning is inside a collapsed `DisclosureGroup("Advanced display")`.

- [ ] Combine current visibility/collapse/completion controls with max visible sessions, reply lines, tool status, and git branch.
- [ ] Move smart suppression, hover haptics/intensity, font size, collapsed-width scale, and notch-height mode/custom height into the Advanced display disclosure.
- [ ] Preserve every retained `@AppStorage` key and existing conditional haptic/custom-height controls.
- [ ] Remove `.behavior` and `.appearance` navigation cases and their previous standalone page wrappers.
- [ ] Run `swift test --filter "NotchPanelViewTests"` and launch the built app to verify collapsed and expanded advanced states.
- [ ] Commit: `git commit -m "Consolidate display preferences"`.

### Task 4: Create an Integrations task area and an Advanced recovery area

**Files:**
- Modify: `Sources/CodeIsland/SettingsView.swift`
- Test: `Tests/CodeIslandTests/ConfigInstallerTests.swift`
- Test: `Tests/CodeIslandTests/OmpExtensionContractTests.swift`

**Interfaces:**
- `IntegrationsPage` exposes Coding agents, Remote hosts, and Companions through a native segmented picker that switches between the existing full Form views without nested Forms.
- `AdvancedPage` owns hook approval policy, Claude config override, hook CWD filtering, webhook forwarding, update checks, and diagnostic export.

- [ ] Add `.integrations` and `.advanced` navigation cases; remove `.hooks`, `.remote`, `.buddy`, and `.about` from primary navigation.
- [ ] Move the existing Hooks, Remote Hosts, and Buddy Forms behind an Integrations segmented picker; retain all behavior and device-state disabling.
- [ ] Move auto-approve tools, Claude config directory, hook CWD exclusion, and webhook controls from Behavior into Advanced. Add explicit copy that auto-approve bypasses permission prompts.
- [ ] Move the About update-state switch and diagnostic export action into Advanced support controls; remove `AboutPage` and the empty `PageHeader`.
- [ ] Run ConfigInstaller and OMP extension contract tests, then `swift build`.
- [ ] Commit: `git commit -m "Organize integrations and advanced settings"`.

### Task 5: Reduce notification default density and verify end-to-end

**Files:**
- Modify: `Sources/CodeIsland/SettingsView.swift`
- Test: existing sound tests if present

**Interfaces:**
- `SoundPage` is renamed/relabelled Notifications in navigation but retains its persistence keys.
- Per-event rows and custom sound selection move under a collapsed `DisclosureGroup("Customize sounds")` shown only when sound is enabled.

- [ ] Keep Sound enabled, volume, quiet hours, completion, and approval at the top level.
- [ ] Put session start, error, prompt submit, boot sound, custom file menus, and preview buttons in Customize sounds.
- [ ] Rename the navigation label/icon to Notifications while preserving localization fallback where a label is unavailable.
- [ ] Launch the app and verify all five destination pages, shortcut record/cancel, integrations selector, disabled device controls, advanced disclosure, and sound customizer.
- [ ] Run `./scripts/check-companion-ui-regressions.sh`, `swift build`, and `swift test`.
- [ ] Commit: `git commit -m "Simplify settings navigation"`.

## Self-review

- Spec coverage: Tasks 1–5 cover all approved removals, five destinations, advanced demotion, support relocation, and sound density reduction.
- Placeholder scan: no deferred implementation or undefined interface names remain.
- Type consistency: all moved controls retain their existing SwiftUI views, `SettingsKey` names, and manager APIs; no new persistence interface is introduced.
