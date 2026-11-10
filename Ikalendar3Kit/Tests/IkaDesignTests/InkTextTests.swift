//
//  InkTextTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import IkaDesign

/// Pins that Ink's own strings resolve from its table in every text set.
struct InkTextTests {
  @Test(arguments: GameLanguage.allCases)
  func `Every Ink string resolves in the text set`(language: GameLanguage) {
    for text in InkText.allCases {
      let value = text.text(in: language)

      #expect(!value.isEmpty && value != text.rawValue, "\(language.rawValue): \(text.rawValue)")
    }
  }

  @Test
  func `State tags read as the game's English tags`() {
    #expect(InkText.now.text(in: .enUS) == "Now!")
    #expect(InkText.next.text(in: .enUS) == "Next")
  }
}
