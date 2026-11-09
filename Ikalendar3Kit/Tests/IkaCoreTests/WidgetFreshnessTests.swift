//
//  WidgetFreshnessTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Testing
@testable import IkaCore

struct WidgetFreshnessTests {
  static let rotations = [
    TestData.rotation(hours: 0 ..< 2),
    TestData.rotation(hours: 2 ..< 4),
    TestData.rotation(hours: 4 ..< 6),
  ]

  @Test
  func `Every entry carries the fetch time, and an entry marks the data stale once it is three hours old`() throws {
    let fetchTime: Date = TestData.instant(hours: 0.5)
    let snapshot: Snapshot = .init(schedules: Fetched(
      content: TestData.feed(regularBattle: Self.rotations),
      fetchTime: fetchTime))

    let timeline = try #require(snapshot.battleWidgetTimeline(
      of: .regular,
      family: .small,
      from: TestData.instant(hours: 1)))

    #expect(timeline.entries.map(\.date) == [1, 2, 3.5, 4, 6].map { TestData.instant(hours: $0) })
    #expect(timeline.entries.map(\.isStale) == [false, false, true, true, true])
    #expect(timeline.entries.allSatisfy { $0.fetchTime == fetchTime })
    #expect(timeline.entries[2].content == timeline.entries[1].content)
  }

  @Test
  func `Data already three hours old is stale from the first entry, with no extra entry`() throws {
    let snapshot: Snapshot = .init(schedules: Fetched(
      content: TestData.feed(regularBattle: Self.rotations),
      fetchTime: TestData.instant(hours: -2)))

    let timeline = try #require(snapshot.battleWidgetTimeline(
      of: .regular,
      family: .small,
      from: TestData.instant(hours: 1)))

    #expect(timeline.entries.map(\.date) == [1, 2, 4, 6].map { TestData.instant(hours: $0) })
    #expect(timeline.entries.allSatisfy { $0.isStale })
  }

  @Test
  func `A timeline with nothing to come asks for a reload an hour later, never at once`() throws {
    let snapshot: Snapshot = .init(schedules: Fetched(
      content: TestData.feed(regularBattle: [], failedSections: [.rotations(.battle(.regular))]),
      fetchTime: TestData.instant(hours: -5)))

    let timeline = try #require(snapshot.battleWidgetTimeline(of: .regular, family: .small, from: TestData.epoch))

    #expect(timeline.entries.map(\.content.current) == [.nothingCurrent])
    #expect(timeline.reloadDate == TestData.instant(hours: 1))
  }

  @Test
  func `Every timeline is nil before the schedules feed's first good response`() {
    let snapshot: Snapshot = .init()

    #expect(snapshot.battleWidgetTimeline(of: .regular, family: .small, from: TestData.epoch) == nil)
    #expect(snapshot.extraLargeBattleWidgetTimeline(from: TestData.epoch) == nil)
    #expect(snapshot.salmonRunWidgetTimeline(from: TestData.epoch) == nil)
    #expect(Mode.allCases.allSatisfy { snapshot.watchWidgetTimeline(of: $0, from: TestData.epoch) == nil })
  }
}
