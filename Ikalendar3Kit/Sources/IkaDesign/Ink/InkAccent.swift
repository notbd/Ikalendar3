//
//  InkAccent.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - InkAccent

/// The colour an Ink screen or row marks itself in: its stamp's splat, its form tag, "Now!", the
/// Rule on the featured panel and the progress. A Mode's or event's own colour, or white for
/// Splatfest Battle and Tricolor Turf War, which have none: a team's colour appears only beside
/// its name.
public struct InkAccent: Hashable, Sendable {
  /// The colour.
  public let base: SRGBColor

  /// The accent of a Mode or event, or white for `nil`, one with no colour of its own (a summary
  /// row's `color`).
  public init(_ modeColor: ModeColor?) {
    base = modeColor?.base ?? Self.splatfest.base
  }

  private init(base: SRGBColor) {
    self.base = base
  }

  /// The accent of a Splatfest's screens and card.
  static let splatfest: Self = .init(base: .white)

  /// The colour as a fill, such as a tag or the progress, with black or white text on it.
  public var fill: ColorPair {
    ColorPair(foreground: base.labelColor, background: base)
  }

  /// The colour as text on Ink's panel in `colorScheme`: the base colour, or its nearest tint
  /// that reads there.
  func onPanel(in colorScheme: ColorScheme) -> ColorPair {
    let panel: SRGBColor = Style.ink.panel(in: colorScheme)
    return ColorPair(foreground: base.readableTint(on: panel, for: .text), background: panel)
  }
}
