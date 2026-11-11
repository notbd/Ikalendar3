//
//  ReadableSecondaryTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Testing
@testable import IkaDesign

/// Pins that secondary text reads 4.5:1 on every ground it is drawn on, primary black over the
/// light ones and primary white over the dark ones.
struct ReadableSecondaryTests {
  @Test(arguments: [
    (ground: 0xFFFFFF, isDark: false), // a white cell
    (ground: 0xF2F2F7, isDark: false), // the grouped ground, Classic's list
    (ground: 0x1C1C1E, isDark: true), // a dark cell
    (ground: 0x000000, isDark: true), // the dark grouped ground
    (ground: 0x292E35, isDark: true), // Timeline's page
  ])
  func `Secondary text reads 4.5 to 1 on its grounds`(ground: UInt32, isDark: Bool) {
    let background: SRGBColor = .init(hex: ground)
    let primary: SRGBColor = isDark ? .white : .black
    let share: Double = ReadableSecondary.primaryShare
    let text: SRGBColor = .init(
      red: (Double(primary.red) * share + Double(background.red) * (1 - share)) / 255,
      green: (Double(primary.green) * share + Double(background.green) * (1 - share)) / 255,
      blue: (Double(primary.blue) * share + Double(background.blue) * (1 - share)) / 255)

    #expect(text.contrastRatio(with: background) >= ContrastTarget.text.minimumRatio)
  }
}
