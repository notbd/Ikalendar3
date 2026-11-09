//
//  WidgetTextTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import IkaDesign

/// Pins that the strings every widget extension writes resolve from `IkaDesign`'s table in every
/// text set, so the iPhone widgets and the watch complications read alike.
struct WidgetTextTests {
  @Test(arguments: GameLanguage.allCases)
  func `Every widget string resolves in the text set`(language: GameLanguage) {
    for text in WidgetText.allCases {
      let value = text.text(in: language)

      #expect(!value.isEmpty && value != text.rawValue, "\(language.rawValue): \(text.rawValue)")
    }
  }

  @Test
  func `The stale mark reads that the schedule may be out of date`() {
    #expect(WidgetText.stale.text(in: .enUS) == "Schedule may be out of date")
  }
}
