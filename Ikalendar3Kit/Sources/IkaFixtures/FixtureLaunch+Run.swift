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

      return try launch.prepare(sharedCache: sharedCache, now: now)
    }
    catch {
      fatalError("Fixture launch: \(error)")
    }
  }
}
#endif
