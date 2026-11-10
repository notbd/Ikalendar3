//
//  PeriodicPulse.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - PeriodicPulse

/// Pulses the content red and back, once on appear and then every `interval` seconds; a plain
/// colour cross-fade under Reduce Motion.
///
/// The trigger is this modifier's own `@State` and the loop is this view's `.task`, so nothing
/// shared can restart or synchronize the rhythm. Hoisting pulse and nudge timers into shared
/// state made unrelated views pulse together in ikalendar 2 (a5bfe35, fixed in 20a3489).
private struct PeriodicPulse: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let interval: TimeInterval
  let animation: Animation

  @State private var trigger: Int = 0

  func body(content: Content) -> some View {
    let pulseAnimation: Animation =
      DecorativeMotion.periodicPulse.form(reduceMotion: reduceMotion) == .full ? animation : Motion.crossFade

    content
      .phaseAnimator([false, true], trigger: trigger) { content, isLit in
        content
          .foregroundStyle(isLit ? Color.red : Color.secondary)
      } animation: { _ in
        pulseAnimation
      }
      .task {
        trigger += 1

        while !Task.isCancelled {
          try? await Task.sleep(for: .seconds(interval), tolerance: .seconds(Motion.timerTolerance))
          guard !Task.isCancelled else { return }

          trigger += 1
        }
      }
  }
}

extension View {
  /// Pulses the content red every `interval` seconds while it is on screen.
  public func periodicPulse(
    every interval: TimeInterval = Motion.pulseInterval,
    animation: Animation = Motion.pulse)
    -> some View
  {
    modifier(PeriodicPulse(interval: interval, animation: animation))
  }
}
