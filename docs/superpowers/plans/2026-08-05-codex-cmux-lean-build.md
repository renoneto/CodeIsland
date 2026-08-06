# Codex + CMUX Lean Build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a CodeIsland build that monitors Codex sessions in CMUX with no animated rendering, periodic hook repair, or optional-device/remote/updater/sound runtime paths.

**Architecture:** The existing socket bridge, HookServer, Codex App Server watcher, panel, and CMUX-aware Smart Suppress behavior remain intact. Event admission and hook installation are restricted to Codex; the shared `MascotView` becomes a static status glyph so current notch and session-list layout need no redesign.

**Tech Stack:** Swift 5.9, SwiftUI, Swift Package Manager, XCTest.

---

### Task 1: Prove only Codex events are admitted

**Files:**
- Modify: `Sources/CodeIslandCore/SessionSnapshot.swift`
- Modify: `Sources/CodeIsland/HookServer.swift`
- Test: `Tests/CodeIslandTests/SessionSnapshotTests.swift`

- [ ] **Step 1: Write the failing admission test**

```swift
func testNormalizedSupportedSourceAcceptsOnlyCodex() {
    XCTAssertEqual(SessionSnapshot.normalizedSupportedSource("codex"), "codex")
    XCTAssertNil(SessionSnapshot.normalizedSupportedSource("claude"))
    XCTAssertNil(SessionSnapshot.normalizedSupportedSource("gemini"))
}
```

- [ ] **Step 2: Run the focused test and verify it fails because non-Codex sources remain supported**

Run: `swift test --filter SessionSnapshotTests/testNormalizedSupportedSourceAcceptsOnlyCodex`

Expected: failure because `claude` and `gemini` are currently normalized.

- [ ] **Step 3: Restrict source normalization**

```swift
public static let supportedSources: Set<String> = ["codex"]

public static func normalizedSupportedSource(_ source: String?) -> String? {
    source?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "codex" ? "codex" : nil
}
```

Remove provider-specific fast paths in `HookServer` that only exist for Gemini/Cursor routing, while retaining Codex native-subagent handling.

- [ ] **Step 4: Run the focused test and verify it passes**

Run: `swift test --filter SessionSnapshotTests/testNormalizedSupportedSourceAcceptsOnlyCodex`

Expected: PASS.

### Task 2: Limit managed hooks to Codex and remove recurring repair

**Files:**
- Modify: `Sources/CodeIsland/ConfigInstaller.swift`
- Modify: `Sources/CodeIsland/AppDelegate.swift`
- Test: `Tests/CodeIslandTests/ConfigInstallerTests.swift`

- [ ] **Step 1: Write a failing install-list test**

```swift
func testLeanBuildInstallsOnlyCodexHooks() {
    XCTAssertEqual(ConfigInstaller.managedCLIs.map(\.source), ["codex"])
}
```

- [ ] **Step 2: Run the focused test and verify it fails because the current managed list contains every provider**

Run: `swift test --filter ConfigInstallerTests/testLeanBuildInstallsOnlyCodexHooks`

Expected: failure because `allCLIs` contains non-Codex providers.

- [ ] **Step 3: Add the Codex-only managed list and use it for install, settings status, and repair**

```swift
static var managedCLIs: [CLIConfig] {
    allCLIs.filter { $0.source == "codex" }
}
```

Replace `allCLIs` iteration in `install()` with `managedCLIs`, retain the existing Codex TOML hook enablement, and remove `hookRecoveryTimer`, the workspace-activation observer, `lastHookCheck`, and `checkAndRepairHooks()` from `AppDelegate`.

- [ ] **Step 4: Run the focused test and verify it passes**

Run: `swift test --filter ConfigInstallerTests/testLeanBuildInstallsOnlyCodexHooks`

Expected: PASS.

### Task 3: Remove optional runtime services

**Files:**
- Modify: `Sources/CodeIsland/AppDelegate.swift`
- Modify: `Sources/CodeIsland/HookServer.swift`
- Modify: `Sources/CodeIsland/AppState+TranscriptTailer.swift`
- Modify: `Sources/CodeIsland/AppState+CodexAppServer.swift`

- [ ] **Step 1: Write a compile-safe startup expectation**

