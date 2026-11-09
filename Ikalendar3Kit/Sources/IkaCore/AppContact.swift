//
//  AppContact.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - AppContact

/// Where the app and its developer are reached: what every request's `User-Agent` names and what
/// About links to (ADR 0004).
public enum AppContact {
  /// The app's website. A fixed literal, so it always parses.
  static public let website: URL = .init(string: "https://ikalendar.app/3")!
  /// The developer's address for feedback and support.
  static public let email = "ikalendar3@tianwei.io"
}
