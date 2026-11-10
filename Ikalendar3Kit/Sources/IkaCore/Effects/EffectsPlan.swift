//
//  EffectsPlan.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - EffectsPlan

/// The effects one run of the effects shell applies after its refresh. Every decision is made
/// here, where it is tested; the shell in `IkaIntents` applies the plan and decides nothing itself.
public struct EffectsPlan: Equatable, Sendable {
  /// Whether every widget timeline reloads: after each refresh that committed a feed, a 304
  /// included, so the widgets show the fetch time the app shows.
  public let reloadsWidgetTimelines: Bool
  /// What the run does to each running Tracking, by its activity's id. Every run re-arms each
  /// one from the cache, a run the gate kept from the network included, so the activity moves to
  /// the item on now and its stale date to that item's end. One past its end date ends instead.
  /// While the cache holds no schedules feed, a running Tracking has no entry and stays as it is.
  public let tracking: [String: TrackingEffect]
  /// When the run asks the background task to run next: at the next boundary of a running
  /// Tracking, the end of its current item or its own end, so one update lands between any two
  /// boundaries and an ended Tracking leaves at once, or two hours on if that is sooner. `nil`
  /// while no Tracking runs: the request made as the app last moved to the background stands.
  public let nextBackgroundRun: Date?
  /// The event reminders that replace every pending one of the app's, or `nil` to leave them as
  /// they are. Rebuilt from the cache after each refresh that committed a feed, a 304 included,
  /// and whenever a switch changes, so a newly published or moved event is reminded of at its
  /// start. A refresh that committed nothing leaves them, since the data they came from stands.
  public let reminders: [EventReminder]?

  /// The plan after a refresh at `instant`, with `tracking` running. With no `reminders`
  /// settings, as on the watch, the plan leaves the pending reminders as they are.
  public init(
    after result: RefreshResult,
    tracking: [RunningTracking] = [],
    reminders reminderSettings: ReminderSettings? = nil,
    at instant: Date)
  {
    reloadsWidgetTimelines = result.hasCommitted
    reminders = result.hasCommitted
      ? reminderSettings.map { result.snapshot.eventReminders(for: $0, after: instant) }
      : nil

    var effects: [String: TrackingEffect] = [:]
    for running in tracking {
      if TrackingContent.endDate(startedAt: running.startTime) <= instant {
        effects[running.id] = .end
      }
      else if let state = result.snapshot.trackingState(of: running.mode, at: instant) {
        effects[running.id] = .update(state)
      }
    }
    self.tracking = effects
    nextBackgroundRun = tracking.isEmpty
      ? nil
      : Self.nextBackgroundRun(
        after: instant,
        tracking: tracking.filter { effects[$0.id] != .end },
        staleDates: effects.values.compactMap { $0.state?.staleDate })
  }

  /// The plan after a reminder switch changed at `instant`: the reminders `settings` call for
  /// from `snapshot`, the cache as last read, and no other effect.
  public init(remindersChangedTo settings: ReminderSettings, in snapshot: Snapshot, at instant: Date) {
    reloadsWidgetTimelines = false
    tracking = [:]
    nextBackgroundRun = nil
    reminders = snapshot.eventReminders(for: settings, after: instant)
  }

  /// When the background task should run next after `now`: at the first boundary of the running
  /// `tracking`, the end of a current item (an activity's stale date, in `staleDates`) or a
  /// Tracking's own end, or two hours on if that is sooner. The system holds one pending request
  /// for the task, so every request, wherever it is made, asks for this run.
  static public func nextBackgroundRun(
    after now: Date,
    tracking: [RunningTracking],
    staleDates: some Sequence<Date>)
    -> Date
  {
    let ends = tracking.lazy.map { TrackingContent.endDate(startedAt: $0.startTime) }
    return ends.reduce(staleDates.reduce(now.addingTimeInterval(backgroundRefreshInterval), min), min)
  }

  /// How long after a run the background task is due again with no boundary sooner: about two
  /// hours, so widgets stay fresh while the app is not opened. The Mac's periodic run, which
  /// stands in for the task there, keeps the same interval.
  static public let backgroundRefreshInterval: TimeInterval = 2 * 3600
}

// MARK: - RunningTracking

/// A running Live Activity as the effects plan sees it: its id and its attributes.
public struct RunningTracking: Hashable, Sendable {
  /// The activity's id.
  public let id: String
  /// The tracked Mode.
  public let mode: Mode
  /// When Tracking started.
  public let startTime: Date

  public init(id: String, mode: Mode, startTime: Date) {
    self.id = id
    self.mode = mode
    self.startTime = startTime
  }
}

// MARK: - TrackingEffect

/// What a run of the effects shell does to one running Tracking.
public enum TrackingEffect: Hashable, Sendable {
  /// Update the activity to `state`, with its stale date at `state.staleDate`.
  case update(TrackingState)
  /// End the activity: it is past its end date, eight hours after it started.
  case end

  /// The state an update applies, or `nil` for an end.
  var state: TrackingState? {
    if case .update(let state) = self { state } else { nil }
  }
}

// MARK: - RefreshResult

extension RefreshResult {
  /// Whether the refresh committed any feed's answer: a new body, or a 304's renewed fetch time.
  /// A refresh whose every feed failed or was kept from the network by the gate left the cache as
  /// it was.
  fileprivate var hasCommitted: Bool {
    outcomes.values.contains { outcome in
      switch outcome {
        case .fetched(.updated),
             .fetched(.confirmed): true
        case .fetched(.failed),
             .gateClosed: false
      }
    }
  }
}
