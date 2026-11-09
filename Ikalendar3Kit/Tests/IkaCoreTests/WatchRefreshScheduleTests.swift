//
//  WatchRefreshScheduleTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaFixtures
import Testing
@testable import IkaCore

/// Rotations change at even UTC hours, and splatoon3.ink serves the new Schedule within a minute.
struct WatchRefreshScheduleTests {
  @Test(arguments: [
    // A background run on time asks for the one after the next boundary.
    ("2026-10-20T14:05:00Z", "2026-10-20T16:05:00Z"),
    // A run the system started late keeps to the boundaries.
    ("2026-10-20T14:40:00Z", "2026-10-20T16:05:00Z"),
    // The gate stays closed for an hour after a refresh, so the next boundary is skipped when it
    // comes sooner: the run would only find the gate closed.
    ("2026-10-20T15:30:00Z", "2026-10-20T18:05:00Z"),
    ("2026-10-20T15:05:00Z", "2026-10-20T16:05:00Z"),
    ("2026-10-20T15:05:01Z", "2026-10-20T18:05:00Z"),
    // Across midnight UTC.
    ("2026-10-20T23:10:00Z", "2026-10-21T02:05:00Z"),
  ])
  func `The next run is five minutes past the first Rotation boundary an hour or more away`(
    _ instant: String,
    _ nextRun: String)
  {
    #expect(WatchRefreshSchedule.nextRun(after: date(instant)) == date(nextRun))
  }
}
