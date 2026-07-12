# AGENTS.md

## What this is

Taskbarra is a personal-use macOS Dock replacement: a Windows-style taskbar showing one entry per open window. Swift Package Manager only — no Xcode project; the `.app` bundle is assembled by `Scripts/build-app.sh`. Product and architecture decisions live in `CONTEXT.md`; per-decision rationale lives in `docs/adr/`. Dependency direction: `Taskbarra` (app shell) → `TaskbarraCore` (pure logic) only.

## Stack

| Area | Tech |
|---|---|
| Language | Swift 6, macOS 14+ (`Package.swift` owns both) |
| UI | SwiftUI content inside AppKit windows (`NSHostingView`) |
| System APIs | Accessibility (`AXUIElement`, `AXObserver`), CoreGraphics (`CGWindowListCopyWindowInfo`) |
| Tests | XCTest-based runner in `Tests/TaskbarraCoreTests`, core logic only |
| Lint | swift-format, swiftlint (`.swiftlint.yml`), semgrep (`.semgrep/`) |
| Releases | Release Please + GitHub Actions (`.github/workflows/`), DMG + Homebrew cask in `jalbarrang/homebrew-tap` |

## Commands

| Task | Command |
|---|---|
| Full check (format, lint, semgrep, tests, build) | `./Scripts/check.sh` |
| Tests only | `swift test` |
| Build app bundle → `.build/Taskbarra.app` | `./Scripts/build-app.sh` |
| Install to `/Applications` for Accessibility testing | `./Scripts/install-local-app.sh` |
| One-time stable local signing identity | `./Scripts/setup-local-codesign.sh` |
| Install git hooks (required before committing) | `./Scripts/install-git-hooks.sh` |

## Rules

- **Core/shell split:** policy, parsing, and matching logic goes in `Sources/TaskbarraCore` with tests; `Sources/Taskbarra` is the AppKit/SwiftUI shell and stays untested. Never import AppKit into `TaskbarraCore`.
- **Passive discovery must not touch windows.** `WindowScanner`, `PassiveAXWindowScanner`, and `WindowStore.refreshPassiveSnapshot()` are read-only: no activating, raising, focusing, minimizing, moving, or resizing. Explicit user actions belong in `WindowInteractionController`; work-area layout belongs in `AXWindowWorkAreaCoordinator`. ADR 0002 owns the boundary.
- **Read the relevant ADR before reshaping an area it covers:** 0001 native Dock collision, 0002 passive window enumeration, 0003 multi-monitor taskbars.
- **Conventional Commits, enforced.** The `commit-msg` hook (`.githooks/`, installed via `install-git-hooks.sh`) validates messages; Release Please derives versions and `CHANGELOG.md` from them. Never hand-edit `CHANGELOG.md` or version numbers.
- **User-facing strings go through `L10n.text(...)`** (`Sources/Taskbarra/Localization.swift`), with keys in `Sources/Taskbarra/Resources/en.lproj/Localizable.strings`. No hardcoded UI literals.
- **Banned constructs are machine-enforced:** no `try!`, `as!`, `fatalError`, `Process()`, or private Spaces APIs (`CGS*`) in `Sources/`. The rule list lives in `.semgrep/swift-taskbarra.yml`, not here.
- **Notification Center access is read-only.** `NotificationCenterDatabaseReader` reads the private `usernoted` SQLite db; never write to it or mark notifications read. Privacy defaults (previews off, exclusions, max age) are `UserDefaults` keys owned by `NotificationPrivacySettingsStore`.

## Key paths

- `Sources/TaskbarraCore/` → pure, testable logic: window scanning/matching, policies, notification reading
- `Sources/Taskbarra/` → app shell: coordinators, controllers, views, onboarding, status item
- `Tests/TaskbarraCoreTests/` → core tests (one file per subject)
- `Scripts/` → build, check, install, codesign, hooks — the authoritative command list
- `Resources/` → `Info.plist`, entitlements for the app bundle
- `docs/adr/` → architecture decision records
- `.plans/` → taskman plan ledger (plan and task tracking)
- `CONTEXT.md` → product decisions and scope (Spanish)

## Gotchas

- **Accessibility/TCC permissions are bound to signing identity + install path.** A plain rebuild resets them. Run `setup-local-codesign.sh` once, then always test via `install-local-app.sh` and `/Applications/Taskbarra.app`. `TASKBARRA_CODESIGN_IDENTITY` overrides the identity choice.
- **Releases are ad-hoc signed, not notarized.** Every release is a new identity to macOS: users must re-grant Accessibility and clear quarantine (`xattr -dr com.apple.quarantine`). Don't "fix" Gatekeeper prompts in code; the constraint is the missing Developer ID.
- **AX window data is unreliable for Electron/Chromium/Java apps,** and minimized windows may lack a CoreGraphics window id — synthetic ids and ignore-on-ambiguity are deliberate (`WindowSnapshotMatcher`, ADR 0002), not bugs to fix.
- **Blocking the native Dock hover trigger is out of scope** — it needs private APIs or brittle hacks (ADR 0001). The mitigation is user-side Dock placement.
