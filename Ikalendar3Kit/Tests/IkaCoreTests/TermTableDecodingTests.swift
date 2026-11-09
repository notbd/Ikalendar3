//
//  TermTableDecodingTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

struct TermTableDecodingTests {
  /// One locale fixture and the names it gives Scorch Gorge, Turf War, the random mark,
  /// Cohozuna, the 2026-10-23 Challenge and the 2026-10-31 Splatfest.
  struct LocaleCase: CustomTestStringConvertible {
    let fixture: Fixture
    let stage: String
    let rule: String
    let random: String
    let kingSalmonid: String
    let challenge: String
    let splatfestTitle: String
    let teamNames: [String]

    var testDescription: String { fixture.rawValue }
  }

  @Test(arguments: [
    LocaleCase(
      fixture: .localeEnUS,
      stage: "Scorch Gorge",
      rule: "Turf War",
      random: "Random",
      kingSalmonid: "Cohozuna",
      challenge: "Dualies at Ten Paces",
      splatfestTitle: "What would you be in a fantasy world?",
      teamNames: ["Wizard", "Knight", "Ninja"]),
    LocaleCase(
      fixture: .localeJaJP,
      stage: "ユノハナ大渓谷",
      rule: "ナワバリバトル",
      random: "ランダム",
      kingSalmonid: "ヨコヅナ",
      challenge: "最強マニューバー決定戦",
      splatfestTitle: "ファンタジーの世界に飛びこむなら？",
      teamNames: ["魔法使い", "ナイト", "忍者"]),
    LocaleCase(
      fixture: .localeKoKR,
      stage: "석순 대협곡",
      rule: "영역 배틀",
      random: "랜덤",
      kingSalmonid: "천하장사",
      challenge: "최강 머누버 결정전",
      splatfestTitle: "판타지 세계로 들어간다면?",
      teamNames: ["마법사", "기사", "닌자"]),
    LocaleCase(
      fixture: .localeZhCN,
      stage: "温泉花大峡谷",
      rule: "占地对战",
      random: "随机",
      kingSalmonid: "横纲",
      challenge: "最强机动枪争夺战",
      splatfestTitle: "如果进入幻想世界想成为哪种职业？",
      teamNames: ["魔法师", "骑士", "忍者"]),
    LocaleCase(
      fixture: .localeZhTW,
      stage: "溫泉花大峽谷",
      rule: "占地對戰",
      random: "隨機",
      kingSalmonid: "橫綱",
      challenge: "最強機動槍爭奪戰",
      splatfestTitle: "如果進入幻想世界想成為哪種職業？",
      teamNames: ["魔法師", "騎士", "忍者"]),
  ])
  func `Each locale file decodes every kind of term by id`(_ locale: LocaleCase) async throws {
    let terms = try await TermTable.decode(from: locale.fixture.data())

    #expect(terms.stages[StageID("VnNTdGFnZS0x")] == locale.stage)
    #expect(terms.rules[RuleID("VnNSdWxlLTA=")] == locale.rule)
    #expect(terms.weapons[.random] == locale.random)
    #expect(terms.weapons[.rareRandom] == locale.random)
    #expect(terms.kingSalmonids[KingSalmonidID("Q29vcEVuZW15LTIz")] == locale.kingSalmonid)
    #expect(terms.challenges[ChallengeID("TGVhZ3VlTWF0Y2hFdmVudC1XZWFwb25MaW1pdGVkX01hbmV1dmVy")]?.name
      == locale.challenge)
    #expect(terms.splatfests[SplatfestID("JUEA-00108")] == SplatfestTerms(
      title: locale.splatfestTitle,
      teamNames: locale.teamNames))
  }

  @Test(arguments: [Fixture.localeKoKR, .localeZhCN, .localeZhTW])
  func `The bogus undefined Rule key is left out`(_ fixture: Fixture) async throws {
    let terms = try await TermTable.decode(from: fixture.data())

    #expect(Set(terms.rules.keys) == Set([
      "VnNSdWxlLTA=",
      "VnNSdWxlLTE=",
      "VnNSdWxlLTI=",
      "VnNSdWxlLTM=",
      "VnNSdWxlLTQ=",
    ]
    .map { RuleID($0) }))
  }

  @Test
  func `An entry with an empty name is left out, so lookup falls back for it`() async throws {
    let terms = try await TermTable.decode(from: Fixture.localeZhCN.data())

    #expect(terms.stages[StageID("Q29vcFN0YWdlLS05OTk=")] == nil)
    #expect(terms.stages[StageID("Q29vcFN0YWdlLTg=")] == "生筋子系统交流道遗址")
  }

  // MARK: - Feed terms

  @Test
  func `The schedules feed's English names are the fallback terms, by id`() async throws {
    let feed = try await ScheduleFeed.decode(from: Fixture.normalDay.data())
    let terms = Snapshot(schedules: .init(content: feed, fetchTime: date("2026-10-20T12:00:00Z"))).feedTerms

    #expect(terms.stages[StageID("VnNTdGFnZS0x")] == "Scorch Gorge")
    #expect(terms.stages[StageID("Q29vcFN0YWdlLTg=")] == "Jammin' Salmon Junction")
    #expect(terms.rules[RuleID("VnNSdWxlLTA=")] == "Turf War")
    #expect(terms.weapons[WeaponID("de8a2a542dbe6b99")] == "S-BLAST '92")
    #expect(terms.kingSalmonids[KingSalmonidID("Q29vcEVuZW15LTIz")] == "Cohozuna")
    #expect(terms.challenges[ChallengeID("TGVhZ3VlTWF0Y2hFdmVudC1XZWFwb25MaW1pdGVkX01hbmV1dmVy")] == ChallengeTerms(
      name: "Dualies at Ten Paces",
      description: "Enter a battlefield filled with slippery<br />customers in this all-dualies war!",
      rulesText: "Stick and move with the best of 'em in this dualies dustup!<br /><br />"
        + "・ Players can only choose different varieties of dualies.<br />"
        + "・ Both primary and secondary abilities will be enabled."))
  }

  @Test
  func `The Splatfest's fallback title and team names come from its festivals record`() async throws {
    let schedules = try await Fetched(
      content: ScheduleFeed.decode(from: Fixture.splatfestSecondHalf.data()),
      fetchTime: date("2026-11-01T05:23:00Z"))
    let festivals = try await Fetched(
      content: FestivalFeed.decode(from: Fixture.festivals.data()),
      fetchTime: date("2026-11-01T05:23:00Z"))
    let id: SplatfestID = .init("JUEA-00108")

    #expect(Snapshot(schedules: schedules, festivals: festivals).feedTerms.splatfests[id] == SplatfestTerms(
      title: "What would you be in a fantasy world?",
      teamNames: ["Wizard", "Knight", "Ninja"]))
    #expect(Snapshot(schedules: schedules).feedTerms.splatfests[id] == SplatfestTerms(
      title: "What would you be in a fantasy world?",
      teamNames: []))
  }

  @Test
  func `A Challenge keeps its description and rules text`() async throws {
    let terms = try await TermTable.decode(from: Fixture.localeEnUS.data())

    let challenge = try #require(terms.challenges[ChallengeID("TGVhZ3VlTWF0Y2hFdmVudC1XZWFwb25MaW1pdGVkX01hbmV1dmVy")])
    #expect(challenge.description == "Enter a battlefield filled with slippery<br />customers in this all-dualies war!")
    #expect(challenge.rulesText.hasPrefix("Stick and move with the best of 'em in this dualies dustup!<br /><br />"))
  }
}
