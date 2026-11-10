//
//  WatchDebugLaunch.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if DEBUG
import Foundation
import IkaCore
import IkaFixtures
import SwiftUI

// MARK: - WatchDebugLaunch

/// The launch options only the watch app's Debug builds read, besides the fixture launch it takes
/// as the app does (`FixtureLaunch.run(sharedCache:)`). CONTRIBUTING.md shows how to pass them.
///
/// - `--scroll-anchor top|center|bottom`: where the Now page starts scrolled, so a fixture launch
///   can screenshot every row of a page taller than the screen. The watch simulator takes no
///   scroll input from the command line.
/// - `--mode-page <Mode>`: opens that Mode's page over the Now page, by the Mode parameter's raw
///   value (`regularBattle`, `anarchySeries`, `anarchyOpen`, `xBattle` or `salmonRun`), and with
///   `--later-list` its later Rotations or Shifts too, so a fixture launch can screenshot pages
///   the simulator cannot tap to.
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

  /// The pages the launch opens over the Now page: none, a Mode's page, or its page and its later
  /// list.
  static func openPages(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> [WatchRoute] {
    let arguments: LaunchArguments = .init(arguments)
    let option = "--mode-page"
    guard arguments.contains(option) else {
      if arguments.contains("--later-list") { fatalError("--later-list goes with --mode-page") }
      return []
    }
    guard let name = arguments.value(of: option), let mode = modes[name] else {
      fatalError("\(option) takes a Mode parameter's raw value, such as regularBattle or salmonRun")
    }

    return arguments.contains("--later-list") ? [.modePages(mode), .later(mode)] : [.modePages(mode)]
  }

  /// The Modes by the Mode parameter's raw values, which the watch app does not link.
  static private let modes: [String: Mode] = [
    "regularBattle": .battle(.regular),
    "anarchySeries": .battle(.anarchySeries),
    "anarchyOpen": .battle(.anarchyOpen),
    "xBattle": .battle(.x),
    "salmonRun": .salmonRun,
  ]
}
#endif
