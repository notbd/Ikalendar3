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
}
