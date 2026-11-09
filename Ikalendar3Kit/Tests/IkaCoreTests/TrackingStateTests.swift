//
//  TrackingStateTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

// MARK: - TrackingStateTests

/// The Live Activity's content state as the cache gives it: what Tracking carries and when its
/// schedules feed was fetched.
struct TrackingStateTests {
  @Test
  func `The state carries the Mode's Tracking content and the schedules feed's fetch time`() async throws {
    let fetchTime = date("2026-10-20T12:05:00Z")
    let snapshot: Snapshot = try await .schedules(.normalDay, fetchedAt: fetchTime)
    let instant = date("2026-10-20T13:15:00Z")

    let state = try #require(snapshot.trackingState(of: .battle(.x), at: instant))

    let feed = try #require(snapshot.schedules?.content)
    #expect(state.content == feed.trackingContent(of: .battle(.x), at: instant))
    #expect(state.fetchTime == fetchTime)
    #expect(state.staleDate == date("2026-10-20T14:00:00Z"))
  }

  @Test
  func `There is no state before the schedules feed's first good response`() {
    #expect(Snapshot().trackingState(of: .salmonRun, at: date("2026-10-20T13:15:00Z")) == nil)
  }

  /// ActivityKit refuses a content state over 4 KB; the attributes, a Mode and a time, add a few
  /// bytes more.
  @Test(arguments: [
    (Fixture.normalDay, "2026-10-20T12:00:00Z"),
    (.splatfestSecondHalf, "2026-11-01T05:23:00Z"),
    (.bigRun, "2026-09-09T12:00:00Z"),
  ])
  func `Every Mode's state encodes under ActivityKit's 4 KB and decodes back unchanged`(
    _ fixture: Fixture,
    _ instant: String)
    async throws
  {
    let snapshot: Snapshot = try await .schedules(fixture)

    for mode in Mode.allCases {
      let state = try #require(snapshot.trackingState(of: mode, at: date(instant)))
      let encoded = try JSONEncoder().encode(state)
      #expect(encoded.count < 4096, "\(mode): \(encoded.count) bytes")
      #expect(try JSONDecoder().decode(TrackingState.self, from: encoded) == state)
    }
  }
}
