//
//  Signal.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - Signal

/// A flag a task raises and a test waits for, on the main actor. A task that raises it and then
/// calls a main-actor step has run that step up to its first suspension by the time `wait()`
/// returns, since nothing between the two suspends.
@MainActor
final class Signal {
  private(set) var isRaised = false

  func raise() {
    isRaised = true
  }

  func wait() async {
    while !isRaised {
      await Task.yield()
    }
  }
}
