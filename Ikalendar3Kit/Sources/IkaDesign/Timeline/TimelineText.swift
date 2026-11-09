//
//  TimelineText.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import Foundation
import IkaCore

// MARK: - TimelineText

/// Timeline's own strings, from `IkaDesign`'s `Timeline` string table. The raw value is the
/// catalog key. Mode names and labels come from `IkaCore`'s shared vocabulary.
enum TimelineText: String, CaseIterable {
  /// "Now": the tag on the Rotation or Shift that runs.
  case now = "timeline.now"
  /// "%@ left", with the countdown of the time left.
  case timeLeft = "timeline.timeLeft"

  /// The string in a text set, its placeholders filled in.
  func text(in language: GameLanguage, _ arguments: any CVarArg...) -> String {
    let template = Bundle.module.localizedString(forKey: rawValue, table: "Timeline", in: language)
    return arguments.isEmpty
      ? template
      : String(format: template, locale: Locale(identifier: language.rawValue), arguments: arguments)
  }
}
#endif
