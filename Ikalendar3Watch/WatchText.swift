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
  /// "Lists the later Rotations": what tapping a Battle Mode's page does, for VoiceOver.
  case listsLaterRotations = "watch.listsLaterRotations"
  /// "Lists the later Shifts": what tapping Salmon Run's page does, for VoiceOver.
  case listsLaterShifts = "watch.listsLaterShifts"

  /// What tapping `mode`'s page does, for VoiceOver.
  static func laterHint(of mode: Mode) -> Self {
    switch mode {
      case .battle: .listsLaterRotations
      case .salmonRun: .listsLaterShifts
    }
  }

  /// The string in a text set.
  func text(in language: GameLanguage) -> String {
    Bundle.main.localizedString(forKey: rawValue, table: "Watch", in: language)
  }
}
