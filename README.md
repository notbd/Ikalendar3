# ikalendar 3

Splatoon 3's schedules at a glance, on iPhone, iPad, Mac and Apple Watch.

ikalendar 3 shows which battles and Salmon Run Shifts are on now and next. It is the Splatoon 3 successor of [ikalendar 2](https://github.com/notbd/Ikalendar2), which stays on the App Store for Splatoon 2. It is free, with no ads, in-app purchases or tips.

ikalendar 3 is in development and not on the App Store yet.

## Features

- **Every public schedule**: Regular Battle, Anarchy Series, Anarchy Open, X Battle and Challenges; Splatfest Battle and Tricolor Turf War while a Splatfest runs; Salmon Run with Big Run and Eggstra Work, its Stages, weapons and King Salmonids.
- **Three Styles**: Classic (ikalendar 2's look), Ink (the game's materials, the default) and Timeline (SplatNet 3's schedule page).
- **Everywhere on the device**: Home Screen, Lock Screen, StandBy and Mac desktop widgets, a Live Activity with the Dynamic Island, a Control Center control, Siri, a Mac menu bar window, and watch complications and the Smart Stack.
- **Mac app**: a native window with three views (Columns, Sidebar and Overview) and the menu bar window.
- **Apple Watch app**: fetches on its own, so it works without the iPhone nearby.
- **Reminders** for the start of each Big Run, Eggstra Work, Splatfest and Challenge.
- **14 languages**: the game's text sets, with the game's official names and SplatNet 3's fonts.

Requires iOS, iPadOS, macOS and watchOS 26 or later.

## Privacy

ikalendar 3 collects no data. It contacts only `splatoon3.ink` (the schedules) and `assets.splatoon3.ink` (Splatfest art), and its requests carry the app's name, version and contact address but no identifier. Settings and cached schedules stay on the device. Links in About and Credits open in the browser, Mail or the App Store. `scripts/check-hosts.sh` fails the build checks if any code could contact another host.

## Building

You need the Xcode version pinned in `scripts/versions.env`.

1. Open `Ikalendar3.xcodeproj` and run the `Ikalendar3` scheme (iPhone, iPad and Mac) or `Ikalendar3Watch` (Apple Watch).
2. Simulator runs sign to run locally, which gives the app its App Group container. Device runs need your own development team and App Group.

A fresh clone builds and runs without the fonts: text then uses the system font.

### Fonts and images

The bundled Stage, weapon, Rule, Mode and King Salmonid images are built by `scripts/assets.sh` from `scripts/assets/manifest.json` and committed. The same script builds SplatNet 3's fonts from pinned, hash-checked downloads into `IkaResources/Fonts`, which git ignores: the repository holds no font file. To build them (needs network and the Python version in `scripts/versions.env`):

```sh
scripts/assets.sh --only fonts
```

`scripts/check-release-fonts.sh` builds the fonts and the Release products and fails unless every product that draws text ships or loads every face. A release runs it before archiving.

### Verifying

```sh
scripts/verify.sh
```

It runs every check CI runs: formatting and lint, the wording, string catalog and hosts checks, package tests, Debug and Release builds for iOS, macOS and watchOS with zero warnings, and the test run in the iOS Simulator. [CONTRIBUTING.md](CONTRIBUTING.md) explains each step, the linter versions, the Debug launch options for recorded data, and how the code is laid out.

## Credits

- Schedules, game terms and Splatfest art come from [splatoon3.ink](https://splatoon3.ink). Mode names and labels the game's language files lack come from [splatoon3.ink's site strings](https://github.com/misenhower/splatoon3.ink) (MIT License).
- Text uses SplatNet 3's fonts: Nintendo's Splatoon faces, with kanji by Fontworks, hanzi by DynaComware and Hangul by AsiaSoft. Each remains the property of its owner, and none is in this repository.
- The app shows these credits and the licence texts in Credits.

## License

[GPL-3.0](LICENSE)

## Disclaimer

ikalendar 3 is a third-party companion app for Splatoon 3 and is not affiliated with Nintendo. All associated names, logos and trademarks are the property of their respective owners.
