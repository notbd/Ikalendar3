//
//  FixtureSnapshot.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
@testable import IkaCore

extension Snapshot {
  /// A snapshot holding only a recorded schedules feed, fetched at `fetchTime`.
  static func schedules(_ fixture: Fixture, fetchedAt fetchTime: Date = TestData.epoch) async throws -> Snapshot {
    try await Snapshot(schedules: Fetched(content: ScheduleFeed.decode(from: fixture.data()), fetchTime: fetchTime))
  }

  /// A snapshot holding only `feed`, fetched at the test epoch.
  static func schedules(_ feed: ScheduleFeed) -> Snapshot {
    Snapshot(schedules: Fetched(content: feed, fetchTime: TestData.epoch))
  }
}
