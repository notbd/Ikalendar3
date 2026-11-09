//
//  TermTable.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - TermTable

/// The names of game items in one language, by id. Domain values carry ids only; every name,
/// the feed's own English one included, comes from a table like this. A locale file decodes
/// into one, and the feeds' English names form the last fallback (`Snapshot.feedTerms`).
public struct TermTable: Hashable, Sendable {
  /// Stage names.
  public var stages: [StageID: String] = [:]
  /// Rule names.
  public var rules: [RuleID: String] = [:]
  /// Weapon names, the random marks included.
  public var weapons: [WeaponID: String] = [:]
  /// King Salmonid names.
  public var kingSalmonids: [KingSalmonidID: String] = [:]
  /// Challenge texts.
  public var challenges: [ChallengeID: ChallengeTerms] = [:]
  /// Splatfest texts.
  public var splatfests: [SplatfestID: SplatfestTerms] = [:]

  /// An empty table.
  public init() { }
}

// MARK: - ChallengeTerms

/// A Challenge's texts.
public struct ChallengeTerms: Hashable, Sendable {
  /// The name.
  public let name: String
  /// The one-line description.
  public let description: String
  /// The rules text. The feed marks line breaks with `<br />`.
  public let rulesText: String
}

// MARK: - SplatfestTerms

/// A Splatfest's texts.
public struct SplatfestTerms: Hashable, Sendable {
  /// The title, the question the teams answer.
  public let title: String
  /// The team names in the feed's order (Alpha, Bravo, Charlie), the order of
  /// `Splatfest.teamColors`; `nil` when the source has none, as the schedules feed does. Never
  /// index them beside the colours without checking: look each team's name up on its own.
  public let teamNames: [String]?
}
