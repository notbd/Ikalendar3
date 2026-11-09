//
//  MenuBarTextTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import Ikalendar3

// MARK: - MenuBarTextTests

struct MenuBarTextTests {
  /// A key the `MenuBar` table lacks resolves to itself, so this catches a key that the catalog
  /// check cannot see: one the code names and the catalog never got.
  @Test(arguments: GameLanguage.allCases)
  func `Every menu bar string resolves in each text set`(language: GameLanguage) {
    for text in MenuBarText.allCases {
      #expect(text.text(in: language) != text.rawValue, "\(text) in \(language)")
    }
  }

  @Test
  func `The open-window button names the app`() {
    #expect(MenuBarText.openApp.text(in: .enUS) == "Open ikalendar3")
    #expect(MenuBarText.openApp.text(in: .jaJP) == "ikalendar3を開く")
  }
}
