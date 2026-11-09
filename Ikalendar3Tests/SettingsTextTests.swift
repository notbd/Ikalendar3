//
//  SettingsTextTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import Ikalendar3

// MARK: - SettingsTextTests

struct SettingsTextTests {
  /// A key the `Settings` table lacks resolves to itself, so this catches a key that the catalog
  /// check cannot see: one the code names and the catalog never got.
  @Test(arguments: GameLanguage.allCases)
  func `Every Settings string resolves in each text set`(language: GameLanguage) {
    for text in SettingsText.allCases {
      #expect(text.text(in: language) != text.rawValue, "\(text) in \(language)")
    }
  }

  @Test
  func `Each English text set spells colour its own way`() {
    #expect(SettingsText.colorScheme.text(in: .enUS) == "Color Scheme")
    #expect(SettingsText.colorScheme.text(in: .enGB) == "Colour Scheme")
  }
}
