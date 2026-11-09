//
//  AppGroup.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import OSLog

// MARK: - AppGroup

/// The App Group the app and its widget extension share on iPhone, iPad and Mac, and the watch
/// app and its widget extension share on the watch: one container per device. It holds the feed
/// cache and the preferences that every process on that device reads.
public enum AppGroup {
  /// The group's identifier, derived from the bundle identifier `io.tianwei.ikalendar3`. Every
  /// target's entitlements list the same value. It also names the preferences suite.
  static public let identifier = "group.io.tianwei.ikalendar3"

  /// The group's container, or `nil`, logged as an error, when the process lacks the App Group
  /// entitlement, as an unsigned simulator build does. Callers never fall back to a folder of
  /// their own: the other processes on the device could not see it.
  static public func container() -> URL? {
    guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
      Logger.store
        .error("No App Group container for \(identifier, privacy: .public): the process lacks the entitlement")
      return nil
    }

    return url
  }

  /// Where the feed cache and its attempt records live in a container.
  static public func feedDirectory(in container: URL) -> URL {
    container.appending(path: "Library/Application Support/Feeds", directoryHint: .isDirectory)
  }
}
