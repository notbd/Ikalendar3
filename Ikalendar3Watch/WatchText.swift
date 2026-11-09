//
//  WatchText.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - WatchText

/// The watch app's own strings, from its `Watch` string table. The raw value is the catalog key.
/// Mode names and the strings every Style's screens share come from `IkaCore` and `IkaDesign`.
enum WatchText: String, CaseIterable {
  /// "Now": the Now page's title.
  case now = "watch.now"

  /// The string in a text set.
  func text(in language: GameLanguage) -> String {
    Bundle.main.localizedString(forKey: rawValue, table: "Watch", in: language)
  }
}
