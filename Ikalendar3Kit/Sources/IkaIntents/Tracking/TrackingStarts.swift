//
//  TrackingStarts.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if !os(watchOS)
import IkaCore

// MARK: - TrackingStarts

/// Turns for starting Tracking, one Mode at a time: a start of a Mode waits until every earlier
/// start of that Mode has finished, across all its suspension points, so ending the Mode's running
/// activity and requesting the new one never interleave with another start of it. Starts of other
/// Modes never wait.
///
/// The main actor alone does not do this: two starts both end the old activity, then both
/// request a new one. `TrackingActivities.start` takes its turn here, and every start goes through
/// it (the track button, Siri, Shortcuts and the Control Center control run the start intent in
/// the app's process), so overlapping starts leave one activity per Mode. Built on every platform
/// but watchOS, so the package tests run it on the Mac; only iOS starts Tracking.
@MainActor
final class TrackingStarts {
  /// Each Mode's turns, made at its first start.
  private var turns: [Mode: Turns] = [:]

  nonisolated init() { }

  /// Runs `start` in `mode`'s turn and returns what it returns.
  func run<Value>(_ mode: Mode, _ start: () async throws -> Value) async rethrows -> Value {
    let modeTurns = turns[mode] ?? Turns()
    turns[mode] = modeTurns
    return try await modeTurns.run(start)
  }
}
#endif
