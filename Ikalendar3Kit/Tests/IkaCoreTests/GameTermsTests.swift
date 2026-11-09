//
//  GameTermsTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

// MARK: - GameTermsTests

struct GameTermsTests {
  /// Scorch Gorge, which every table names.
  static let scorchGorge: StageID = .init("VnNTdGFnZS0x")
  /// An id missing from every locale table.
  static let unknownStage: StageID = .init("VnNTdGFnZS05OTk=")

  // MARK: - Precedence

  @Test
  func `The refreshed table's name wins`() {
    var refreshed: TermTable = .init()
    refreshed.stages[Self.scorchGorge] = "ユノハナ大渓谷 (refreshed)"

    let terms: GameTerms = .init(language: .jaJP, refreshed: refreshed, feed: TermTable())

    #expect(terms.name(of: Self.scorchGorge) == "ユノハナ大渓谷 (refreshed)")
  }

  @Test
  func `Without a refreshed table, or without the id in it, the shipped snapshot's name is used`() {
    let feed: TermTable = .init(stage: Self.scorchGorge, name: "Scorch Gorge")

    #expect(GameTerms(language: .jaJP, refreshed: nil, feed: feed).name(of: Self.scorchGorge) == "ユノハナ大渓谷")
    #expect(GameTerms(language: .jaJP, refreshed: TermTable(), feed: feed).name(of: Self.scorchGorge) == "ユノハナ大渓谷")
  }

  @Test(arguments: GameLanguage.allCases)
  func `An id missing from both tables falls back to the feed's English name`(language: GameLanguage) {
    let terms: GameTerms = .init(
      language: language,
      refreshed: TermTable(),
      feed: TermTable(stage: Self.unknownStage, name: "New Stage"))

    #expect(terms.name(of: Self.unknownStage) == "New Stage")
  }

  @Test
  func `An id missing everywhere is named by its id, never blank`() {
    let terms: GameTerms = .init(language: .deDE, refreshed: nil, feed: TermTable())

    #expect(terms.name(of: Self.unknownStage) == "VnNTdGFnZS05OTk=")
    #expect(terms.challenge(ChallengeID("TGVhZ3VlTWF0Y2hFdmVudC1OZXc=")).name == "TGVhZ3VlTWF0Y2hFdmVudC1OZXc=")
    #expect(terms.splatfest(SplatfestID("JUEA-99999")) == SplatfestTerms(title: "JUEA-99999", teamNames: []))
  }

  @Test
  func `A snapshot's terms use its refreshed locale file and its feeds' English names`() async throws {
    let schedules = try await ScheduleFeed.decode(from: Fixture.normalDay.data())
    var refreshed: TermTable = .init()
    refreshed.stages[Self.scorchGorge] = "Gorge (refreshed)"
    let snapshot: Snapshot = .init(
      schedules: .init(content: schedules, fetchTime: date("2026-10-20T12:00:00Z")),
      locales: [.frFR: .init(content: refreshed, fetchTime: date("2026-10-20T12:00:00Z"))])

    #expect(snapshot.terms(in: .frFR).name(of: Self.scorchGorge) == "Gorge (refreshed)")
    #expect(snapshot.terms(in: .deDE).name(of: Self.scorchGorge) == "Sengkluft")
  }

  // MARK: - Coverage

  /// Every Stage, Rule, weapon, King Salmonid and Challenge the schedules fixtures name.
  static func fixtureIDs() async throws -> TermTable {
    var ids: TermTable = .init()
    for fixture in Fixture.allCases where fixture.rawValue.hasPrefix("schedules-") {
      let terms = try await ScheduleFeed.decode(from: fixture.data()).terms
      ids.stages.merge(terms.stages) { $1 }
      ids.rules.merge(terms.rules) { $1 }
      ids.weapons.merge(terms.weapons) { $1 }
      ids.kingSalmonids.merge(terms.kingSalmonids) { $1 }
      ids.challenges.merge(terms.challenges) { $1 }
    }
    return ids
  }

  /// The shipped snapshot names every fixture id in every language. An id that is missing would
  /// show the feed's English name instead; the test lists each one.
  @Test(arguments: GameLanguage.allCases)
  func `Every fixture id resolves in the shipped snapshot`(language: GameLanguage) async throws {
    let ids = try await Self.fixtureIDs()
    let shipped: TermTable = .shipped(in: language)

    let missing = ids.stages.keys.filter { shipped.stages[$0] == nil }.map { "stage \($0)" }
      + ids.rules.keys.filter { shipped.rules[$0] == nil }.map { "rule \($0)" }
      + ids.weapons.keys.filter { shipped.weapons[$0] == nil }.map { "weapon \($0)" }
      + ids.kingSalmonids.keys.filter { shipped.kingSalmonids[$0] == nil }.map { "King Salmonid \($0)" }
      + ids.challenges.keys.filter { shipped.challenges[$0] == nil }.map { "Challenge \($0)" }
    #expect(missing.isEmpty, "Falls back to English in \(language.rawValue): \(missing.sorted())")
    #expect(!ids.stages.isEmpty && !ids.weapons.isEmpty && !ids.challenges.isEmpty)
  }

  /// Flounder Heights and Undertow Spillway in each language. Regional variants differ in one
  /// of the two (es-ES and es-MX in the second, fr-FR and fr-CA in the first), so each text
  /// set is read from its own file. en-US and en-GB name every Stage alike.
  @Test(arguments: [
    (GameLanguage.enUS, "Flounder Heights", "Undertow Spillway"),
    (.enGB, "Flounder Heights", "Undertow Spillway"),
    (.esES, "Complejo Medusa", "Cisterna Navajuela"),
    (.esMX, "Complejo Medusa", "Desagüe Navajuela"),
    (.frFR, "Lotissement Filament", "Réservoir Rigadelle"),
    (.frCA, "Appartements Filament", "Réservoir Rigadelle"),
    (.deDE, "Schollensiedlung", "Schwertmuschel-Reservoir"),
    (.itIT, "Cime Sogliolose", "Cisterna Cernia"),
    (.nlNL, "Baleinbuurt", "Baarsreservoir"),
    (.ruRU, "Микрорайон «Камбалово»", "Приливослив"),
    (.jaJP, "ヒラメが丘団地", "マテガイ放水路"),
    (.koKR, "넙치 언덕 단지", "맛조개 방수로"),
    (.zhCN, "比目鱼住宅区", "竹蛏疏洪道"),
    (.zhTW, "比目魚住宅區", "竹蟶疏洪道"),
  ])
  func `Each language reads its own shipped file`(
    language: GameLanguage,
    flounderHeights: String,
    undertowSpillway: String)
  {
    let terms: GameTerms = .init(language: language, refreshed: nil, feed: TermTable())

    #expect(terms.name(of: StageID("VnNTdGFnZS05")) == flounderHeights)
    #expect(terms.name(of: StageID("VnNTdGFnZS00")) == undertowSpillway)
  }
}

extension TermTable {
  /// A table that names one Stage.
  fileprivate init(stage: StageID, name: String) {
    self.init()
    stages[stage] = name
  }
}
