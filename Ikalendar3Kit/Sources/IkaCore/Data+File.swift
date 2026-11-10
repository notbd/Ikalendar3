//
//  Data+File.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

extension Data {
  /// The contents of a local file: a cache record, a bundled resource or the stored art.
  ///
  /// The one reader that takes a URL: `Data(contentsOf:)` and its kind load an `https` URL too,
  /// so shipped code reads through this one, which `scripts/check-hosts.sh` checks.
  ///
  /// - Throws: `CocoaError(.fileReadUnsupportedScheme)` for any URL that is not a file's, without
  ///   reading it, or the read's error, such as `CocoaError(.fileReadNoSuchFile)`.
  public init(readingFile url: URL) throws {
    guard url.isFileURL else { throw CocoaError(.fileReadUnsupportedScheme) }

    try self.init(contentsOf: url)
  }
}
