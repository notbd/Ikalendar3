//
//  Snapshot+Fixture.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

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
}
