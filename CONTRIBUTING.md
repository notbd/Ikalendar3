# Contributing to ikalendar 3

## Tools

- Xcode, SwiftFormat and SwiftLint at the versions pinned in `scripts/versions.env`. CI uses exactly these, and the verify script refuses other linter versions, because rule behaviour changes between releases.
- Homebrew may carry newer linters. To install the pinned ones as CI does, download `swiftformat.zip` from the SwiftFormat release and `portable_swiftlint.zip` from the SwiftLint release with that version number, check each with `shasum -a 256` against its checksum in `scripts/versions.env`, and put both binaries first on your `PATH`.
- `jq`, `xmllint`, `perl` and `shasum` ship with macOS.
- Only the asset script (see Bundled images and Fonts) needs Python, at the version `scripts/versions.env` pins.

## Verify

`scripts/verify.sh` runs every check CI runs, in the same order, and stops at the first failure: SwiftFormat and SwiftLint, the wording check (`scripts/check-wording.sh`), the string catalog check, the hosts check (`scripts/check-hosts.sh`: shipped code can contact only `splatoon3.ink` and `assets.splatoon3.ink`, and every other address is a listed link the player opens), package tests on macOS, unsigned Debug builds for the iOS simulator, macOS and the watchOS simulator, unsigned Release builds for an iOS device (with the watch app) and macOS, each checked for fixture files, for one resource framework per app and for a privacy manifest that declares each required-reason API its binaries use (the macOS app and widget extension also for their copy of `IkaIntents`' names), then the iOS simulator test run. `scripts/verify.sh --help` lists what each step proves. Every ticket ends with it passing in full.

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
# Package tests on the Mac, in seconds. The first run after a new resource file can test an old
# copy of the resources and read a string's key; run it again (verify's package test step says why).
swift test --package-path Ikalendar3Kit

# App and package tests on the Mac (iOS-only code is not compiled there)
xcodebuild test -project Ikalendar3.xcodeproj -scheme Ikalendar3 -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build/Dev CODE_SIGNING_ALLOWED=NO

# One suite or test: add -only-testing:IkaCoreTests/AppGroupTests
```

## Running the app

- Simulator runs keep the default signing (Sign to Run Locally), which gives the app its App Group container. An unsigned simulator build has none: the app logs it as an error in the `store` category and shows the empty state. It never keeps data in a folder of its own, which the widget extension could not see.
- Each request logs its status in the `network` category at info level, so a launch that sends none shows nothing:

  ```sh
  xcrun simctl spawn <UDID> log stream --level info \
    --predicate 'subsystem == "io.tianwei.ikalendar3" AND category == "network"'
  ```

- The background refresh task (`BackgroundRefresh` in `IkaIntents`) never runs in the Simulator: the system refuses every request there, which the app logs in the `background` category each time it moves to the background. How often it runs is checked on a device.
- The Mac has no background refresh task. While the app runs, with its window open or only its menu bar entry, `MacBackgroundRefresh` in `IkaIntents` runs the effects shell about every two hours (an `NSBackgroundActivityScheduler`, which runs an overdue run soon after a wake) and 30 seconds after each wake from sleep, under the same gate, so desktop widgets reload after each refresh that commits a feed. Each run is logged at info level in the `background` category. Nothing refreshes after the player quits the app. Closing the window keeps the app running in the menu bar; the menu bar window's button brings the window back.
- The watch app (`io.tianwei.ikalendar3.watchkitapp`) fetches on its own: its own refresh engine on the watch's App Group container, under the same gate. It refreshes each time it becomes active and from its background refresh task (`WatchBackgroundRefresh`), which asks for a run five minutes past the first Rotation boundary at least an hour away (`WatchRefreshSchedule` in `IkaCore`); watchOS grants those runs only within its budget, about four an hour while a complication of the app is on the active face. Each refresh that committed a feed reloads the complications, as the effects plan says. Requests and refusals are logged in its `background` category. How often it runs is checked on a device.
- Debug builds read these launch options; Release builds ignore them. Pass them after `xcrun simctl launch <UDID> io.tianwei.ikalendar3`, after `--args` of `open` on the Mac, or in the scheme's arguments. A launch with a missing or malformed option stops with its reason instead of falling back to the network.

  | Option | Effect |
  |---|---|
  | `--fixture <name>` `--fixture-folder <path>` `--fixture-instant <ISO 8601>` | Runs on the recorded schedules feed `<name>` (a `Fixture` case, such as `normalDay`) with the recorded `festivals.json` and locale files, read from `<path>`, the checkout's absolute `Ikalendar3Kit/Fixtures`. The clock starts at the instant and runs from it, so a screen can cross a boundary while you watch. The shared cache stays untouched. |
  | `--fixture-rebase` | With the fixture options: moves every time in the payloads by now minus the instant, commits them to the shared cache and runs on the system clock, so widgets and the Live Activity show the fixture day too. The cache keeps them until a live refresh replaces them, which the gate allows from an hour after the launch; delete the app to drop them at once. Without it the app hides the track button: Tracking runs on the shared cache and the network, which an unrebased launch never touches. |
  | `--fixture-time-zone <identifier>` | With the fixture options: the screens write every time as it reads in `<identifier>` (such as `Asia/Tokyo`); reminders and Siri answers keep the device's zone. With `--fixture-rebase` too, the payloads move by whole hours only and the screens use a fixed-offset zone that takes back that move, so a launch at any hour shows the recorded clock times; the system clock then stands within half an hour of the instant in the recording. |
  | `--fixture-short-tracking <Mode>` | iOS app only: after each activation run, Tracks `<Mode>` (`regularBattle`, `anarchySeries`, `anarchyOpen`, `xBattle` or `salmonRun`, the Mode parameter's raw values) with the cached items, each two minutes long from now, so a recording crosses two Live Activity boundaries in four minutes. Opening the app again starts it over, and the activity's Refresh button re-arms it from the cache with the real times. |
  | `--fixture-offline` | App only: every request fails as with no network, through the scripted transport with nothing scripted. With `--data-folder` and `--defaults-suite` naming a new folder and suite, the launch is a first launch with no network and no cache: the welcome screen, then the empty state. |
  | `--event-cards` | Shows every event card at the app clock's instant, one under the other, instead of the tabs, so a fixture launch can screenshot them at an iPhone's width; the iPad event strip shows them side by side. |
  | `--showcase widgets\|live-activity\|menu-bar` | Instead of the tabs, draws the Surfaces the system draws with their own views from the snapshot at the app clock's instant, on a backdrop standing in for the Lock Screen, Home Screen or desktop: on iPhone, the Lock Screen and Home Screen widgets (`widgets`) or the Live Activity in the Dynamic Island and on the Lock Screen (`live-activity`); on iPad, Home Screen widgets; on the Mac, the menu bar window beside desktop widgets (`menu-bar`). Pass `--fixture-rebase`, so the system's countdowns run on the fixture day. The watch app takes `--showcase complications`: the complications on a watch face. |
  | `--window-size <width>x<height>` `--landscape` | Mac: opens the main window with that frame in points, title bar included (the title bar turns clear with a showcase). iPad: lays the window out as in landscape, turned a quarter clockwise to fill the portrait screen with no status bar, since the simulator takes no rotation from the command line; turn the screenshot back (`sips --rotate 270`). |
  | `--data-folder <path>` `--defaults-suite <name>` | Keeps the feed cache and its attempt records in `<path>` and the preferences in the suite `<name>` instead of the App Group. The two go together. |
  | `--scroll-anchor top\|center\|bottom` | Watch app only: starts the Now page, or a later list, scrolled to its top, middle or bottom, so a fixture launch can screenshot every row; the watch simulator takes no scroll input from the command line. |
  | `--mode-page <Mode>` `--later-list` | Watch app only: opens that Mode's page over the Now page (the Mode parameter's raw values, as `--fixture-short-tracking` takes them), and with `--later-list` its later Rotations or Shifts too, so a fixture launch can screenshot pages the simulator cannot tap to. |

  ```sh
  # Regular Battle ten seconds before the 14:00 UTC Rotation boundary of the normal day
  xcrun simctl launch <UDID> io.tianwei.ikalendar3 --fixture normalDay \
    --fixture-folder "$PWD/Ikalendar3Kit/Fixtures" --fixture-instant 2026-10-20T13:59:50Z
  ```

- A launch argument `-<key> <value>` sets a preference for that launch only, over every defaults suite, such as `-pref.default_mode salmon_run` or `-state.should_show_onboarding '<false/>'` (a Boolean is written as a property list value).
- Tracking's Live Activity renders on the system clock, so fixture launches that show it pass `--fixture-rebase`. The Simulator has no lock button an automation can press; Notification Center, pulled down from the top edge, shows the activity as the Lock Screen does. Each start, update and end is logged at info level in the `tracking` category.
- The watch app takes the fixture options, `--scroll-anchor`, `--mode-page` and `--later-list` on the worktree's own watch simulator, which needs no iPhone app running:

  ```sh
  # The Now page during the 2026-11-01 Splatfest, scrolled to its last rows
  xcrun simctl launch <watch UDID> io.tianwei.ikalendar3.watchkitapp --fixture splatfestSecondHalf \
    --fixture-folder "$PWD/Ikalendar3Kit/Fixtures" --fixture-instant 2026-11-01T05:23:00Z --scroll-anchor bottom

  # Salmon Run's later Shifts on the Big Run day
  xcrun simctl launch <watch UDID> io.tianwei.ikalendar3.watchkitapp --fixture bigRun \
    --fixture-folder "$PWD/Ikalendar3Kit/Fixtures" --fixture-instant 2026-09-07T12:00:00Z --mode-page salmonRun --later-list
  ```

- Mac runs start with `open -n <app> --args ...`: a Debug binary started directly from a shell runs but opens no window. macOS restores the window as the last run left it, so a run after one that quit with the window closed opens none; `-ApplePersistenceIgnoreState YES` after the app's options opens it anyway. `open -g` keeps the app behind the window in front.
- The Mac window opens on the view stored in `pref.mac_layout` (`columns`, `sidebar` or `overview`) and the Style in `pref.style`, so a fixture launch picks both with `defaults write <suite> pref.mac_layout overview` before it starts.
- Mac runs from a worktree pass the data options: an unsigned, unsandboxed Mac process gets the App Group folder that every worktree on the machine shares. Use a folder inside the worktree and a suite named after it, for example `--data-folder "$PWD/build/AppData" --defaults-suite "ikalendar3-$(basename "$PWD")"`.

## App Store screenshots

`scripts/screenshots.sh` captures the 16 raw App Store screenshots (iPhone 6, iPad 4, Mac 3, Apple Watch 3) in each of the 14 languages from fixed data into `build/Screenshots/AppStore/<language>`; `--languages "en ja"` takes fewer. Build the fonts first (`scripts/assets.sh --only fonts`): before it captures anything, the script launches the app once on each device and stops unless that launch's font log says every face registered. A capture fails when the app has quit by then, or on the Mac has closed its window, since a crashed app leaves a Home Screen of the right size. It checks each image's pixel size against the App Store size it targets.

- App screens come from fixture launches, opened by launch options and preferences passed as launch arguments, with no taps. Widgets, the Live Activity, the menu bar window and the complications come from `--showcase`, rebased, since a script can neither place a widget nor show the Lock Screen. Every launch writes times as they read in Tokyo (`--fixture-time-zone`), so every language and every run shows the same times.
- It builds Debug into `build/Dev` (`--derived-data` names another folder), creates its own iPhone, iPad and Apple Watch simulators of App Store sizes and deletes them at the end; `--iphone`, `--ipad` and `--watch` take existing UDIDs instead. It installs the app, sets the iPhone and iPad to dark appearance with a 9:41 status bar, switches the iPad to full-screen apps, and before each language sets the iPad's and the watch's system language and restarts them, so the iPad status bar's date and the watch's clock read in it too. Its rebased launches commit fixture payloads to each device's App Group cache, as `--fixture-rebase` does.
- A simulator passed by UDID is put back at the end as it was found: its languages, appearance, status bar override, the iPad's multitasking setting, the App Group container as the installed app found it, and whether the simulator was booted. One that was booted restarts, so its languages apply. The app it installs stays installed, in place of any build that was there. A simulator it cannot put back is named in an error, with what it was saved in the output folder's `.borrowed`.
- The Mac window is captured by its window id, so nothing else on the screen is.
- A run of all 14 languages, builds included, took 35 minutes on a 10-core Apple silicon Mac. The watch simulator takes no status bar override, so its corner shows the real time, and the complications' watch face shows the same.

## Project layout

- `Ikalendar3/`: the app for iPhone, iPad and Mac (one target). `Ikalendar3Widgets/`: the widget extension for iOS and macOS. The views of the widgets, the Live Activity and the complications live in `IkaDesign` (`Widgets/`, `Tracking/`, `WatchWidgets/`), so the app's Debug showcase draws the same ones; the extensions keep their configurations, timeline providers, intents and the Refresh button. `Ikalendar3Watch/` and `Ikalendar3WatchWidgets/`: the watch app and its widget extension. `Ikalendar3Tests/`: the app's tests. `IkaResources/`: the framework that ships the fonts and the image catalog (below).
- `Ikalendar3Kit/`: the local package with `IkaCore` (domain, data and every Surface's content), `IkaDesign` (design system) and `IkaIntents` (the Siri and Tracking intents and the effects shell on iOS and macOS, Live Activity and Siri parts behind `#if os(iOS)`; on watchOS only its parameter types). The app and the widget extension link all three; the watch app links `IkaCore` and `IkaDesign`, and the watch widget extension those two and `IkaIntents`, for the Mode its complications are set to. A watchOS build of `IkaIntents` holds no Live Activity, background task, effects shell or Siri code: each sits behind `#if os(iOS)` or `#if !os(watchOS)`. The app, both widget extensions and the watch app also link `IkaFixtures`: the two apps for their Debug launch options, the extensions for their previews; each uses it only under `#if DEBUG`. All four link `IkaResources`.
- `Ikalendar3Kit/Fixtures/`: recorded splatoon3.ink payloads. Everything that needs one reads it by path, so there is one copy; no target lists the folder as a resource, so no product ships it.
- `IkaFixtures`: the package's test support module, not a product module: the scripted transport, the settable clock and the `Fixture` loader for that folder. Package tests, Debug fixture launches and previews use it. Its code is compiled only in Debug (every file is `#if DEBUG`): a package product cannot be linked per configuration, so Release products link it empty, and code that uses it outside `#if DEBUG` fails the Release build. Verify fails when a Release binary names the module, a payload or a fixture launch option. It holds no fixture file. A temporary directory per test stays a test helper (`makeTestDirectory()`).
- Every target folder is a synchronized folder: a Swift file or subfolder added inside it is compiled with no project file change. A non-source file there becomes a resource of the target unless the project lists an exception, as it does for the widget extensions' `Info.plist`.
- Code that more than one target needs goes into a package module, never into two target folders.
- The App Shortcuts provider and its phrase catalog live in the app target (`Ikalendar3/Siri/`), not in `IkaIntents`: the build leaves a package's App Shortcuts out of the app's `Metadata.appintents` (its intents and parameter types do reach it). iOS only.
- The app, the widget extension (both on iOS and macOS) and the watch widget extension also bundle `IkaIntents`' `Localizable.xcstrings` themselves (the same file, listed in each target's Resources). The App Intents metadata records each title and parameter name by key only, and Siri, Shortcuts, the widget and complication editors and Control Center look the key up in the host bundle's own `Localizable` table, so without it they show the English keys in every language. `IntentTablesTests` reads the copies from the built products in the iOS test run, and verify's macOS Release step compares the Mac app's and widget extension's copies with the package's own table. The Control Center control's name, configuration title and Mode setting are read from that copy too, so only its description sits in `Controls.xcstrings`.
- A target that uses `IkaIntents`' App Intents types, such as the Battle Mode a widget is set to, lists `IkaIntentsPackage` in an `AppIntentsPackage` of its own (`Ikalendar3Widgets.swift` and `Ikalendar3WatchWidgets.swift` show how). Without it the build leaves them out of the target's `Metadata.appintents`, and the system never offers them.
- `IkaCore` imports no SwiftUI, UIKit, AppKit, WidgetKit, ActivityKit, App Intents, UserNotifications or BackgroundTasks; a SwiftLint rule fails the run if it does.
- `Ikalendar3.xctestplan` must list the app's test target and every package test target, or `xcodebuild` never runs them; verify fails until it does.
- A resource folder a package target declares must be committed, even if empty (a placeholder file keeps it). Font files are never committed, and no build step may need them.
- The build copies a package module's resources into every product that links the module, so a package module holds only small resources, such as its string tables (read from its own `Bundle.module`). The fonts and the image catalog live in `IkaResources/`, a framework embedded once in the app and once in the watch app; each widget extension loads its host app's copy through its run path (`@executable_path/../../Frameworks`; on macOS four levels up) and carries none. The verify script fails on any other copy. Each of the four targets calls `BundledResources.load(from: IkaResources.bundle)` once at start: it registers the fonts, points `BundledImage.catalogBundle` at the catalog and logs both locations (OSLog categories `fonts` and `images`). Nothing else registers fonts.
- `IkaResources` builds every architecture in Debug too (`ONLY_ACTIVE_ARCH = NO`). A watchOS Simulator build leaves a link stub of the framework that later builds reuse; a stub with only the active architecture fails the next build that needs both, such as the watch app built for the iOS test run.
- The package folder is also a file reference in the project. Without it, `xcodebuild` silently skips the package's tests.
- Signing: builds and macOS runs pass `CODE_SIGNING_ALLOWED=NO`. Simulator test runs keep automatic signing with no team (Xcode signs to run locally), so the test host carries its App Group entitlement.
- Swift 6 language mode with Approachable Concurrency everywhere. The app, its tests and the watch app run on the main actor by default; the widget extensions and package modules stay nonisolated.

