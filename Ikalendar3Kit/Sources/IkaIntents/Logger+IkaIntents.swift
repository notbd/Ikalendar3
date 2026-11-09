//
//  Logger+IkaIntents.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import OSLog

/// `IkaIntents`' loggers, one per concern, under the bundle id of the process that runs it.
/// View in Console.app or `log stream` filtered by that bundle id.
extension Logger {
  static private let subsystem = Bundle.main.bundleIdentifier ?? "ikalendar3"

  /// Background refresh: each run asked of the system (at info level), and requests it refused.
  static let background: Logger = .init(subsystem: subsystem, category: "background")

  /// Tracking: each Live Activity started, updated and ended, at info level.
  static let tracking: Logger = .init(subsystem: subsystem, category: "tracking")

  /// Intents: each run of a Siri intent, naming the process that runs it, at notice level, so
  /// the line stays in the log store.
  static let intents: Logger = .init(subsystem: subsystem, category: "intents")

  /// Logs that an intent of `type` runs, and in which process: the app's, or another the system
  /// picked.
  static func logRun(of type: Any.Type) {
    intents
      .notice(
        "\(String(describing: type), privacy: .public) ran in \(ProcessInfo.processInfo.processName, privacy: .public)")
  }
}
