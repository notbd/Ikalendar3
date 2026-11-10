//
//  FixtureLaunch+Run.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if DEBUG
import Foundation
import IkaCore

extension FixtureLaunch {
  /// The run a process's launch arguments ask for, or `nil` when they ask for none: what the app
  /// and the watch app each call at start, in Debug builds.
  ///
  /// With a time zone, the run's zone becomes the process's default (`NSTimeZone.default`); each
  /// root hands it to SwiftUI's environment too, whose zone does not follow the default.
  ///
  /// A launch whose options are missing or malformed, or whose payloads cannot be read, stops with
  /// the reason: a launch that asked for test data never falls back to the network or the shared
  /// cache.
  ///
  /// - Parameter sharedCache: Where a rebased launch commits its payloads.
  static public func run(
    sharedCache: FeedCache,
    arguments: [String] = ProcessInfo.processInfo.arguments,
    now: Date = Date())
    -> FixtureRun?
  {
    do {
      guard let launch = try FixtureLaunch(arguments: arguments) else { return nil }

      let run = try launch.prepare(sharedCache: sharedCache, now: now)
      // Formatters that read the current zone; each root also hands it to SwiftUI's environment.
      if let zone = run.timeZone { NSTimeZone.default = zone }
      return run
    }
    catch {
      fatalError("Fixture launch: \(error)")
    }
  }
}
#endif
