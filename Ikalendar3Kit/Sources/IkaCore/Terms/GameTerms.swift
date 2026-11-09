//
//  GameTerms.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - GameTerms

/// The game's own names for the items a Surface shows, in one of its 14 text sets, so every
/// name matches the player's copy of the game. Each lookup takes the first table that has the
/// id: the refreshed locale file, else the snapshot shipped in `IkaCore`, else the feeds'
/// English names. A name is never blank: an id that no table has is named by the id itself.
public struct GameTerms: Sendable {
  /// The text set the names are in.
  public let language: GameLanguage

  /// The tables in lookup order.
  private let tables: [TermTable]

  /// The names in a text set.
  ///
  /// - Parameters:
  ///   - refreshed: The text set's locale file fetched at run time, if there is one.
  ///   - feed: The feeds' English names (`Snapshot.feedTerms`).
  public init(language: GameLanguage, refreshed: TermTable?, feed: TermTable) {
    self.language = language
    tables = [refreshed, TermTable.shipped(in: language), feed].compactMap(\.self)
  }

  /// A Stage's name.
  public func name(of id: StageID) -> String {
    lookUp(id, in: \.stages) ?? id.rawValue
  }

  /// A Rule's name.
  public func name(of id: RuleID) -> String {
    lookUp(id, in: \.rules) ?? id.rawValue
  }

  /// A weapon's name, or the random marks' ("Random").
  public func name(of id: WeaponID) -> String {
    lookUp(id, in: \.weapons) ?? id.rawValue
  }

  /// A King Salmonid's name.
  public func name(of id: KingSalmonidID) -> String {
    lookUp(id, in: \.kingSalmonids) ?? id.rawValue
  }

  /// A Challenge's texts. With no table that has it, the name is the id and the other texts
  /// are empty.
  public func challenge(_ id: ChallengeID) -> ChallengeTerms {
    lookUp(id, in: \.challenges) ?? ChallengeTerms(name: id.rawValue, description: "", rulesText: "")
  }

  /// A Splatfest's texts. With no table that has it, the title is the id and there are no
  /// team names.
  public func splatfest(_ id: SplatfestID) -> SplatfestTerms {
    lookUp(id, in: \.splatfests) ?? SplatfestTerms(title: id.rawValue, teamNames: nil)
  }

  /// The term of the first table that has the id.
  private func lookUp<Kind, Term>(_ id: FeedID<Kind>, in table: KeyPath<TermTable, [FeedID<Kind>: Term]>) -> Term? {
    tables.lazy.compactMap { $0[keyPath: table][id] }.first
  }
}

// MARK: - Snapshot

extension Snapshot {
  /// The game's names in a text set: from its locale file when one was fetched, else from the
  /// shipped snapshot, else from the feeds' English names.
  public func terms(in language: GameLanguage) -> GameTerms {
    GameTerms(language: language, refreshed: locales[language]?.content, feed: feedTerms)
  }
}

// MARK: - FeedCache

extension FeedCache {
  /// The game's names in a text set, read on the spot for a view that renders with no snapshot
  /// at hand, such as a Live Activity's: from the cached locale file, else from the shipped
  /// snapshot. The locale file is decoded on the calling thread. The feeds' English names, the
  /// last fallback, are left out: they would mean decoding the schedules feed on every render.
  public func terms(in language: GameLanguage) -> GameTerms {
    let refreshed = record(for: .locale(language)).flatMap { try? TermTable(localeFile: $0.body) }
    return GameTerms(language: language, refreshed: refreshed, feed: TermTable())
  }
}
