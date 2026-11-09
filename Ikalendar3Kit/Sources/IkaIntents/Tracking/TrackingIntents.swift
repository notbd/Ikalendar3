//
//  TrackingIntents.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import AppIntents
import Foundation
import IkaCore

// MARK: - StartTrackingIntent

/// Starts Tracking a Mode, for Siri, the Control Center control and the app's track button. A
/// Live Activity intent, so the system runs it in the app's process and it starts the activity
/// with the app in the background.
public struct StartTrackingIntent: LiveActivityIntent {
  static public let title: LocalizedStringResource = .init("Start Tracking", bundle: #bundle)

  @Parameter(title: LocalizedStringResource("Mode", bundle: #bundle))
  public var mode: ModeParameter

  public init() { }

  public init(mode: ModeParameter) {
    self.mode = mode
  }

  @MainActor
  public func perform() async throws -> some IntentResult {
    try await EffectsShell.forIntents().startTracking(mode.mode)
    return .result()
  }
}

// MARK: - RefreshTrackingIntent

/// The Live Activity's Refresh button: a run of the effects shell, which refreshes under the
/// hourly gate and re-arms every running Tracking from the cache, with no download while the gate
/// is closed. Offered only on the activity, never in Shortcuts.
public struct RefreshTrackingIntent: LiveActivityIntent {
  static public let title: LocalizedStringResource = .init("Refresh", bundle: #bundle)
  static public let isDiscoverable = false

  public init() { }

  @MainActor
  public func perform() async throws -> some IntentResult {
    try await EffectsShell.forIntents().run()
    return .result()
  }
}

// MARK: - EffectsShell

extension EffectsShell {
  /// The shell an intent runs: an engine of its own on the App Group cache, which it shares with
  /// the app and every other engine through the gate's attempt records, in the app language. No
  /// runtime registration: an intent builds it each time it runs.
  ///
  /// - Throws: `TrackingError.noSchedule` with no App Group container (logged by `AppGroup`),
  ///   where no cache can hold a schedule.
  static func forIntents() throws -> EffectsShell {
    guard let container = AppGroup.container() else { throw TrackingError.noSchedule }

    let client: FeedClient = .init(
      transport: URLSessionTransport(),
      cache: FeedCache(directory: AppGroup.feedDirectory(in: container)))
    return EffectsShell(engine: RefreshEngine(client: client, language: GameLanguage(resolvedFor: .main)))
  }
}

// MARK: - TrackingText

/// The words of Tracking's buttons in a text set: the intents' titles, from this module's
/// string catalog, so a button reads as the intent it runs. The Refresh button's word is the one
/// `TrackingReminder`'s phrases tell the player to tap.
public enum TrackingText: String, CaseIterable, Sendable {
  /// "Start Tracking": the app's track button.
  case startTracking = "Start Tracking"
  /// "Refresh": the Live Activity's Refresh button.
  case refresh = "Refresh"

  /// The word in a text set.
  public func text(in language: GameLanguage) -> String {
    Bundle.module.localizedString(forKey: rawValue, in: language)
  }
}
#endif
