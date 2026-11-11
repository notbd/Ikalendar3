//
//  ModeNameAndForm.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore

// MARK: - ModeNameAndForm

/// A Mode's name in two parts, as the game's menu shows it: the name and, for Anarchy Battle and
/// Splatfest Battle, the form apart from it (Series or Open, Open or Pro). Ink's and Classic's
/// headings and the watch's rows show the form under the name; the Challenge and Splatfest
/// screens are headed this way too. One rule, so every Style splits a name alike.
public struct ModeNameAndForm: Equatable, Sendable {
  /// The Mode's name.
  public let name: ModeLabel
  /// The form under the name, or `nil` for a Mode with one form.
  public let form: ModeLabel?

  /// The heading of `mode`.
  public init(_ mode: Mode) {
    switch mode {
      case .battle(.regular): self.init(name: .regularBattle, form: nil)
      case .battle(.anarchySeries): self.init(name: .anarchyBattle, form: .series)
      case .battle(.anarchyOpen): self.init(name: .anarchyBattle, form: .open)
      case .battle(.x): self.init(name: .xBattle, form: nil)
      case .salmonRun: self.init(name: .salmonRun, form: nil)
    }
  }

  /// The heading of Splatfest Battle in `form`, over the Splatfest screen.
  public init(splatfestBattle form: SplatfestBattleForm) {
    switch form {
      case .open: self.init(name: .splatfestBattle, form: .open)
      case .pro: self.init(name: .splatfestBattle, form: .pro)
    }
  }

  /// The heading of a Mode summary's row: its Mode's, Splatfest Battle's in its form, or a running
  /// Big Run's, which shows as one, as `SummaryRowContent` names the row.
  public init(_ summary: ModeSummary) {
    switch summary {
      case .battle(let mode, _): self.init(.battle(mode))
      case .splatfestBattle(let form, _): self.init(splatfestBattle: form)
      case .salmonRun(.running(let running)): self.init(name: ModeLabel(running.item.kind), form: nil)
      case .salmonRun: self.init(.salmonRun)
    }
  }

  /// A heading of `name`, with `form` under it when the Mode has one.
  public init(name: ModeLabel, form: ModeLabel?) {
    self.name = name
    self.form = form
  }
}

extension ModeNameAndForm {
  /// The heading over the Challenge screen.
  static let challenges: Self = .init(name: .challenges, form: nil)
}
