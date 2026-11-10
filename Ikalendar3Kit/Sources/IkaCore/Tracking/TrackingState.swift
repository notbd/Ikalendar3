//
//  TrackingState.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - TrackingState

/// A Live Activity's content state while Tracking a Mode: what Tracking carries, and when the
/// schedules feed it came from was last confirmed, which the expanded views write (ticket 19's
/// fetch-time decision, recorded on `WidgetEntry`).
public struct TrackingState: Codable, Hashable, Sendable {
  /// The carried items, ids and times only.
  public let content: TrackingContent
  /// When the schedules feed was last confirmed, by a 200 or a 304.
  public let fetchTime: Date

  /// A state of `content` from data fetched at `fetchTime`.
  public init(content: TrackingContent, fetchTime: Date) {
    self.content = content
    self.fetchTime = fetchTime
  }

  /// When the item on at build time ends, where every update sets the activity's stale date.
  public var staleDate: Date? { content.staleDate }
}

// MARK: - Snapshot

extension Snapshot {
  /// The state of Tracking `mode` at `instant`, or `nil` before the schedules feed's first good
  /// response.
  public func trackingState(of mode: Mode, at instant: Date) -> TrackingState? {
    schedules.map { TrackingState(content: $0.content.trackingContent(of: mode, at: instant), fetchTime: $0.fetchTime) }
  }
}
