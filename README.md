# Taskbarra

Taskbarra is a macOS-only Dock replacement prototype written in Swift. Its core goal is to show one taskbar entry per window, with app icon + window title, instead of macOS Dock's app-level grouping.

## Status and discretion

Taskbarra is personal-use software, not a polished public product. Use it with discretion: it relies on sensitive macOS capabilities such as Accessibility access and optional read-only access to the local Notification Center database. This project has also been generated and modified mostly with LLM assistance, so review changes, keep backups, and treat the app as experimental software.

See [`CONTEXT.md`](./CONTEXT.md) for product and architecture decisions.

## Requirements

- macOS 14+
- Swift toolchain / Xcode Command Line Tools

This repo intentionally starts without an Xcode project. The current scaffold builds with Swift Package Manager and packages a local `.app` bundle via script.

## Installation

### Homebrew

```bash
brew install --cask jalbarrang/tap/taskbarra
xattr -dr com.apple.quarantine /Applications/Taskbarra.app
```

The release is ad-hoc signed rather than Developer ID signed or notarized. Homebrew 6 no longer supports `--no-quarantine`, so clear the quarantine attribute explicitly before the first launch.

### Manual DMG

Download the latest `Taskbarra-X.Y.Z.dmg` from [GitHub Releases](https://github.com/jalbarrang/taskbarra/releases), open it, and drag Taskbarra into Applications. Then run:

```bash
xattr -dr com.apple.quarantine /Applications/Taskbarra.app
```

On first launch, grant Taskbarra access in System Settings > Privacy & Security > Accessibility. Full Disk Access is optional and only needed for Notification Center badges and previews.

## Updating

For a Homebrew installation:

```bash
brew update
brew upgrade --cask taskbarra
xattr -dr com.apple.quarantine /Applications/Taskbarra.app
```

Every ad-hoc-signed release has a new signing identity from macOS's perspective. After an update, open System Settings > Privacy & Security > Accessibility, remove any stale Taskbarra entry, add `/Applications/Taskbarra.app` again, and relaunch the app.

## Releases and versioning

Taskbarra uses [Release Please](https://github.com/googleapis/release-please) with Conventional Commits to maintain semantic versioning and `CHANGELOG.md`. Pushes to `main` update or create a release PR; merging that PR creates the GitHub Release/tag.

When a GitHub Release is published, the release build workflow creates a versioned macOS DMG and updates the Taskbarra cask in [`jalbarrang/homebrew-tap`](https://github.com/jalbarrang/homebrew-tap). These personal builds use free ad-hoc signing (`codesign --sign -`) only so macOS can attach entitlements; they are **not** Developer ID signed or notarized. Expect Gatekeeper/TCC prompts, and keep treating the app as personal experimental software.

## Quality checks

```bash
./Scripts/check.sh
```

The check script requires and runs:

- `swift-format` (from PATH or `xcrun`)
- `swiftlint`
- `semgrep` with local rules from `.semgrep/`
- the local core test runner
- the app bundle build

Required quality tools:

```bash
brew install swiftlint semgrep
# swift-format can come from Xcode via xcrun, or Homebrew if preferred.
```

## Local setup

Install the versioned Git hooks before committing:

```bash
./Scripts/install-git-hooks.sh
```

This enables a `commit-msg` hook that enforces [Conventional Commits](https://www.conventionalcommits.org/):

```text
feat(taskbar): render app icons
fix(ax): refresh windows after Space changes
docs: document local build flow
```

## Build

```bash
./Scripts/build-app.sh
```

The local app bundle is created at:

```text
.build/Taskbarra.app
```

## Run locally

```bash
open .build/Taskbarra.app
```

For Accessibility testing, install and launch the app from a stable path:

```bash
./Scripts/install-local-app.sh
open /Applications/Taskbarra.app
```

macOS Accessibility/TCC permissions are tied to the app's code-signing identity and launch path. The default local build uses ad-hoc signing (`-`), which is convenient but can require re-approval after rebuilds. For repeated Accessibility testing, sign with a stable local certificate:

```bash
TASKBARRA_CODESIGN_IDENTITY="Apple Development: Your Name (TEAMID)" ./Scripts/install-local-app.sh
```

The scaffold shows a dark, always-visible bottom bar on the main display. Window detection, Accessibility onboarding, real work-area reservation, and window actions are tracked as Beads issues.

## Notification permissions and privacy

Taskbarra asks for Full Disk Access so it can read macOS Notification Center's local SQLite database and show app badges/previews in the taskbar. The database path is:

```text
~/Library/Group Containers/group.com.apple.usernoted/db2/db
```

Taskbarra opens this database read-only. It does not modify Notification Center data, mark system notifications as read, or upload notification contents. Notification badge state is tracked locally with a per-bundle-id "last seen" timestamp when you activate an app/window from Taskbarra or choose "Mark Notifications as Seen".

This integration depends on private macOS storage owned by `usernoted`. Apple can change the schema, path, or access behavior in any macOS release, and notification titles/bodies can contain sensitive data.

Notification previews are controlled by local `UserDefaults` keys:

- `showNotificationPreviews` (`false` by default): Taskbarra uses privacy-first defaults and shows generic notification labels instead of titles/bodies until previews are explicitly enabled.
- `excludedNotificationBundleIdentifiers` (empty by default): bundle ids to omit from notification menus/badges.
- `maxNotificationAge` (7 days by default): maximum age in seconds for notifications shown by Taskbarra.

To grant Full Disk Access, macOS requires a manual user action: open System Settings > Privacy & Security > Full Disk Access, click `+`, choose `Taskbarra.app`, and restart Taskbarra if prompted. Taskbarra can open the pane and reveal the app bundle, but it cannot add or enable itself automatically.

To disable notification reading entirely, revoke Full Disk Access from System Settings > Privacy & Security > Full Disk Access.

## Passive window enumeration

Taskbarra separates passive window discovery from explicit user actions:

- `WindowScanner` uses CoreGraphics `CGWindowListCopyWindowInfo` as the primary read-only source for visible windows.
- `WindowStore.refreshPassiveSnapshot()` builds the taskbar snapshot without activating, raising, focusing, minimizing, closing, moving, or resizing windows.
- `PassiveAXWindowScanner` uses Accessibility attribute reads to discover minimized windows and missing metadata without activating apps.
- `WindowSnapshotMatcher` correlates CoreGraphics windows with passive AX snapshots using PID, compatible titles, and tolerant frame matching.
- `WindowInteractionController` owns explicit user actions such as activate, raise, minimize, close, hide, quit, force quit, and relaunch.

Accessibility permission is still required for AX metadata and actions. Some apps, especially Electron, Chromium, Java, games, and heavily custom UIs, may expose incomplete or inconsistent AX window data. Minimized windows do not always have a CoreGraphics window id, so Taskbarra assigns deterministic synthetic ids for passive AX-only snapshots. Ambiguous matches are intentionally ignored instead of guessing.

Taskbarra also has a separate layout-management phase: `AXWindowWorkAreaCoordinator` may move/resize maximized windows to reserve the taskbar work area. That is not part of discovery; it is an explicit coordinator phase wired by `TaskbarWindowController` after passive snapshots change.

See [`docs/adr/0002-passive-window-enumeration.md`](./docs/adr/0002-passive-window-enumeration.md) for the detailed API boundary and audit.

## Native Dock collision

Taskbarra intentionally does not try to block the native macOS Dock hover trigger while it is open. That trigger is a system-level edge behavior and blocking it would require brittle global preference changes, private APIs, or unreliable transparent event shields.

For now, if you use Taskbarra on the bottom edge with the native Dock set to auto-hide, move the native Dock to the left or right edge to avoid overlap. See [`docs/adr/0001-dock-hover-collision.md`](./docs/adr/0001-dock-hover-collision.md) for the decision and follow-up placement work.

## Localization

Taskbarra uses English as the default UI language. User-facing app strings live in:

```text
Sources/Taskbarra/Resources/en.lproj/Localizable.strings
```

Use `L10n.text("string.key")` from `Sources/Taskbarra/Localization.swift` for visible app text instead of hardcoded literals. To add a translation, create another locale folder next to `en.lproj` (for example `es.lproj`) with a `Localizable.strings` file containing the same keys translated for that language.

## Issues

```bash
bd ready
bd show <id>
bd update <id> --claim
```
