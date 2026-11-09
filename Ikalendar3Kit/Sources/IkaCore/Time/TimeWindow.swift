//
//  TimeWindow.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - TimeWindow

/// Something that runs in one fixed window of time: a Rotation, a Shift, a Challenge window or a
/// Splatfest.
///
/// A window holds its start and not its end, so on a boundary the item that starts is on and the
/// one that ends is over.
public protocol TimeWindow {
  /// When the window opens.
  var startTime: Date { get }
  /// When the window closes.
  var endTime: Date { get }
}

extension TimeWindow {
  /// Whether the window is open at `instant`.
  public func isRunning(at instant: Date) -> Bool {
    startTime <= instant && instant < endTime
  }

  /// How far the window has run at `instant`. An instant outside the window counts as its
  /// nearest end.
  public func progress(at instant: Date) -> WindowProgress {
    let length = endTime.timeIntervalSince(startTime)
    let passed = min(max(instant.timeIntervalSince(startTime), 0), length)
    return WindowProgress(timeLeft: .seconds(length - passed), sharePassed: length > 0 ? passed / length : 1)
  }
}

// MARK: - WindowProgress

/// How far a window has run at an instant.
public struct WindowProgress: Hashable, Sendable {
  /// The time until the window closes.
  public let timeLeft: Duration
  /// The share of the window that has passed, from 0 at its start to 1 at its end.
  public let sharePassed: Double
}

// MARK: - Rotation + TimeWindow

extension Rotation: TimeWindow { }

// MARK: - Shift + TimeWindow

extension Shift: TimeWindow { }

// MARK: - Challenge.Window + TimeWindow

extension Challenge.Window: TimeWindow { }

// MARK: - Splatfest + TimeWindow

extension Splatfest: TimeWindow { }
