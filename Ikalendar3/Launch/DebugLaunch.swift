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
import IkaIntents

// MARK: - DebugLaunch

/// The launch options only Debug builds read. CONTRIBUTING.md shows how to pass them.
///
/// - The fixture launch (`FixtureLaunch`, in the fixture support module the watch app shares):
///   `--fixture <name> --fixture-folder <path> --fixture-instant <ISO 8601> [--fixture-rebase]
///   [--fixture-short-tracking <Mode>]`.
/// - The worktree data option: `--data-folder <path> --defaults-suite <name>`. An unsigned Mac
///   run gets the App Group folder every worktree on the machine shares, so each Mac run from a
///   worktree passes a folder inside it and a suite named after it. It is an explicit option,
///   never a fallback.
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

  #if os(iOS)
  /// Restarts the short-item Tracking the fixture launch asks for (`--fixture-short-tracking`),
  /// right after an activation run, which re-armed every activity from the cache: the content of
  /// the Mode at the app clock's `instant`, its items two minutes long from now on the wall clock
  /// the system renders by. So a recording that starts after the app opens crosses two
  /// boundaries in four minutes; opening the app again starts it over.
  static func restartShortTracking(
    after result: RefreshResult,
    with effects: EffectsShell,
    at instant: Date,
    _ arguments: [String] = ProcessInfo.processInfo.arguments)
    async
  {
    guard
      let mode = (try? FixtureLaunch(arguments: arguments))?.shortTracking,
      let state = result.snapshot.trackingState(of: mode, at: instant)
    else { return }

    let now: Date = .init()
    do {
      let short: TrackingState = .init(
        content: state.content.withShortItems(startingAt: now),
        fetchTime: state.fetchTime)
      try await effects.startTracking(short, at: now)
    }
    catch {
      fatalError("Short-item Tracking: \(error)")
    }
  }
  #endif
}
#endif
