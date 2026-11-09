//
//  GameLanguage.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - GameLanguage

/// One of Splatoon 3's 14 text sets. The raw value is the locale code splatoon3.ink names its
/// locale file by (`locale/ja-JP.json`).
public enum GameLanguage: String, CaseIterable, Codable, Hashable, Sendable {
  /// English (US).
  case enUS = "en-US"
  /// English (UK).
  case enGB = "en-GB"
  /// Spanish (Spain).
  case esES = "es-ES"
  /// Spanish (Latin America).
  case esMX = "es-MX"
  /// French (France).
  case frFR = "fr-FR"
  /// French (Canada).
  case frCA = "fr-CA"
  /// German.
  case deDE = "de-DE"
  /// Italian.
  case itIT = "it-IT"
  /// Dutch.
  case nlNL = "nl-NL"
  /// Russian.
  case ruRU = "ru-RU"
  /// Japanese.
  case jaJP = "ja-JP"
  /// Korean.
  case koKR = "ko-KR"
  /// Simplified Chinese.
  case zhCN = "zh-CN"
  /// Traditional Chinese.
  case zhTW = "zh-TW"
}
