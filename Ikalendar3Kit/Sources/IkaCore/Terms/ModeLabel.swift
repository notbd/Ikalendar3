//
//  ModeLabel.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - ModeLabel

/// A Mode name or label the locale files lack, in the game's words. The texts come from
/// splatoon3.ink's site strings (MIT License, notice in `Resources/splatoon3.ink-LICENSE.txt`)
/// and live in `IkaCore`'s string catalog; the raw value is the catalog key.
public enum ModeLabel: String, CaseIterable, Sendable {
  /// Regular Battle.
  case regularBattle = "mode.regularBattle"
  /// Anarchy Battle, which Series and Open qualify.
  case anarchyBattle = "mode.anarchyBattle"
  /// X Battle.
  case xBattle = "mode.xBattle"
  /// Splatfest Battle.
  case splatfestBattle = "mode.splatfestBattle"
  /// Challenges, plural in English.
  case challenges = "mode.challenges"
  /// Salmon Run.
  case salmonRun = "mode.salmonRun"
  /// Series, the ranked form of Anarchy Battle.
  case series = "mode.series"
  /// Open, the form of Anarchy Battle and Splatfest Battle friends join together.
  case open = "mode.open"
  /// Pro, the solo form of Splatfest Battle.
  case pro = "mode.pro"
  /// Tricolor, as in Tricolor Turf War.
  case tricolor = "mode.tricolor"
  /// Big Run.
  case bigRun = "mode.bigRun"
  /// Eggstra Work.
  case eggstraWork = "mode.eggstraWork"

  /// The label in a text set.
  public func text(in language: GameLanguage) -> String {
    Bundle.module.localizedString(forKey: rawValue, in: language)
  }
}

// MARK: - TimeUnit

/// A unit of a time span in the game's words, as splatoon3.ink's site strings write it, with
/// each language's plural rules.
public enum TimeUnit: String, CaseIterable, Sendable {
  case days
  case hours
  case minutes
  case seconds

  /// A count in the short form: "5d", "5時間".
  public func abbreviated(_ count: Int, in language: GameLanguage) -> String {
    format(count, key: "time.\(rawValue).abbreviated", in: language)
  }

  /// A count in the long form: "5 days", "5 дней".
  public func spelledOut(_ count: Int, in language: GameLanguage) -> String {
    format(count, key: "time.\(rawValue).spelledOut", in: language)
  }

  private func format(_ count: Int, key: String, in language: GameLanguage) -> String {
    String(
      format: Bundle.module.localizedString(forKey: key, in: language),
      locale: Locale(identifier: language.rawValue),
      count)
  }
}
