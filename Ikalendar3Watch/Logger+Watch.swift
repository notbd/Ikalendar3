//
//  Logger+Watch.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import OSLog

/// The watch app's loggers, one per concern, under its bundle id. View in Console.app or
/// `log stream` filtered by that bundle id.
extension Logger {
  nonisolated static private let subsystem = Bundle.main.bundleIdentifier ?? "ikalendar3"

  /// Background refresh: each run asked of the system (at info level), and requests it refused.
  nonisolated static let background: Logger = .init(subsystem: subsystem, category: "background")
}
