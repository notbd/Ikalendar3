//
//  CountdownRoll.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - CountdownRoll

/// Rolls the countdown digits on each change of `value`; cross-fades them under Reduce Motion.
private struct CountdownRoll<Value: Equatable>: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let value: Value

  func body(content: Content) -> some View {
    let isRolling: Bool = DecorativeMotion.countdownRoll.form(reduceMotion: reduceMotion) == .full

    content
      .contentTransition(isRolling ? .numericText(countsDown: true) : .opacity)
      .animation(isRolling ? Motion.countdownRoll : Motion.crossFade, value: value)
  }
}

extension View {
  /// Rolls the time-left digits as `value` (the current instant) changes.
  public func countdownRoll(value: some Equatable) -> some View {
    modifier(CountdownRoll(value: value))
  }
}
