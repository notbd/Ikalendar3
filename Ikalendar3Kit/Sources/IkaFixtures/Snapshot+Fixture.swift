//
//  Snapshot+Fixture.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if DEBUG
import Foundation
import IkaCore

extension Snapshot {
  /// A snapshot of a recorded schedules feed and the recorded `festivals.json`, every time moved
  /// so the recording's `recordedAt` falls on `shownAt`, and fetched then. Previews of Surfaces
  /// the system draws on its own clock, such as widgets, show a recorded day with it.
  static public func fixture(
    _ schedules: Fixture,
    recordedAt instant: Date,
    shownAt now: Date) async throws
    -> Snapshot
  {
    let offset: Duration = .seconds(now.timeIntervalSince(instant).rounded(.towardZero))
    func fetched<Content>(_ fixture: Fixture, decode: (Data) async throws -> Content) async throws -> Fetched<Content> {
      try await Fetched(content: decode(Fixture.rebase(fixture.data(), by: offset)), fetchTime: now)
    }

    return try await Snapshot(
      schedules: fetched(schedules, decode: ScheduleFeed.decode),
      festivals: fetched(.festivals, decode: FestivalFeed.decode))
  }

  /// Widget and complication previews: a loader of a recorded day, moved so that a moment of it
  /// is now: the normal day mid-Rotation, the Splatfest in its second half, or the Big Run with
  /// its random weapons. An empty snapshot if the recording cannot be read.
  static public func preview(_ schedules: Fixture) -> @Sendable () async -> Snapshot {
    let recordedAt =
      switch schedules {
        case .splatfestSecondHalf: "2026-11-01T05:30:00Z"
        case .bigRun: "2026-09-12T06:00:00Z"
        default: "2026-10-20T13:15:00Z"
      }
    return {
      guard let instant = try? Date(recordedAt, strategy: .iso8601) else { return Snapshot() }

      return await (try? fixture(schedules, recordedAt: instant, shownAt: .now)) ?? Snapshot()
    }
  }
}
#endif
