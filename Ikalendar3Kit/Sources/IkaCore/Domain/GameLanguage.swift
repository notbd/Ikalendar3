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

// MARK: - App localizations

extension GameLanguage {
  /// The text set of an app localization: the one the system resolved for a process's own
  /// bundle (`Bundle.main.preferredLocalizations[0]`). Any other name resolves to en-US.
  ///
  /// Every target declares the same 14 localizations, so the app, the widget extension and the
  /// watch targets resolve the same text set from the same system languages.
  public init(localization: String) {
    self = Self.allCases.first { $0.localization == localization } ?? .enUS
  }

  /// The name of the app localization that holds this text set, which is also its `.lproj`
  /// folder. The names let the system's own matching land on the nearest text set: Latin
  /// American Spanish on `es-419`, Canadian French on `fr-CA`, British English on `en-GB`,
  /// Traditional Chinese, Hong Kong's included, on `zh-Hant`, and every other variant of a
  /// language on its plain name.
  public var localization: String {
    switch self {
      case .enUS: "en"
      case .enGB: "en-GB"
      case .esES: "es"
      case .esMX: "es-419"
      case .frFR: "fr"
      case .frCA: "fr-CA"
      case .deDE: "de"
      case .itIT: "it"
      case .nlNL: "nl"
      case .ruRU: "ru"
      case .jaJP: "ja"
      case .koKR: "ko"
      case .zhCN: "zh-Hans"
      case .zhTW: "zh-Hant"
    }
  }
}
