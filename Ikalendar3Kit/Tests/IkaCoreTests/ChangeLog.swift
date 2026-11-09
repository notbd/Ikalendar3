//
//  ChangeLog.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Observation

/// Records the value of an observable property after each change Observation reports, so a test
/// sees what was published, and that an equal value was not published again.
///
/// Each value is read on the main actor after the change, so the code under test must suspend
/// between two changes it wants told apart, as an engine does between a refresh's start and end.
@MainActor
final class ChangeLog<Value: Sendable> {
  /// The values read after each reported change, in order.
  private(set) var values: [Value] = []

  private let read: @MainActor @Sendable () -> Value

  /// Starts recording the property `read` reads.
  init(_ read: @escaping @MainActor @Sendable () -> Value) {
    self.read = read
    track()
  }

  private func track() {
    withObservationTracking { _ = read() } onChange: { [weak self] in
      Task { @MainActor [weak self] in self?.record() }
    }
  }

  private func record() {
    values.append(read())
    track()
  }
}
