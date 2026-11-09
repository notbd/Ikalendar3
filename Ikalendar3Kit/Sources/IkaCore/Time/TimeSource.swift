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

  /// Returns at `deadline` or a little after, or throws `CancellationError` once the calling
  /// task is cancelled.
  func sleep(until deadline: Date) async throws
}

// MARK: - SystemTimeSource

/// The system's wall clock. A sleep may end up to 0.1 s late, so the system can coalesce wakes.
public struct SystemTimeSource: TimeSource {
  /// The system's wall clock.
  public init() { }

  /// The current instant.
  public var now: Date { Date() }

  /// Returns at `deadline` or up to 0.1 s after it.
  public func sleep(until deadline: Date) async throws {
    try await Task.sleep(for: .seconds(deadline.timeIntervalSinceNow), tolerance: .milliseconds(100))
  }
}
