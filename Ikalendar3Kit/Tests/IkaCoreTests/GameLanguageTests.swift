//
//  GameLanguageTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Testing
@testable import IkaCore

struct GameLanguageTests {
  /// Pinned: the 14 app localizations, named so the system's own matching lands on the nearest
  /// text set (Latin American Spanish on `es-419`, Hong Kong Chinese on `zh-Hant`).
  @Test(arguments: [
    ("en", GameLanguage.enUS),
    ("en-GB", .enGB),
    ("es", .esES),
    ("es-419", .esMX),
    ("fr", .frFR),
    ("fr-CA", .frCA),
    ("de", .deDE),
    ("it", .itIT),
    ("nl", .nlNL),
    ("ru", .ruRU),
    ("ja", .jaJP),
    ("ko", .koKR),
    ("zh-Hans", .zhCN),
    ("zh-Hant", .zhTW),
  ])
  func `Each app localization resolves to its text set`(localization: String, language: GameLanguage) {
    #expect(GameLanguage(localization: localization) == language)
    #expect(language.localization == localization)
  }

  @Test(arguments: ["pt-BR", "Base", "", "en-US", "zh-HK"])
  func `Any other localization resolves to en-US`(localization: String) {
    #expect(GameLanguage(localization: localization) == .enUS)
  }

  /// The name the language row shows: the localization's name in itself, as the system's
  /// language list writes it, starting with a capital.
  @Test(arguments: [
    (GameLanguage.enUS, "English"),
    (.enGB, "English (United Kingdom)"),
    (.esMX, "Español (Latinoamérica)"),
    (.frCA, "Français (Canada)"),
    (.ruRU, "Русский"),
    (.jaJP, "日本語"),
    (.zhCN, "简体中文"),
    (.zhTW, "繁體中文"),
  ])
  func `Each text set is named in itself`(language: GameLanguage, name: String) {
    #expect(language.nativeName == name)
  }
}
