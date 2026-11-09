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
      case .anarchySeries: Self.anarchyBattle(.series, in: language)
      case .anarchyOpen: Self.anarchyBattle(.open, in: language)
      case .x: ModeLabel.xBattle.text(in: language)
    }
  }

  static private func anarchyBattle(_ form: ModeLabel, in language: GameLanguage) -> String {
    String(
      format: Bundle.module.localizedString(forKey: "mode.withForm", in: language),
      ModeLabel.anarchyBattle.text(in: language),
      form.text(in: language))
  }
}
