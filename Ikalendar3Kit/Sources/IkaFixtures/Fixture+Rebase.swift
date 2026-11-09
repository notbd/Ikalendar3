//
//  Fixture+Rebase.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

extension Fixture {
  /// A payload with every time moved by `offset` and every other byte kept.
  ///
  /// A time is a JSON string that is a whole UTC instant as splatoon3.ink writes it
  /// (`"2026-10-20T12:00:00Z"`, fractional seconds kept as they are). The offset counts in whole
  /// seconds, toward zero. A rebased payload makes the fixture's day the day the offset leads to,
  /// so the Surfaces the system renders on its own clock (widgets, the Live Activity) show it. A
  /// payload that is not UTF-8 text is returned as it is.
  static public func rebase(_ payload: Data, by offset: Duration) -> Data {
    let seconds: TimeInterval = .init(offset.components.seconds)
    guard let text = String(bytes: payload, encoding: .utf8) else { return payload }

    // A JSON string holding only a UTC instant, captured as its whole seconds and its fraction.
    let rebased = text.replacing(/"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})(\.\d+)?Z"/) { match in
      let (_, wholeSeconds, fraction) = match.output
      guard let time = try? Date(String(wholeSeconds) + "Z", strategy: .iso8601) else { return String(match.output.0) }

      let moved = time.addingTimeInterval(seconds).formatted(.iso8601).dropLast() // "Z"
      return "\"\(moved)\(fraction ?? "")Z\""
    }
    return Data(rebased.utf8)
  }
}
