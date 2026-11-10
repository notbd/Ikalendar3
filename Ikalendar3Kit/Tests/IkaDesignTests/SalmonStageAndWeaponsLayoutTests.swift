//
//  SalmonStageAndWeaponsLayoutTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreGraphics
import Testing
@testable import IkaDesign

/// Pins how a Shift's row splits its width: a 16:9 Stage picture and a square weapons card, one
/// spacing apart, filling the width exactly.
struct SalmonStageAndWeaponsLayoutTests {
  @Test
  func `Stage is 16 by 9, weapons are square, and both fill the width`() {
    // 258 pt minus 8 pt spacing leaves 250 pt: 160 pt of Stage and 90 pt of weapons.
    let split: SalmonStageAndWeaponsLayout.Split = .init(width: 258, spacing: 8)

    #expect(split.stage == CGSize(width: 160, height: 90))
    #expect(split.weapons == CGSize(width: 90, height: 90))
  }
}
