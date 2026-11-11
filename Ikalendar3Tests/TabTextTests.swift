//
//  TabTextTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import Ikalendar3

// MARK: - TabTextTests

struct TabTextTests {
  /// A key the `Tabs` table lacks resolves to itself, so this catches a key that the catalog
  /// check cannot see: one the code names and the catalog never got.
  @Test(arguments: GameLanguage.allCases)
  func `Every tab name resolves in each text set`(language: GameLanguage) {
    for text in TabText.allCases {
      #expect(text.text(in: language) != text.rawValue, "\(text) in \(language)")
    }
  }
}
