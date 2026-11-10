//
//  EffectsShell.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if !os(watchOS)
import Foundation
import IkaCore
import Observation
import WidgetKit

// MARK: - EffectsShell

/// The one run every entry point makes: the app on activation, on a manual refresh and from its
/// background task (on the Mac, its periodic and after-wake runs), and the intents that refresh,
/// directly. A run refreshes under the hourly gate, then applies the effects plan `IkaCore` makes
/// of the result, deciding nothing itself. So a run that commits new data applies every effect,
/// whichever entry point started it.
///
/// It replaces the app's pending event reminders as the plan says, after a refresh that committed a
/// feed and whenever a reminder switch changes (`followReminderSwitches()`), with the switches the
/// preferences' suite holds as it plans: an intent's store is a copy taken as the intent started,
/// and the player may have flipped a switch since. Replacements take turns in the order the shell
/// plans them (`ReminderReplacements`), so the latest switches always stand.
///
/// On iOS it also starts Tracking, and every run re-arms each running Tracking from the cache.
/// Live Activities render on the system's clock, so their instant is the wall clock's. Not on
/// watchOS: the watch app runs its own shell and links no `IkaIntents`.
@MainActor
public struct EffectsShell {
  private let engine: RefreshEngine
  private let preferences: PreferenceStore
  private let reminders: ReminderReplacements

  /// A shell that refreshes through an engine, whose snapshot the caller shows, with the reminder
  /// switches of `preferences`.
  public init(engine: RefreshEngine, preferences: PreferenceStore) {
    self.init(engine: engine, preferences: preferences, reminders: .system)
  }

  /// A shell that replaces the pending reminders through `reminders`: the process's own
  /// (`ReminderReplacements.system`), or a test's.
  init(engine: RefreshEngine, preferences: PreferenceStore, reminders: ReminderReplacements) {
    self.engine = engine
    self.preferences = preferences
    self.reminders = reminders
  }

  /// Refreshes under the hourly gate, then applies the effects the result calls for. A run that
  /// starts while another is in flight joins its refresh.
  @discardableResult
  public func run() async -> RefreshResult {
    let result = await engine.refresh()
    #if os(iOS)
    await apply(EffectsPlan(
      after: result,
      tracking: TrackingActivities.running(),
      reminders: reminderSettings,
      at: Date()))
    #else
    await apply(EffectsPlan(after: result, reminders: reminderSettings, at: Date()))
    #endif
    return result
  }

  /// Rebuilds the pending reminders each time the reminder switches change, whoever writes them
  /// (Settings, Debug Options' resets, any later writer), until the returned task is cancelled.
  /// The app starts it once at launch, so no writer rebuilds them itself.
  ///
  /// The switches are read as it is called, and only a change from them rebuilds: a rebuild at
  /// launch would replace the pending reminders from a snapshot the first refresh has not
  /// published yet.
  @discardableResult
  public func followReminderSwitches() -> Task<Void, Never> {
    let initialKinds = preferences.reminderKinds
    return Task {
      var kinds = initialKinds
      for await changedKinds in Observations({ preferences.reminderKinds }) where changedKinds != kinds {
        kinds = changedKinds
        await rebuildReminders()
      }
    }
  }

  /// Replaces the pending reminders after a reminder switch changed, from the snapshot the engine
  /// shows, with no refresh.
  private func rebuildReminders() async {
    await apply(EffectsPlan(remindersChangedTo: reminderSettings, in: engine.snapshot, at: Date()))
  }

  private func apply(_ plan: EffectsPlan) async {
    if plan.reloadsWidgetTimelines {
      WidgetCenter.shared.reloadAllTimelines()
    }
    if let planned = plan.reminders {
      await reminders.replace(with: planned)
    }
    #if os(iOS)
    await TrackingActivities.apply(plan.tracking)
    if let nextBackgroundRun = plan.nextBackgroundRun {
      await BackgroundRefresh.requestRun(at: nextBackgroundRun)
    }
    #endif
  }

  /// The switches as the suite holds them now, with the reminder text in the app language and the
  /// device's time zone and hour cycle, read at each plan so a change in the system's settings
  /// applies.
  private var reminderSettings: ReminderSettings {
    ReminderSettings(
      kinds: preferences.storedReminderKinds,
      language: GameLanguage(resolvedFor: .main),
      timeZone: .current,
      hourCycle: Locale.current.hourCycle)
  }
}

#if os(iOS)
extension EffectsShell {
  /// The shell an intent runs, a Siri question's or a Tracking one's: an engine of its own on the
  /// App Group cache, which it shares with the app and every other engine through the gate's
  /// attempt records, in the app language, with the reminder switches of the App Group's suite.
  /// No runtime registration: an intent builds it each time it runs.
  ///
  /// - Throws: `TrackingError.noSchedule` with no App Group container (logged by `AppGroup`) or
  ///   suite, where no cache can hold a schedule.
  static func forIntents() throws -> EffectsShell {
    guard let container = AppGroup.container(), let defaults = UserDefaults(suiteName: AppGroup.identifier) else {
      throw TrackingError.noSchedule
    }

    let client: FeedClient = .init(
      transport: URLSessionTransport(),
      cache: FeedCache(directory: AppGroup.feedDirectory(in: container)))
    return EffectsShell(
      engine: RefreshEngine(client: client, language: GameLanguage(resolvedFor: .main)),
      preferences: PreferenceStore(defaults: defaults))
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
