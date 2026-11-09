//
//  SalmonRunScreenTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

struct SalmonRunScreenTests {
  @Test
  func `A Big Run sits among the Shifts in time order`() async throws {
    let snapshot = try await Snapshot.schedules(.bigRun)
    let published = try #require(snapshot.schedules?.content.salmonRun)
    try #require(published.map(\.kind) == [.regular, .regular, .regular, .bigRun, .regular])

    let screen = try #require(snapshot.salmonRunScreen(at: date("2026-09-07T12:00:00Z")))

    // 4 of the first Shift's 40 hours have passed.
    #expect(screen.current == .running(.init(
      item: published[0],
      progress: .init(timeLeft: .seconds(36 * 3600), sharePassed: 0.1))))
    #expect(screen.next == published[1])
    #expect(screen.later == Array(published[2...]))
    #expect(screen.later.map(\.startTime) == ["2026-09-10T16:00:00Z", "2026-09-12T00:00:00Z", "2026-09-14T00:00:00Z"]
      .map(date))
    #expect(screen.eggstraWork == nil)
  }

  @Test
  func `A running Eggstra Work is on top, apart from the regular Shifts`() async throws {
    let snapshot = try await Snapshot.schedules(.eggstraWork)
    let feed = try #require(snapshot.schedules?.content)
    let eggstraWork = try #require(feed.eggstraWork.first)

    let screen = try #require(snapshot.salmonRunScreen(at: date("2026-08-29T12:00:00Z")))

    // 12 of its 48 hours have passed.
    #expect(screen.eggstraWork == .init(
      item: eggstraWork,
      progress: .init(timeLeft: .seconds(36 * 3600), sharePassed: 0.25)))
    #expect(screen.current == .running(.init(
      item: feed.salmonRun[0],
      progress: .init(timeLeft: .seconds(12 * 3600), sharePassed: 28.0 / 40))))
    #expect(screen.next == feed.salmonRun[1])
    #expect(screen.later == Array(feed.salmonRun[2...]))
    #expect(screen.next?.kind == .regular)
    #expect(screen.later.allSatisfy { $0.kind == .regular })
  }

  @Test(arguments: ["2026-08-28T23:59:59Z", "2026-08-31T00:00:00Z"])
  func `An Eggstra Work is not on top before it starts or after it ends`(_ instant: String) async throws {
    let snapshot = try await Snapshot.schedules(.eggstraWork)

    let screen = try #require(snapshot.salmonRunScreen(at: date(instant)))

    #expect(screen.eggstraWork == nil)
    #expect(screen.current != .nothingCurrent)
  }

  @Test
  func `Past the last published Shift the Salmon Run screen reports nothing current`() async throws {
    let snapshot = try await Snapshot.schedules(.bigRun)

    let screen = try #require(snapshot.salmonRunScreen(at: date("2026-09-15T16:00:00Z")))

    #expect(screen.current == .nothingCurrent)
    #expect(screen.next == nil)
    #expect(screen.later.isEmpty)
  }

  @Test
  func `The Salmon Run screen carries the fetch time of the schedules feed`() async throws {
    let fetchTime = date("2026-09-07T12:01:00Z")
    let snapshot = try await Snapshot.schedules(.bigRun, fetchedAt: fetchTime)

    #expect(snapshot.salmonRunScreen(at: date("2026-09-07T12:00:00Z"))?.fetchTime == fetchTime)
    #expect(Snapshot().salmonRunScreen(at: TestData.epoch) == nil)
  }
}
