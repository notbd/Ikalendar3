//
//  SidebarTextTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import IkaDesign

/// Pins that the sidebar's own strings resolve from its table in every text set, the toolbar's
/// too, which only the app target reads.
struct SidebarTextTests {
  @Test(arguments: GameLanguage.allCases)
  func `Every sidebar string resolves in the text set`(language: GameLanguage) {
    for text in SidebarText.allCases {
      let value = text.text(in: language)

      #expect(!value.isEmpty && value != text.rawValue, "\(language.rawValue): \(text.rawValue)")
    }
  }
}
