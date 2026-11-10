//
//  WatchServices.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import SwiftUI
#if DEBUG
import IkaFixtures
#endif

// MARK: - WatchServices

/// The watch app's long-lived objects, built once per launch by the composition root.
///
/// The watch fetches on its own, so it works without its iPhone: its own refresh engine on the
/// watch's App Group container, which its widget extension reads, with the attempt records in the
/// same folder, under the same hourly gate and back-off and with the same `User-Agent` as the app.
struct WatchServices {
  /// The one refresh engine, whose snapshot every page shows.
  let engine: RefreshEngine
  /// The one effects shell, which every refresh on the watch runs: activation and the background
  /// task.
  let effects: WatchEffectsShell
  /// The one clock the pages read.
  let clock: AppClock
  /// The time zone a fixture launch writes times in, or `nil` for the device's.
  let timeZone: TimeZone?

  /// The engine with its effects shell, and a clock reading `timeSource`, writing times in
  /// `timeZone`.
  init(client: FeedClient, timeSource: any TimeSource, timeZone: TimeZone? = nil) {
    let engine: RefreshEngine = .init(client: client, language: Self.language)
    self.engine = engine
    effects = WatchEffectsShell(engine: engine)
    clock = AppClock(source: timeSource)
    self.timeZone = timeZone
  }
}

extension WatchServices {
  /// The app language, resolved for the watch app's bundle. Every target declares the same 14
  /// localizations, so the watch widget extension resolves the same one.
  static let language: GameLanguage = .init(resolvedFor: .main)

  /// The services this launch asks for.
  ///
  /// - A Debug launch may run on recorded payloads (`FixtureLaunch`), with the app's options.
  /// - Any other launch keeps its data in the watch's App Group container. With no container it
  ///   has no services: the error is logged, and no other folder is used.
  static func forThisLaunch() -> WatchServices? {
    guard let container = AppGroup.container() else { return nil }

    let cache: FeedCache = .init(directory: AppGroup.feedDirectory(in: container))

    #if DEBUG
    if let run = FixtureLaunch.run(sharedCache: cache) {
      return WatchServices(client: run.client, timeSource: run.timeSource, timeZone: run.timeZone)
    }
    #endif

    return WatchServices(
      client: FeedClient(transport: URLSessionTransport(), cache: cache),
      timeSource: SystemTimeSource())
  }
}

// MARK: - Environment

extension View {
  /// Injects the engine and the clock the pages read, and a fixture launch's time zone.
  func environment(_ services: WatchServices) -> some View {
    environment(services.engine)
      .environment(services.clock)
      .environment(\.timeZone, services.timeZone ?? .autoupdatingCurrent)
  }
}
