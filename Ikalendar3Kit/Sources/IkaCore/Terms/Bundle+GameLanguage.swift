//
//  Bundle+GameLanguage.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

extension Bundle {
  /// A string of this bundle's string catalog in one of the 14 text sets. Package modules look
  /// their own strings up with it (`Bundle.module`), in the language the process passes in, so
  /// UI strings and game terms never disagree. The process's own locale is never read.
  ///
  /// - Returns: The key when the bundle has no localization for the text set or no such key.
  ///   The catalog check in `scripts/verify.sh` keeps every key in all 14.
  public func localizedString(forKey key: String, table: String? = nil, in language: GameLanguage) -> String {
    guard
      let path = path(forResource: language.localization, ofType: "lproj"),
      let localization = Bundle(path: path)
    else { return key }

    return localization.localizedString(forKey: key, value: nil, table: table)
  }
}
