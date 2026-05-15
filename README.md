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

The scaffold shows a dark, always-visible bottom bar on the main display. Window detection, Accessibility onboarding, real work-area reservation, and window actions are tracked as Beads issues.

## Issues

```bash
bd ready
bd show <id>
bd update <id> --claim
```
