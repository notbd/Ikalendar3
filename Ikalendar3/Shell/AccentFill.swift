//
//  AccentFill.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

extension ShapeStyle where Self == Color {
  /// The app's accent as a fill under a dark label or glyph, such as Get Started, the app icon
  /// stand-in and a switch that is on: ikalendar 2's orange, the system's, which black reads 9.6:1
  /// on in light appearance (#FF9500) and 10.2:1 in dark (#FF9F0A). Text and glyphs drawn in the
  /// accent take the `AppAccent` colour instead, darker in light so it reads on white.
  static var accentFill: Color { .orange }
}
