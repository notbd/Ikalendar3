//
//  Mode.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - Mode

/// A Mode a widget, the control, Siri or Tracking can choose.
public enum Mode: CaseIterable, Codable, Hashable, Sendable {
  /// One of the four continuous Battle Modes.
  case battle(BattleMode)
  /// Salmon Run.
  case salmonRun

  /// The five Modes: the four continuous Battle Modes, then Salmon Run.
  static public var allCases: [Mode] { BattleMode.allCases.map(Mode.battle) + [.salmonRun] }
}

// MARK: - BattleMode

/// The four continuous Battle Modes. Challenge and Splatfest Battle are not members.
public enum BattleMode: CaseIterable, Codable, Hashable, Sendable {
  /// Regular Battle.
  case regular
  /// Anarchy Series, the ranked form of Anarchy Battle.
  case anarchySeries
  /// Anarchy Open, the form of Anarchy Battle friends can join together.
  case anarchyOpen
  /// X Battle.
  case x
}
