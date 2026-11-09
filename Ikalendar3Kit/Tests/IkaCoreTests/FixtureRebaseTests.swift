//
//  FixtureRebaseTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import IkaFixtures
import Testing

// MARK: - FixtureRebaseTests

/// Rebasing moves a payload's times, so the Surfaces the system renders on its own clock see the
/// fixture day.
struct FixtureRebaseTests {
  @Test
  func `Rebasing moves each time by the offset, across a day, and leaves other text alone`() {
    let payload: Data = .init(#"{"startTime":"2026-10-31T23:00:00Z","id":"2026-10-31T23","n":[1, 2]}"#.utf8)

    let rebased: Data = Fixture.rebase(payload, by: .seconds(90 * 60))

    #expect(String(bytes: rebased, encoding: .utf8) ==
      #"{"startTime":"2026-11-01T00:30:00Z","id":"2026-10-31T23","n":[1, 2]}"#)
  }

  @Test
  func `Rebasing by a negative offset moves times back`() {
    let payload: Data = .init(#"["2026-03-01T00:00:00Z", "2026-03-01T00:00:00.250Z"]"#.utf8)

    let rebased: Data = Fixture.rebase(payload, by: .seconds(-24 * 3600))

    #expect(String(bytes: rebased, encoding: .utf8) == #"["2026-02-28T00:00:00Z", "2026-02-28T00:00:00.250Z"]"#)
  }

  /// An offset with days, hours, minutes and seconds in it: 23 d 5 h 17 min 3 s.
  static private let offset: Duration = .seconds(2_006_223)

  @Test(arguments: Fixture.allCases)
  func `Rebasing a fixture moves every time by the offset and changes nothing else`(fixture: Fixture) throws {
    let payload = try fixture.data()

    let rebased: Data = Fixture.rebase(payload, by: Self.offset)

    let times = try Self.times(in: payload)
    #expect(try Self.times(in: rebased) == times.map { $0.addingTimeInterval(Self.offset / .seconds(1)) })
    #expect(try Self.blankingTimes(in: rebased) == Self.blankingTimes(in: payload))
    #expect(times.isEmpty == fixture.rawValue.hasPrefix("locale-"), "only locale files carry no time")
  }

  @Test
  func `A rebased schedules feed commits through the cache with its Rotations moved`() async throws {
    let directory = try makeTestDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let cache: FeedCache = .init(directory: directory)
    let recordedInstant = date("2026-10-20T13:15:00Z")
    let recorded = try await Snapshot.schedules(.normalDay).battleScreen(of: .anarchySeries, at: recordedInstant)

    let body = try Fixture.rebase(Fixture.normalDay.data(), by: Self.offset)
    try cache.commit(FeedRecord(body: body, etag: nil, fetchTime: recordedInstant), for: .schedules)

    let movedInstant = recordedInstant.addingTimeInterval(Self.offset / .seconds(1))
    let moved = await cache.snapshot().battleScreen(of: .anarchySeries, at: movedInstant)
    guard case .running(let recordedNow) = recorded?.current, case .running(let movedNow) = moved?.current else {
      Issue.record("no current Rotation in the recorded or the rebased schedules")
      return
    }

    #expect(movedNow.item.setting == recordedNow.item.setting)
    #expect(movedNow.item.startTime == recordedNow.item.startTime.addingTimeInterval(Self.offset / .seconds(1)))
    #expect(movedNow.progress == recordedNow.progress)
    #expect(moved?.later.count == recorded?.later.count)
  }

  // MARK: Reading times

  /// A JSON string that is a UTC instant, as the recorded payloads write it.
  static private let timeLiteral = #""\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z""#

  /// Every time in a payload, in order.
  static private func times(in payload: Data) throws -> [Date] {
    let text = try #require(String(bytes: payload, encoding: .utf8))
    return try text.ranges(of: Regex(timeLiteral)).map { range in
      try Date(String(text[range].dropFirst().dropLast()), strategy: .iso8601)
    }
  }

  /// A payload with every time replaced by the same placeholder.
  static private func blankingTimes(in payload: Data) throws -> String {
    try #require(String(bytes: payload, encoding: .utf8)).replacing(Regex(timeLiteral), with: "TIME")
  }
}
