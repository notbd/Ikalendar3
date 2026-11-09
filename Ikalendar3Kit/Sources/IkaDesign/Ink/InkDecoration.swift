//
//  InkDecoration.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

/// The colours of Ink's decoration: the dots and the tape. They carry no information, so they
/// have no contrast target, and every piece that draws them is hidden from VoiceOver. Text
/// colours are `InkPair`'s.
enum InkDecoration {
  /// The background's dots, faint on black.
  static let backgroundDot: Color = .init(SRGBColor(hex: 0x1F1F1F))
  /// A dotted rule's dots on a panel.
  static let ruleDot: Color = .init(SRGBColor(hex: 0x6A6A6A))
  /// Translucent masking tape.
  static let tape: Color = .init(.sRGB, red: 226 / 255, green: 220 / 255, blue: 200 / 255, opacity: 0.32)
}
