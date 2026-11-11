//
//  ScreenTextTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import IkaDesign

/// Pins that the strings every Style's screens share resolve from their table in every text set.
struct ScreenTextTests {
  @Test(arguments: GameLanguage.allCases)
  func `Every screen string resolves in the text set`(language: GameLanguage) {
    for text in ScreenText.allCases {
      let value = text.text(in: language)

      #expect(!value.isEmpty && value != text.rawValue, "\(language.rawValue): \(text.rawValue)")
    }
  }
}
