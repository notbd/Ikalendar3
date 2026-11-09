//
//  RunningClock.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if DEBUG
import Foundation
import IkaCore

// MARK: - RunningClock

/// A clock that starts at a given instant and runs at real speed from it, so a fixture launch
/// can start seconds before a boundary and cross it while the screen is watched. It counts on
/// the continuous clock, so a change of the system time does not move it.
public struct RunningClock: TimeSource {
  /// The instant the clock showed when it started.
  private let start: Date
  /// When it started.
  private let started: ContinuousClock.Instant

  /// A clock showing `start` now.
  public init(startingAt start: Date) {
    self.start = start
    started = .now
  }

  public var now: Date {
    start.addingTimeInterval((ContinuousClock.now - started) / .seconds(1))
  }

  /// Returns at `deadline` or up to 0.1 s after it, as the system's clock does.
  public func sleep(until deadline: Date) async throws {
    try await Task.sleep(
      until: started.advanced(by: .seconds(deadline.timeIntervalSince(start))),
      tolerance: .milliseconds(100),
      clock: .continuous)
  }
}
#endif
