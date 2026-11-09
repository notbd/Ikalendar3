//
//  SplatfestPhaseTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Testing
@testable import IkaCore

struct SplatfestPhaseTests {
  /// A Splatfest fixture at the hour it was recorded, and the phase there.
  struct RecordedCase: CustomTestStringConvertible {
    let fixture: Fixture
    let instant: String
    let phase: Splatfest.Phase

    var testDescription: String { fixture.rawValue }
  }

  @Test(arguments: [
    RecordedCase(fixture: .splatfestAnnounced, instant: "2026-10-30T12:00:00Z", phase: .announced),
    RecordedCase(fixture: .splatfestFirstHalf, instant: "2026-10-31T12:00:00Z", phase: .firstHalf),
    RecordedCase(fixture: .splatfestSecondHalf, instant: "2026-11-01T05:23:00Z", phase: .secondHalf),
    RecordedCase(fixture: .splatfestEnd, instant: "2026-08-23T20:00:00Z", phase: .secondHalf),
  ])
  func `Each Splatfest fixture is in the phase it was recorded in`(_ recorded: RecordedCase) async throws {
    let splatfest = try await #require(Self.splatfest(of: recorded.fixture))

    #expect(splatfest.phase(at: date(recorded.instant)) == recorded.phase)
  }

  @Test(arguments: [
    ("2026-10-30T23:59:59Z", Splatfest.Phase.announced),
    ("2026-10-31T00:00:00Z", .firstHalf),
    ("2026-10-31T23:59:59Z", .firstHalf),
    ("2026-11-01T00:00:00Z", .secondHalf),
    ("2026-11-01T23:59:59Z", .secondHalf),
    ("2026-11-02T00:00:00Z", .over),
    ("2026-11-09T00:00:00Z", .over),
  ])
  func `The phase changes on the start, midterm and end times with no fetch`(
    _ instant: String,
    _ phase: Splatfest.Phase)
    async throws
  {
    // Recorded before the Splatfest started.
    let splatfest = try await #require(Self.splatfest(of: .splatfestAnnounced))

    #expect(splatfest.phase(at: date(instant)) == phase)
  }

  /// The Splatfest a schedules fixture names.
  static func splatfest(of fixture: Fixture) async throws -> Splatfest? {
    try await Snapshot(schedules: .init(content: ScheduleFeed.decode(from: fixture.data()), fetchTime: .distantPast))
      .splatfest
  }
}
