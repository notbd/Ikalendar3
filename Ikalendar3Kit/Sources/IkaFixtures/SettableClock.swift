//
//  SettableClock.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Synchronization

// MARK: - SettableClock

/// A wall clock that stands still until it is set. Hand `{ clock.now }` to whatever reads the
/// current instant, then move it by setting `now`.
final public class SettableClock: Sendable {
  private let instant: Mutex<Date>

  /// A clock standing at an instant.
  public init(_ now: Date) {
    instant = .init(now)
  }

  /// The instant the clock shows.
  public var now: Date {
    get { instant.withLock { $0 } }
    set { instant.withLock { $0 = newValue } }
  }
}
