//
//  AppClock.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Observation

// MARK: - AppClock

/// The app's clock: the current instant as a whole second, published once a second for the
/// app's screens. Build one in the composition root and hand it to the views, which read `now`
/// and pass it to the time functions, so a Rotation boundary flips on its exact second. A slower
/// cadence stays with the view that needs it.
@MainActor
@Observable
final public class AppClock {
  /// The current instant, snapped to its whole second. Each tick publishes the next second once;
  /// a wake after a suspension publishes the second it woke in, not every missed one.
  private(set) public var now: Date

  @ObservationIgnored private var tickTask: Task<Void, Never>?

  /// A clock reading `source`, the system's wall clock unless a test or preview passes another.
  public init(source: any TimeSource = SystemTimeSource()) {
    now = Self.wholeSecond(containing: source.now)
    // Weak, so a released clock (a preview, a test) stops ticking and deinits.
    tickTask = Task { [weak self] in
      while true {
        // To the next whole second of the source's time, not a second after the last wake: ticks
        // never drift, and a changed system time is picked up within a second.
        do {
          try await source.sleep(until: Self.wholeSecond(containing: source.now).addingTimeInterval(1))
        }
        catch {
          return
        }
        guard let self else { return }

        // A sleep that ends early is still in the second already published. Observation does not
        // publish a value equal to the current one, so no screen re-renders for it.
        now = Self.wholeSecond(containing: source.now)
      }
    }
  }

  deinit {
    // Legal in a nonisolated deinit: a Task is Sendable and `cancel()` is nonisolated.
    tickTask?.cancel()
  }

  /// The whole second `instant` is in.
  nonisolated static private func wholeSecond(containing instant: Date) -> Date {
    Date(timeIntervalSinceReferenceDate: instant.timeIntervalSinceReferenceDate.rounded(.down))
  }
}
