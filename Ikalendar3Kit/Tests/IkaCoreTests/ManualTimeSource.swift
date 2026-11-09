//
//  ManualTimeSource.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Synchronization
@testable import IkaCore

// MARK: - ManualTimeSource

/// A time source the test moves by hand. Its time stands still until `wake(at:)` moves it and
/// ends the pending sleep, early or late as the test chooses, the way a system timer can.
final class ManualTimeSource: TimeSource {
  private let state: Mutex<State>

  private struct State {
    var now: Date
    /// The pending sleep and its deadline.
    var sleep: (deadline: Date, continuation: CheckedContinuation<Void, any Error>)?
    /// A test waiting in `pendingSleep()`.
    var waiter: CheckedContinuation<Date, Never>?
  }

  init(now: Date) {
    state = Mutex(State(now: now))
  }

  var now: Date { state.withLock { $0.now } }

  /// Whether a sleep is pending.
  var isSleeping: Bool { state.withLock { $0.sleep != nil } }

  func sleep(until deadline: Date) async throws {
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
        let outcome = state.withLock { state -> (isCancelled: Bool, waiter: CheckedContinuation<Date, Never>?) in
          // The cancellation flag is set before the handler runs, so this check under the lock
          // covers a cancellation that came before the sleep was stored.
          guard !Task.isCancelled else { return (true, nil) }

          state.sleep = (deadline, continuation)
          return (false, state.waiter.take())
        }
        if outcome.isCancelled {
          continuation.resume(throwing: CancellationError())
        }
        outcome.waiter?.resume(returning: deadline)
      }
    } onCancel: {
      let sleep = state.withLock { $0.sleep.take() }
      sleep?.continuation.resume(throwing: CancellationError())
    }
  }

  /// Waits until a sleep is pending and returns its deadline. A sleep `wake(at:)` ended is never
  /// returned again.
  func pendingSleep() async -> Date {
    await withCheckedContinuation { (waiter: CheckedContinuation<Date, Never>) in
      let deadline = state.withLock { state -> Date? in
        if let sleep = state.sleep { return sleep.deadline }

        state.waiter = waiter
        return nil
      }
      if let deadline {
        waiter.resume(returning: deadline)
      }
    }
  }

  /// Moves the time to `instant` and ends the pending sleep.
  func wake(at instant: Date) {
    let sleep = state.withLock { state in
      state.now = instant
      return state.sleep.take()
    }
    sleep?.continuation.resume()
  }
}
