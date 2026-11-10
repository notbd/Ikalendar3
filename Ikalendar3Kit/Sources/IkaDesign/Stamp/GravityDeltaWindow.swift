//
//  GravityDeltaWindow.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreGraphics
import Foundation

// MARK: - GravityDeltaWindow

/// A rolling window of one gravity component. `push` returns the new sample minus the window mean,
/// so a held tilt decays to zero over the window length and only motion shows.
///
/// The device-motion monitor keeps one window per axis and samples at `updateInterval`.
public struct GravityDeltaWindow: Sendable {
  /// The stamp's gravity sampling period (10 Hz).
  static public let updateInterval: TimeInterval = 0.1
  /// How far back the stamp's rolling mean reaches: a held tilt decays to zero over this long.
  static public let windowLength: TimeInterval = 10

  /// The most samples the window holds: one window length at the update interval.
  public let capacity: Int

  /// Oldest first.
  private(set) var samples: [CGFloat] = []

  /// An empty window covering `windowLength` seconds of samples taken every `updateInterval`, and
  /// at least the newest sample.
  public init(
    windowLength: TimeInterval = windowLength,
    updateInterval: TimeInterval = updateInterval)
  {
    // Rounded where ikalendar 2 truncates: a quotient such as 0.3 / 0.1 is 2.9999999999999996.
    capacity = max(Int((windowLength / updateInterval).rounded()), 1)
  }

  /// Appends `sample`, dropping the oldest once the window is full, and returns `sample` minus the
  /// mean of the window (which includes `sample`).
  public mutating func push(_ sample: CGFloat) -> CGFloat {
    if samples.count >= capacity { samples.removeFirst() }
    samples.append(sample)
    return sample - samples.reduce(0, +) / CGFloat(samples.count)
  }
}
