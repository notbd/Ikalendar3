# Native multiplatform SwiftUI with a real macOS target

ikalendar 3 builds native SwiftUI targets for iOS, iPadOS, macOS and watchOS from one codebase. ikalendar 2 reaches the Mac only as its iPad app running on Apple silicon ("Designed for iPad": `SUPPORTS_MACCATALYST = NO` and `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = YES` on the app target, `Ikalendar2.xcodeproj/project.pbxproj:1398-1399` at `9a99cf3`; its README's "Mac Catalyst" line is out of date). A native macOS destination is what unlocks a menu bar entry (`MenuBarExtra`), a Settings window and macOS desktop widgets, none of which an iPad app or Catalyst gets, and the same SwiftUI views already have to run on watchOS. AppKit appears only as small bridges where a Mac behaviour needs it. Decided with the owner on 2026-11-01 ([ticket 10](../../.scratch/ikalendar3/issues/10-platforms-and-minimum-os.md)); the SDK facts are in research 05.

## Considered Options

- The iPad app on the Mac, as in ikalendar 2: no extra work, but no menu bar extra, no Settings window and no Mac-native widgets.
- Mac Catalyst: a Mac build of the iPad app, still without `MenuBarExtra` and `Settings`.
- A standalone AppKit app: the most Mac-like, but a second UI codebase to keep in sync with the SwiftUI one.
