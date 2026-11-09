//
//  EffectsShell.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if !os(watchOS)
import Foundation
import IkaCore
import WidgetKit

// MARK: - EffectsShell

/// The one run every entry point makes: the app on activation, on a manual refresh and from its
/// background task (on the Mac, its periodic and after-wake runs), and the intents that refresh,
/// directly. A run refreshes under the hourly gate, then applies the effects plan `IkaCore` makes
/// of the result, deciding nothing itself. So a run that commits new data applies every effect,
/// whichever entry point started it.
///
/// On iOS it also starts Tracking, and every run re-arms each running Tracking from the cache.
/// Live Activities render on the system's clock, so their instant is the wall clock's. Not on
/// watchOS: the watch app runs its own shell and links no `IkaIntents`.
@MainActor
public struct EffectsShell {
  private let engine: RefreshEngine

  /// A shell that refreshes through an engine, whose snapshot the caller shows.
  public init(engine: RefreshEngine) {
    self.engine = engine
  }

  /// Refreshes under the hourly gate, then applies the effects the result calls for. A run that
  /// starts while another is in flight joins its refresh.
  @discardableResult
  public func run() async -> RefreshResult {
    let result = await engine.refresh()
    #if os(iOS)
    await apply(EffectsPlan(after: result, tracking: TrackingActivities.running(), at: Date()))
    #else
    await apply(EffectsPlan(after: result, at: Date()))
    #endif
    return result
  }

  private func apply(_ plan: EffectsPlan) async {
    if plan.reloadsWidgetTimelines {
      WidgetCenter.shared.reloadAllTimelines()
    }
    #if os(iOS)
    await TrackingActivities.apply(plan.tracking)
    if let nextBackgroundRun = plan.nextBackgroundRun {
      await BackgroundRefresh.requestRun(at: nextBackgroundRun)
    }
    #endif
  }
}

#if os(iOS)
extension EffectsShell {
  /// The shell an intent runs, a Siri question's or a Tracking one's: an engine of its own on the
  /// App Group cache, which it shares with the app and every other engine through the gate's
  /// attempt records, in the app language. No runtime registration: an intent builds it each time
  /// it runs.
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

  /// Starts Tracking `mode`: a run as every entry point makes, then the Live Activity from the
  /// cache it left, replacing any Tracking of that Mode already running.
  ///
  /// - Throws: `TrackingError.noSchedule` before the schedules feed's first good response, or
  ///   ActivityKit's error when the system refuses the activity.
  public func startTracking(_ mode: Mode) async throws {
    let result = await run()
    let now: Date = .init()
    guard let state = result.snapshot.trackingState(of: mode, at: now) else { throw TrackingError.noSchedule }

    try await startTracking(state, at: now)
  }

  /// Starts Tracking with `state` at `startTime`, replacing any Tracking of its Mode already
  /// running, and asks the background task to run by its first boundary. The Debug short-item
  /// fixture starts its Tracking here too.
  public func startTracking(_ state: TrackingState, at startTime: Date) async throws {
    try await TrackingActivities.start(state, at: startTime)
    await BackgroundRefresh.requestNextRun(after: startTime)
  }
}

// MARK: - TrackingError

/// Why Tracking could not start.
public enum TrackingError: Error, CustomLocalizedStringResourceConvertible {
  /// The cache holds no schedules feed yet: there is nothing to Track.
  case noSchedule

  public var localizedStringResource: LocalizedStringResource {
    switch self {
      case .noSchedule: LocalizedStringResource("No schedule yet", bundle: #bundle)
    }
  }
}
#endif
#endif
