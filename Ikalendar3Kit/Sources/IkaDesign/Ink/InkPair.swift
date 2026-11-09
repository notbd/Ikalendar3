//
//  InkPair.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - InkPair

/// Every text colour Ink's base components draw, with the surface it sits on. Components take
/// both colours from here, so the pairs the contrast tests check are the pairs on screen. The
/// Mode-colour tags (Series, Open, "Now!") draw `ModeColor.asFill` instead.
///
/// Ink draws on the game's dark materials in light appearance too, until ticket 56 designs its
/// light look; the appearance is a parameter so that look changes only this type.
public enum InkPair: CaseIterable, Sendable {
  /// Text on the dotted black background, such as the Mode name.
  case backgroundText
  /// Primary text on a dark panel.
  case panelText
  /// Quieter text on a dark panel, such as the time left.
  case panelSecondaryText
  /// Text on a black tag: a time or a Stage name.
  case tagText
  /// Text on the purple "Next" tag, the game's colour for a state tag that is not "Now".
  case nextTagText

  /// The text colour and its surface in `colorScheme`.
  public func colors(in colorScheme: ColorScheme) -> ColorPair {
    switch self {
      case .backgroundText,
           .tagText:
        ColorPair(foreground: .white, background: .black)
      case .panelText:
        ColorPair(foreground: .white, background: Style.ink.panel(in: colorScheme))
      case .panelSecondaryText:
        ColorPair(foreground: SRGBColor(hex: 0xC8C8C8), background: Style.ink.panel(in: colorScheme))
      case .nextTagText:
        ColorPair(foreground: .white, background: SRGBColor(hex: 0x603AFF))
    }
  }
}
