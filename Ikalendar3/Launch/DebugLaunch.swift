//
//  DebugLaunch.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if DEBUG
import Foundation
import IkaCore
import IkaFixtures

// MARK: - DebugLaunch

/// The launch options only Debug builds read. CONTRIBUTING.md shows how to pass them.
///
/// - The fixture launch (`FixtureLaunch`, in the fixture support module the watch app shares):
///   `--fixture <name> --fixture-folder <path> --fixture-instant <ISO 8601> [--fixture-rebase]`.
/// - The worktree data option: `--data-folder <path> --defaults-suite <name>`. An unsigned Mac
///   run gets the App Group folder every worktree on the machine shares, so each Mac run from a
///   worktree passes a folder inside it and a suite named after it. It is an explicit option,
///   never a fallback.
/// - The event card gallery: `--event-cards` shows every event card at the app clock's instant
///   instead of the tabs, for screenshots until the iPad event strip shows them.
///
/// A malformed option stops the launch with its reason: a launch that asked for test data never
/// falls back to the network or the shared folder.
enum DebugLaunch {
  /// The worktree's folder and suite, or `nil` when the launch names none.
  static func worktreeStorage(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> SharedStorage? {
    let arguments: LaunchArguments = .init(arguments)
    let folder = arguments.value(of: "--data-folder")
    let suite = arguments.value(of: "--defaults-suite")
    guard folder != nil || suite != nil else { return nil }
    guard let folder, let suite, let defaults = UserDefaults(suiteName: suite) else {
      fatalError("--data-folder and --defaults-suite go together, each with a value")
    }

    return SharedStorage(feedDirectory: URL(filePath: folder, directoryHint: .isDirectory), defaults: defaults)
  }

  /// Whether the launch asks for the event card gallery instead of the tabs.
  static func showsEventCards(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
    LaunchArguments(arguments).contains("--event-cards")
  }

  /// The run of the fixture launch the arguments ask for, or `nil` when they ask for none.
  ///
  /// - Parameter sharedCache: Where a rebased launch commits its payloads.
  static func fixtureRun(
    sharedCache: FeedCache,
    _ arguments: [String] = ProcessInfo.processInfo.arguments)
    -> FixtureRun?
  {
    do {
      guard let launch = try FixtureLaunch(arguments: arguments) else { return nil }

      return try launch.prepare(sharedCache: sharedCache, now: Date())
    }
    catch {
      fatalError("Fixture launch: \(error)")
    }
  }
}
#endif
