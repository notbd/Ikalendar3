//
//  TimelineTintTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Testing
@testable import IkaDesign

// MARK: - TimelineTintTests

/// Pins the colours Timeline's axis draws in: a Mode's own, or neutral for Splatfest Battle,
/// which no one team's colour stands for.
struct TimelineTintTests {
  @Test(arguments: ModeColor.allCases)
  func `A Mode's tint fills its pins as the Mode colour does`(color: ModeColor) {
    #expect(TimelineTint(color).asFill == color.asFill)
  }

  @Test
  func `The neutral tint fills a pin in white with black text`() {
    let fill = TimelineTint.neutral.asFill

    #expect(fill == ColorPair(foreground: .black, background: .white))
  }

  @Test
  func `The neutral tint's text reads on Timeline's panel`() {
    #expect(TimelineTint.neutral.onPanel(in: .dark).contrastRatio >= ContrastTarget.text.minimumRatio)
  }
}
