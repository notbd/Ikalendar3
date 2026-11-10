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

  /// Network: each request's status (at info level), requests with no answer and answers the
  /// client cannot use.
  static let network: Logger = .init(subsystem: subsystem, category: "network")

  /// Store: cache writes and removals that failed, and a missing App Group container.
  static let store: Logger = .init(subsystem: subsystem, category: "store")
}
