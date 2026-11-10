//
//  SettableClock.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if DEBUG
import Foundation
import IkaCore
import Synchronization

// MARK: - SettableClock

/// A wall clock that stands still until it is set: the one fake clock for tests, previews and the
/// Debug fixture launch. Hand it to `AppClock` as its time source, or `{ clock.now }` to whatever
/// reads only the current instant, then move it by setting `now`.
///
/// Setting `now` ends every pending sleep, early or late as the setter chooses, the way a system
/// timer can. Any number of sleepers may wait on one clock, as two `AppClock`s on one fake do.
final public class SettableClock: TimeSource {
  private let state: Mutex<State>

  private struct State {
    var now: Date
    /// The pending sleeps, in the order they began.
    var sleeps: [Sleep] = []
    /// Callers waiting in `pendingSleep()`, in the order they began.
    var waiters: [Waiter] = []
  }

  private struct Sleep {
    let id: UUID
    let deadline: Date
    let continuation: CheckedContinuation<Void, any Error>
    /// Whether `pendingSleep()` has returned this sleep.
    var isReported = false
  }

  /// A caller of `pendingSleep()`, waiting for a sleep's deadline.
  private typealias Waiter = CheckedContinuation<Date, Never>

  /// A clock standing at an instant.
  public init(_ now: Date) {
    state = .init(State(now: now))
  }

  /// The instant the clock shows. Setting it ends every pending sleep.
  public var now: Date {
    get { state.withLock { $0.now } }
    set {
      let sleeps = state.withLock { state in
        state.now = newValue
        let sleeps = state.sleeps
        state.sleeps.removeAll()
        return sleeps
      }
      for sleep in sleeps {
        sleep.continuation.resume()
      }
    }
  }

  /// Whether a sleep is pending.
  public var isSleeping: Bool { state.withLock { !$0.sleeps.isEmpty } }

  /// Returns at once when the clock already shows `deadline` or later; otherwise waits until
  /// `now` is next set, whatever it is set to, or throws `CancellationError` once the calling
  /// task is cancelled.
  public func sleep(until deadline: Date) async throws {
    let id: UUID = .init()
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
        let outcome = state.withLock { state -> (result: Result<Void, any Error>?, waiter: Waiter?) in
          // The cancellation flag is set before the handler runs, so this check under the lock
          // covers a cancellation that came before the sleep was stored.
          guard !Task.isCancelled else { return (.failure(CancellationError()), nil) }
          guard state.now < deadline else { return (.success(()), nil) }

          let waiter = state.waiters.isEmpty ? nil : state.waiters.removeFirst()
          state.sleeps.append(Sleep(id: id, deadline: deadline, continuation: continuation, isReported: waiter != nil))
          return (nil, waiter)
        }
        if let result = outcome.result {
          continuation.resume(with: result)
        }
        outcome.waiter?.resume(returning: deadline)
      }
    } onCancel: {
      let sleep = state.withLock { state in
        state.sleeps.firstIndex { $0.id == id }.map { state.sleeps.remove(at: $0) }
      }
      sleep?.continuation.resume(throwing: CancellationError())
    }
  }

  /// Waits until a sleep is pending that this method has not returned yet, and returns its
  /// deadline. Each sleep is returned once, in the order the sleeps began; one that setting `now`
  /// ended is never returned.
  public func pendingSleep() async -> Date {
    await withCheckedContinuation { (waiter: Waiter) in
      let deadline = state.withLock { state -> Date? in
        if let index = state.sleeps.firstIndex(where: { !$0.isReported }) {
          state.sleeps[index].isReported = true
          return state.sleeps[index].deadline
        }

        state.waiters.append(waiter)
        return nil
      }
      if let deadline {
        waiter.resume(returning: deadline)
      }
    }
  }
}
#endif
