//
//  InkPairTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI
import Testing
@testable import IkaDesign

/// Pins that every text pair Ink's base components draw is readable in light and dark appearance.
/// The Mode-colour tag draws `ModeColor.asFill`, which `ModeColorTests` covers.
struct InkPairTests {
  @Test(arguments: InkPair.allCases)
  func `Ink text pair reaches 4.5 to 1 in both appearances`(pair: InkPair) {
    for colorScheme: ColorScheme in ColorScheme.allCases {
      let colors: ColorPair = pair.colors(in: colorScheme)

      #expect(
        colors.contrastRatio >= ContrastTarget.text.minimumRatio,
        "\(colors.foreground) on \(colors.background) (\(colorScheme)): \(colors.contrastRatio)")
    }
  }

  @Test
  func `Panel text sits on Ink's panel, the one Mode colours are tinted for`() {
    for colorScheme: ColorScheme in ColorScheme.allCases {
      #expect(InkPair.panelText.colors(in: colorScheme).background == Style.ink.panel(in: colorScheme))
      #expect(InkPair.panelSecondaryText.colors(in: colorScheme).background == Style.ink.panel(in: colorScheme))
    }
  }

  @Test
  func `Background and tags are the game's black`() {
    for colorScheme: ColorScheme in ColorScheme.allCases {
      #expect(InkPair.backgroundText.colors(in: colorScheme).background == .black)
      #expect(InkPair.tagText.colors(in: colorScheme).background == .black)
    }
  }
}
