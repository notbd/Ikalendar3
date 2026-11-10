//
//  DuplicatedWordsTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import Foundation
import IkaCore
import IkaDesign
import Testing

/// Pins the words two package modules each carry, since modules cannot share a string table:
/// "Refresh" in `IkaIntents`' table (the Live Activity's button and Siri's) and on the iPad
/// toolbar, and "No schedule yet" in Tracking's error and the shared empty state. A change to one
/// copy fails here until the other follows. `IkaIntents`' table is read from the app's copy of
/// it, which Siri and Shortcuts read; only the iOS app bundles one.
struct DuplicatedWordsTests {
  @Test(arguments: GameLanguage.allCases)
  func `Refresh reads the same in Tracking's table and the sidebar's`(language: GameLanguage) {
    #expect(Bundle.main.localizedString(forKey: "Refresh", in: language) == SidebarText.refresh.text(in: language))
  }

  @Test(arguments: GameLanguage.allCases)
  func `No schedule yet reads the same in Tracking's table and the screens'`(language: GameLanguage) {
    #expect(
      Bundle.main.localizedString(forKey: "No schedule yet", in: language) == ScreenText.empty.text(in: language))
  }
}
#endif
