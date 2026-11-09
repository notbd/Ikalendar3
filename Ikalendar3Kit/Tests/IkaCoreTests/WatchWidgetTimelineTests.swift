//
//  WatchWidgetTimelineTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

// MARK: - WatchWidgetTimelineTests

struct WatchWidgetTimelineTests {
  @Test(arguments: Mode.allCases)
  func `Each watch entry holds the Mode's current and next item, one entry per boundary`(_ mode: Mode) async throws {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let feed = try #require(snapshot.schedules?.content)

    let timeline = try #require(snapshot.watchWidgetTimeline(of: mode, from: date("2026-10-20T13:17:00Z")))

    #expect(timeline.entries.allSatisfy { $0.content.mode == mode })
    switch mode {
      case .battle(let battleMode):
        let published = feed.rotations(for: .battle(battleMode))
        let entries = timeline.entries.compactMap(\.content.battle)
        #expect(timeline.entries.map(\.date) == [date("2026-10-20T13:17:00Z")]
          + everyTwoHours(from: "2026-10-20T14:00:00Z", count: 12))
        #expect(entries.map(\.current) == published.map(WidgetCurrent.item) + [.nothingCurrent])
        #expect(entries.map(\.upcoming) == published.dropFirst().map { [$0] } + [[], []])

      case .salmonRun:
        let entries = timeline.entries.compactMap(\.content.salmonRun)
        #expect(timeline.entries.map(\.date) == [date("2026-10-20T13:17:00Z")] + feed.salmonRun.map(\.endTime))
        #expect(entries.map(\.current) == feed.salmonRun.map(WidgetCurrent.item) + [.nothingCurrent])
        #expect(entries.map(\.upcoming) == feed.salmonRun.dropFirst().map { [$0] } + [[], []])
    }
  }

  @Test
  func `A watch complication set to a Battle Mode shows Splatfest Battle while it replaces the Battle Mode`()
    async throws
  {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)
    let pro = try #require(snapshot.schedules?.content.rotations(for: .splatfestBattle(.pro)))

    let timeline = try #require(snapshot.watchWidgetTimeline(of: .battle(.x), from: date("2026-11-01T05:23:00Z")))

    let first = try #require(timeline.entries.first?.content.battle)
    #expect(first.current == .item(pro[0]))
    #expect(first.upcoming == [pro[1]])
    #expect(first.shownMode == .splatfestBattle(.pro))
  }
}

extension WatchWidgetContent {
  /// The content of a Battle Mode's entry, `nil` for Salmon Run's.
  var battle: BattleWidgetContent? {
    if case .battle(let content) = self { content } else { nil }
  }

  /// The content of Salmon Run's entry, `nil` for a Battle Mode's.
  var salmonRun: SalmonRunWidgetContent? {
    if case .salmonRun(let content) = self { content } else { nil }
  }
}
