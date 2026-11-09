//
//  Date+Literal.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

/// Parses an ISO 8601 UTC time the way the feed writes it, for the package tests' literals: a
/// malformed one stops the test at once.
public func date(_ string: String) -> Date {
  // swiftlint:disable:next force_try
  try! Date(string, strategy: .iso8601)
}
