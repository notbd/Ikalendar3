//
//  TermTable+Shipped.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import OSLog
import Synchronization

extension TermTable {
  /// The locale file of a text set that ships in `IkaCore`, decoded once per process and kept.
  ///
  /// The 14 files in `Resources/LocaleSnapshot` are `https://splatoon3.ink/data/locale/<code>.json`
  /// byte for byte, downloaded 2026-11-09 10:41 UTC (en-US, en-GB and ja-JP last modified
  /// 2026-11-09 10:30 UTC, the other 11 on 2026-11-07 08:05 UTC).
  static func shipped(in language: GameLanguage) -> TermTable {
    if let table = shippedTables.withLock({ $0[language] }) { return table }

    let table = loadShipped(language)
    shippedTables.withLock { $0[language] = table }
    return table
  }

  /// The shipped tables decoded so far.
  static private let shippedTables: Mutex<[GameLanguage: TermTable]> = .init([:])

  /// Decodes a shipped locale file. Empty, with a fault logged, if the file is missing or does
  /// not decode: lookup then falls back to the feed's English names.
  static private func loadShipped(_ language: GameLanguage) -> TermTable {
    do {
      guard let url = Bundle.module.url(forResource: language.rawValue, withExtension: "json") else {
        throw CocoaError(.fileNoSuchFile)
      }

      return try TermTable(localeFile: Data(readingFile: url))
    }
    catch {
      Logger.decode.fault("shipped locale \(language.rawValue, privacy: .public): \(error, privacy: .public)")
      return TermTable()
    }
  }
}
