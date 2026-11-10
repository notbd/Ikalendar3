//
//  ScheduleFeedDecodingTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

// MARK: - ScheduleFeedDecodingTests

struct ScheduleFeedDecodingTests {
  @Test
  func `Normal day decodes twelve Rotations per continuous Battle Mode with their first Rule and Stages`()
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: Fixture.normalDay.data())

    let expectedFirst: [BattleMode: (rule: String, stages: [String])] = [
      .regular: ("VnNSdWxlLTA=", ["VnNTdGFnZS0x", "VnNTdGFnZS0xOQ=="]),
      .anarchySeries: ("VnNSdWxlLTM=", ["VnNTdGFnZS01", "VnNTdGFnZS0xMQ=="]),
      .anarchyOpen: ("VnNSdWxlLTE=", ["VnNTdGFnZS0z", "VnNTdGFnZS0yMw=="]),
      .x: ("VnNSdWxlLTI=", ["VnNTdGFnZS0xMg==", "VnNTdGFnZS0yMQ=="]),
    ]
    for mode in BattleMode.allCases {
      let rotations = feed.rotations(for: .battle(mode))
      #expect(rotations.count == 12, "\(mode)")

      let first = try #require(rotations.first)
      let expected = try #require(expectedFirst[mode])
      #expect(first.mode == .battle(mode))
      #expect(first.setting?.rule == RuleID(expected.rule))
      #expect(first.setting?.stages == expected.stages.map { StageID($0) })
      #expect(first.startTime == date("2026-10-20T12:00:00Z"))
      #expect(first.endTime == date("2026-10-20T14:00:00Z"))
    }
    #expect(feed.failedSections.isEmpty)
  }

  /// A Salmon Run fixture's first Regular Battle and X Battle Rotations.
  struct FirstRotationsCase: CustomTestStringConvertible {
    let fixture: Fixture
    let startTime: String
    let regularStages: [String]
    let xStages: [String]

    var testDescription: String { fixture.rawValue }
  }

  @Test(arguments: [
    FirstRotationsCase(
      fixture: .bigRun,
      startTime: "2026-09-07T12:00:00Z",
      regularStages: ["VnNTdGFnZS01", "VnNTdGFnZS0xMQ=="],
      xStages: ["VnNTdGFnZS02", "VnNTdGFnZS0yNg=="]),
    FirstRotationsCase(
      fixture: .eggstraWork,
      startTime: "2026-08-28T12:00:00Z",
      regularStages: ["VnNTdGFnZS0xNA==", "VnNTdGFnZS0yNg=="],
      xStages: ["VnNTdGFnZS0z", "VnNTdGFnZS00"]),
  ])
  func `Big Run and Eggstra Work days decode twelve Rotations per Battle Mode and no Splatfest Battle`(
    _ day: FirstRotationsCase)
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: day.fixture.data())

    for mode in BattleMode.allCases {
      #expect(feed.rotations(for: .battle(mode)).count == 12, "\(mode)")
      #expect(feed.rotations(for: .battle(mode)).first?.startTime == date(day.startTime), "\(mode)")
    }
    let regular = feed.rotations(for: .battle(.regular)).first?.setting
    #expect(regular?.rule == RuleID("VnNSdWxlLTA="))
    #expect(regular?.stages == day.regularStages.map { StageID($0) })
    let x = feed.rotations(for: .battle(.x)).first?.setting
    #expect(x?.rule == RuleID("VnNSdWxlLTQ="))
    #expect(x?.stages == day.xStages.map { StageID($0) })
    #expect(feed.rotations(for: .splatfestBattle(.open)).isEmpty)
    #expect(feed.rotations(for: .splatfestBattle(.pro)).isEmpty)
    #expect(feed.failedSections.isEmpty)
  }

  @Test
  func `Normal day decodes two Challenges with their Rule, Stages and six windows`() async throws {
    let feed = try await ScheduleFeed.decode(from: Fixture.normalDay.data())

    #expect(feed.challenges.map(\.id) == [
      ChallengeID("TGVhZ3VlTWF0Y2hFdmVudC1XZWFwb25MaW1pdGVkX01hbmV1dmVy"),
      ChallengeID("TGVhZ3VlTWF0Y2hFdmVudC1Sb2xsZXJCcnVzaFNwZWVkVXA="),
    ])
    let first = try #require(feed.challenges.first)
    #expect(first.rule == RuleID("VnNSdWxlLTE="))
    #expect(first.stages == [StageID("VnNTdGFnZS01"), StageID("VnNTdGFnZS0xNA==")])
    #expect(first.windows.count == 6)
    #expect(first.windows.first == .init(
      startTime: date("2026-10-23T02:00:00Z"),
      endTime: date("2026-10-23T04:00:00Z")))
    #expect(first.windows.last == .init(
      startTime: date("2026-10-23T22:00:00Z"),
      endTime: date("2026-10-24T00:00:00Z")))
  }

  @Test
  func `Normal day decodes regular Shifts with their Stage, four weapons and King Salmonid`() async throws {
    let feed = try await ScheduleFeed.decode(from: Fixture.normalDay.data())

    #expect(feed.salmonRun.count == 5)
    #expect(feed.salmonRun.allSatisfy { $0.kind == .regular })
    let first = try #require(feed.salmonRun.first)
    #expect(first.stage == StageID("Q29vcFN0YWdlLTg="))
    #expect(first.weapons == ["de8a2a542dbe6b99", "83c543ed4ae19005", "ed647072fa99c73e", "17b8d348d6380ae9"]
      .map { WeaponID($0) })
    #expect(first.kingSalmonid == KingSalmonidID("Q29vcEVuZW15LTIz"))
    #expect(first.startTime == date("2026-10-19T00:00:00Z"))
    #expect(first.endTime == date("2026-10-20T16:00:00Z"))
    #expect(feed.eggstraWork.isEmpty)
  }

  @Test
  func `A Big Run sits among the regular Shifts in time order with four random weapon marks`() async throws {
    let feed = try await ScheduleFeed.decode(from: Fixture.bigRun.data())

    #expect(feed.salmonRun.map(\.kind) == [.regular, .regular, .regular, .bigRun, .regular])
    #expect(feed.salmonRun.map(\.startTime) == [
      "2026-09-07T08:00:00Z",
      "2026-09-09T00:00:00Z",
      "2026-09-10T16:00:00Z",
      "2026-09-12T00:00:00Z",
      "2026-09-14T00:00:00Z",
    ].map(date))
    let bigRun = feed.salmonRun[3]
    #expect(bigRun.endTime == date("2026-09-14T00:00:00Z"))
    #expect(bigRun.stage == StageID("Q29vcFN0YWdlLTEwMA=="))
    #expect(bigRun.weapons == Array(repeating: .random, count: 4))
    #expect(bigRun.kingSalmonid == KingSalmonidID("Q29vcEVuZW15LTMw"))
  }

  @Test
  func `An Eggstra Work decodes apart from Salmon Run with no King Salmonid`() async throws {
    let feed = try await ScheduleFeed.decode(from: Fixture.eggstraWork.data())

    let eggstraWork = try #require(feed.eggstraWork.only)
    #expect(eggstraWork.kind == .eggstraWork)
    #expect(eggstraWork.stage == StageID("Q29vcFN0YWdlLTc="))
    #expect(eggstraWork.weapons == ["83c543ed4ae19005", "fe3b9b3b87ca491e", "23deec47199c37d1", "3aac272457998973"]
      .map { WeaponID($0) })
    #expect(eggstraWork.kingSalmonid == nil)
    #expect(eggstraWork.startTime == date("2026-08-29T00:00:00Z"))
    #expect(eggstraWork.endTime == date("2026-08-31T00:00:00Z"))

    #expect(feed.salmonRun.count == 4)
    #expect(feed.salmonRun.allSatisfy { $0.kind == .regular })
  }

  @Test
  func `A regular Shift can hand out four rare random weapon marks`() async throws {
    let feed = try await ScheduleFeed.decode(from: Fixture.eggstraWork.data())

    let first = try #require(feed.salmonRun.first)
    #expect(first.startTime == date("2026-08-28T08:00:00Z"))
    #expect(first.weapons == Array(repeating: .rareRandom, count: 4))
    #expect(first.kingSalmonid == KingSalmonidID("Q29vcEVuZW15LTMw"))
  }

  /// What a Splatfest fixture publishes: how many windows each continuous Battle Mode lists and
  /// how many of them come first and are paused, and the first Open and Pro Stages.
  struct SplatfestCase: CustomTestStringConvertible {
    let fixture: Fixture
    let windows: Int
    let paused: Int
    let splatfestRotations: Int
    let firstOpenStages: [String]
    let firstProStages: [String]

    var testDescription: String { fixture.rawValue }
  }

  @Test(arguments: [
    SplatfestCase(
      fixture: .splatfestSecondHalf,
      windows: 13,
      paused: 10,
      splatfestRotations: 10,
      firstOpenStages: ["VnNTdGFnZS0z", "VnNTdGFnZS0yMQ=="],
      firstProStages: ["VnNTdGFnZS0xNg==", "VnNTdGFnZS0xOA=="]),
    SplatfestCase(
      fixture: .splatfestEnd,
      windows: 12,
      paused: 2,
      splatfestRotations: 2,
      firstOpenStages: ["VnNTdGFnZS0y", "VnNTdGFnZS00"],
      firstProStages: ["VnNTdGFnZS0xMQ==", "VnNTdGFnZS0xNw=="]),
  ])
  func `During a Splatfest the continuous Battle Modes are paused and Splatfest Battle has Open and Pro Rotations`(
    _ splatfest: SplatfestCase)
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: splatfest.fixture.data())

    for mode in BattleMode.allCases {
      let rotations = feed.rotations(for: .battle(mode))
      #expect(rotations.count == splatfest.windows, "\(mode)")
      #expect(
        rotations.map(\.isPaused) == Array(repeating: true, count: splatfest.paused)
          + Array(repeating: false, count: splatfest.windows - splatfest.paused),
        "\(mode)")
    }

    let open = feed.rotations(for: .splatfestBattle(.open))
    let pro = feed.rotations(for: .splatfestBattle(.pro))
    #expect(open.count == splatfest.splatfestRotations)
    #expect(pro.count == splatfest.splatfestRotations)
    #expect(open.map(\.startTime) == feed.rotations(for: .battle(.regular)).prefix(splatfest.paused).map(\.startTime))
    #expect(open.first?.setting?.rule == RuleID("VnNSdWxlLTA="))
    #expect(open.first?.setting?.stages == splatfest.firstOpenStages.map { StageID($0) })
    #expect(pro.first?.setting?.rule == RuleID("VnNSdWxlLTA="))
    #expect(pro.first?.setting?.stages == splatfest.firstProStages.map { StageID($0) })
    #expect(feed.failedSections.isEmpty)
  }
}

extension Collection {
  /// The only element, or `nil` when there are none or several.
  var only: Element? { count == 1 ? first : nil }
}
