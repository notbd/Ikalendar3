//
//  ChangeMotion.swift
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

// MARK: - ListReflow

/// Animates rows into place on each change of `value`; changes them at once under Reduce Motion.
private struct ListReflow<Value: Equatable>: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let value: Value

  func body(content: Content) -> some View {
    let isReflowing: Bool = DecorativeMotion.listReflow.form(reduceMotion: reduceMotion) == .full

    content
      .animation(isReflowing ? Motion.listReflow : nil, value: value)
  }
}

extension View {
  /// Rolls the time-left digits as `value` (the current instant) changes.
  public func countdownRoll(value: some Equatable) -> some View {
    modifier(CountdownRoll(value: value))
  }

  /// Moves the rows into place when `value` (the list's items) changes.
  public func listReflow(value: some Equatable) -> some View {
    modifier(ListReflow(value: value))
  }
}
