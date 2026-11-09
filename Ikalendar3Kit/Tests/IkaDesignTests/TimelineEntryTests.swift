//
//  TimelineEntryTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import IkaFixtures
import Testing
@testable import IkaDesign

// MARK: - TimelineEntryTests

/// Pins what Timeline's axis holds, top to bottom, on the recorded feeds: the current Rotation or
/// Shift with its progress, or why none is on, then every one still to come.
struct TimelineEntryTests {
  // MARK: Battle Mode

  @Test
  func `A Battle Mode's axis holds the current Rotation with its progress, then every later one`() async throws {
    let snapshot = try await snapshot(.normalDay)
    let screen = try #require(snapshot.battleScreen(of: .regular, at: date("2026-10-20T13:10:00Z")))
    let next = try #require(screen.next)

    let entries: [TimelineEntry<Rotation>] = TimelineEntry.entries(of: screen)

    #expect(entries.first?.item?.startTime == date("2026-10-20T12:00:00Z"))
    #expect(entries.first?.progress?.sharePassed == 70.0 / 120)
    #expect(entries.dropFirst().first == .item(next, progress: nil))
    #expect(entries.count == 2 + screen.later.count)
    #expect(entries.dropFirst().allSatisfy { $0.progress == nil })
  }

  @Test
  func `The next Rotation keeps its slot when it becomes current`() async throws {
    let snapshot = try await snapshot(.normalDay)
    let before = try #require(snapshot.battleScreen(of: .regular, at: date("2026-10-20T13:59:59Z")))
    let after = try #require(snapshot.battleScreen(of: .regular, at: date("2026-10-20T14:00:00Z")))

    let next = try #require(TimelineEntry.entries(of: before).dropFirst().first)
    let current = try #require(TimelineEntry.entries(of: after).first)

    #expect(next.id == current.id)
    #expect(next.progress == nil)
    #expect(current.progress?.sharePassed == 0)
  }

  @Test
  func `A paused Battle Mode shows its return at the top of the axis`() async throws {
    let snapshot = try await snapshot(.splatfestSecondHalf)
    let screen = try #require(snapshot.battleScreen(of: .x, at: date("2026-11-01T06:00:00Z")))
    guard case .paused(let returnTime) = screen.current else {
      Issue.record("X Battle is not paused during the Splatfest")
      return
    }

    #expect(TimelineEntry.entries(of: screen).first == .paused(returnTime: returnTime))
  }

  @Test
  func `A Battle Mode past its Schedule shows nothing current`() async throws {
    let snapshot = try await snapshot(.normalDay)
    let screen = try #require(snapshot.battleScreen(of: .regular, at: date("2026-10-30T00:00:00Z")))

    #expect(TimelineEntry.entries(of: screen) == [.nothingCurrent])
  }

  // MARK: Salmon Run

  @Test
  func `A running Eggstra Work sits on top of the current Shift`() async throws {
    let snapshot = try await snapshot(.eggstraWork)
    let screen = try #require(snapshot.salmonRunScreen(at: date("2026-08-29T12:00:00Z")))
    let eggstraWork = try #require(screen.eggstraWork)
    guard case .running(let current) = screen.current else {
      Issue.record("No Shift runs beside the Eggstra Work")
      return
    }

    let entries: [TimelineEntry<Shift>] = TimelineEntry.entries(of: screen)

    #expect(entries.prefix(2) == [
      .item(eggstraWork.item, progress: eggstraWork.progress),
      .item(current.item, progress: current.progress),
    ])
    #expect(entries.count == 2 + 1 + screen.later.count)
  }

  @Test
  func `An announced Eggstra Work waits on top of the current Shift`() async throws {
    let snapshot = try await snapshot(.eggstraWork)
    let screen = try #require(snapshot.salmonRunScreen(at: date("2026-08-28T12:00:00Z")))
    let nextEggstraWork = try #require(screen.nextEggstraWork)
    guard case .running(let current) = screen.current else {
      Issue.record("No Shift runs before the Eggstra Work")
      return
    }

    let entries: [TimelineEntry<Shift>] = TimelineEntry.entries(of: screen)

    #expect(entries.prefix(2) == [
      .item(nextEggstraWork, progress: nil),
      .item(current.item, progress: current.progress),
    ])
  }

  @Test
  func `A Big Run sits inline where it falls`() async throws {
    let snapshot = try await snapshot(.bigRun)
    let screen = try #require(snapshot.salmonRunScreen(at: date("2026-09-07T12:00:00Z")))

    let kinds = TimelineEntry.entries(of: screen).compactMap(\.item?.kind)

    #expect(kinds == [.regular, .regular, .regular, .bigRun, .regular])
  }

  @Test
  func `Before its first Shift, Salmon Run shows nothing current above the Shifts to come`() async throws {
    let snapshot = try await snapshot(.normalDay)
    let first = try #require(snapshot.schedules?.content.salmonRun.first)
    let screen = try #require(snapshot.salmonRunScreen(at: first.startTime.addingTimeInterval(-3600)))

    let entries: [TimelineEntry<Shift>] = TimelineEntry.entries(of: screen)

    #expect(entries.prefix(2) == [.nothingCurrent, .item(first, progress: nil)])
  }

  // MARK: Helpers

  private func snapshot(_ fixture: Fixture) async throws -> Snapshot {
    try await Snapshot(schedules: Fetched(content: ScheduleFeed.decode(from: fixture.data()), fetchTime: .distantPast))
  }

  private func date(_ text: String) -> Date {
    // A test literal: a malformed one should stop the test at once.
    // swiftlint:disable:next force_try
    try! Date(text, strategy: .iso8601)
  }
}
