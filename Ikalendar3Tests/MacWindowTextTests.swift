//
//  MacWindowTextTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import Ikalendar3

// MARK: - MacWindowTextTests

struct MacWindowTextTests {
  /// A key the `MacWindow` table lacks resolves to itself, so this catches a key that the catalog
  /// check cannot see: one the code names and the catalog never got.
  @Test(arguments: GameLanguage.allCases)
  func `Every Mac window string resolves in each text set`(language: GameLanguage) {
    for text in MacWindowText.allCases {
      #expect(text.text(in: language) != text.rawValue, "\(text) in \(language)")
    }
  }

  @Test
  func `The three views read as the macOS View menu names them`() {
    #expect(MacWindowText.columns.text(in: .enUS) == "Columns")
    #expect(MacWindowText.overview.text(in: .jaJP) == "概要")
    #expect(MacWindowText.sidebar.text(in: .zhCN) == "边栏")
  }
}
