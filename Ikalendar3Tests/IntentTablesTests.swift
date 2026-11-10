//
//  IntentTablesTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import AppIntents
import Foundation
import IkaCore
import IkaIntents
import Testing

// MARK: - IntentTablesTests

/// The App Intents metadata records each title and parameter name by its key only, and the system
/// looks the key up in the host bundle's own `Localizable` table: the app's, the widget
/// extension's, on iOS the watch widget extension's. Each carries a copy of `IkaIntents`' table
/// (CONTRIBUTING); without it, a widget's or a complication's editor, Shortcuts and Control Center
/// show the English keys in every language. Read from the built products.
struct IntentTablesTests {
  @Test(arguments: GameLanguage.allCases)
  func `Every host bundle names IkaIntents' types in every language`(language: GameLanguage) throws {
    for host in try Self.hosts() {
      for name in Self.names {
        #expect(
          host.localizedString(forKey: name.key, in: language) == Self.resolve(name, in: language),
          "\(host.bundleURL.lastPathComponent): \(name.key)")
      }
    }
  }

  /// The names the system shows from `IkaIntents`' table: the parameter types and their values,
  /// and on iOS the start-Tracking intent's title, which the control's name and configuration
  /// read too.
  static private var names: [LocalizedStringResource] {
    var names: [LocalizedStringResource] = [
      ModeParameter.typeDisplayRepresentation.name,
      BattleModeParameter.typeDisplayRepresentation.name,
      RuleParameter.typeDisplayRepresentation.name,
    ]
    names += ModeParameter.allCases.compactMap { ModeParameter.caseDisplayRepresentations[$0]?.title }
    names += BattleModeParameter.allCases.compactMap { BattleModeParameter.caseDisplayRepresentations[$0]?.title }
    names += RuleParameter.allCases.compactMap { RuleParameter.caseDisplayRepresentations[$0]?.title }
    #if os(iOS)
    names.append(StartTrackingIntent.title)
    #endif
    return names
  }

  /// The app, its widget extension and, on iOS, the watch widget extension inside the watch app it
  /// embeds.
  static private func hosts() throws -> [Bundle] {
    let plugIns = try #require(Bundle.main.builtInPlugInsURL)
    var urls: [URL] = [Bundle.main.bundleURL, plugIns.appending(path: "Ikalendar3Widgets.appex")]
    #if os(iOS)
    urls.append(Bundle.main.bundleURL.appending(path: "Watch/Ikalendar3Watch.app/PlugIns/Ikalendar3WatchWidgets.appex"))
    #endif
    return try urls.map { url in try #require(Bundle(url: url), "\(url.lastPathComponent)") }
  }

  /// `name` as `IkaIntents`' own table writes it in a text set.
  static private func resolve(_ name: LocalizedStringResource, in language: GameLanguage) -> String {
    var name = name
    name.locale = Locale(identifier: language.localization)
    return String(localized: name)
  }
}
