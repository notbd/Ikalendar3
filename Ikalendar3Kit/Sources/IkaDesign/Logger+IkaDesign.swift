//
//  Logger+IkaDesign.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import OSLog

/// `IkaDesign`'s loggers, one per concern, under the bundle id of the process that runs it.
/// View in Console.app or `log stream` filtered by that bundle id.
extension Logger {
  static private let subsystem = Bundle.main.bundleIdentifier ?? "ikalendar3"

  /// Fonts: where each process registered faces from, and which ones.
  static let fonts: Logger = .init(subsystem: subsystem, category: "fonts")
}
