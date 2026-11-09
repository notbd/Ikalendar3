//
//  TestDirectory.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

/// A new empty directory for one test, standing in for the App Group container. Parallel tests
/// never share one. The suite that makes it removes it in `deinit`.
func makeTestDirectory() throws -> URL {
  let url = FileManager.default
    .temporaryDirectory
    .appending(path: "ikalendar3-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
  try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  return url
}
