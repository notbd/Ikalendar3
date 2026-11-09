//
//  Logger+IkaCore.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import OSLog

/// `IkaCore`'s loggers, one per concern, under the bundle id of the process that runs it.
/// View in Console.app or `log stream` filtered by that bundle id.
extension Logger {
  static private let subsystem = Bundle.main.bundleIdentifier ?? "ikalendar3"

  /// Decoding: the feed parts that failed, with the underlying `DecodingError`.
  static let decode: Logger = .init(subsystem: subsystem, category: "decode")
}
