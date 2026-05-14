# Taskbarra

Taskbarra is a macOS-only Dock replacement prototype written in Swift. Its core goal is to show one taskbar entry per window, with app icon + window title, instead of macOS Dock's app-level grouping.

See [`CONTEXT.md`](./CONTEXT.md) for product and architecture decisions.

## Requirements

- macOS 14+
- Swift toolchain / Xcode Command Line Tools

This repo intentionally starts without an Xcode project. The current scaffold builds with Swift Package Manager and packages a local `.app` bundle via script.

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
