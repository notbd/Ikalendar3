//
//  WaitUntil.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Testing

/// Waits until `condition` holds, re-checking every 10 ms on the main actor, and records an
/// issue if it still does not hold at the deadline. Use it instead of a fixed sleep before an
/// assertion: CI runners can be slow enough to make any fixed sleep flaky, and the generous
/// deadline only costs time when something is actually broken.
@MainActor
func waitUntil(
  timeout: Duration = .seconds(10),
  sourceLocation: SourceLocation = #_sourceLocation,
  _ condition: () -> Bool)
  async
{
  let deadline: ContinuousClock.Instant = .now + timeout
  while !condition() {
    if ContinuousClock.now >= deadline {
      Issue.record("Condition not met within \(timeout)", sourceLocation: sourceLocation)
      return
    }
    try? await Task.sleep(for: .milliseconds(10))
  }
}
