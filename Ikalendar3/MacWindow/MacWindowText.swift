//
//  MacWindowText.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - MacWindowText

/// The Mac window's own strings and its View menu's, from the app's `MacWindow` string table. The
/// raw value is the catalog key. The refresh button's and Mode names come from `IkaDesign` and
/// `IkaCore`.
enum MacWindowText: String, CaseIterable {
  /// "View": the toolbar switch between the three views, as VoiceOver and the toolbar's
  /// customization sheet name it.
  case view = "macWindow.view"
  /// "Columns": one column per Mode under the event strip.
  case columns = "macWindow.columns"
  /// "Sidebar": a sidebar of Modes beside one detail column.
  case sidebar = "macWindow.sidebar"
  /// "Overview": a card per Mode under the event strip.
  case overview = "macWindow.overview"

  /// The string in a text set.
  func text(in language: GameLanguage) -> String {
    Bundle.main.localizedString(forKey: rawValue, table: "MacWindow", in: language)
  }
}
