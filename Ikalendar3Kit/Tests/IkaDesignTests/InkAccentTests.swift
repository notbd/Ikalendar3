//
//  InkAccentTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI
import Testing
@testable import IkaDesign

struct InkAccentTests {
  @Test(arguments: ModeColor.allCases)
  func `A Mode's accent fills like its Mode tag`(modeColor: ModeColor) {
    #expect(InkAccent(modeColor).fill == modeColor.asFill)
  }

  @Test
  func `Splatfest Battle, with no Mode colour, is marked in white with black text`() {
    #expect(InkAccent.splatfest.fill == ColorPair(foreground: .black, background: .white))
  }

  @Test(arguments: [InkAccent.splatfest] + ModeColor.allCases.map(InkAccent.init))
  func `Every accent reads as text on Ink's panel`(accent: InkAccent) {
    for colorScheme in ColorScheme.allCases {
      #expect(accent.onPanel(in: colorScheme).contrastRatio >= 4.5)
    }
  }
}