## Bundled images

- `scripts/assets.sh` builds every Stage, weapon, Rule, Mode and King Salmonid image from `scripts/assets/manifest.json`: it downloads each source, checks its sha256, renders the group's three pixel sizes into the asset catalog in `IkaResources/` and writes the Swift index of bundled ids (`BundledImage+Index.swift`). It needs network and the Python version pinned in `scripts/versions.env`; its packages are pinned with hashes in `scripts/assets/requirements.txt`, so a second run writes the same bytes. The built images are committed; CI never runs it.
- A new Stage or weapon: add one line to its group with the id and image path as the feed writes them, and run the script. It stops with the file's sha256; add that to the line and run it again. Commit the manifest, the catalog and the index together.
- Names are the decoded feed id, lowercased (`VsStage-1` gives `vsstage-1_small`); weapons and Mode icons carry their group (`weapon-<id>`, `mode-<name>`). The script refuses an id outside the namespaces its group lists, and two ids that give one name.
- Stage art is JPEG (opaque photos, about a quarter of the size of PNG); everything else is PNG with alpha. Raster sources are scaled down to fit each size, never up.
- An id with no bundled image, such as a Stage added after a release, shows its group's placeholder.

## Fonts

- `scripts/assets.sh` also builds SplatNet 3's fonts into `IkaResources/Fonts`, which git ignores: one file per face, named for the face and carrying it as its PostScript name, as `FontFace` expects (`Splatoon1`, `Splatoon1KRko`, `Splatoon1JP`, `Splatoon1CHzh`, `Splatoon1TWzh` and the same five for `Splatoon2`). The resource framework ships whatever faces are there (Project layout). `scripts/assets.sh --only fonts` builds only the fonts. CI and the verify script never run it.
- Sources: the manifest's `fonts` list SplatNet 3's woff subsets in splatoon3.ink's repository at the commit its `repo` base pins, each with its sha256. `KRko-level2` is left out: its Hangul outlines are empty. If splatoon3.ink drops the files, point the sources at Nintendo's host (`https://api.lp1.av5ja.srv.nintendo.net/static/media/`) and keep the hashes: Nintendo serves the same bytes under names with a content hash, which SplatNet 3's main CSS lists.
- The script unpacks each woff to plain TrueType or OpenType, merges a face's subsets with fontTools and sets the PostScript name; Fontworks' Rowdy subsets are CID-keyed, so they become name-keyed first. It stops if any character's outline or advance differs from its subset's. Merging drops the vertical-origin table (`VORG`), which only vertical text uses.
- A face whose file is missing falls back to the system font for its script, so a checkout without fonts builds and runs. `FontManifestTests` keeps the manifest's faces equal to `FontFace.allCases` without needing a font file.
- Before a release is archived, `scripts/check-release-fonts.sh` builds the fonts, rebuilds the Release products from scratch (iOS with the watch app, and macOS) and fails unless the app, the watch app and the Mac app each carry every face of the manifest in their resource framework and each widget extension resolves its host app's copy through its run path. A release without fonts would pass every other check and set its text in the system font. It needs network and takes several minutes; `--derived-data` picks the build folder (default `build/ReleaseCheck`).

