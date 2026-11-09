//
//  IkaShortcuts.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import AppIntents
import IkaIntents

// MARK: - IkaShortcuts

/// The six App Shortcuts Siri offers with no setup, six of the ten the system allows. Every phrase
/// names the app, and `AppShortcuts.xcstrings` next to this file translates each one into all 14
/// languages (`scripts/check-string-catalogs.sh` checks both). App Shortcuts do not exist on
/// macOS.
///
/// The provider and its phrases live in the app, not with the intents in `IkaIntents`: the build
/// keeps a package's App Shortcuts out of the app's App Intents metadata, so the system would
/// offer none. The short titles and the Mode and Rule names a phrase expands to are looked up by
/// key in the app's `Localizable` table, which is `IkaIntents`' catalog, bundled into the app too.
///
/// A phrase holds at most one parameter, so the chosen-Rule shortcut names the Rule and Siri asks
/// for the Battle Mode.
struct IkaShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: NowIntent(),
      phrases: [
        "What's on now in \(.applicationName)",
        "What's on in \(\.$mode) in \(.applicationName)",
      ],
      shortTitle: "What's On Now",
      systemImageName: "clock")
    AppShortcut(
      intent: NextIntent(),
      phrases: [
        "What's next in \(.applicationName)",
        "What's next in \(\.$mode) in \(.applicationName)",
      ],
      shortTitle: "What's Next",
      systemImageName: "forward")
    AppShortcut(
      intent: NextRuleIntent(),
      phrases: [
        "When is a Rule next in \(.applicationName)",
        "When is \(\.$rule) next in \(.applicationName)",
      ],
      shortTitle: "When a Rule Is Next",
      systemImageName: "calendar")
    AppShortcut(
      intent: CurrentShiftIntent(),
      phrases: [
        "What's the current Shift in \(.applicationName)",
        "What's on in Salmon Run in \(.applicationName)",
      ],
      shortTitle: "Current Shift",
      systemImageName: "fish")
    AppShortcut(
      intent: NextBigRunAndSplatfestIntent(),
      phrases: [
        "When is the next Big Run in \(.applicationName)",
        "When is the next Splatfest in \(.applicationName)",
      ],
      shortTitle: "Next Big Run and Splatfest",
      systemImageName: "flag")
    AppShortcut(
      intent: StartTrackingIntent(),
      phrases: [
        "Start Tracking in \(.applicationName)",
        "Start Tracking \(\.$mode) in \(.applicationName)",
      ],
      shortTitle: "Start Tracking",
      systemImageName: "livephoto")
  }
}
#endif
