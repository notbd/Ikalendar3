//
//  TestDefaults.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Testing

/// A fresh `UserDefaults` suite for one test, so parallel tests never share state. The suite and
/// its file are deleted when the holder goes away: keep the holder in a stored property of the
/// test suite, which Swift Testing creates for each test and releases when the test ends. Never
/// touch `.standard` in tests.
final class TestDefaults {
  let name = "ikalendar3-tests-\(UUID().uuidString)"
  let defaults: UserDefaults

  init() throws {
    defaults = try #require(UserDefaults(suiteName: name))
  }

  deinit {
    // Removing the domain empties it but leaves its file behind.
    defaults.removePersistentDomain(forName: name)
    try? FileManager.default.removeItem(at: URL.libraryDirectory.appending(path: "Preferences/\(name).plist"))
  }
}
