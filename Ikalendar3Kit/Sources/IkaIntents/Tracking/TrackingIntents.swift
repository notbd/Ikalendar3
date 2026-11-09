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
import OSLog

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
    Logger.logRun(of: Self.self)
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

// MARK: - TrackingText

/// The words and symbols of Tracking's buttons. The words are the intents' titles, from this
/// module's string catalog, so a button reads as the intent it runs. The Refresh button's word is
/// the one `TrackingReminder`'s phrases tell the player to tap.
public enum TrackingText: String, CaseIterable, Sendable {
  /// "Start Tracking": the app's track button.
  case startTracking = "Start Tracking"
  /// "Refresh": the Live Activity's Refresh button.
  case refresh = "Refresh"

  /// The word in a text set.
  public func text(in language: GameLanguage) -> String {
    Bundle.module.localizedString(forKey: rawValue, in: language)
  }

  /// The button's SF Symbol. The app's track button and the Control Center control share the
  /// start-Tracking one: Control Center draws only symbols, never the bundled Mode icons.
  public var systemImage: String {
    switch self {
      case .startTracking: "dot.radiowaves.left.and.right"
      case .refresh: "arrow.clockwise"
    }
  }
}
#endif