Use the existing `AppDelegate` lifecycle tests to assert the HookServer and Codex watcher start without setting up remote-host callbacks, ESP32, Apple companion, Sparkle updater, or boot audio.

- [ ] **Step 2: Run the affected lifecycle test and confirm its current expectation requires the optional startup work**

Run: `swift test --filter AppDelegate`

Expected: existing coverage does not establish the lean startup boundary.

- [ ] **Step 3: Delete optional startup and event calls**

Remove `RemoteManager`, ESP32, Apple companion, `UpdateChecker`, `SoundManager`, the Claude usage prewarm, and matching shutdown calls from `AppDelegate`. Remove sound event calls in the two Codex event paths. Preserve `HookServer`, `ConfigInstaller.install()`, `PanelWindowController`, `startSessionDiscovery()`, and `startCodexAppServerWatcher()`.

- [ ] **Step 4: Build the application target**

Run: `swift build`

Expected: build completes with no unresolved optional-service references.

### Task 4: Replace all animated mascot rendering with a static status glyph

**Files:**
- Modify: `Sources/CodeIsland/MascotView.swift`
- Modify: `Sources/CodeIsland/NotchPanelView.swift`
- Modify: `Sources/CodeIsland/PanelWindowController.swift`
- Modify: `Sources/CodeIsland/AppDelegate.swift`
- Delete: `Sources/CodeIsland/{PixelCharacterView,BuddyView,DexView,GeminiView,CursorView,TraeView,CopilotView,QoderView,DroidView,StepFunView,OpenCodeView,QwenView,AntiGravityView,WorkBuddyView,HermesView,OpenClawView,KiroView,KimiView,PiView,ClineView,MascotAgentStatus,MascotAnimationGate,MascotMotion,MascotTimeline}.swift`

- [ ] **Step 1: Write the failing static-render contract test**

```swift
func testStatusIconUsesCodexAndWaitingSymbols() {
    XCTAssertEqual(CodexStatusIcon.symbol(for: .running), "terminal.fill")
    XCTAssertEqual(CodexStatusIcon.symbol(for: .waitingApproval), "exclamationmark.triangle.fill")
}
```

- [ ] **Step 2: Run the focused test and verify it fails because `CodexStatusIcon` does not exist**

Run: `swift test --filter MascotViewTests/testStatusIconUsesCodexAndWaitingSymbols`

Expected: compile failure for missing `CodexStatusIcon`.

- [ ] **Step 3: Implement the static SwiftUI view and delete timeline sources**

```swift
struct CodexStatusIcon: View {
    let status: AgentStatus
    var size: CGFloat

    static func symbol(for status: AgentStatus) -> String {
        switch status {
        case .waitingApproval, .waitingQuestion: return "exclamationmark.triangle.fill"
        case .running, .processing: return "terminal.fill"
        case .idle: return "terminal"
        }
    }
    var body: some View { Image(systemName: Self.symbol(for: status)) }
}
```

Keep the existing `MascotView` call sites as a compatibility wrapper around `CodexStatusIcon`, remove animation-gate environments from `NotchPanelView`, remove panel visibility calls from `PanelWindowController`, and replace the animated `TypingIndicator` with plain static status text. Delete the listed pixel-art sources and unused audio/icon resources.

- [ ] **Step 4: Run the focused test and verify it passes**

Run: `swift test --filter MascotViewTests/testStatusIconUsesCodexAndWaitingSymbols`

Expected: PASS.

### Task 5: Verify, commit, and push

**Files:**
- Modify: `README.md`
- Test: `Tests/CodeIslandTests/*`

- [ ] **Step 1: Replace the product description**

State that this fork monitors Codex sessions in CMUX and omits the upstream multi-provider, device-companion, sound, remote, and update features.

- [ ] **Step 2: Run the full test suite**

Run: `swift test`

Expected: 0 failures.

- [ ] **Step 3: Produce the release app**

Run: `./build.sh`

Expected: `.build/release/CodeIsland.app` exists.

- [ ] **Step 4: Commit and push only this lean-build change set**

```bash
git add Sources Tests README.md docs/superpowers/plans/2026-08-05-codex-cmux-lean-build.md
git commit -m "feat: make CodeIsland Codex CMUX only"
git push
```
