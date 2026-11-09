//
//  TrackingRender.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import ActivityKit
import Foundation
import IkaCore
import IkaIntents
import WidgetKit

// MARK: - TrackingRender

/// A Tracking activity at one render: what its carried items show at the render time and the
/// system's stale flag (`TrackingFrame`), when their data was fetched, and the names to write it
/// in. The system archives each render, so the render time is the moment it draws: at an update,
/// and once more at the stale date, the end of the first carried item.
struct TrackingRender {
  /// The frame of a Battle Mode's Rotations or of Salmon Run's Shifts.
  enum Frame {
    case battle(BattleMode, TrackingFrame<TrackedRotation>)
    case salmonRun(TrackingFrame<TrackedShift>)
  }

  /// The tracked Mode.
  let mode: Mode
  /// What the views show.
  let frame: Frame
  /// When the schedules feed the content came from was last confirmed.
  let fetchTime: Date
  /// The moment of the render.
  let renderTime: Date
  /// The game's names in the app language.
  let terms: GameTerms

  init(_ context: ActivityViewContext<TrackingAttributes>, at renderTime: Date = .now) {
    let state = context.state
    switch state.content {
      case .battle(let mode, let rotations):
        frame = .battle(mode, TrackingFrame(rotations, at: renderTime, isStale: context.isStale))
      case .salmonRun(let shifts):
        frame = .salmonRun(TrackingFrame(shifts, at: renderTime, isStale: context.isStale))
    }
    mode = context.attributes.mode
    fetchTime = state.fetchTime
    self.renderTime = renderTime
    terms = WidgetData.trackingTerms()
  }

  /// The window of the item shown as on, which the countdown runs to the end of.
  var currentWindow: ClosedRange<Date>? {
    switch frame {
      case .battle(_, let frame): frame.current.map { $0.startTime ... $0.endTime }
      case .salmonRun(let frame): frame.current.map { $0.startTime ... $0.endTime }
    }
  }

  /// The reminder shown, if any.
  var reminder: TrackingReminder? {
    switch frame {
      case .battle(_, let frame): frame.reminder
      case .salmonRun(let frame): frame.reminder
    }
  }
}

// MARK: - WidgetData

extension WidgetData {
  /// The game's names for a Live Activity's render, which cannot wait for a snapshot: the cached
  /// locale file of the app language, else the shipped snapshot.
  static func trackingTerms() -> GameTerms {
    guard let container = AppGroup.container() else { return Snapshot().terms(in: language) }

    return FeedCache(directory: AppGroup.feedDirectory(in: container)).terms(in: language)
  }
}
#endif