## Tests

- Swift Testing. Each test name is a raw identifier that states the behaviour as a sentence, as in ikalendar 2:

  ```swift
  @Test
  func `App Group container resolves`() { ... }
  ```

  SwiftFormat removes a leading "Test" from such names, so start with the subject.
- The test plan runs in English (US). A test of another language passes the language explicitly.
- No test may depend on a font file being present: CI has none.

## Strings

- The app speaks the game's 14 text sets. Every target declares the same 14 localizations (`en`, `en-GB`, `es`, `es-419`, `fr`, `fr-CA`, `de`, `it`, `nl`, `ru`, `ja`, `ko`, `zh-Hans`, `zh-Hant`), so each process resolves the same text set with `GameLanguage(resolvedFor: .main)`.
- Every key of every string catalog has a value in all 14, the source language included; `scripts/check-string-catalogs.sh` fails verify otherwise. Only keys marked Don't Translate are exempt. The same script fails when an App Shortcuts phrase, in its key or any language, lacks `${applicationName}`, and when two phrases read the same in a language once each parameter is filled in with every value it can take: the names of its type's cases in `IkaIntents`' catalog, read from the intents' `public var <name>: <Type>Parameter` and the type's `DisplayRepresentation(title:)` lines. Siri then picks one of the two shortcuts by itself.
- Game terms come from splatoon3.ink's locale files (shipped in `IkaCore`, looked up through `GameTerms`), Mode names and labels from its MIT-licensed site strings (`ModeLabel`). Strings written for this app use each language's in-game vocabulary; in es-ES, es-MX, fr-FR, fr-CA, de-DE, it-IT, nl-NL, ru-RU and ko-KR they carry the Needs Review state until a native speaker checks them.
- Package modules look their strings up with `Bundle.module.localizedString(forKey:in:)` in the language the process passes in, never in the process locale.
- Each Style and each feature area has its own string table, so parallel work never edits one catalog file: `Screens` (what every Style's screens share), `Classic`, `Ink`, `Timeline`, `Sidebar` (the iPad sidebar and its toolbar), `MenuBar` (the Mac menu bar window), `MacWindow` (the Mac window's view switch and its View menu), `Settings`, `About` (About, Credits and onboarding), `Reminders`, `Widgets`, `LiveActivity`, `Controls` and `Watch`; Siri's phrases are the app target's `AppShortcuts`, the name the system reads. A table is a `<Name>.xcstrings` in the module or target whose code shows its strings, added by the first change that needs it. `Localizable` stays `IkaCore`'s shared vocabulary (Mode names, labels and sentences) and `IkaIntents`' Siri strings.

## Code and commits

- Code style follows ikalendar 2, which means `notbd/Ikalendar2` at commit `9a99cf3` on `main`; its SwiftFormat and SwiftLint configurations are carried over with this repository's file header and exclusions. `print` never ships: log with OSLog.
- Conventional commits in English with a verb-first description and a scope where one fits, for example `feat(core): decode battle schedules from the feed`.

## CI

`.github/workflows/ci.yml` runs `scripts/verify.sh` on every push and on manual dispatch, on GitHub's `xcode-27` image with exactly the pinned Xcode. It fails when the image lacks that Xcode instead of falling back to another, because code built against a newer SDK breaks on an older one. It downloads the pinned linters, fails unless their SHA-256 matches `scripts/versions.env`, and downloads nothing else: no fonts, no assets. On failure, the verify logs are attached to the run as `verify-logs`.
