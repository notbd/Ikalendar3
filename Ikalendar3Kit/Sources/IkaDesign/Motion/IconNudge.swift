//
//  IconNudge.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - IconNudge

/// Periodically wiggles a symbol to hint at an undiscovered, tappable row.
///
/// The cadence is tied to the view's identity, so parent re-renders don't reset the rhythm.
/// Starts one full interval after appearing; stops once discovered, and never runs under Reduce
/// Motion.
private struct IconNudge: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let isActive: Bool
  let interval: TimeInterval

  @State private var trigger: Int = 0

  func body(content: Content) -> some View {
    let isNudging: Bool = isActive && DecorativeMotion.iconNudge.form(reduceMotion: reduceMotion) == .full

    content
      .symbolEffect(.wiggle, value: trigger)
      .task(id: isNudging) {
        guard isNudging else { return }

        while !Task.isCancelled {
          try? await Task.sleep(for: .seconds(interval), tolerance: .seconds(Motion.timerTolerance))
          guard !Task.isCancelled else { return }

          trigger += 1
        }
      }
  }
}

extension View {
  /// Wiggles the symbol every `interval` seconds while `isActive` is true.
  public func iconNudge(
    isActive: Bool,
    interval: TimeInterval = Motion.nudgeInterval)
    -> some View
  {
    modifier(IconNudge(isActive: isActive, interval: interval))
  }
}
