//
//  AppServices.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import IkaDesign
import IkaIntents
import SwiftUI
#if DEBUG
import IkaFixtures
#endif

// MARK: - AppServices

/// The app's long-lived objects, built once per launch by the composition root.
struct AppServices {
  /// The one refresh engine, whose snapshot every screen shows.
  let engine: RefreshEngine
  /// The one effects shell, which every refresh in the app runs: activation, pull to refresh and
  /// the background task.
  let effects: EffectsShell
  /// The player's preferences.
  let preferences: PreferenceStore
  /// The one clock the screens read.
  let clock: AppClock
  /// The in-session state.
  let status: AppStatus
  #if DEBUG
  /// The time zone a fixture launch writes times in, or `nil` for the device's.
  private(set) var timeZone: TimeZone?
  #endif

  /// The engine with its effects shell, the preferences on `defaults`, a clock reading
  /// `timeSource` and the status, opening on the default Mode.
  init(client: FeedClient, timeSource: any TimeSource, defaults: UserDefaults) {
    let engine: RefreshEngine = .init(client: client, language: Self.language)
    let preferences: PreferenceStore = .init(defaults: defaults)
    self.engine = engine
    effects = EffectsShell(engine: engine, preferences: preferences)
    self.preferences = preferences
    clock = AppClock(source: timeSource)
    status = AppStatus(selectedPlace: preferences.defaultMode)
  }
}

extension AppServices {
  /// The app language, resolved for the app bundle. Every target declares the same 14
  /// localizations, so the widget extension resolves the same one.
  static let language: GameLanguage = .init(resolvedFor: .main)

  /// Whether the process hosts the app's unit tests, which need a live process and no UI.
  static let isTestHost: Bool = {
    let environment = ProcessInfo.processInfo.environment
    return environment["XCTestConfigurationFilePath"] != nil || environment["XCTestSessionIdentifier"] != nil
  }()

  /// The services this launch asks for.
  ///
  /// - A unit-test host gets an inert transport and storage of its own, wiped on every launch.
  /// - A Debug launch may run on recorded payloads (`FixtureLaunch`), with no network
  ///   (`DebugLaunch.isOffline`), or keep its data in a worktree's folder and suite (`DebugLaunch`).
  /// - Any other launch keeps its data in the App Group, shared with the widget extension. With no
  ///   App Group container it has no services: the error is logged, and no other folder is used.
  static func forThisLaunch() -> AppServices? {
    if isTestHost { return testHost() }

    #if DEBUG
    let storage = DebugLaunch.worktreeStorage() ?? SharedStorage.appGroup()
    #else
    let storage: SharedStorage? = .appGroup()
    #endif
    guard let storage else { return nil }

    #if DEBUG
    if let run = FixtureLaunch.run(sharedCache: FeedCache(directory: storage.feedDirectory)) {
      var services: AppServices = .init(client: run.client, timeSource: run.timeSource, defaults: storage.defaults)
      services.timeZone = run.timeZone
      return services
    }
    if DebugLaunch.isOffline() {
      return AppServices(
        client: FeedClient(transport: ScriptedTransport(), cache: FeedCache(directory: storage.feedDirectory)),
        timeSource: SystemTimeSource(),
        defaults: storage.defaults)
    }
    #endif

    return AppServices(
      client: FeedClient(transport: URLSessionTransport(), cache: FeedCache(directory: storage.feedDirectory)),
      timeSource: SystemTimeSource(),
      defaults: storage.defaults)
  }

  /// The unit-test host's services, as ikalendar 2 builds them: every request fails at once, and
  /// the cache and preferences live in a throwaway folder and suite, so the host never touches
  /// the network or the simulator's real data.
  static private func testHost() -> AppServices {
    let suiteName = "ikalendar3-test-host"
    let defaults: UserDefaults = .init(suiteName: suiteName) ?? .standard
    defaults.removePersistentDomain(forName: suiteName)
    let directory = FileManager.default.temporaryDirectory.appending(path: suiteName, directoryHint: .isDirectory)
    try? FileManager.default.removeItem(at: directory)
    return AppServices(
      client: FeedClient(transport: InertTransport(), cache: FeedCache(directory: directory)),
      timeSource: SystemTimeSource(),
      defaults: defaults)
  }
}

// MARK: - Environment

extension View {
  /// Injects the services and the app language, which picks every string, game term and Han
  /// face. In Debug, a fixture launch's time zone replaces SwiftUI's; nothing else sets it.
  func environment(_ services: AppServices) -> some View {
    environment(services.engine)
      .environment(\.effects, services.effects)
      .environment(services.preferences)
      .environment(services.clock)
      .environment(services.status)
      .environment(\.gameLanguage, AppServices.language)
      #if DEBUG
      .transformEnvironment(\.timeZone) { zone in
        if let fixtureZone = services.timeZone { zone = fixtureZone }
      }
      #endif
  }
}

extension EnvironmentValues {
  /// The effects shell, which every refresh control runs; `nil` only where no services are
  /// injected.
  @Entry var effects: EffectsShell?
}

// MARK: - SharedStorage

/// Where a launch keeps what every process on the device reads: the feed cache with its attempt
/// records, and the preferences.
struct SharedStorage {
  /// The folder of the feed cache and its attempt records.
  let feedDirectory: URL
  /// The preferences suite.
  let defaults: UserDefaults

  /// The App Group's container and suite, or `nil` when the process has no container
  /// (`AppGroup.container()` logs it).
  static func appGroup() -> SharedStorage? {
    guard let container = AppGroup.container(), let defaults = UserDefaults(suiteName: AppGroup.identifier) else {
      return nil
    }

    return SharedStorage(feedDirectory: AppGroup.feedDirectory(in: container), defaults: defaults)
  }
}

// MARK: - InertTransport

/// The unit-test host's transport: every request fails at once.
nonisolated struct InertTransport: HTTPTransport {
  @concurrent
  func send(_: URLRequest) async throws -> HTTPResponse {
    throw URLError(.notConnectedToInternet)
  }
}
