//
//  WatchDebugLaunch.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if DEBUG
import Foundation
import IkaFixtures
import SwiftUI

// MARK: - WatchDebugLaunch

/// The launch options only the watch app's Debug builds read, besides the fixture launch it takes
/// as the app does (`FixtureLaunch.run(sharedCache:)`). CONTRIBUTING.md shows how to pass them.
///
/// - `--scroll-anchor top|center|bottom`: where the Now page starts scrolled, so a fixture launch
///   can screenshot every row of a page taller than the screen. The watch simulator takes no
///   scroll input from the command line.
///
/// A malformed option stops the launch with its reason.
enum WatchDebugLaunch {
  /// Where the Now page starts scrolled, or `nil` when the launch names nowhere.
  static func scrollAnchor(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> UnitPoint? {
    switch LaunchArguments(arguments).value(of: "--scroll-anchor") {
      case nil: nil
      case "top": .top
      case "center": .center
      case "bottom": .bottom
      case let value?: fatalError("--scroll-anchor takes top, center or bottom, not \(value)")
    }
  }
}
#endif
