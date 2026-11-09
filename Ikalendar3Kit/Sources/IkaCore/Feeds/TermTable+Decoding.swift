//
//  TermTable+Decoding.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

extension TermTable {
  /// Decodes a `locale/<code>.json` response body. Runs off the main actor.
  ///
  /// An entry the app cannot use is left out, so lookup falls back for it: one without a name,
  /// such as the bogus `"undefined": {}` Rule key some files carry, or one whose name is empty.
  /// The tables the app does not show (brands, gear, abilities) are not read.
  ///
  /// - Throws: `DecodingError` when the body is not a locale file.
  @concurrent
  static public func decode(from body: Data) async throws -> TermTable {
    let dto = try FeedJSON.decoder().decode(LocaleDTO.self, from: body)

    var terms: TermTable = .init()
    terms.stages = usable(dto.stages) { $0.name.nonEmpty }
    terms.rules = usable(dto.rules) { $0.name.nonEmpty }
    terms.weapons = usable(dto.weapons) { $0.name.nonEmpty }
    terms.kingSalmonids = usable(dto.bosses) { $0.name.nonEmpty }
    terms.challenges = usable(dto.events) { event in
      event.name.nonEmpty.map { ChallengeTerms(name: $0, description: event.desc, rulesText: event.regulation) }
    }
    terms.splatfests = usable(dto.festivals) { festival in
      festival.title.nonEmpty.map { SplatfestTerms(title: $0, teamNames: festival.teams.map(\.teamName)) }
    }
    return terms
  }

  /// The entries of a locale table that decode and that `term` accepts, keyed by typed id.
  static private func usable<Kind, Entry, Term>(
    _ entries: [String: Isolated<Entry>]?,
    _ term: (Entry) -> Term?)
    -> [FeedID<Kind>: Term]
  {
    .init(uniqueKeysWithValues: (entries ?? [:]).compactMap { key, entry in
      (try? entry.result.get()).flatMap(term).map { (FeedID(key), $0) }
    })
  }
}

extension String {
  /// The string, or `nil` when it is empty.
  fileprivate var nonEmpty: String? { isEmpty ? nil : self }
}

// MARK: - LocaleDTO

/// A locale file: one table per kind of term, each keyed by id. Each entry decodes on its own.
private struct LocaleDTO: Decodable {
  let stages: [String: Isolated<NameDTO>]?
  let rules: [String: Isolated<NameDTO>]?
  let weapons: [String: Isolated<NameDTO>]?
  let bosses: [String: Isolated<NameDTO>]?
  let events: [String: Isolated<EventDTO>]?
  let festivals: [String: Isolated<FestivalDTO>]?
}

// MARK: - NameDTO

private struct NameDTO: Decodable {
  let name: String
}

// MARK: - EventDTO

private struct EventDTO: Decodable {
  let name: String
  let desc: String
  let regulation: String
}

// MARK: - FestivalDTO

private struct FestivalDTO: Decodable {
  struct TeamDTO: Decodable {
    let teamName: String
  }

  let title: String
  let teams: [TeamDTO]
}
