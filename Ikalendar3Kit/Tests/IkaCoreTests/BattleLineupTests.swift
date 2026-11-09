//
//  BattleLineupTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

// MARK: - BattleLineupTests

struct BattleLineupTests {
  /// An instant on the normal day and the Rotations its lineup holds, by start time.
  struct NormalDayCase: CustomTestStringConvertible {
    let instant: String
    let current: String
    let next: String
    let later: [Date]

    var testDescription: String { instant }
  }

  @Test(arguments: BattleMode.allCases, [
    NormalDayCase(
      instant: "2026-10-20T13:00:00Z",
      current: "2026-10-20T12:00:00Z",
      next: "2026-10-20T14:00:00Z",
      later: everyTwoHours(from: "2026-10-20T16:00:00Z", count: 10)),
    NormalDayCase(
      instant: "2026-10-20T13:59:59Z",
      current: "2026-10-20T12:00:00Z",
      next: "2026-10-20T14:00:00Z",
      later: everyTwoHours(from: "2026-10-20T16:00:00Z", count: 10)),
    NormalDayCase(
      instant: "2026-10-20T14:00:00Z",
      current: "2026-10-20T14:00:00Z",
      next: "2026-10-20T16:00:00Z",
      later: everyTwoHours(from: "2026-10-20T18:00:00Z", count: 9)),
  ])
  func `A continuous Battle Mode holds the Rotation on now, the next one and the rest`(
    _ mode: BattleMode,
    _ normalDay: NormalDayCase)
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: Fixture.normalDay.data())

    let lineup = feed.battleLineup(of: .battle(mode), at: date(normalDay.instant))

    let current = try #require(lineup.current.item)
    #expect(current.mode == .battle(mode))
    #expect(current.startTime == date(normalDay.current))
    #expect(lineup.next?.startTime == date(normalDay.next))
    #expect(lineup.later.map(\.startTime) == normalDay.later)
  }

  @Test(arguments: BattleMode.allCases)
  func `A continuous Battle Mode runs out when its last published Rotation ends`(_ mode: BattleMode) async throws {
    let feed = try await ScheduleFeed.decode(from: Fixture.normalDay.data())

    let lastSecond = feed.battleLineup(of: .battle(mode), at: date("2026-10-21T11:59:59Z"))
    #expect(lastSecond.current.item?.startTime == date("2026-10-21T10:00:00Z"))
    #expect(lastSecond.next == nil)
    #expect(lastSecond.later.isEmpty)

    let end = feed.battleLineup(of: .battle(mode), at: date("2026-10-21T12:00:00Z"))
    #expect(end == Lineup(current: .ranOut, next: nil, later: []))
  }

  /// An instant on a Splatfest fixture, when the continuous Battle Modes return, and the
  /// Rotations published after that, by start time.
  struct PauseCase: CustomTestStringConvertible {
    let fixture: Fixture
    let instant: String
    let returnTime: String
    let upcoming: [Date]

    var testDescription: String { "\(fixture.rawValue) at \(instant)" }
  }

  @Test(arguments: BattleMode.allCases, [
    PauseCase(
      fixture: .splatfestSecondHalf,
      instant: "2026-11-01T05:23:00Z",
      returnTime: "2026-11-02T00:00:00Z",
      upcoming: everyTwoHours(from: "2026-11-02T00:00:00Z", count: 3)),
    PauseCase(
      fixture: .splatfestAnnounced,
      instant: "2026-10-31T00:00:00Z",
      returnTime: "2026-11-02T00:00:00Z",
      upcoming: []),
    // Every published window is paused and the Splatfest outlasts them all: still a pause.
    PauseCase(
      fixture: .splatfestFirstHalf,
      instant: "2026-11-01T13:00:00Z",
      returnTime: "2026-11-02T00:00:00Z",
      upcoming: []),
    PauseCase(
      fixture: .splatfestEnd,
      instant: "2026-08-23T23:59:59Z",
      returnTime: "2026-08-24T00:00:00Z",
      upcoming: everyTwoHours(from: "2026-08-24T00:00:00Z", count: 10)),
  ])
  func `A Splatfest pauses every continuous Battle Mode until it ends, which never runs out`(
    _ mode: BattleMode,
    _ pause: PauseCase)
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: pause.fixture.data())

    let lineup = feed.battleLineup(of: .battle(mode), at: date(pause.instant))

    #expect(lineup.current == .paused(returnTime: date(pause.returnTime)))
    #expect(lineup.upcoming.map(\.startTime) == pause.upcoming)
    #expect(lineup.upcoming.allSatisfy { !$0.isPaused })
  }

  @Test(arguments: BattleMode.allCases)
  func `Before a Splatfest its paused windows are not later Rotations, and after it the Rotations return`(
    _ mode: BattleMode)
    async throws
  {
    let announced = try await ScheduleFeed.decode(from: Fixture.splatfestAnnounced.data())
    let before = announced.battleLineup(of: .battle(mode), at: date("2026-10-30T13:00:00Z"))
    #expect(before.current.item?.startTime == date("2026-10-30T12:00:00Z"))
    #expect(before.next?.startTime == date("2026-10-30T14:00:00Z"))
    #expect(before.later.map(\.startTime) == everyTwoHours(from: "2026-10-30T16:00:00Z", count: 4))

    let ending = try await ScheduleFeed.decode(from: Fixture.splatfestEnd.data())
    let after = ending.battleLineup(of: .battle(mode), at: date("2026-08-24T00:00:00Z"))
    #expect(after.current.item?.startTime == date("2026-08-24T00:00:00Z"))
    #expect(after.current.item?.isPaused == false)
    #expect(after.next?.startTime == date("2026-08-24T02:00:00Z"))
  }

  @Test
  func `Without its Splatfest, a paused Battle Mode returns when its paused windows end`() {
    let rotations = [
      TestData.rotation(hours: 0 ..< 2),
      TestData.rotation(hours: 2 ..< 4, isPaused: true),
      TestData.rotation(hours: 4 ..< 6, isPaused: true),
      TestData.rotation(hours: 6 ..< 8),
    ]
    let feed: ScheduleFeed = TestData.feed(regularBattle: rotations, failedSections: [.splatfest])

    let before = feed.battleLineup(of: .battle(.regular), at: TestData.instant(hours: 1))
    #expect(before == Lineup(current: .item(rotations[0]), next: rotations[3], later: []))

    let paused = feed.battleLineup(of: .battle(.regular), at: TestData.instant(hours: 2))
    #expect(paused == Lineup(current: .paused(returnTime: TestData.instant(hours: 6)), next: rotations[3], later: []))
  }

  /// An instant on a Splatfest fixture and Splatfest Battle's lineup there, by start time.
  struct SplatfestBattleCase: CustomTestStringConvertible {
    let fixture: Fixture
    let instant: String
    let current: Current
    let upcoming: [Date]

    /// The Rotation on by its start time, or why none is.
    enum Current {
      case startingAt(String)
      case noItem(Lineup<Rotation>.Current)
    }

    var testDescription: String { "\(fixture.rawValue) at \(instant)" }
  }

  @Test(arguments: SplatfestBattleForm.allCases, [
    SplatfestBattleCase(
      fixture: .splatfestAnnounced,
      instant: "2026-10-30T13:00:00Z",
      current: .noItem(.gap),
      upcoming: everyTwoHours(from: "2026-10-31T00:00:00Z", count: 6)),
    SplatfestBattleCase(
      fixture: .splatfestSecondHalf,
      instant: "2026-11-01T05:23:00Z",
      current: .startingAt("2026-11-01T04:00:00Z"),
      upcoming: everyTwoHours(from: "2026-11-01T06:00:00Z", count: 9)),
    // The Splatfest still runs past the last published Rotation: the data ran out.
    SplatfestBattleCase(
      fixture: .splatfestFirstHalf,
      instant: "2026-11-01T13:00:00Z",
      current: .noItem(.ranOut),
      upcoming: []),
    // The Splatfest is over: no Splatfest Battle is announced.
    SplatfestBattleCase(
      fixture: .splatfestEnd,
      instant: "2026-08-24T00:00:00Z",
      current: .noItem(.noneAnnounced),
      upcoming: []),
  ])
  func `Splatfest Battle holds its Rotations while its Splatfest runs`(
    _ form: SplatfestBattleForm,
    _ splatfestBattle: SplatfestBattleCase)
    async throws
  {
    let feed = try await ScheduleFeed.decode(from: splatfestBattle.fixture.data())

    let lineup = feed.battleLineup(of: .splatfestBattle(form), at: date(splatfestBattle.instant))

    switch splatfestBattle.current {
      case .startingAt(let start):
        #expect(lineup.current.item?.mode == .splatfestBattle(form))
        #expect(lineup.current.item?.startTime == date(start))

      case .noItem(let current):
        #expect(lineup.current == current)
    }
    #expect(lineup.upcoming.map(\.startTime) == splatfestBattle.upcoming)
  }
}

extension Lineup {
  /// `next`, then `later`.
  var upcoming: [Item] { (next.map { [$0] } ?? []) + later }
}

/// The start times of `count` Rotations in a row, the first at `first`.
func everyTwoHours(from first: String, count: Int) -> [Date] {
  (0 ..< count).map { date(first).addingTimeInterval(TimeInterval($0) * 2 * 3600) }
}
