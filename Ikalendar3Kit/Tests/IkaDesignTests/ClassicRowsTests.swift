//
//  ClassicRowsTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import IkaFixtures
import Testing
@testable import IkaDesign

// MARK: - ClassicRowsTests

/// Pins what Classic's lists show, in ikalendar 2's order and with its tags, on the recorded
/// feeds: the featured current Rotation or Shift, why none is on, and the ones still to come.
struct ClassicRowsTests {
  // MARK: Battle Mode

  @Test
  func `A Battle Mode list features the current Rotation, then tags the next one`() async throws {
    let snapshot = try await snapshot(.normalDay)
    let screen = try #require(snapshot.battleScreen(of: .regular, at: date("2026-10-20T13:00:00Z")))
    let running = try #require(screen.current.running)

    let rows: [ClassicBattleRow] = ClassicBattleRow.rows(of: screen)

    #expect(rows.first == .current(running))
    #expect(try rows.dropFirst().first == .upcoming(#require(screen.next), isNext: true))
    #expect(rows.dropFirst(2) == ArraySlice(screen.later.map { .upcoming($0, isNext: false) }))
    #expect(rows.map(\.tag) == [.now, .next] + Array(repeating: nil, count: screen.later.count))
  }

  @Test
  func `A Rotation keeps its row when it becomes current`() async throws {
    let snapshot = try await snapshot(.normalDay)
    let before = try #require(snapshot.battleScreen(of: .regular, at: date("2026-10-20T13:59:59Z")))
    let after = try #require(snapshot.battleScreen(of: .regular, at: date("2026-10-20T14:00:00Z")))

    let nextRow = try #require(ClassicBattleRow.rows(of: before).dropFirst().first)
    let currentRow = try #require(ClassicBattleRow.rows(of: after).first)

    #expect(nextRow.id == currentRow.id)
    #expect(currentRow.tag == .now)
  }

  @Test
  func `A paused Battle Mode shows its return in the featured place`() async throws {
    let snapshot = try await snapshot(.splatfestSecondHalf)
    let screen = try #require(snapshot.battleScreen(of: .x, at: date("2026-11-01T06:00:00Z")))
    guard case .paused(let returnTime) = screen.current else {
      Issue.record("X Battle is not paused during the Splatfest")
      return
    }

    let rows: [ClassicBattleRow] = ClassicBattleRow.rows(of: screen)

    #expect(rows.first == .paused(returnTime: returnTime))
    #expect(rows.first?.tag == .now)
  }

  @Test
  func `A Battle Mode past its Schedule shows nothing current`() async throws {
    let snapshot = try await snapshot(.normalDay)
    let screen = try #require(snapshot.battleScreen(of: .regular, at: date("2026-10-30T00:00:00Z")))

    #expect(ClassicBattleRow.rows(of: screen) == [.nothingCurrent])
  }

  // MARK: Salmon Run

  @Test
  func `A running Shift is open and the next one is tagged`() async throws {
    let snapshot = try await snapshot(.normalDay)
    let screen = try #require(snapshot.salmonRunScreen(at: date("2026-10-20T13:00:00Z")))
    let running = try #require(screen.current.running)
    let next = try #require(screen.next)

    let rows: [ClassicSalmonRunRow] = ClassicSalmonRunRow.rows(of: screen)

    #expect(rows.first == .shift(running.item, progress: running.progress, tag: .open))
    #expect(rows.dropFirst().first == .shift(next, progress: nil, tag: .next))
    #expect(rows.dropFirst(2).allSatisfy { $0.tag == nil })
    #expect(rows.count == 2 + screen.later.count)
  }

  @Test
  func `A running Eggstra Work is open on top of the Shifts`() async throws {
    let snapshot = try await snapshot(.eggstraWork)
    let screen = try #require(snapshot.salmonRunScreen(at: date("2026-08-29T12:00:00Z")))
    let eggstraWork = try #require(screen.eggstraWork)

    let rows: [ClassicSalmonRunRow] = ClassicSalmonRunRow.rows(of: screen)

    #expect(rows.first == .shift(eggstraWork.item, progress: eggstraWork.progress, tag: .open))
    #expect(rows.dropFirst().first?.tag == .open)
  }

  @Test
  func `A Big Run sits inline where it falls`() async throws {
    let snapshot = try await snapshot(.bigRun)
    let screen = try #require(snapshot.salmonRunScreen(at: date("2026-09-07T12:00:00Z")))

    let kinds = ClassicSalmonRunRow.rows(of: screen).compactMap(\.shift?.kind)

    #expect(kinds == [.regular, .regular, .regular, .bigRun, .regular])
  }

  @Test
  func `With no Shift open, the first one to come opens soon`() async throws {
    let snapshot = try await snapshot(.normalDay)
    let first = try #require(snapshot.schedules?.content.salmonRun.first)
    let screen = try #require(snapshot.salmonRunScreen(at: first.startTime.addingTimeInterval(-3600)))

    let rows: [ClassicSalmonRunRow] = ClassicSalmonRunRow.rows(of: screen)

    #expect(rows.first == .shift(first, progress: nil, tag: .soon))
    #expect(rows.dropFirst().first?.tag == .next)
  }

  @Test
  func `Salmon Run past its Schedule shows nothing current`() async throws {
    let snapshot = try await snapshot(.normalDay)
    let screen = try #require(snapshot.salmonRunScreen(at: date("2026-12-01T00:00:00Z")))

    #expect(ClassicSalmonRunRow.rows(of: screen) == [.nothingCurrent])
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

extension OnNow {
  /// The running item, if any.
  fileprivate var running: Running<Item>? {
    if case .running(let running) = self { running } else { nil }
  }
}
