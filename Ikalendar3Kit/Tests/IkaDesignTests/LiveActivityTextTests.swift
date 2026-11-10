//
//  LiveActivityTextTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import IkaDesign

/// Pins that the strings the Live Activity writes itself resolve from `IkaDesign`'s table in
/// every text set: a wrong bundle or table shows the key on the Lock Screen.
struct LiveActivityTextTests {
  @Test(arguments: GameLanguage.allCases)
  func `Every Live Activity string resolves in the text set`(language: GameLanguage) {
    for text in LiveActivityText.allCases {
      let value = text.text(in: language)

      #expect(!value.isEmpty && value != text.rawValue, "\(language.rawValue): \(text.rawValue)")
    }
  }

  @Test
  func `The next line says when nothing later is published`() {
    #expect(LiveActivityText.nothingLater.text(in: .enUS) == "Nothing later published yet")
  }
}
