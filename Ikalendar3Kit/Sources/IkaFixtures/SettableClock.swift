//
//  SettableClock.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import Synchronization

// MARK: - SettableClock

/// A wall clock that stands still until it is set: the one fake clock for tests, previews and the
/// Debug fixture launch. Hand it to `AppClock` as its time source, or `{ clock.now }` to whatever
/// reads only the current instant, then move it by setting `now`.
///
/// Setting `now` also ends the pending sleep, early or late as the setter chooses, the way a
/// system timer can.
final public class SettableClock: TimeSource {
  private let state: Mutex<State>

  private struct State {
    var now: Date
    /// The pending sleep and its deadline.
    var sleep: (deadline: Date, continuation: CheckedContinuation<Void, any Error>)?
    /// A caller waiting in `pendingSleep()`.
    var waiter: Waiter?
  }

  /// A caller of `pendingSleep()`, waiting for a sleep's deadline.
  private typealias Waiter = CheckedContinuation<Date, Never>

  /// A clock standing at an instant.
  public init(_ now: Date) {
    state = .init(State(now: now))
  }

  /// The instant the clock shows. Setting it ends the pending sleep.
  public var now: Date {
    get { state.withLock { $0.now } }
    set {
      let sleep = state.withLock { state in
        state.now = newValue
        return state.sleep.take()
      }
      sleep?.continuation.resume()
    }
  }

  /// Whether a sleep is pending.
  public var isSleeping: Bool { state.withLock { $0.sleep != nil } }

  /// Returns at once when the clock already shows `deadline` or later; otherwise waits until
  /// `now` is next set, whatever it is set to, or throws `CancellationError` once the calling
  /// task is cancelled.
  public func sleep(until deadline: Date) async throws {
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
        let outcome = state.withLock { state -> (result: Result<Void, any Error>?, waiter: Waiter?) in
          // The cancellation flag is set before the handler runs, so this check under the lock
          // covers a cancellation that came before the sleep was stored.
          guard !Task.isCancelled else { return (.failure(CancellationError()), nil) }
          guard state.now < deadline else { return (.success(()), nil) }

          state.sleep = (deadline, continuation)
          return (nil, state.waiter.take())
        }
        if let result = outcome.result {
          continuation.resume(with: result)
        }
        outcome.waiter?.resume(returning: deadline)
      }
    } onCancel: {
      let sleep = state.withLock { $0.sleep.take() }
      sleep?.continuation.resume(throwing: CancellationError())
    }
  }

  /// Waits until a sleep is pending and returns its deadline. A sleep that setting `now` ended is
  /// never returned again.
  public func pendingSleep() async -> Date {
    await withCheckedContinuation { (waiter: Waiter) in
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
}
