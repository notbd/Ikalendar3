//
//  BattleWidgetTimelineTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

struct BattleWidgetTimelineTests {
  @Test(arguments: BattleWidgetFamily.allCases, BattleMode.allCases)
  func `Each battle family has an entry at every Rotation start for a day, with its current and later Rotations`(
    _ family: BattleWidgetFamily,
    _ mode: BattleMode)
    async throws
  {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let published = try #require(snapshot.schedules?.content.rotations(for: .battle(mode)))
    try #require(published.count == 12)

    let timeline = try #require(snapshot.battleWidgetTimeline(
      of: mode,
      family: family,
      from: date("2026-10-20T13:17:00Z")))

    let laterCount =
      switch family {
        case .small,
             .circular,
             .rectangular,
             .inline: 0
        case .medium: 1
        case .large: 4
      }
    let runningEntries = timeline.entries.dropFirst().dropLast()
    #expect(runningEntries.map(\.date) == everyTwoHours(from: "2026-10-20T14:00:00Z", count: 11))
    for (index, entry) in zip(1..., runningEntries) {
      #expect(entry.content.mode == mode)
      #expect(entry.content.current.item == published[index])
      #expect(entry.content.upcoming == Array(published.dropFirst(index + 1).prefix(laterCount)))
    }
    #expect(timeline.entries.first?.date == date("2026-10-20T13:17:00Z"))
    #expect(timeline.entries.first?.content.current.item == published[0])
  }

  @Test(arguments: BattleWidgetFamily.allCases)
  func `Past the last Rotation the entry shows nothing current, and the timeline reloads after it`(
    _ family: BattleWidgetFamily)
    async throws
  {
    let snapshot = try await Snapshot.schedules(.normalDay)

    let timeline = try #require(snapshot.battleWidgetTimeline(
      of: .regular,
      family: family,
      from: date("2026-10-20T13:17:00Z")))

    let last = try #require(timeline.entries.last)
    #expect(last.date == date("2026-10-21T12:00:00Z"))
    #expect(last.content.current == .nothingCurrent)
    #expect(last.content.upcoming.isEmpty)
    #expect(timeline.reloadDate == last.date)
  }

  @Test(arguments: [
    (BattleMode.regular, SplatfestBattleForm.open),
    (.anarchyOpen, .open),
    (.anarchySeries, .pro),
    (.x, .pro),
  ])
  func `A widget set to a Battle Mode shows Splatfest Battle in its form until the Battle Mode returns`(
    _ mode: BattleMode,
    _ form: SplatfestBattleForm)
    async throws
  {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)
    let feed = try #require(snapshot.schedules?.content)
    let splatfestBattle = feed.rotations(for: .splatfestBattle(form))
    let returned = feed.rotations(for: .battle(mode)).filter { !$0.isPaused }
    try #require(splatfestBattle.count == 10 && returned.count == 3)

    let timeline = try #require(snapshot.battleWidgetTimeline(
      of: mode,
      family: .large,
      from: date("2026-11-01T05:23:00Z")))

    #expect(timeline.entries.map(\.date) == [date("2026-11-01T05:23:00Z")]
      + everyTwoHours(from: "2026-11-01T06:00:00Z", count: 13))
    let first = try #require(timeline.entries.first?.content)
    #expect(first.mode == mode)
    #expect(first.current.item == splatfestBattle[0])
    #expect(first.upcoming == Array(splatfestBattle[1 ... 4]))
    let lastOfSplatfest = try #require(timeline.entries.first { $0.date == date("2026-11-01T22:00:00Z") }?.content)
    #expect(lastOfSplatfest.current.item == splatfestBattle[9])
    #expect(lastOfSplatfest.upcoming == returned)
    let afterwards = try #require(timeline.entries.first { $0.date == date("2026-11-02T00:00:00Z") }?.content)
    #expect(afterwards.current.item == returned[0])
  }

  @Test(arguments: [BattleWidgetFamily.circular, .rectangular, .inline])
  func `Each Lock Screen family shows the Battle Mode, the Rule and the end the time left runs to`(
    _ family: BattleWidgetFamily)
    async throws
  {
    let normalDay = try await Snapshot.schedules(.normalDay)
    let splatfest = try await Snapshot.schedules(.splatfestSecondHalf)

    let anarchy = try #require(normalDay.battleWidgetTimeline(
      of: .anarchySeries,
      family: family,
      from: date("2026-10-20T13:17:00Z"))?.entries
      .first?
      .content)
    let replaced = try #require(splatfest.battleWidgetTimeline(
      of: .x,
      family: family,
      from: date("2026-11-01T05:23:00Z"))?.entries
      .first?
      .content)

    #expect(anarchy.shownMode == .battle(.anarchySeries))
    #expect(anarchy.current.item?.setting?.rule == RuleID("VnNSdWxlLTM="))
    #expect(anarchy.current.item?.endTime == date("2026-10-20T14:00:00Z"))
    #expect(anarchy.upcoming.isEmpty)
    #expect(replaced.shownMode == .splatfestBattle(.pro))
    #expect(replaced.current.item?.setting?.rule == RuleID("VnNSdWxlLTA="))
    #expect(replaced.current.item?.endTime == date("2026-11-01T06:00:00Z"))
  }

  @Test
  func `A widget built before a Splatfest switches to Splatfest Battle on its own at the start`() async throws {
    let snapshot = try await Snapshot.schedules(.splatfestAnnounced)
    let feed = try #require(snapshot.schedules?.content)
    let open = feed.rotations(for: .splatfestBattle(.open))

    let timeline = try #require(snapshot.battleWidgetTimeline(
      of: .regular,
      family: .medium,
      from: date("2026-10-30T22:30:00Z")))

    let beforeStart = try #require(timeline.entries.first?.content)
    #expect(beforeStart.current.item?.mode == .battle(.regular))
    #expect(beforeStart.upcoming == [open[0]])
    let atStart = try #require(timeline.entries.first { $0.date == date("2026-10-31T00:00:00Z") }?.content)
    #expect(atStart.current.item == open[0])
  }

  @Test
  func `Without Splatfest Battle's Rotations, the widget shows the Battle Mode paused until it returns`() throws {
    let windows = [
      TestData.rotation(hours: 0 ..< 2),
      TestData.rotation(hours: 2 ..< 4, isPaused: true),
      TestData.rotation(hours: 4 ..< 6, isPaused: true),
      TestData.rotation(hours: 6 ..< 8),
    ]
    let snapshot: Snapshot = .init(schedules: Fetched(
      content: TestData.feed(regularBattle: windows, failedSections: [.splatfest]),
      fetchTime: TestData.instant(hours: -3)))

    let timeline = try #require(snapshot.battleWidgetTimeline(of: .regular, family: .medium, from: TestData.epoch))

    #expect(timeline.entries.map(\.date) == [0, 2, 6, 8].map { TestData.instant(hours: $0) })
    #expect(timeline.entries.map(\.content.current) == [
      .item(windows[0]),
      .paused(returnTime: TestData.instant(hours: 6)),
      .item(windows[3]),
      .nothingCurrent,
    ])
    #expect(timeline.entries[1].content.upcoming == [windows[3]])
  }

  @Test
  func `The extra large widget shows each Battle Mode's current Rotation at every Rotation start`()
    async throws
  {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let feed = try #require(snapshot.schedules?.content)

    let timeline = try #require(snapshot.extraLargeBattleWidgetTimeline(from: date("2026-10-20T13:17:00Z")))

    #expect(timeline.entries.map(\.date) == [date("2026-10-20T13:17:00Z")]
      + everyTwoHours(from: "2026-10-20T14:00:00Z", count: 12))
    for (index, entry) in timeline.entries.dropLast().enumerated() {
      #expect(entry.content.map(\.mode) == [.regular, .anarchySeries, .anarchyOpen, .x])
      for row in entry.content {
        #expect(row.current.item == feed.rotations(for: .battle(row.mode))[index])
        #expect(row.upcoming.isEmpty)
      }
    }
    #expect(timeline.entries.last?.content.map(\.current) == Array(repeating: .nothingCurrent, count: 4))
  }

  @Test
  func `During a Splatfest the extra large widget shows each Battle Mode paused, as its summary does`()
    async throws
  {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)

    let timeline = try #require(snapshot.extraLargeBattleWidgetTimeline(from: date("2026-11-01T05:23:00Z")))

    let first = try #require(timeline.entries.first)
    #expect(first.content.map(\.current) == Array(
      repeating: .paused(returnTime: date("2026-11-02T00:00:00Z")),
      count: 4))
    #expect(first.content.allSatisfy { $0.shownMode == .battle($0.mode) })
    for row in first.content {
      #expect(snapshot.summary(of: .battle(row.mode), at: first.date) == .battle(
        row.mode,
        .paused(returnTime: date("2026-11-02T00:00:00Z"))))
    }
    #expect(timeline.entries.map(\.date) == [date("2026-11-01T05:23:00Z")]
      + everyTwoHours(from: "2026-11-02T00:00:00Z", count: 4))
  }
}
