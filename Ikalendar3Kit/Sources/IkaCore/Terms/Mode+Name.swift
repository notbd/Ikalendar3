//
//  Mode+Name.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

extension Mode {
  /// The Mode's name in a text set, where one string names it: a widget's configuration, the
  /// control, Siri. "Regular Battle", "Anarchy Battle (Series)", "Salmon Run".
  public func name(in language: GameLanguage) -> String {
    switch self {
      case .battle(let battleMode): battleMode.name(in: language)
      case .salmonRun: ModeLabel.salmonRun.text(in: language)
    }
  }
}

extension BattleMode {
  /// The Battle Mode's name in a text set. The Anarchy Battle forms are written as the Battle
  /// Mode with its form: "Anarchy Battle (Series)", "バンカラマッチ（チャレンジ）".
  public func name(in language: GameLanguage) -> String {
    switch self {
      case .regular: ModeLabel.regularBattle.text(in: language)
      case .anarchySeries: ModeLabel.anarchyBattle.withForm(.series, in: language)
      case .anarchyOpen: ModeLabel.anarchyBattle.withForm(.open, in: language)
      case .x: ModeLabel.xBattle.text(in: language)
    }
  }
}

extension RotationMode {
  /// The name of a Rotation's Battle Mode in a text set: a continuous Battle Mode's, or
  /// Splatfest Battle with its form, "Splatfest Battle (Pro)".
  public func name(in language: GameLanguage) -> String {
    switch self {
      case .battle(let battleMode): battleMode.name(in: language)
      case .splatfestBattle(.open): ModeLabel.splatfestBattle.withForm(.open, in: language)
      case .splatfestBattle(.pro): ModeLabel.splatfestBattle.withForm(.pro, in: language)
    }
  }

  /// The name of a Rotation's Battle Mode in a list the Splatfest heads, as the sidebar's
  /// Splatfest group and the Splatfest tab's menu write it: a form of Splatfest Battle by its
  /// label alone, "Open" or "Pro"; a continuous Battle Mode by its full name.
  public func shortName(in language: GameLanguage) -> String {
    switch self {
      case .battle(let battleMode): battleMode.name(in: language)
      case .splatfestBattle(.open): ModeLabel.open.text(in: language)
      case .splatfestBattle(.pro): ModeLabel.pro.text(in: language)
    }
  }
}

extension ModeLabel {
  /// A Battle Mode label with its form: "Anarchy Battle (Series)".
  fileprivate func withForm(_ form: ModeLabel, in language: GameLanguage) -> String {
    String(
      format: Bundle.module.localizedString(forKey: "mode.withForm", in: language),
      text(in: language),
      form.text(in: language))
  }
}
