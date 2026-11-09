//
//  FeedIDTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

struct FeedIDTests {
  static let schedules: [Fixture] = [
    .normalDay,
    .splatfestSecondHalf,
    .splatfestEnd,
    .bigRun,
    .eggstraWork,
    .splatfestAnnounced,
    .splatfestFirstHalf,
  ]

  @Test(arguments: schedules)
  func `Every decoded item is keyed by a feed id, never by an English name`(_ fixture: Fixture) async throws {
    let feed = try await ScheduleFeed.decode(from: fixture.data())
    let splatfest = Snapshot(schedules: .init(content: feed, fetchTime: .distantPast)).splatfest
    let rotations = (BattleMode.allCases.map(RotationMode.battle)
      + SplatfestBattleForm.allCases.map(RotationMode.splatfestBattle))
      .flatMap(feed.rotations(for:))
      .compactMap(\.setting)
    let shifts = feed.salmonRun + feed.eggstraWork

    let stages = rotations.flatMap(\.stages) + feed.challenges.flatMap(\.stages) + shifts.map(\.stage)
      + (splatfest?.tricolorStages ?? [])
    let rules = rotations.map(\.rule) + feed.challenges.map(\.rule)
    #expect(!stages.isEmpty && !rules.isEmpty && !shifts.isEmpty)

    for id in stages {
      #expect(nintendoID(id.rawValue).contains(/^(Vs|Coop)Stage-\d+$/), "\(id)")
    }
    for id in rules {
      #expect(nintendoID(id.rawValue).contains(/^VsRule-\d$/), "\(id)")
    }
    for id in shifts.compactMap(\.kingSalmonid) {
      #expect(nintendoID(id.rawValue).contains(/^CoopEnemy-\d+$/), "\(id)")
    }
    for id in feed.challenges.map(\.id) {
      #expect(nintendoID(id.rawValue).contains(/^LeagueMatchEvent-\w+$/), "\(id)")
    }
    for id in shifts.flatMap(\.weapons) {
      #expect(id.rawValue.contains(/^[0-9a-f]{16}$/), "\(id)")
    }
    if let id = splatfest?.id {
      #expect(id.rawValue.contains(/^[A-Z]+-\d{5}$/), "\(id)")
    }
  }

  /// Nintendo's base64 id decoded, such as `VsStage-1`.
  private func nintendoID(_ base64: String) -> String {
    Data(base64Encoded: base64).flatMap { String(data: $0, encoding: .utf8) } ?? ""
  }
}
