//
//  InkText.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - InkText

/// The strings only Ink's screens show, from `IkaDesign`'s `Ink` string table. The raw value is
/// the catalog key.
enum InkText: String, CaseIterable {
  /// "Now!": the featured panel's state tag.
  case now = "ink.now"
  /// "Next": the next panel's state tag.
  case next = "ink.next"

  /// The string in a text set.
  func text(in language: GameLanguage) -> String {
    Bundle.module.localizedString(forKey: rawValue, table: "Ink", in: language)
  }
}
