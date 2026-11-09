//
//  SplatfestScreenTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

/// The 2026-10-31 Splatfest runs from 2026-10-31 00:00 UTC, with Tricolor Turf War from
/// 2026-11-01 00:00, to 2026-11-02 00:00; the 2026-08-22 one ends 2026-08-24 00:00 UTC.
struct SplatfestScreenTests {
  /// A Splatfest fixture at an instant, and what its screen shows there.
  struct PhaseCase: CustomTestStringConvertible {
    let fixture: Fixture
    let instant: String
    let phase: Splatfest.Phase
    /// The start of the Splatfest Battle Rotation on and its progress, or `nil` when none is.
    let current: (start: String, progress: WindowProgress)?
    let nextStart: String?
    let laterCount: Int
    /// Tricolor Turf War's progress, or `nil` when it is not on.
    let tricolorProgress: WindowProgress?
    /// The starts of the Regular Battle Rotations published after the Splatfest's end.
    let afterwardsStarts: [String]

    var testDescription: String { fixture.rawValue }
  }

  @Test(arguments: SplatfestBattleForm.allCases, [
    // Recorded before the start: the first Rotations are published, none is on.
    PhaseCase(
      fixture: .splatfestAnnounced,
      instant: "2026-10-30T12:00:00Z",
      phase: .announced,
      current: nil,
      nextStart: "2026-10-31T00:00:00Z",
      laterCount: 5,
      tricolorProgress: nil,
      afterwardsStarts: []),
    PhaseCase(
      fixture: .splatfestFirstHalf,
      instant: "2026-10-31T12:00:00Z",
      phase: .firstHalf,
      current: ("2026-10-31T12:00:00Z", .init(timeLeft: .seconds(7200), sharePassed: 0)),
      nextStart: "2026-10-31T14:00:00Z",
      laterCount: 10,
      tricolorProgress: nil,
      afterwardsStarts: []),
    // 5 h 23 min into the second half's 24 hours.
    PhaseCase(
      fixture: .splatfestSecondHalf,
      instant: "2026-11-01T05:23:00Z",
      phase: .secondHalf,
      current: ("2026-11-01T04:00:00Z", .init(timeLeft: .seconds(37 * 60), sharePassed: 83.0 / 120)),
      nextStart: "2026-11-01T06:00:00Z",
      laterCount: 8,
      tricolorProgress: .init(timeLeft: .seconds(67020), sharePassed: 19380.0 / 86400),
      afterwardsStarts: ["2026-11-02T00:00:00Z", "2026-11-02T02:00:00Z", "2026-11-02T04:00:00Z"]),
    // The last four hours: the Splatfest's last two Rotations, then Regular Battle's.
    PhaseCase(
      fixture: .splatfestEnd,
      instant: "2026-08-23T20:00:00Z",
      phase: .secondHalf,
      current: ("2026-08-23T20:00:00Z", .init(timeLeft: .seconds(7200), sharePassed: 0)),
      nextStart: "2026-08-23T22:00:00Z",
      laterCount: 0,
      tricolorProgress: .init(timeLeft: .seconds(4 * 3600), sharePassed: 20.0 / 24),
      afterwardsStarts: everyTwoHours(from: "2026-08-24T00:00:00Z", count: 10).map { $0.ISO8601Format() }),
  ])
  func `The Splatfest screen shows the card, its Rotations, Tricolor Turf War and what follows in each phase`(
    _ form: SplatfestBattleForm,
    _ phaseCase: PhaseCase)
    async throws
  {
    let snapshot = try await Snapshot.schedules(phaseCase.fixture)
    let splatfest = try #require(snapshot.splatfest)
    let published = try #require(snapshot.schedules?.content.rotations(for: .splatfestBattle(form)))
    let instant = date(phaseCase.instant)

    let screen = try #require(snapshot.splatfestScreen(of: form, at: instant))

    #expect(screen.splatfest == splatfest)
    #expect(screen.phase == phaseCase.phase)
    #expect(screen.form == form)
    if let expected = phaseCase.current {
      let current = try #require(published.first { $0.startTime == date(expected.start) })
      #expect(screen.current == .running(.init(item: current, progress: expected.progress)))
    }
    else {
      #expect(screen.current == .nothingCurrent)
    }
    #expect(screen.next?.startTime == phaseCase.nextStart.map(date))
    #expect(screen.next?.mode == .splatfestBattle(form))
    #expect(screen.later.count == phaseCase.laterCount)
    #expect(screen.later.allSatisfy { $0.mode == .splatfestBattle(form) })
    #expect(screen.tricolorTurfWar?.progress == phaseCase.tricolorProgress)
    if screen.tricolorTurfWar != nil {
      #expect(screen.tricolorTurfWar?.item.stages == splatfest.tricolorStages)
      #expect(screen.tricolorTurfWar?.item.startTime == splatfest.midtermTime)
      #expect(screen.tricolorTurfWar?.item.endTime == splatfest.endTime)
    }
    #expect(screen.afterwards.map(\.startTime) == phaseCase.afterwardsStarts.map(date))
    #expect(screen.afterwards.allSatisfy { $0.mode == .battle(.regular) && !$0.isPaused })
  }

  @Test
  func `The Splatfest card carries its art address from festivals json`() async throws {
    let snapshot = try await Snapshot(
      schedules: .init(content: ScheduleFeed.decode(from: Fixture.splatfestSecondHalf.data()), fetchTime: TestData.epoch),
      festivals: .init(content: FestivalFeed.decode(from: Fixture.festivals.data()), fetchTime: TestData.epoch))

    let screen = try #require(snapshot.splatfestScreen(of: .open, at: date("2026-11-01T05:23:00Z")))

    #expect(screen.splatfest.artURL != nil)
    #expect(screen.splatfest.teamColors.count == 3)
  }

  @Test
  func `Once the Splatfest is over, or with none in the feed, there is no Splatfest screen`() async throws {
    let ended = try await Snapshot.schedules(.splatfestSecondHalf)
    let normalDay = try await Snapshot.schedules(.normalDay)

    #expect(ended.splatfestScreen(of: .open, at: date("2026-11-02T00:00:00Z")) == nil)
    #expect(normalDay.splatfestScreen(of: .pro, at: date("2026-10-20T12:00:00Z")) == nil)
    #expect(Snapshot().splatfestScreen(of: .open, at: TestData.epoch) == nil)
  }

  @Test(arguments: SplatfestBattleForm.allCases)
  func `Each Splatfest Battle summary matches the current Rotation of that form's screen`(
    _ form: SplatfestBattleForm)
    async throws
  {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)
    let instant = date("2026-11-01T05:23:00Z")
    let published = try #require(snapshot.schedules?.content.rotations(for: .splatfestBattle(form)).first)

    let summary = try #require(snapshot.splatfestBattleSummary(of: form, at: instant))

    // 83 of the first Rotation's 120 minutes have passed.
    #expect(summary == .init(form: form, current: .running(.init(
      item: published,
      progress: .init(timeLeft: .seconds(37 * 60), sharePassed: 83.0 / 120)))))
    #expect(summary.current == snapshot.splatfestScreen(of: form, at: instant)?.current)
  }
}
