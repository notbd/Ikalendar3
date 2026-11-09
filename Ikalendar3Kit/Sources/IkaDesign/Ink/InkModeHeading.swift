//
//  InkModeHeading.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore

// MARK: - InkModeHeading

/// How Ink names a Mode over its list: the Mode's name in the heavy face and, for Anarchy
/// Battle, its form (Series or Open) on a Mode-colour tag under it, as the game's menu does.
struct InkModeHeading: Equatable {
  /// The Mode's name.
  let name: ModeLabel
  /// The form under the name, or `nil` for a Mode with one form.
  let form: ModeLabel?

  /// The heading of `mode`.
  init(_ mode: Mode) {
    switch mode {
      case .battle(.regular): self.init(name: .regularBattle, form: nil)
      case .battle(.anarchySeries): self.init(name: .anarchyBattle, form: .series)
      case .battle(.anarchyOpen): self.init(name: .anarchyBattle, form: .open)
      case .battle(.x): self.init(name: .xBattle, form: nil)
      case .salmonRun: self.init(name: .salmonRun, form: nil)
    }
  }

  init(name: ModeLabel, form: ModeLabel?) {
    self.name = name
    self.form = form
  }
}
