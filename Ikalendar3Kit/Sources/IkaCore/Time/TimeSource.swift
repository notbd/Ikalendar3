//
//  TimeSource.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - TimeSource

/// Where the app clock reads the time and waits for the next second: the system's wall clock in
/// the app, a fake one in tests.
public protocol TimeSource: Sendable {
  /// The current instant.
  var now: Date { get }

  /// Returns at `deadline` or a little after by the clock that measures the wait, or throws
  /// `CancellationError` once the calling task is cancelled.
  ///
  /// It may also return before `deadline` as `now` reads it: when the wall clock is set during
  /// the wait, or a fake clock's `now` is set. So the caller rereads `now` when it returns and
  /// never assumes the deadline has passed.
  func sleep(until deadline: Date) async throws
}

// MARK: - SystemTimeSource

/// The system's wall clock. A sleep may end up to 0.1 s late, so the system can coalesce wakes.
public struct SystemTimeSource: TimeSource {
  /// The system's wall clock.
  public init() { }

  /// The current instant.
  public var now: Date { Date() }

  /// Waits the time from now to `deadline`, plus up to 0.1 s. It measures a duration, so a wall
  /// clock set back during the wait ends it before `deadline` as `now` then reads it.
  public func sleep(until deadline: Date) async throws {
    try await Task.sleep(for: .seconds(deadline.timeIntervalSinceNow), tolerance: .milliseconds(100))
  }
}
