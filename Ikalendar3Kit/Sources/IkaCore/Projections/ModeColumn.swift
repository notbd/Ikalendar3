//
//  ModeColumn.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - ModeColumn

/// One column of the iPad's landscape layout, which shows a Mode's Schedule beside the others
/// under the event strip.
///
/// The Anarchy column's Series or Open choice is the app's state, as the Anarchy tab's is, so
/// switching forms never changes the columns.
public enum ModeColumn: Hashable, Sendable {
  /// Regular Battle.
  case regularBattle
  /// Anarchy Series or Anarchy Open.
  case anarchy
  /// X Battle.
  case xBattle
  /// A form of Splatfest Battle, while a Splatfest runs.
  case splatfestBattle(SplatfestBattleForm)
  /// Salmon Run.
  case salmonRun

  /// The menu the column's header opens: Anarchy's Series and Open menu, as on the iPhone tab.
  /// The Splatfest's forms have a column each, so none needs a menu.
  public var menu: TabMenu? {
    switch self {
      case .anarchy: .anarchy
      case .regularBattle,
           .xBattle,
           .splatfestBattle,
           .salmonRun: nil
    }
  }
}

extension Snapshot {
  /// The columns at `instant`, in order: Regular Battle, Anarchy, X Battle and Salmon Run, or
  /// while a Splatfest runs, its first half and second half alike, Splatfest Battle (Open) and
  /// (Pro) in place of the Battle Modes it pauses, then Salmon Run.
  public func columns(at instant: Date) -> [ModeColumn] {
    guard let splatfest, splatfest.isRunning(at: instant) else {
      return [.regularBattle, .anarchy, .xBattle, .salmonRun]
    }

    return SplatfestBattleForm.allCases.map(ModeColumn.splatfestBattle) + [.salmonRun]
  }
}
