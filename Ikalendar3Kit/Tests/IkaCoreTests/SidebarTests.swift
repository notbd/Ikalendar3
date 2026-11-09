//
//  SidebarTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

/// The iPad sidebar's groups and rows on the recorded days, and which row the detail shows.
///
/// The normal day's first Challenge window runs on 2026-10-23 from 02:00 to 04:00 UTC; the Eggstra
/// Work fixture's Eggstra Work runs from 2026-08-29 00:00 to 2026-08-31 00:00 UTC; the 2026-10-31
/// Splatfest runs from 2026-10-31 00:00 UTC, with its midterm time a day later and its end two.
struct SidebarTests {
  static private let battleItems: [SidebarItem] = BattleMode.allCases.map { .mode(.battle($0)) }

  @Test
  func `On a normal day the sidebar lists Battle, Events and Salmon Run, each Mode with its summary`() async throws {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let instant = date("2026-10-20T13:30:00Z")
    let challenge = try #require(snapshot.schedules?.content.challenges.first)
    let firstWindow = try ChallengeWindow(challenge: challenge, window: #require(challenge.windows.first))
    try #require(firstWindow.startTime == date("2026-10-23T02:00:00Z"))

    let sidebar = try #require(snapshot.sidebar(at: instant))

    #expect(sidebar.groups.map(\.kind) == [.battle, .events, .salmonRun])
    #expect(sidebar.groups.map { $0.rows.map(\.item) } == [Self.battleItems, [.challenge], [.mode(.salmonRun)]])
    let summaries = try Mode.allCases.map { try #require(snapshot.summary(of: $0, at: instant)) }
    #expect(sidebar.groups[0].rows + sidebar.groups[2].rows == summaries.map(SidebarRow.mode))
    #expect(sidebar.groups[1].rows == [.challenge(.next(firstWindow))])
    #expect(sidebar.groups.flatMap(\.rows).allSatisfy { !$0.isDimmed })
  }

  /// A normal-day instant and what the Challenge row shows there.
  struct ChallengeCase: CustomTestStringConvertible {
    enum Shown { case running(WindowProgress), next, noneAnnounced }

    let instant: String
    let shown: Shown

    var testDescription: String { instant }
  }

  @Test(arguments: [
    ChallengeCase(instant: "2026-10-23T03:00:00Z", shown: .running(.init(timeLeft: .seconds(3600), sharePassed: 0.5))),
    ChallengeCase(instant: "2026-10-23T01:00:00Z", shown: .next),
    ChallengeCase(instant: "2026-10-31T00:00:00Z", shown: .noneAnnounced),
  ])
  func `The Challenge row shows the window on now, else the next one, else none announced`(
    _ challengeCase: ChallengeCase)
    async throws
  {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let challenge = try #require(snapshot.schedules?.content.challenges.first)
    let firstWindow = try ChallengeWindow(challenge: challenge, window: #require(challenge.windows.first))

    let sidebar = try #require(snapshot.sidebar(at: date(challengeCase.instant)))

    let expected: SidebarRow =
      switch challengeCase.shown {
        case .running(let progress): .challenge(.running(Running(item: firstWindow, progress: progress)))
        case .next: .challenge(.next(firstWindow))
        case .noneAnnounced: .challenge(nil)
      }
    #expect(sidebar.groups.first { $0.kind == .events }?.rows == [expected])
  }

  @Test
  func `While an Eggstra Work runs, its row follows Salmon Run's, which keeps the regular Shift`() async throws {
    let snapshot = try await Snapshot.schedules(.eggstraWork)
    let instant = date("2026-08-29T12:00:00Z")
    let eggstraWork = try #require(snapshot.schedules?.content.eggstraWork.first)

    let sidebar = try #require(snapshot.sidebar(at: instant))

    #expect(sidebar.groups.map(\.kind) == [.battle, .events, .salmonRun])
    #expect(try sidebar.groups.last?.rows == [
      .mode(#require(snapshot.summary(of: .salmonRun, at: instant))),
      .eggstraWork(Running(item: eggstraWork, progress: .init(timeLeft: .seconds(129_600), sharePassed: 0.25))),
    ])
  }

  @Test(arguments: ["2026-08-28T12:00:00Z", "2026-08-31T00:00:00Z"])
  func `No Eggstra Work row shows before the Eggstra Work starts or from its end`(_ instant: String) async throws {
    let snapshot = try await Snapshot.schedules(.eggstraWork)

    let sidebar = try #require(snapshot.sidebar(at: date(instant)))

    #expect(sidebar.groups.last?.rows.map(\.item) == [.mode(.salmonRun)])
  }

  @Test
  func `During the Splatfest's second half its group leads and the paused Battle Modes are dimmed`() async throws {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)
    let instant = date("2026-11-01T05:23:00Z")
    let splatfest = try #require(snapshot.splatfest)

    let sidebar = try #require(snapshot.sidebar(at: instant))

    #expect(sidebar.groups.map(\.kind) == [.splatfest, .battle, .events, .salmonRun])
    #expect(sidebar.groups[0].rows.map(\.item) == [
      .splatfest,
      .splatfestBattle(.open),
      .splatfestBattle(.pro),
      .tricolorTurfWar,
    ])
    #expect(sidebar.groups[0].rows.first == .splatfest(Running(
      item: splatfest,
      progress: splatfest.progress(at: instant))))
    // 5 hours 23 minutes into the 24-hour second half.
    #expect(sidebar.groups[0].rows.last == .tricolorTurfWar(.running(Running(
      item: splatfest.tricolorTurfWar,
      progress: .init(timeLeft: .seconds(67020), sharePassed: 19380.0 / 86400)))))
    let returnTime = date("2026-11-02T00:00:00Z")
    #expect(sidebar.groups[1].rows == BattleMode.allCases.map { .mode(.battle($0, .paused(returnTime: returnTime))) })
    #expect(sidebar.groups.flatMap(\.rows).filter(\.isDimmed).map(\.item) == Self.battleItems)
  }

  @Test
  func `Each form of Splatfest Battle's row shows the current Rotation of its Splatfest screen`() async throws {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)
    let instant = date("2026-11-01T05:23:00Z")

    let sidebar = try #require(snapshot.sidebar(at: instant))

    for form in SplatfestBattleForm.allCases {
      let screen = try #require(snapshot.splatfestScreen(of: form, at: instant))
      guard case .running = screen.current else {
        Issue.record("\(form) plays at the instant")
        continue
      }

      #expect(sidebar.groups[0].rows.contains(.mode(.splatfestBattle(form, screen.current))))
    }
  }

  @Test
  func `In the Splatfest's first half the Tricolor row waits for the midterm time, dimmed`() async throws {
    let snapshot = try await Snapshot.schedules(.splatfestFirstHalf)
    let splatfest = try #require(snapshot.splatfest)

    let sidebar = try #require(snapshot.sidebar(at: date("2026-10-31T12:00:00Z")))

    #expect(sidebar.groups[0].rows.last == .tricolorTurfWar(.next(splatfest.tricolorTurfWar)))
    #expect(splatfest.tricolorTurfWar.startTime == date("2026-11-01T00:00:00Z"))
    #expect(sidebar.groups.flatMap(\.rows).filter(\.isDimmed).map(\.item) == [.tricolorTurfWar] + Self.battleItems)
  }

  /// A Splatfest fixture at an instant outside the Splatfest.
  struct OutsideCase: CustomTestStringConvertible {
    let fixture: Fixture
    let instant: String

    var testDescription: String { "\(fixture.rawValue) at \(instant)" }
  }

  @Test(arguments: [
    OutsideCase(fixture: .splatfestAnnounced, instant: "2026-10-30T12:00:00Z"),
    OutsideCase(fixture: .splatfestSecondHalf, instant: "2026-11-02T00:00:00Z"),
  ])
  func `No Splatfest group shows while the Splatfest is only announced or after its end`(
    _ outside: OutsideCase)
    async throws
  {
    let snapshot = try await Snapshot.schedules(outside.fixture)

    let sidebar = try #require(snapshot.sidebar(at: date(outside.instant)))

    #expect(sidebar.groups.map(\.kind) == [.battle, .events, .salmonRun])
  }

  @Test
  func `No sidebar exists before the schedules feed's first good response`() {
    #expect(Snapshot().sidebar(at: TestData.epoch) == nil)
  }

  // MARK: Selection

  @Test(arguments: [SidebarItem.eggstraWork, .mode(.salmonRun)])
  func `A row the sidebar lists stays selected`(_ item: SidebarItem) async throws {
    let snapshot = try await Snapshot.schedules(.eggstraWork)

    let sidebar = try #require(snapshot.sidebar(at: date("2026-08-29T12:00:00Z")))

    #expect(item.shown(in: sidebar) == item)
  }

  @Test(arguments: [
    (SidebarItem.eggstraWork, SidebarItem.mode(.salmonRun)),
    (.splatfest, .mode(.battle(.regular))),
    (.splatfestBattle(.open), .mode(.battle(.regular))),
    (.splatfestBattle(.pro), .mode(.battle(.regular))),
    (.tricolorTurfWar, .mode(.battle(.regular))),
    (.mode(.battle(.x)), .mode(.battle(.x))),
    (.challenge, .challenge),
  ])
  func `A row that leaves the sidebar gives its place to Salmon Run or Regular Battle`(
    _ item: SidebarItem,
    _ shown: SidebarItem)
    async throws
  {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let sidebar = try #require(snapshot.sidebar(at: date("2026-10-20T13:30:00Z")))

    #expect(item.shown(in: sidebar) == shown)
    #expect(item.shown(in: nil) == shown)
  }

  @Test(arguments: [
    (AppTab.mode(.regularBattle), BattleMode.anarchySeries, SidebarItem.mode(.battle(.regular))),
    (.mode(.anarchy), .anarchySeries, .mode(.battle(.anarchySeries))),
    (.mode(.anarchy), .anarchyOpen, .mode(.battle(.anarchyOpen))),
    (.mode(.xBattle), .anarchySeries, .mode(.battle(.x))),
    (.mode(.challenge), .anarchySeries, .challenge),
    (.mode(.salmonRun), .anarchySeries, .mode(.salmonRun)),
    (.splatfest, .anarchySeries, .splatfest),
  ])
  func `Before any choice the sidebar opens on the row of the default Mode's tab`(
    _ tab: AppTab,
    _ anarchyMode: BattleMode,
    _ item: SidebarItem)
  {
    #expect(SidebarItem(tab, anarchyMode: anarchyMode) == item)
  }
}
