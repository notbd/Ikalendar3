//
//  ParameterNameTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import AppIntents
import Foundation
import IkaCore
import Testing
@testable import IkaIntents

/// App Intents read their names from `IkaIntents`' string catalog, which the compiler cannot
/// check against `IkaCore`. These tests fail when a name there differs from the one `IkaCore`
/// gives, in any of the 14 languages.
struct ParameterNameTests {
  @Test(arguments: GameLanguage.allCases)
  func `Each Mode is named as IkaCore names it`(language: GameLanguage) {
    for parameter in ModeParameter.allCases {
      #expect(name(of: parameter, in: language) == parameter.mode.name(in: language), "\(parameter)")
    }
  }

  @Test(arguments: GameLanguage.allCases)
  func `Each Battle Mode is named as IkaCore names it`(language: GameLanguage) {
    for parameter in BattleModeParameter.allCases {
      #expect(name(of: parameter, in: language) == parameter.battleMode.name(in: language), "\(parameter)")
    }
  }

  @Test(arguments: GameLanguage.allCases)
  func `Each Rule is named as IkaCore's shipped terms name it`(language: GameLanguage) {
    let terms: GameTerms = .init(language: language, refreshed: nil, feed: TermTable())
    for parameter in RuleParameter.allCases {
      #expect(name(of: parameter, in: language) == terms.name(of: parameter.rule), "\(parameter)")
    }
  }

  /// The keys are the English names, so only another language shows that the lookup found the
  /// catalog.
  @Test
  func `Each parameter type is named in the given language`() {
    #expect([
      ModeParameter.typeDisplayRepresentation.name,
      BattleModeParameter.typeDisplayRepresentation.name,
      RuleParameter.typeDisplayRepresentation.name,
    ].map { resolve($0, in: .jaJP) } == ["モード", "バトルモード", "ルール"])
  }

  // MARK: Helpers

  /// The name the system shows for a value, in a text set.
  private func name<Value: AppEnum>(of value: Value, in language: GameLanguage) -> String {
    guard let title = Value.caseDisplayRepresentations[value]?.title else { return "" }

    return resolve(title, in: language)
  }

  /// A string of a catalog in a text set, as the system resolves it for that language.
  private func resolve(_ resource: LocalizedStringResource, in language: GameLanguage) -> String {
    var resource = resource
    resource.locale = Locale(identifier: language.localization)
    return String(localized: resource)
  }
}
