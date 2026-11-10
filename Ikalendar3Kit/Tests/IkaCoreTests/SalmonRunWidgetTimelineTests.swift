//
//  SalmonRunWidgetTimelineTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

struct SalmonRunWidgetTimelineTests {
  @Test
  func `The Salmon Run widget switches at real Shift boundaries and shows nothing current past the last`()
    async throws
  {
    let snapshot = try await Snapshot.schedules(.normalDay)
    let shifts = try #require(snapshot.schedules?.content.salmonRun)

    let timeline = try #require(snapshot.salmonRunWidgetTimeline(from: date("2026-10-20T13:17:00Z")))

    #expect(timeline.entries.map(\.date) == [
      "2026-10-20T13:17:00Z",
      "2026-10-20T16:00:00Z",
      "2026-10-22T08:00:00Z",
      "2026-10-24T00:00:00Z",
      "2026-10-25T16:00:00Z",
      "2026-10-27T08:00:00Z",
    ].map(date))
    #expect(timeline.entries.map(\.content.current) == shifts.map(WidgetCurrent.item) + [.nothingCurrent])
    #expect(timeline.entries.allSatisfy { $0.content.upcoming.isEmpty })
    #expect(timeline.reloadDate == date("2026-10-27T08:00:00Z"))
  }

  @Test
  func `While an Eggstra Work runs, the Salmon Run widget shows the regular Shifts with their King Salmonid`()
    async throws
  {
    let snapshot = try await Snapshot.schedules(.eggstraWork)
    let shifts = try #require(snapshot.schedules?.content.salmonRun)

    let timeline = try #require(snapshot.salmonRunWidgetTimeline(from: date("2026-08-28T12:00:00Z")))

    #expect(timeline.entries.map(\.date) == [
      "2026-08-28T12:00:00Z",
      "2026-08-30T00:00:00Z",
      "2026-08-31T16:00:00Z",
      "2026-09-02T08:00:00Z",
      "2026-09-04T00:00:00Z",
    ].map(date))
    let duringEggstraWork = try #require(timeline.entries.first?.content.current.item)
    #expect(duringEggstraWork == shifts[0])
    #expect(duringEggstraWork.kind == .regular)
    #expect(duringEggstraWork.kingSalmonid != nil)
  }

  @Test
  func `A Big Run takes the Salmon Run widget at its start`() async throws {
    let snapshot = try await Snapshot.schedules(.bigRun)

    let timeline = try #require(snapshot.salmonRunWidgetTimeline(from: date("2026-09-09T12:00:00Z")))

    let atStart = try #require(timeline.entries.first { $0.date == date("2026-09-12T00:00:00Z") })
    #expect(atStart.content.current.item?.kind == .bigRun)
    #expect(atStart.content.current.item?.endTime == date("2026-09-14T00:00:00Z"))
  }

  @Test
  func `A Splatfest leaves the Salmon Run widget's entries unaffected`() async throws {
    let snapshot = try await Snapshot.schedules(.splatfestSecondHalf)
    let shifts = try #require(snapshot.schedules?.content.salmonRun)

    let timeline = try #require(snapshot.salmonRunWidgetTimeline(from: date("2026-11-01T05:23:00Z")))

    #expect(timeline.entries.map(\.date) == [date("2026-11-01T05:23:00Z")] + shifts.map(\.endTime))
    #expect(timeline.entries.map(\.content.current) == shifts.map(WidgetCurrent.item) + [.nothingCurrent])
  }
}
