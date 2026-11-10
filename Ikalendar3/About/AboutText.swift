//
//  AboutText.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - AboutText

/// The strings of About, Credits, Debug Options and the welcome screen, from the app's `About`
/// string table. The raw value is the catalog key. Names (ikalendar3, splatoon3.ink, Twitter)
/// and licence names are never translated, so they are not keys.
enum AboutText: String, CaseIterable {
  // MARK: About

  /// "Share", the section header.
  case share = "about.share"
  /// "Share %@", with the app's name.
  case shareApp = "about.shareApp"
  /// "Review", the section header.
  case review = "about.review"
  /// "Rate %@", with the app's name.
  case rate = "about.rate"
  /// "Leave a Review".
  case leaveReview = "about.leaveReview"
  /// "View %@ on the App Store", with an app's name.
  case viewOnAppStore = "about.viewOnAppStore"
  /// "Contact", the section header.
  case contact = "about.contact"
  /// "Feedback Email".
  case email = "about.email"
  /// "App", the section header.
  case app = "about.app"
  /// "App Website".
  case website = "about.website"
  /// "Source Code".
  case sourceCode = "about.sourceCode"
  /// "Privacy Policy".
  case privacyPolicy = "about.privacyPolicy"
  /// "Debug Options", the row and the page title.
  case debugOptions = "about.debugOptions"
  /// "Version %1$@ (%2$@)", with the version and the build number.
  case version = "about.version"
  /// The footer's two lines pointing back to ikalendar2.
  case ikalendar2Note = "about.ikalendar2Note"

  // MARK: Debug Options

  /// "Show Onboarding Screen".
  case showOnboarding = "debug.showOnboarding"
  /// "Reset App States".
  case resetAppStates = "debug.resetAppStates"
  /// "Reset App Preferences".
  case resetAppPreferences = "debug.resetAppPreferences"
  /// "Reset All".
  case resetAll = "debug.resetAll"
  /// "Warning: Proceed with Caution", the banner.
  case warning = "debug.warning"
  /// "States Reset", the banner after Reset App States.
  case statesReset = "debug.statesReset"
  /// "Preferences Reset", the banner after Reset App Preferences.
  case preferencesReset = "debug.preferencesReset"

  // MARK: Credits

  /// "Data Source", the section header.
  case dataSource = "credits.dataSource"
  /// "Licenses", the section header.
  case licenses = "credits.licenses"
  /// What the app takes from splatoon3.ink's site strings.
  case siteStrings = "credits.siteStrings"
  /// "Splatoon 3", the game's official title, as the section header.
  case splatoon3 = "credits.splatoon3"
  /// "Official Website".
  case officialSite = "credits.officialSite"
  /// Whose fonts the app's text uses.
  case fontNote = "credits.fontNote"
  /// That the app is not affiliated with Nintendo.
  case disclaimer = "credits.disclaimer"
  /// "View Repository", the licence page's toolbar button.
  case viewRepository = "license.viewRepository"

  // MARK: Welcome screen

  /// "Welcome to\n%@", with the app's name.
  case welcome = "onboarding.welcome"
  /// "Get Started".
  case getStarted = "onboarding.getStarted"

  /// The string in a text set, its placeholders filled in.
  func text(in language: GameLanguage, _ arguments: any CVarArg...) -> String {
    text(in: language, arguments: arguments)
  }

  /// The string in a text set, its placeholders filled in from `arguments`.
  func text(in language: GameLanguage, arguments: [any CVarArg]) -> String {
    let template = Bundle.main.localizedString(forKey: rawValue, table: "About", in: language)
    return arguments.isEmpty
      ? template
      : String(format: template, locale: Locale(identifier: language.rawValue), arguments: arguments)
  }
}
