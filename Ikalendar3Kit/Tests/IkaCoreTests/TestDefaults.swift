//
//  TestDefaults.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Testing

/// A fresh `UserDefaults` suite for one test, so parallel tests never share state.
/// Never touch `.standard` in tests.
func makeTestDefaults() throws -> UserDefaults {
  try #require(UserDefaults(suiteName: "ikalendar3-tests-\(UUID().uuidString)"))
}
