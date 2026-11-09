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

  /// The icon of a Rotation's Battle Mode: a continuous Battle Mode's, or Splatfest Battle's in
  /// either form, as a widget shows while a Splatfest replaces its Battle Mode.
  public init(_ mode: RotationMode) {
    switch mode {
      case .battle(let battleMode): self.init(Mode.battle(battleMode))
      case .splatfestBattle: self = .splatfestBattle
    }
  }

  /// The icon of a Shift of `kind`: Salmon Run's for a regular Shift.
  public init(_ kind: Shift.Kind) {
    switch kind {
      case .regular: self = .salmonRun
      case .bigRun: self = .bigRun
      case .eggstraWork: self = .eggstraWork
    }
  }
}

extension BundledImage {
  /// The icon of a Mode, of Challenge or Splatfest Battle, or of a kind of Shift.
  static public func name(for icon: ModeIcon, size: Size) -> String {
    name(of: icon.rawValue, in: .mode, size: size)
  }
}
