//
//  AboutTextTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import Ikalendar3

// MARK: - AboutTextTests

struct AboutTextTests {
  /// A key the `About` table lacks resolves to itself, so this catches a key that the catalog
  /// check cannot see: one the code names and the catalog never got.
  @Test(arguments: GameLanguage.allCases)
  func `Every About string resolves in each text set`(language: GameLanguage) {
    for text in AboutText.allCases {
      #expect(text.text(in: language) != text.rawValue, "\(text) in \(language)")
    }
  }
}
