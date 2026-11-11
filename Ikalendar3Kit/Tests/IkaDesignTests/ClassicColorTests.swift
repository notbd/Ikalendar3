//
//  ClassicColorTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI
import Testing
@testable import IkaDesign

/// Pins the colours Classic draws itself rather than taking from the system: its grey tags, and
/// its secondary text and the ground of the game's icons in light appearance.
struct ClassicColorTests {
  @Test(arguments: [ColorScheme.light, .dark])
  func `A tag's text reaches 4.5 to 1 on its fill`(colorScheme: ColorScheme) {
    #expect(ColorPair.classicTag(in: colorScheme).contrastRatio >= ContrastTarget.text.minimumRatio)
  }

  @Test
  func `A tag in dark appearance is light with dark text, as ikalendar 2's rendered`() {
    let tag: ColorPair = .classicTag(in: .dark)

    #expect(tag.background.relativeLuminance > Style.classic.panel(in: .dark).relativeLuminance + 0.2)
    #expect(tag.foreground == .black)
  }

  @Test
  func `White icons keep 3 to 1 on their ground in light appearance`() {
    let ratio: Double = SRGBColor.white.contrastRatio(with: ClassicMetrics.iconGroundLight)

    #expect(ratio >= ContrastTarget.largeTextAndIcons.minimumRatio)
  }

  @Test(arguments: [SRGBColor.white, Style.classic.panel(in: .light)])
  func `Secondary text in light appearance reaches 4.5 to 1 on cells and their ground`(background: SRGBColor) {
    #expect(ClassicMetrics.secondaryTextLight.contrastRatio(with: background) >= ContrastTarget.text.minimumRatio)
  }
}
