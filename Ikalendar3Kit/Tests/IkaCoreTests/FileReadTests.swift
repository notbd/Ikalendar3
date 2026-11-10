//
//  FileReadTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Testing
@testable import IkaCore

// MARK: - FileReadTests

/// Pins that the one reader shipped code reads through a URL with reads only files: any other URL
/// is refused before it is read, so no reader can fetch from the network.
struct FileReadTests {
  @Test
  func `A file's contents are read`() throws {
    let directory = try makeTestDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let file = directory.appending(path: "record")
    try Data("stored".utf8).write(to: file)

    #expect(try Data(readingFile: file) == Data("stored".utf8))
  }

  /// A `data:` URL is one Foundation reads without the network, so the test sends nothing even
  /// where the reader fails to refuse it.
  @Test
  func `A URL that is not a file's is refused, not read`() throws {
    let url = try #require(URL(string: "data:,remote"))

    #expect(throws: CocoaError(.fileReadUnsupportedScheme)) {
      try Data(readingFile: url)
    }
  }
}
