//
//  ModeSummaryTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

struct ModeSummaryTests {
  /// A fixture at an instant.
  struct Moment: CustomTestStringConvertible {
    let fixture: Fixture
    let instant: String

    var testDescription: String { "\(fixture.rawValue) at \(instant)" }
  }

  @Test(arguments: Mode.allCases, [
    Moment(fixture: .normalDay, instant: "2026-10-20T13:30:00Z"),
    Moment(fixture: .normalDay, instant: "2026-10-21T12:00:00Z"),
    Moment(fixture: .bigRun, instant: "2026-09-12T06:00:00Z"),
    Moment(fixture: .eggstraWork, instant: "2026-08-29T12:00:00Z"),
    Moment(fixture: .splatfestSecondHalf, instant: "2026-11-01T05:23:00Z"),
  ])
  func `Each Mode summary matches the current item of that Mode's screen`(
    _ mode: Mode,
    _ moment: Moment)
    async throws
  {
    let snapshot = try await Snapshot.schedules(moment.fixture)
    let instant = date(moment.instant)

    let summary = try #require(snapshot.summary(of: mode, at: instant))

    #expect(summary.mode == mode)
    switch summary {
      case .battle(let battleMode, let current):
        #expect(current == snapshot.battleScreen(of: battleMode, at: instant)?.current)

      case .salmonRun(let current):
        #expect(current == snapshot.salmonRunScreen(at: instant)?.current)

      case .splatfestBattle:
        Issue.record("A Mode's summary is never a form of Splatfest Battle's")
    }
  }

  @Test
  func `A Battle Mode summary gives the current Rotation, its time left and the share passed`() async throws {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let published = try #require(snapshot.schedules?.content.rotations(for: .battle(.anarchyOpen)))

    let summary = snapshot.summary(of: .battle(.anarchyOpen), at: date("2026-10-20T13:30:00Z"))

    #expect(summary == .battle(.anarchyOpen, .running(.init(
      item: published[0],
      progress: .init(timeLeft: .seconds(1800), sharePassed: 0.75)))))
  }

  @Test
  func `The Salmon Run summary is the current regular Shift, never a running Eggstra Work`() async throws {
    let snapshot = try await Snapshot.schedules(.eggstraWork)
    let regularShift = try #require(snapshot.schedules?.content.salmonRun.first)
    try #require(regularShift.kind == .regular)

    let summary = snapshot.summary(of: .salmonRun, at: date("2026-08-29T12:00:00Z"))

    #expect(summary == .salmonRun(.running(.init(
      item: regularShift,
      progress: .init(timeLeft: .seconds(12 * 3600), sharePassed: 28.0 / 40)))))
  }

  @Test
  func `The Salmon Run summary is the Big Run while one runs`() async throws {
    let snapshot = try await Snapshot.schedules(.bigRun)

    let summary = snapshot.summary(of: .salmonRun, at: date("2026-09-13T12:00:00Z"))

    guard case .salmonRun(.running(let running)) = summary else {
      Issue.record("No running Shift in \(String(describing: summary))")
      return
    }

    #expect(running.item.kind == .bigRun)
    #expect(running.progress == .init(timeLeft: .seconds(12 * 3600), sharePassed: 0.75))
  }

  /// The recorded decision: while a Splatfest pauses a Battle Mode, its summary reports the pause
  /// with the time the Battle Mode returns, as the iPhone tabs do.
  @Test(arguments: BattleMode.allCases)
  func `During the Splatfest a paused Battle Mode's summary reports its return time`(_ mode: BattleMode) async throws {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)

    let summary = snapshot.summary(of: .battle(mode), at: date("2026-11-01T05:23:00Z"))

    #expect(summary == .battle(mode, .paused(returnTime: date("2026-11-02T00:00:00Z"))))
  }

  @Test(arguments: Mode.allCases)
  func `No Mode summary exists before the schedules feed's first good response`(_ mode: Mode) {
    #expect(Snapshot().summary(of: mode, at: TestData.epoch) == nil)
  }

  @Test
  func `The Mode value's pages list its five Modes in its order, each with its summary`() async throws {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let instant = date("2026-10-20T13:30:00Z")

    let pages = try #require(snapshot.modePages(at: instant))

    #expect(pages.map(\.mode) == [
      .battle(.regular),
      .battle(.anarchySeries),
      .battle(.anarchyOpen),
      .battle(.x),
      .salmonRun,
    ])
    #expect(pages.map(\.summary) == Mode.allCases.compactMap { snapshot.summary(of: $0, at: instant) })
  }

  @Test
  func `During the Splatfest the Mode value's pages keep the paused Battle Modes, never Splatfest Battle`()
    async throws
  {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)

    let pages = try #require(snapshot.modePages(at: date("2026-11-01T05:23:00Z")))

    let returnTime = date("2026-11-02T00:00:00Z")
    #expect(pages.prefix(4).map(\.summary) == BattleMode.allCases.map { .battle($0, .paused(returnTime: returnTime)) })
    #expect(pages.count == 5)
  }

  @Test
  func `No list of the Mode value's pages exists before the schedules feed's first good response`() {
    #expect(Snapshot().modePages(at: TestData.epoch) == nil)
  }
}
