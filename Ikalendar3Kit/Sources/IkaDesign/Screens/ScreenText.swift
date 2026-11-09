//
//  ScreenText.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - ScreenText

/// The strings every Style's screens share, from `IkaDesign`'s `Screens` string table. The raw
/// value is the catalog key.
///
/// Each Style's own strings live in its own table (`Classic`, `Ink`, `Timeline`), so parallel
/// work on two Styles never edits one catalog file.
public enum ScreenText: String, CaseIterable, Sendable {
  /// "No schedule yet": the shared empty state.
  case empty = "screen.empty"
  /// "Updated %@", with the fetch time.
  case fetchTime = "screen.fetchTime"
  /// "Next": the next Challenge window.
  case next = "screen.next"
  /// "Nothing on right now".
  case nothingCurrent = "screen.nothingCurrent"
  /// "Returns %@", with the time a paused Battle Mode returns.
  case paused = "screen.paused"
  /// "Couldn't refresh".
  case refreshFailed = "screen.refreshFailed"

  /// The string in a text set, its placeholders filled in.
  public func text(in language: GameLanguage, _ arguments: any CVarArg...) -> String {
    let template = Bundle.module.localizedString(forKey: rawValue, table: "Screens", in: language)
    return arguments.isEmpty
      ? template
      : String(format: template, locale: Locale(identifier: language.rawValue), arguments: arguments)
  }
}
