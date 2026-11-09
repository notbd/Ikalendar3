# Contributing to ikalendar 3

## Tools

- Xcode, SwiftFormat and SwiftLint at the versions pinned in `scripts/versions.env`. CI uses exactly these, and the verify script refuses other linter versions, because rule behaviour changes between releases.
- Homebrew may carry newer linters. To install the pinned ones as CI does, download `swiftformat.zip` from the SwiftFormat release and `portable_swiftlint.zip` from the SwiftLint release with that version number, check each with `shasum -a 256` against its checksum in `scripts/versions.env`, and put both binaries first on your `PATH`.
- `jq`, `xmllint`, `perl` and `shasum` ship with macOS.

## Verify

`scripts/verify.sh` runs every check CI runs, in the same order, and stops at the first failure: SwiftFormat and SwiftLint, package tests on macOS, unsigned Debug builds for the iOS simulator, macOS and the watchOS simulator, unsigned Release builds for an iOS device (with the watch app) and macOS, then the iOS simulator test run. `scripts/verify.sh --help` lists what each step proves. Every ticket ends with it passing in full.

| Option | Environment variable | Default |
|---|---|---|
| `--derived-data PATH` | `VERIFY_DERIVED_DATA` | `build/DerivedData` in this checkout |
| `--ios-simulator UDID` | `VERIFY_IOS_SIMULATOR` | this checkout's own iPhone simulator |
| `--watch-simulator UDID` | `VERIFY_WATCH_SIMULATOR` | this checkout's own Apple Watch simulator |

- Logs, xUnit reports and result bundles of the last run are in `<derived data>/Verify`.
- On the skeleton, a run from scratch took 1.5 to 3 minutes on an Apple silicon Mac, and about 40 seconds after that.
- Any compiler or build warning fails the run. Swift warnings are errors in verify runs; any other warning also removes `<derived data>/Build`, so the next run builds from scratch and shows it again until it is fixed.
- The test step fails when a test bundle of `Ikalendar3.xctestplan` is missing or ran no tests, or when a package test bundle ran fewer tests in the simulator than on macOS. `xcodebuild` can skip a package's tests and still report success, so the exit code alone proves nothing.

## Parallel worktrees

Several checkouts can verify at the same time if each has its own derived data and its own simulators.

- Derived data: the default is inside the checkout. Only verify writes to it: a build warning that another build showed first is not shown again. For manual builds, use another folder, such as `build/Dev`.
- Simulators: pass the UDIDs assigned to the worktree, or leave them out. Without them, verify creates `ikalendar3 <checkout folder> <path hash> iPhone` and `... Apple Watch` on first use and reuses them. It never falls back to a shared device: two runs on one simulator install the same bundle ID, and the second kills the first's test host ("Test crashed with signal kill before establishing connection").
- The same rule holds for every simulator run, not only verify: fixture launches and screenshots on iPhone, iPad and watch simulators use the worktree's own devices.
- Verify leaves the iPhone simulator booted, so the next run starts faster. `xcrun simctl shutdown <UDID>` frees it.
- When a worktree goes away, delete its simulators: `xcrun simctl list devices | grep 'ikalendar3 '`, then `xcrun simctl delete <UDID>`. `xcrun simctl delete unavailable` removes devices whose runtime is gone.

## Faster loops

```sh
# Package tests on the Mac, in seconds
swift test --package-path Ikalendar3Kit

# App and package tests on the Mac (iOS-only code is not compiled there)
xcodebuild test -project Ikalendar3.xcodeproj -scheme Ikalendar3 -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build/Dev CODE_SIGNING_ALLOWED=NO

# One suite or test: add -only-testing:IkaCoreTests/AppGroupTests
```

## Project layout

- `Ikalendar3/`: the app for iPhone, iPad and Mac (one target). `Ikalendar3Widgets/`: the widget extension for iOS and macOS. `Ikalendar3Watch/` and `Ikalendar3WatchWidgets/`: the watch app and its widget extension. `Ikalendar3Tests/`: the app's tests.
- `Ikalendar3Kit/`: the local package with `IkaCore` (domain, data and every Surface's content), `IkaDesign` (design system) and `IkaIntents` (Siri, App Shortcuts and the effects shell; iOS and macOS, Live Activity parts behind `#if os(iOS)`). The app and the widget extension link all three; the watch targets link `IkaCore` and `IkaDesign`.
- `Ikalendar3Kit/Fixtures/`: recorded splatoon3.ink payloads. Everything that needs one reads it by path, so there is one copy; no target lists the folder as a resource, so no product ships it.
- Every target folder is a synchronized folder: a Swift file or subfolder added inside it is compiled with no project file change. A non-source file there becomes a resource of the target unless the project lists an exception, as it does for the widget extensions' `Info.plist`.
- Code that more than one target needs goes into a package module, never into two target folders.
- `IkaCore` imports no SwiftUI, UIKit, AppKit, WidgetKit, ActivityKit or App Intents; a SwiftLint rule fails the run if it does.
- `Ikalendar3.xctestplan` must list the app's test target and every package test target, or `xcodebuild` never runs them; verify fails until it does.
- A resource folder a package target declares must be committed, even if empty (a placeholder file keeps it). Font files are never committed, and no build step may need them.
- The package folder is also a file reference in the project. Without it, `xcodebuild` silently skips the package's tests.
- Signing: builds and macOS runs pass `CODE_SIGNING_ALLOWED=NO`. Simulator test runs keep automatic signing with no team (Xcode signs to run locally), so the test host carries its App Group entitlement.
- Swift 6 language mode with Approachable Concurrency everywhere. The app, its tests and the watch app run on the main actor by default; the widget extensions and package modules stay nonisolated.

## Tests

- Swift Testing. Each test name is a raw identifier that states the behaviour as a sentence, as in ikalendar 2:

  ```swift
  @Test
  func `App Group container resolves`() { ... }
  ```

  SwiftFormat removes a leading "Test" from such names, so start with the subject.
- The test plan runs in English (US). A test of another language passes the language explicitly.
- No test may depend on a font file being present: CI has none.

## Code and commits

- Code style follows ikalendar 2, which means `notbd/Ikalendar2` at commit `9a99cf3` on `main`; its SwiftFormat and SwiftLint configurations are carried over with this repository's file header and exclusions. `print` never ships: log with OSLog.
- Conventional commits in English with a verb-first description and a scope where one fits, for example `feat(core): decode battle schedules from the feed`.

## CI

`.github/workflows/ci.yml` runs `scripts/verify.sh` on every push and on manual dispatch, on GitHub's `xcode-27` image with exactly the pinned Xcode. It fails when the image lacks that Xcode instead of falling back to another, because code built against a newer SDK breaks on an older one. It downloads the pinned linters, fails unless their SHA-256 matches `scripts/versions.env`, and downloads nothing else: no fonts, no assets. On failure, the verify logs are attached to the run as `verify-logs`.
