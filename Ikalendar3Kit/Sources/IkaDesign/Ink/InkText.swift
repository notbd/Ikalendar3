//
//  InkText.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - InkText

/// The strings only Ink draws, from `IkaDesign`'s `Ink` string table: on its screens and on the
/// Surfaces that always use Ink, the Live Activity and the watch. The raw value is the catalog key.
public enum InkText: String, CaseIterable, Sendable {
  /// "Now!": the featured panel's state tag.
  case now = "ink.now"
  /// "Next": the next panel's state tag, and the tag before the next item on the Live Activity
  /// and the watch's Mode pages.
  case next = "ink.next"

  /// The string in a text set.
  public func text(in language: GameLanguage) -> String {
    Bundle.module.localizedString(forKey: rawValue, table: "Ink", in: language)
  }
}
