//
//  ModeLabelTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Testing
@testable import IkaCore

struct ModeLabelTests {
  @Test(arguments: GameLanguage.allCases)
  func `Every Mode name and label resolves`(language: GameLanguage) {
    for label in ModeLabel.allCases {
      let text = label.text(in: language)
      #expect(!text.isEmpty && text != label.rawValue, "\(label) in \(language.rawValue): [\(text)]")
    }
    for unit in TimeUnit.allCases {
      for text in [unit.abbreviated(2, in: language), unit.spelledOut(2, in: language)] {
        #expect(text.contains("2") && !text.contains("time."), "\(unit) in \(language.rawValue): \(text)")
      }
    }
  }

  /// Regional variants read their own strings: es-MX and fr-CA differ from es-ES and fr-FR.
  @Test(arguments: [
    (GameLanguage.enUS, ModeLabel.anarchyBattle, "Anarchy Battle"),
    (.esES, .eggstraWork, "Alianza alevínica"),
    (.esMX, .eggstraWork, "Recolección extra"),
    (.frFR, .challenges, "Match Challenge"),
    (.frCA, .challenges, "Match épreuve"),
    (.deDE, .series, "Serie"),
    (.jaJP, .anarchyBattle, "バンカラマッチ"),
    (.koKR, .bigRun, "빅 런"),
    (.zhCN, .anarchyBattle, "蛮颓比赛"),
    (.zhTW, .salmonRun, "鮭魚跑"),
  ])
  func `Each language reads its own labels`(language: GameLanguage, label: ModeLabel, text: String) {
    #expect(label.text(in: language) == text)
  }

  @Test
  func `Time units follow each language's plural rules`() {
    #expect([1, 2].map { TimeUnit.days.spelledOut($0, in: .enUS) } == ["1 day", "2 days"])
    #expect([1, 2, 5, 21].map { TimeUnit.hours.spelledOut($0, in: .ruRU) } == ["1 час", "2 часа", "5 часов", "21 час"])
    #expect(TimeUnit.minutes.abbreviated(5, in: .enUS) == "5m")
    #expect(TimeUnit.hours.abbreviated(3, in: .jaJP) == "3時間")
  }
}
