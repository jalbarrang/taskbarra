# Taskbarra

Taskbarra is a macOS-only Dock replacement prototype written in Swift. Its core goal is to show one taskbar entry per window, with app icon + window title, instead of macOS Dock's app-level grouping.

See [`CONTEXT.md`](./CONTEXT.md) for product and architecture decisions.

## Requirements

- macOS 14+
- Swift toolchain / Xcode Command Line Tools

This repo intentionally starts without an Xcode project. The current scaffold builds with Swift Package Manager and packages a local `.app` bundle via script.

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

This integration depends on private macOS storage owned by `usernoted`. Apple can change the schema, path, or access behavior in any macOS release, and notification titles/bodies can contain sensitive data. If notification preview controls are added in configuration, disable or limit previews there; until then, revoke Full Disk Access from System Settings > Privacy & Security > Full Disk Access to disable notification reading entirely.

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
