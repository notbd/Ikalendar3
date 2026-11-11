//
//  InkDecoration.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

/// The colours of Ink's decoration: the dots, the tape, the progress bar's track and the
/// splat's shadow. They carry no information, so they
/// have no contrast target, and every piece that draws them is hidden from VoiceOver. Text
/// colours are `InkPair`'s.
enum InkDecoration {
  /// The background's dots, faint on black.
  static let backgroundDot: Color = .init(SRGBColor(hex: 0x1F1F1F))

  /// A screen board's dots in `colorScheme`: the background's on black, a shade under the paper
  /// in light appearance.
  static func boardDot(in colorScheme: ColorScheme) -> Color {
    switch colorScheme {
      case .light: Color(SRGBColor(hex: 0x878884))
      default: backgroundDot
    }
  }

  /// A dotted rule's dots on a panel.
  static let ruleDot: Color = .init(SRGBColor(hex: 0x6A6A6A))
  /// Translucent masking tape.
  static let tape: Color = .init(.sRGB, red: 226 / 255, green: 220 / 255, blue: 200 / 255, opacity: 0.32)
  /// The progress bar's empty track, darker than the panel.
  static let progressTrack: Color = .init(SRGBColor(hex: 0x111111))
  /// A note's hatch stripes, a shade over the panel.
  static let noteHatch: Color = .init(SRGBColor(hex: 0x464646))
  /// The shadow a splat casts on the board.
  static let splatShadow: Color = .black.opacity(0.45)
}
