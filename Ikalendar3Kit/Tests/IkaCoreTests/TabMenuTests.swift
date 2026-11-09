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
  func `Each Anarchy option shows its current Rule and time left`() async throws {
    let snapshot = try await Snapshot.schedules(.normalDay)

    let options = snapshot.options(of: .anarchy, at: date("2026-10-20T13:30:00Z"))

    let progress: WindowProgress = .init(timeLeft: .seconds(1800), sharePassed: 0.75)
    #expect(options.map(\.mode) == [.battle(.anarchySeries), .battle(.anarchyOpen)])
    #expect(options.map { $0.current?.running?.item.setting?.rule } == [RuleID("VnNSdWxlLTM="), RuleID("VnNSdWxlLTE=")])
    #expect(options.map { $0.current?.running?.progress } == [progress, progress])
  }

  @Test
  func `Each Splatfest option shows its current Rule and time left during a Splatfest`() async throws {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)

    let options = snapshot.options(of: .splatfestBattle, at: date("2026-11-01T05:23:00Z"))

    let progress: WindowProgress = .init(timeLeft: .seconds(37 * 60), sharePassed: 83.0 / 120)
    #expect(options.map(\.mode) == [.splatfestBattle(.open), .splatfestBattle(.pro)])
    #expect(options.map { $0.current?.running?.item.setting?.rule } == [RuleID("VnNSdWxlLTA="), RuleID("VnNSdWxlLTA=")])
    #expect(options.map { $0.current?.running?.progress } == [progress, progress])
  }

  @Test
  func `During a Splatfest the Anarchy options report the pause with the return time`() async throws {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)

    let options = snapshot.options(of: .anarchy, at: date("2026-11-01T05:23:00Z"))

    #expect(options.map(\.current) == [
      .paused(returnTime: date("2026-11-02T00:00:00Z")),
      .paused(returnTime: date("2026-11-02T00:00:00Z")),
    ])
  }

  @Test
  func `Options keep both Modes and show no Rule before the schedules feed's first good response`() {
    let options = Snapshot().options(of: .anarchy, at: TestData.epoch)

    #expect(options.map(\.mode) == [.battle(.anarchySeries), .battle(.anarchyOpen)])
    #expect(options.map(\.current) == [nil, nil])
  }
}

extension OnNow {
  /// The item on with its progress, or `nil` when none is.
  fileprivate var running: Running<Item>? {
    guard case .running(let running) = self else { return nil }

    return running
  }
}
