//
//  Motion.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

/// Named constants deciding how fast or how often something moves, carried over from ikalendar 2.
/// Choreography that only one screen uses may stay in that screen's private `Timing` enum.
public enum Motion {
  // MARK: Cadences

  /// How often an undiscovered row's symbol wiggles.
  static public let nudgeInterval: TimeInterval = 5
  /// How often a periodic pulse repeats.
  static public let pulseInterval: TimeInterval = 3
  /// The tolerance the cadence timers allow the system, to save energy.
  static public let timerTolerance: TimeInterval = 0.1

  // MARK: Named Animations

  /// A periodic pulse's swing to its colour and back.
  static public let pulse: Animation = .spring(duration: 1.2)
  /// The countdown digits rolling.
  static public let countdownRoll: Animation = .snappy
  /// Rows moving into place.
  static public let listReflow: Animation = .bouncy
  /// The onboarding button growing.
  static public let buttonPulseIn: Animation = .snappy(duration: 0.5)
  /// The onboarding button settling back.
  static public let buttonPulseOut: Animation = .bouncy(duration: 0.4, extraBounce: 0.2)
  /// The cross-fade that stands in for a decorative motion under Reduce Motion.
  static public let crossFade: Animation = .easeInOut(duration: 0.25)
}
