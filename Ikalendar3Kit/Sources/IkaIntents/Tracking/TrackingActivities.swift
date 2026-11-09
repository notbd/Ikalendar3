//
//  TrackingActivities.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import ActivityKit
import Foundation
import IkaCore
import OSLog

// MARK: - TrackingActivities

/// The Tracking Live Activities on this device, through ActivityKit. Only the effects shell and
/// the background task use it; the decisions are the effects plan's.
enum TrackingActivities {
  /// Every Tracking that runs, as the effects plan sees it. A stale one still runs.
  static func running() -> [RunningTracking] {
    runningActivities().map { activity in
      RunningTracking(id: activity.id, mode: activity.attributes.mode, startTime: activity.attributes.startTime)
    }
  }

  /// The end of each running Tracking's current item: its activity's stale date.
  static func staleDates() -> [Date] {
    runningActivities().compactMap(\.content.staleDate)
  }

  /// Applies the plan's effect to each activity it names.
  static func apply(_ effects: [String: TrackingEffect]) async {
    for activity in runningActivities() {
      switch effects[activity.id] {
        case .update(let state):
          await activity.update(ActivityContent(state: state, staleDate: state.staleDate))
          Logger.tracking
            .info("Updated \(activity.id, privacy: .public) until \(Self.describe(state.staleDate), privacy: .public)")

        case .end:
          await activity.end(nil, dismissalPolicy: .default)
          Logger.tracking.info("Ended \(activity.id, privacy: .public) eight hours after its start")

        case nil:
          break
      }
    }
  }

  /// Starts Tracking `state`'s Mode at `startTime`, ending any Tracking of that Mode already
  /// running at once, so a Mode is Tracked once and a new start gives it a fresh eight hours. The
  /// whole step takes the Mode's turn in `starts`, so overlapping starts leave one activity.
  ///
  /// - Throws: ActivityKit's error when the system refuses the activity, as when the player
  ///   turned Live Activities off.
  @MainActor
  static func start(_ state: TrackingState, at startTime: Date) async throws {
    let mode = state.content.mode
    try await starts.run(mode) {
      for activity in runningActivities() where activity.attributes.mode == mode {
        await activity.end(nil, dismissalPolicy: .immediate)
      }
      let activity = try Activity.request(
        attributes: TrackingAttributes(mode: mode, startTime: startTime),
        content: ActivityContent(state: state, staleDate: state.staleDate))
      Logger.tracking
        .info("Started \(activity.id, privacy: .public) until \(Self.describe(state.staleDate), privacy: .public)")
    }
  }

  /// The process's one set of turns for starting Tracking.
  static private let starts: TrackingStarts = .init()

  /// A stale date in a log line: `-` when nothing is on.
  static private func describe(_ staleDate: Date?) -> String {
    staleDate?.description ?? "-"
  }

  /// Whether an activity in `state` is a running Tracking: active, or stale after a missed
  /// boundary. One the player dismissed, or that ended, is not: no run re-arms it, no start waits
  /// to end it, and the Mode is Tracked again from the next start.
  static func isRunning(_ state: ActivityState) -> Bool {
    [.active, .stale].contains(state)
  }

  /// The activities that run (`isRunning(_:)`).
  static private func runningActivities() -> [Activity<TrackingAttributes>] {
    Activity<TrackingAttributes>.activities.filter { isRunning($0.activityState) }
  }
}
#endif
