//
//  IkaFont.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

extension EnvironmentValues {
  /// The app language, which picks the Han face of every text set with `ikaFont`. The composition
  /// root of each target sets it from the localization the system resolved for its bundle.
  @Entry public var gameLanguage: GameLanguage = .enUS
}

// MARK: - IkaFontModifier

/// Sets text in `role`'s cascade for the environment's language, at `size` points scaled with
/// Dynamic Type relative to a text style.
private struct IkaFontModifier: ViewModifier {
  @Environment(\.gameLanguage) private var language
  @ScaledMetric private var size: CGFloat

  let role: FontRole

  init(role: FontRole, size: CGFloat, textStyle: Font.TextStyle) {
    self.role = role
    _size = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
  }

  func body(content: Content) -> some View {
    content
      .font(FontCascade(role: role, language: language, registered: FontRegistry.registered).font(size: size))
  }
}

extension View {
  /// Sets text in SplatNet 3's heavy or light face for the app language, falling back per character
  /// to the language's Han face and then the system font, at `size` points scaled with Dynamic
  /// Type relative to `textStyle`.
  public func ikaFont(
    _ role: FontRole,
    size: CGFloat,
    relativeTo textStyle: Font.TextStyle)
    -> some View
  {
    modifier(IkaFontModifier(role: role, size: size, textStyle: textStyle))
  }
}
