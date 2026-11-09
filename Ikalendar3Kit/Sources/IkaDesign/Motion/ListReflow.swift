//
//  ListReflow.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

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
  /// Moves the rows into place when `value` (the list's items) changes.
  public func listReflow(value: some Equatable) -> some View {
    modifier(ListReflow(value: value))
  }
}
