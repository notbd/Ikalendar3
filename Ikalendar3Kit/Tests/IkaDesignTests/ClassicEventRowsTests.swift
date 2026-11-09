//
//  ClassicEventRowsTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import IkaFixtures
import Testing
@testable import IkaDesign

// MARK: - ClassicEventRowsTests

/// Pins what Classic's Challenge and Splatfest lists show on the recorded feeds: which Challenge
/// window is tagged, and the Splatfest Battle Rotations in ikalendar 2's order with the Regular
/// Battle Rotations after the end.
struct ClassicEventRowsTests {
  // MARK: Challenge

  @Test
  func `A running Challenge window is tagged now and the window after it next`() async throws {
    let snapshot = try await snapshot(.normalDay)
    let screen = try #require(snapshot.challengeScreen(at: date("2026-10-23T02:30:00Z")))

    #expect(screen.challenges.map { $0.windows.map(\.mark.classicTag) } == [
      [.now, .next, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil],
    ])
  }

  @Test
  func `Between Challenge windows only the next one is tagged`() async throws {
    let snapshot = try await snapshot(.normalDay)
    let screen = try #require(snapshot.challengeScreen(at: date("2026-10-23T04:30:00Z")))

    #expect(screen.challenges.first?.windows.map(\.mark.classicTag) == [nil, .next, nil, nil, nil, nil])
  }

  // MARK: Splatfest

  @Test
  func `A Splatfest list features the current Rotation, then tags the next one`() async throws {
    let snapshot = try await snapshot(.splatfestSecondHalf)
    let screen = try #require(snapshot.splatfestScreen(of: .open, at: date("2026-11-01T05:23:00Z")))
    guard case .running(let running) = screen.current else {
      Issue.record("No Splatfest Battle Rotation runs in the second half")
      return
    }

    let rows: [ClassicBattleRow] = ClassicBattleRow.rows(of: screen)

    #expect(rows.first == .current(running))
    #expect(try rows.dropFirst().first == .upcoming(#require(screen.next), isNext: true))
    #expect(rows.map(\.tag) == [.now, .next] + Array(repeating: nil, count: screen.later.count))
  }

  @Test
  func `Before the Splatfest starts, its list shows nothing current and the first Rotation next`() async throws {
    let snapshot = try await snapshot(.splatfestAnnounced)
    let screen = try #require(snapshot.splatfestScreen(of: .pro, at: date("2026-10-30T12:00:00Z")))

    let rows: [ClassicBattleRow] = ClassicBattleRow.rows(of: screen)

    #expect(rows.first == .nothingCurrent)
    #expect(try rows.dropFirst().first == .upcoming(#require(screen.next), isNext: true))
  }

  @Test
  func `Regular Battle's Rotations after the end follow untagged, each row keeping its own identity`() async throws {
    let snapshot = try await snapshot(.splatfestEnd)
    let screen = try #require(snapshot.splatfestScreen(of: .open, at: date("2026-08-23T20:00:00Z")))

    let rows: [ClassicBattleRow] = ClassicBattleRow.rows(of: screen)
    let afterwards: [ClassicBattleRow] = ClassicBattleRow.afterwardsRows(of: screen)

    #expect(afterwards == screen.afterwards.map { .upcoming($0, isNext: false) })
    #expect(afterwards.count == 10)
    #expect(Set((rows + afterwards).map(\.id)).count == rows.count + afterwards.count)
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
