//
//  FontRegistryTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreText
import Foundation
import OSLog
import Testing
@testable import IkaDesign

/// Pins registration from a font folder with no SplatNet 3 font files, as on CI and in fresh clones:
/// it succeeds, registers nothing and says so in the log.
struct FontRegistryTests {
  /// A new empty folder, removed after `body`.
  private func withTemporaryFolder(_ body: (URL) throws -> Void) throws {
    let folder: URL = FileManager.default
      .temporaryDirectory
      .appending(path: "FontRegistryTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    try body(folder)
  }

  /// The messages this process logged to the font category since `start`.
  private func fontLog(since start: Date) throws -> [String] {
    let store: OSLogStore = try .init(scope: .currentProcessIdentifier)
    return try store.getEntries(at: store.position(date: start))
      .compactMap { $0 as? OSLogEntryLog }
      .filter { $0.category == "fonts" }
      .map(\.composedMessage)
  }

  @Test
  func `An empty folder registers no face and logs it`() throws {
    try withTemporaryFolder { folder in
      let start: Date = .now

      let registered: Set<FontFace> = FontRegistry.register(from: folder)

      #expect(registered.isEmpty)
      let log: [String] = try fontLog(since: start)
      #expect(log.contains { $0.contains("No font face registered from \(folder.path)") })
    }
  }

  @Test
  func `A missing folder registers no face and logs it`() throws {
    let folder: URL = FileManager.default.temporaryDirectory.appending(path: "FontRegistryTests-missing-\(UUID())")
    let start: Date = .now

    let registered: Set<FontFace> = FontRegistry.register(from: folder)

    #expect(registered.isEmpty)
    let log: [String] = try fontLog(since: start)
    #expect(log.contains { $0.contains("No font face registered from \(folder.path)") })
  }

  @Test
  func `A file whose PostScript name is not its face's is not registered`() throws {
    let systemFont: CTFont = try #require(CTFontCreateUIFontForLanguage(.system, 12, nil))
    let systemFontURL: URL = try #require(CTFontCopyAttribute(systemFont, kCTFontURLAttribute) as? URL)

    try withTemporaryFolder { folder in
      try FileManager.default.copyItem(at: systemFontURL, to: folder.appending(path: "Splatoon1.ttf"))
      let start: Date = .now

      let registered: Set<FontFace> = FontRegistry.register(from: folder)

      #expect(registered.isEmpty)
      let log: [String] = try fontLog(since: start)
      #expect(log.contains { $0.contains("Splatoon1.ttf is not the face Splatoon1") })
    }
  }
}
