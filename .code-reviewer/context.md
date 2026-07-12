# Review Context — Taskbarra

## Mode signals
Default target: uncommitted changes. Base branch: `main` (single-branch repo, conventional commits enforced by `Scripts/validate-conventional-commit.sh`). Full gate: `Scripts/check.sh` (swift-format, swiftlint --strict, semgrep `.semgrep/`, swift test, app-bundle build).

## Architecture (dependency order)
- `Sources/TaskbarraCore/` → pure, testable logic (window parsing/matching, notification reading/privacy/deep-link policy, frame policy). No AppKit/AX side effects; system APIs only behind protocols (e.g. `WindowInfoProviding`). A bug here propagates into every scan/refresh cycle in the app layer.
- `Sources/Taskbarra/` → AppKit/AX shell: window store, event monitors, interaction controller, geometry, onboarding, status item. Depends on Core, never the reverse.
- `Tests/TaskbarraCoreTests/` → only Core is covered; app-layer changes ship without test evidence.
- Domain docs: `CONTEXT.md` (design decisions table) and `docs/adr/` own product-level rationale — check ADRs before flagging a decision as a bug.

## Critical invariants
- **Notification previews default to private:** `NotificationPrivacyConfiguration` defaults `showNotificationPreviews: false`; title/body must pass through `NotificationPrivacyFilter` before display, and deep links through `NotificationDeepLinkPolicy` (block `file`/`javascript`/`data`, confirm unknown schemes). Owner: `Sources/TaskbarraCore/NotificationPrivacyFilter.swift`, `NotificationDeepLinkPolicy.swift`. Breaks → notification content or unsafe URL opens leak past user privacy settings.
- **No global Dock / system-pref mutation:** never kill Dock.app, rewrite user defaults at runtime, or use private APIs to suppress Dock hover. Owner: `docs/adr/0001-dock-hover-collision.md`. Breaks → user's global system state silently changed, possibly persisting after a crash.
- **TaskbarraCore purity:** Core must stay free of AppKit/AX imports and side effects so it remains testable under the custom runner. System reads enter only via injected protocols. Owner: `Package.swift` target split + existing Core sources as precedent. Breaks → untestable logic and layer inversion.

## Intentional patterns (false-positive suppressors)
- **Reading Notification Center's private sqlite DB:** `NotificationCenterDatabaseReader` reads the macOS private notification store via Full Disk Access. Looks like data exfiltration; it is the core notification feature (read-only, filtered by the privacy layer).
- **`AXWindowWorkAreaCoordinator` setting `kAXPositionAttribute`/`kAXSizeAttribute`:** looks like a passive-boundary violation; it is the sanctioned layout-reconciliation phase per `docs/adr/0002-passive-window-enumeration.md`, deliberately wired as a separate post-snapshot step (`reconcileWorkAreaAfterPassiveDiscovery`).
- **Ad hoc signing, no notarization, no auto-update:** deliberate personal-software distribution decision (owner: `CONTEXT.md` decisions table). Not a supply-chain finding.
- **Best-effort AX reads with silent failure:** AX attribute reads returning nil / swallowing errors are expected — many apps lack AX support. Only flag when a swallowed error masks a state-machine transition (see permission bugs below).

## Historical bug classes
- **Wrong-window activation/raise:** app-level `activate` raising all of an app's windows instead of the clicked one. Trigger: any change to `WindowInteractionController` activation paths. Impact: focus disruption — the top severity class here.
- **Permission state-machine flakiness:** Accessibility / Full Disk Access onboarding and re-prompt logic misreading grant state. Trigger: changes around `AccessibilityPermission`, `FullDiskAccessPermission`, onboarding controllers.
- **CG↔AX snapshot mismatches:** `WindowSnapshotMatcher` correlates CoreGraphics windows with passive AX snapshots via PID + title compatibility + tolerant frame comparison. Trigger: heuristic tweaks or new window states (minimized, fullscreen, Rectangle-resized). Impact: stale/duplicate/missing taskbar entries or actions sent to the wrong AX window.

## Testing conventions
Custom XCTest executable runner (`Tests/TaskbarraCoreTests/main.swift`) because this toolchain setup doesn't expose XCTest/Testing to SwiftPM (`private_unit_test` lint disabled for this reason — owner: `.swiftlint.yml`). Unit tests exist only for `TaskbarraCore`; system-API seams are stub protocols (e.g. `StubWindowInfoProvider`). App-layer (`Sources/Taskbarra/`) behavior has no automated coverage — reviewer must not accept "tests pass" as evidence for app-layer changes.

## Severity calibration
- 9-10: Disrupting the user's system uninvited — stealing focus, raising/moving/resizing windows from discovery paths (violating ADR-0002's passive contract), or mutating global Dock/system prefs.
- 7-8: Notification content or deep links bypassing the privacy layer; actions dispatched to the wrong window via matcher regressions.
- 5-6: Taskbar showing wrong state (stale entries, wrong active indicator, missing minimized windows); permission onboarding dead-ends.
- 3-4: Degraded-but-recoverable behavior: missed refresh, icon/title fallback failures, geometry off-by-a-few-px without overlap.

## Review priorities
1. Any AX/`NSRunningApplication` call added to discovery/scan/monitor code paths (`WindowScanner`, `WindowStore`, `PassiveAXWindowScanner`, `AXWindowEventMonitor`) — mutation belongs only in `WindowInteractionController` and `AXWindowWorkAreaCoordinator`.
2. Notification display/open paths — must route through `NotificationPrivacyFilter` and `NotificationDeepLinkPolicy`.
3. Changes to `WindowSnapshotMatcher` heuristics or `WindowInteractionController` activation logic — the two recurring bug factories.
