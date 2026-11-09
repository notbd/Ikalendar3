//
//  MenuBarText.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - MenuBarText

/// The Mac menu bar window's own strings, from the app's `MenuBar` string table. The raw value is
/// the catalog key. Mode names, row summaries and the fetch time come from `IkaCore` and
/// `IkaDesign`.
enum MenuBarText: String, CaseIterable {
  /// "Open ikalendar3": the button that brings the app's window to the front.
  case openApp = "menuBar.openApp"

  /// The string in a text set.
  func text(in language: GameLanguage) -> String {
    Bundle.main.localizedString(forKey: rawValue, table: "MenuBar", in: language)
  }
}
