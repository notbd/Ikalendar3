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
/// - The fixture launch, which the watch app takes too, so it lives in the fixture support module
///   (`FixtureLaunch.run(sharedCache:)`):
///   `--fixture <name> --fixture-folder <path> --fixture-instant <ISO 8601> [--fixture-rebase]`.
/// - The worktree data option: `--data-folder <path> --defaults-suite <name>`. An unsigned Mac
///   run gets the App Group folder every worktree on the machine shares, so each Mac run from a
///   worktree passes a folder inside it and a suite named after it. It is an explicit option,
///   never a fallback.
/// - The offline launch: `--fixture-offline` answers every request as if the network were gone
///   (the scripted transport with nothing scripted), so with the worktree data option naming a new
///   folder and suite it shows the first launch with no network and no cache.
/// - The event card gallery: `--event-cards` shows every event card at the app clock's instant
///   instead of the tabs, for screenshots of each card at an iPhone's width.
/// - The short-item Tracking, on iOS: `--fixture-short-tracking <Mode>` Tracks the Mode with
///   items two minutes long after each activation run (`restartShortTracking(with:)`).
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

  /// Whether the launch asks that every request fail as with no network.
  static func isOffline(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
    LaunchArguments(arguments).contains("--fixture-offline")
  }

  /// Whether the launch asks for the event card gallery instead of the tabs.
  static func showsEventCards(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
    LaunchArguments(arguments).contains("--event-cards")
  }

  #if os(iOS)
  /// The Mode the short-item Tracking follows, by the Mode parameter's raw value, or `nil` when
  /// the launch names none.
  static func shortTracking(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> Mode? {
    let option = "--fixture-short-tracking"
    let arguments: LaunchArguments = .init(arguments)
    guard arguments.contains(option) else { return nil }
    guard let name = arguments.value(of: option), let parameter = ModeParameter(rawValue: name) else {
      fatalError("\(option) takes a Mode parameter's raw value, such as regularBattle or salmonRun")
    }

    return parameter.mode
  }

  /// Restarts the short-item Tracking the launch asks for (`shortTracking`), right after an
  /// activation run, which re-armed every activity from the cache: the content of the Mode in the
  /// snapshot that run published, at the app clock's instant, its items two minutes long from now
  /// on the wall clock the system renders by. So a recording that starts after the app opens
  /// crosses two boundaries in four minutes; opening the app again starts it over.
  static func restartShortTracking(
    with services: AppServices,
    _ arguments: [String] = ProcessInfo.processInfo.arguments) async
  {
    guard
      let mode = shortTracking(arguments),
      let state = services.engine.snapshot.trackingState(of: mode, at: services.clock.now)
    else { return }

    let now: Date = .init()
    do {
      let short: TrackingState = .init(
        content: state.content.withShortItems(startingAt: now),
        fetchTime: state.fetchTime)
      try await services.effects.startTracking(short, at: now)
    }
    catch {
      fatalError("Short-item Tracking: \(error)")
    }
  }
  #endif
}
#endif
