//
//  SettingsText.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - SettingsText

/// The strings of Settings, from the app's `Settings` string table. The raw value is the catalog
/// key. Mode names come from `IkaCore`'s `ModeLabel`, so Settings never spells a game term itself.
enum SettingsText: String, CaseIterable {
  /// "Settings".
  case title = "settings.title"
  /// "Default Mode", the section header.
  case defaultMode = "settings.defaultMode"
  /// "Default Tab", the picker of the tab the app opens on.
  case defaultTab = "settings.defaultTab"
  /// "Appearance".
  case appearance = "settings.appearance"
  /// "Color Scheme".
  case colorScheme = "settings.colorScheme"
  /// "Follow System".
  case followSystem = "settings.colorScheme.followSystem"
  /// "Dark".
  case dark = "settings.colorScheme.dark"
  /// "Light".
  case light = "settings.colorScheme.light"
  /// "Minimize Tab Bar".
  case minimizeTabBar = "settings.minimizeTabBar"
  /// "Style".
  case style = "settings.style"
  /// "Classic".
  case classic = "settings.style.classic"
  /// "Ink".
  case ink = "settings.style.ink"
  /// "Timeline".
  case timeline = "settings.style.timeline"
  /// "Language", the section header.
  case language = "settings.language"
  /// "App Language", the row that opens the system Settings.
  case appLanguage = "settings.appLanguage"
  /// "Reminders".
  case reminders = "settings.reminders"
  /// "About".
  case about = "settings.about"
  /// "Credits".
  case credits = "settings.credits"

  /// The string in a text set.
  func text(in language: GameLanguage) -> String {
    Bundle.main.localizedString(forKey: rawValue, table: "Settings", in: language)
  }
}
