//
//  TabMenuTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

// MARK: - TabMenuTests

struct TabMenuTests {
  @Test
  func `The Anarchy menu offers Series then Open, and the Splatfest menu Open then Pro`() {
    #expect(TabMenu.anarchy.modes == [.battle(.anarchySeries), .battle(.anarchyOpen)])
    #expect(TabMenu.splatfestBattle.modes == [.splatfestBattle(.open), .splatfestBattle(.pro)])
  }

  @Test
  func `Each Anarchy option is its Battle Mode's summary, with the current Rule and time left`() async throws {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let instant = date("2026-10-20T13:30:00Z")

    let options = snapshot.options(of: .anarchy, at: instant)

    let progress: WindowProgress = .init(timeLeft: .seconds(1800), sharePassed: 0.75)
    #expect(options.map(\.mode) == [.battle(.anarchySeries), .battle(.anarchyOpen)])
    #expect(options.map(\.summary) == [
      snapshot.summary(of: .battle(.anarchySeries), at: instant),
      snapshot.summary(of: .battle(.anarchyOpen), at: instant),
    ])
    #expect(options.map { $0.summary?.rotation?.setting?.rule } == [RuleID("VnNSdWxlLTM="), RuleID("VnNSdWxlLTE=")])
    #expect(options.map { $0.summary?.progress } == [progress, progress])
  }

  @Test
  func `Each Splatfest option is its form's summary, with the current Rule and time left`() async throws {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)
    let instant = date("2026-11-01T05:23:00Z")

    let options = snapshot.options(of: .splatfestBattle, at: instant)

    let progress: WindowProgress = .init(timeLeft: .seconds(37 * 60), sharePassed: 83.0 / 120)
    #expect(options.map(\.mode) == [.splatfestBattle(.open), .splatfestBattle(.pro)])
    #expect(options.map(\.summary) == [
      snapshot.summary(of: .open, at: instant),
      snapshot.summary(of: .pro, at: instant),
    ])
    #expect(options.map { $0.summary?.rotation?.setting?.rule } == [RuleID("VnNSdWxlLTA="), RuleID("VnNSdWxlLTA=")])
    #expect(options.map { $0.summary?.progress } == [progress, progress])
  }

  @Test
  func `During a Splatfest the Anarchy options report the pause with the return time`() async throws {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)

    let options = snapshot.options(of: .anarchy, at: date("2026-11-01T05:23:00Z"))

    #expect(options.map(\.summary) == [
      .battle(.anarchySeries, .paused(returnTime: date("2026-11-02T00:00:00Z"))),
      .battle(.anarchyOpen, .paused(returnTime: date("2026-11-02T00:00:00Z"))),
    ])
  }

  @Test
  func `Options keep both Modes and show no summary before the schedules feed's first good response`() {
    let options = Snapshot().options(of: .anarchy, at: TestData.epoch)

    #expect(options.map(\.mode) == [.battle(.anarchySeries), .battle(.anarchyOpen)])
    #expect(options.map(\.summary) == [nil, nil])
  }
}

extension ModeSummary {
  /// The Rotation on now, or `nil` when none is or the summary is Salmon Run's.
  fileprivate var rotation: Rotation? {
    switch self {
      case .battle(_, .running(let running)),
           .splatfestBattle(_, .running(let running)): running.item
      case .battle,
           .splatfestBattle,
           .salmonRun: nil
    }
  }
}
