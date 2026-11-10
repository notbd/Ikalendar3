//
//  TermTable+Decoding.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import OSLog

extension TermTable {
  /// Decodes a `locale/<code>.json` response body. Runs off the main actor.
  ///
  /// An entry the app cannot use is left out, so lookup falls back for it: one without a name,
  /// such as the bogus `"undefined": {}` Rule key some files carry, or one whose name is empty.
  /// A table that fails on its own is left out whole. The tables the app does not show (brands,
  /// gear, abilities) are not read.
  ///
  /// - Throws: `DecodingError` when the body is not a locale file.
  @concurrent
  static public func decode(from body: Data) async throws -> TermTable {
    try TermTable(localeFile: body)
  }

  /// Decodes a locale file on the calling thread, as `decode(from:)` does.
  init(localeFile body: Data) throws {
    let dto = try FeedJSON.decoder().decode(LocaleDTO.self, from: body)

    self.init()
    stages = Self.usable(dto.stages) { $0.name.nonEmpty }
    rules = Self.usable(dto.rules) { $0.name.nonEmpty }
    weapons = Self.usable(dto.weapons) { $0.name.nonEmpty }
    kingSalmonids = Self.usable(dto.bosses) { $0.name.nonEmpty }
    challenges = Self.usable(dto.events) { event in
      event.name.nonEmpty.map { ChallengeTerms(name: $0, description: event.desc, rulesText: event.regulation) }
    }
    splatfests = Self.usable(dto.festivals) { festival in
      festival.title.nonEmpty.map { SplatfestTerms(title: $0, teamNames: festival.teams.map(\.teamName)) }
    }
  }

  /// The entries of a locale table that decode and that `term` accepts, keyed by typed id. A
  /// missing table has none; so does a malformed one, which is logged (the error names it).
  static private func usable<Kind, Entry, Term>(
    _ table: Isolated<[String: Isolated<Entry>]>?,
    _ term: (Entry) -> Term?)
    -> [FeedID<Kind>: Term]
  {
    let entries: [String: Isolated<Entry>]
    do {
      entries = try table?.result.get() ?? [:]
    }
    catch {
      Logger.decode.error("locale: a table failed: \(error, privacy: .public)")
      return [:]
    }
    return .init(uniqueKeysWithValues: entries.compactMap { key, entry in
      (try? entry.result.get()).flatMap(term).map { (FeedID(key), $0) }
    })
  }
}

extension String {
  /// The string, or `nil` when it is empty.
  fileprivate var nonEmpty: String? { isEmpty ? nil : self }
}

// MARK: - LocaleDTO

/// A locale file: one table per kind of term, each keyed by id. Each table and each entry
/// decodes on its own.
private struct LocaleDTO: Decodable {
  let stages: Isolated<[String: Isolated<NameDTO>]>?
  let rules: Isolated<[String: Isolated<NameDTO>]>?
  let weapons: Isolated<[String: Isolated<NameDTO>]>?
  let bosses: Isolated<[String: Isolated<NameDTO>]>?
  let events: Isolated<[String: Isolated<EventDTO>]>?
  let festivals: Isolated<[String: Isolated<FestivalDTO>]>?
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
