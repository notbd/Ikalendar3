//
//  ModeIcon.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore

// MARK: - ModeIcon

/// The icon of a Mode, of Challenge or Splatfest Battle, or of a kind of Shift. Raw values are the
/// manifest ids of the `mode` group. A kind `ModeColor` also lists has the same case name there.
public enum ModeIcon: String, CaseIterable, Sendable {
  case regularBattle = "regular"
  /// Anarchy Series and Anarchy Open, as in the game.
  case anarchy
  case xBattle = "x"
  case challenge
  /// Splatfest Battle. A placeholder stands in until the drawn icon lands.
  case splatfestBattle = "splatfest"
  case salmonRun = "salmon-run"
  case bigRun = "big-run"
  case eggstraWork = "eggstra-work"

  /// The icon of `mode`.
  public init(_ mode: Mode) {
    switch mode {
      case .battle(.regular): self = .regularBattle
      case .battle(.anarchySeries),
           .battle(.anarchyOpen): self = .anarchy
      case .battle(.x): self = .xBattle
      case .salmonRun: self = .salmonRun
    }
  }
}

extension BundledImage {
  /// The icon of a Mode, of Challenge or Splatfest Battle, or of a kind of Shift.
  static public func name(for icon: ModeIcon, size: Size) -> String {
    name(of: icon.rawValue, in: .mode, size: size)
  }
}
