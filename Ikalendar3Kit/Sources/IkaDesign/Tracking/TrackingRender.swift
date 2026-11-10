//
//  TrackingRender.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import Foundation
import IkaCore

// MARK: - TrackingRender

/// A Tracking activity at one render: what its carried items show at the render time and the
/// system's stale flag (`TrackingFrame`), when their data was fetched, and the names to write it
/// in. The system archives each render, so the render time is the moment it draws: at an update,
/// and once more at the stale date, the end of the first carried item.
public struct TrackingRender {
  /// The frame of a Battle Mode's Rotations or of Salmon Run's Shifts.
  enum Frame {
    case battle(BattleMode, TrackingFrame<TrackedRotation>)
    case salmonRun(TrackingFrame<TrackedShift>)
  }

  /// The tracked Mode.
  public let mode: Mode
  /// What the views show.
  let frame: Frame
  /// When the schedules feed the content came from was last confirmed.
  let fetchTime: Date
  /// The moment of the render.
  let renderTime: Date
  /// The game's names in the app language.
  public let terms: GameTerms

  /// The render of `state`, Tracking `mode`, at `renderTime` with the system's stale flag: what
  /// the Live Activity draws from its context, and the Debug showcase from a snapshot.
  public init(mode: Mode, state: TrackingState, isStale: Bool, renderTime: Date, terms: GameTerms) {
    switch state.content {
      case .battle(let mode, let rotations):
        frame = .battle(mode, TrackingFrame(rotations, at: renderTime, isStale: isStale))
      case .salmonRun(let shifts):
        frame = .salmonRun(TrackingFrame(shifts, at: renderTime, isStale: isStale))
    }
    self.mode = mode
    fetchTime = state.fetchTime
    self.renderTime = renderTime
    self.terms = terms
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
#endif
