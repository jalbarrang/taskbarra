# Release flow: version stamping, DMG artifact, Homebrew tap

## Context

Taskbarra (`jalbarrang/taskbarra`, public) is a personal macOS 14+ menu-bar/dock-replacement app built with SwiftPM (`Package.swift`, no Xcode project). It stays **ad-hoc signed** by deliberate choice — no Apple Developer account, no notarization, no Sparkle. Release trigger stays **release-please** (already working: conventional commits → release PR → tag `vX.Y.Z` → GitHub Release published → `release-build.yml` fires).

This plan upgrades the publish side to 2026 conventions where they apply to an unsigned personal app:

1. **Version stamping**: `CFBundleShortVersionString` = semver from the release tag; `CFBundleVersion` = monotonic build number (`github.run_number`). Today `Resources/Info.plist` is hardcoded at `0.1.0` while the repo is at `0.2.0`.
2. **DMG artifact** replacing the zip: `hdiutil` UDZO image with an `/Applications` symlink — no third-party dmg tooling.
3. **Generic personal Homebrew tap** (`jalbarrang/homebrew-tap`) so future tools (pit, hiker, …) can share it. Users run `brew tap jalbarrang/tap && brew install --cask taskbarra` (or the one-liner `brew install --cask jalbarrang/tap/taskbarra --no-quarantine`). CI auto-bumps the cask on every release.

Deliberately out of scope (user decision): Developer ID signing, notarization/stapling, Sparkle auto-update, appcast.

## Key facts for the executor

- Build entry point: `Scripts/build-app.sh` — builds via `swift build`, assembles `.build/Taskbarra.app`, copies `Resources/Info.plist` verbatim, ad-hoc signs with `TASKBARRA_CODESIGN_IDENTITY` (default `-`). Version stamping must happen on the **copied** plist inside the bundle (use `/usr/libexec/PlistBuddy`), and **before** codesign (signing seals the bundle).
- Existing workflow `.github/workflows/release-build.yml` triggers on `release: published`, runs on `macos-14`, builds ad-hoc zip, uploads via `gh release upload`. Rework it in place.
- Tag format is `vX.Y.Z` (release-please, `include-component-in-tag: false`). Strip the `v` for `CFBundleShortVersionString`.
- Ad-hoc caveats that must be documented, not hidden:
  - Gatekeeper blocks quarantined ad-hoc apps. Homebrew applies quarantine by default → users must install with `--no-quarantine`. Manual DMG users need `xattr -dr com.apple.quarantine /Applications/Taskbarra.app`. Put this in the cask `caveats` block and README.
  - Every release has a different ad-hoc signature → macOS TCC treats it as a new app → users must **re-grant Accessibility** after each update. Document in README and cask caveats.
- Tap push from CI needs a secret `TAP_GITHUB_TOKEN`: fine-grained PAT scoped to `jalbarrang/homebrew-tap`, contents read/write. The user must create this — CI cannot. STOP and ask if it's missing at execution time.
- Cask URL shape: `https://github.com/jalbarrang/taskbarra/releases/download/v#{version}/Taskbarra-#{version}.dmg`. Note: release-please tags include `v`, cask `version` field does not.

## Verification (whole plan)

Dry-run locally: `VERSION=9.9.9 BUILD_NUMBER=42 CONFIGURATION=release ./Scripts/build-app.sh && ./Scripts/package-dmg.sh` → `.build/Taskbarra-9.9.9.dmg` exists; `hdiutil attach` it, confirm `Taskbarra.app` + `Applications` symlink; `defaults read` the mounted app's Info.plist shows `9.9.9` / `42`. Full E2E: land a `fix:` commit, merge the release PR, watch the workflow upload the DMG and push a cask bump to the tap, then `brew install --cask jalbarrang/tap/taskbarra --no-quarantine` on a real machine.
