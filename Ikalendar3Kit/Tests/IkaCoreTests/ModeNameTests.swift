//
//  ModeNameTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Testing
@testable import IkaCore

struct ModeNameTests {
  @Test
  func `Each Mode is named by its labels, the Anarchy forms with their form`() {
    #expect(Mode.allCases.map { $0.name(in: .enUS) } == [
      "Regular Battle",
      "Anarchy Battle (Series)",
      "Anarchy Battle (Open)",
      "X Battle",
      "Salmon Run",
    ])
  }

  @Test(arguments: [
    (GameLanguage.jaJP, BattleMode.anarchySeries, "バンカラマッチ（チャレンジ）"),
    (.zhTW, .anarchyOpen, "蠻頹比賽（開放）"),
    (.deDE, .anarchyOpen, "Anarchie-Kampf (Offen)"),
    (.esMX, .x, "Combate X"),
  ])
  func `Each language writes the form its own way`(language: GameLanguage, battleMode: BattleMode, name: String) {
    #expect(battleMode.name(in: language) == name)
    #expect(Mode.battle(battleMode).name(in: language) == name)
  }

  @Test(arguments: GameLanguage.allCases)
  func `Every Mode name resolves`(language: GameLanguage) {
    for mode in Mode.allCases {
      let name = mode.name(in: language)
      #expect(
        !name.isEmpty && !name.contains("mode.") && !name.contains("%"),
        "\(mode) in \(language.rawValue): [\(name)]")
    }
  }
}
