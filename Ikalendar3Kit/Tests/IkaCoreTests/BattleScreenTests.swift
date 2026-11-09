//
//  BattleScreenTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

struct BattleScreenTests {
  /// An instant on the normal day, by the index of the published Rotation on then and how far
  /// it has run.
  struct NormalDayCase: CustomTestStringConvertible {
    let instant: String
    let currentIndex: Int
    let progress: WindowProgress

    var testDescription: String { instant }
  }

  @Test(arguments: BattleMode.allCases, [
    NormalDayCase(
      instant: "2026-10-20T12:00:00Z",
      currentIndex: 0,
      progress: .init(timeLeft: .seconds(7200), sharePassed: 0)),
    NormalDayCase(
      instant: "2026-10-20T13:30:00Z",
      currentIndex: 0,
      progress: .init(timeLeft: .seconds(1800), sharePassed: 0.75)),
    NormalDayCase(
      instant: "2026-10-20T14:00:00Z",
      currentIndex: 1,
      progress: .init(timeLeft: .seconds(7200), sharePassed: 0)),
    // The last published Rotation: nothing after it.
    NormalDayCase(
      instant: "2026-10-21T11:00:00Z",
      currentIndex: 11,
      progress: .init(timeLeft: .seconds(3600), sharePassed: 0.5)),
  ])
  func `A Battle Mode screen lists the current, next and later Rotations exactly as published`(
    _ mode: BattleMode,
    _ normalDay: NormalDayCase)
    async throws
  {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let published = try #require(snapshot.schedules?.content.rotations(for: .battle(mode)))
    try #require(published.count == 12)

    let screen = try #require(snapshot.battleScreen(of: mode, at: date(normalDay.instant)))

    #expect(screen.mode == mode)
    #expect(screen.current == .running(.init(item: published[normalDay.currentIndex], progress: normalDay.progress)))
    #expect(screen.next == published.dropFirst(normalDay.currentIndex + 1).first)
    #expect(screen.later == Array(published.dropFirst(normalDay.currentIndex + 2)))
  }

  @Test(arguments: BattleMode.allCases)
  func `Past the last published Rotation a Battle Mode screen reports nothing current`(
    _ mode: BattleMode)
    async throws
  {
    let snapshot = try await Snapshot.schedules(.normalDay)

    let screen = try #require(snapshot.battleScreen(of: mode, at: date("2026-10-21T12:00:00Z")))

    #expect(screen.current == .nothingCurrent)
    #expect(screen.next == nil)
    #expect(screen.later.isEmpty)
  }

  @Test(arguments: BattleMode.allCases)
  func `During the Splatfest a Battle Mode screen reports paused with its return time and the Rotations after it`(
    _ mode: BattleMode)
    async throws
  {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)

    let screen = try #require(snapshot.battleScreen(of: mode, at: date("2026-11-01T05:23:00Z")))

    #expect(screen.current == .paused(returnTime: date("2026-11-02T00:00:00Z")))
    #expect(screen.next?.startTime == date("2026-11-02T00:00:00Z"))
    #expect(screen.later.map(\.startTime) == everyTwoHours(from: "2026-11-02T02:00:00Z", count: 2))
  }

  @Test
  func `A Battle Mode screen carries the fetch time of the schedules feed`() async throws {
    let fetchTime = date("2026-10-20T12:03:00Z")
    let snapshot = try await Snapshot.schedules(.normalDay, fetchedAt: fetchTime)

    #expect(snapshot.battleScreen(of: .regular, at: date("2026-10-20T13:00:00Z"))?.fetchTime == fetchTime)
  }

  @Test
  func `No Battle Mode screen exists before the schedules feed's first good response`() {
    #expect(Snapshot().battleScreen(of: .regular, at: TestData.epoch) == nil)
  }
}
