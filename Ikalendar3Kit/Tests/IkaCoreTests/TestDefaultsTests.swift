//
//  TestDefaultsTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Testing

struct TestDefaultsTests {
  @Test
  func `A test's suite and its file are deleted when the holder goes away`() throws {
    var holder: TestDefaults? = try TestDefaults()
    let name = try #require(holder).name
    try #require(holder).defaults.set(true, forKey: "written")

    holder = nil

    #expect(UserDefaults(suiteName: name)?.object(forKey: "written") == nil)
    let file = URL.libraryDirectory.appending(path: "Preferences/\(name).plist")
    #expect(!FileManager.default.fileExists(atPath: file.path(percentEncoded: false)))
  }
}
