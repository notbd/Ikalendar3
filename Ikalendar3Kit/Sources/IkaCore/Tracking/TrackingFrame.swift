//
//  TrackingFrame.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - TrackingFrame

/// What a Tracking view shows at one render: the item on, the item after it and the reminder,
/// picked from the content's carried items by the render time and the system's stale flag.
///
/// The system renders once at the stale date (the end of the first carried item) and cannot be
/// counted on to render again. So from that boundary on a view shows the next carried item, and
/// on the render the stale date triggers it also warns that the switch after it needs a Refresh.
/// The system keeps the flag set on every later render, so this holds only until the following
/// boundary; past it the schedule is out of date, flag or not, and a view shows the carried item
/// on at the render time, if any. A past item never shows as current.
public struct TrackingFrame<Item: TimeWindow & Hashable & Sendable>: Hashable, Sendable {
  /// The item shown as on, or `nil` once the render is past every carried item.
  public let current: Item?
  /// The item after `current`, or `nil` when nothing later is published yet. Always `nil` once
  /// the schedule is out of date, when the reminder takes the next line's place.
  public let next: Item?
  /// The reminder shown, if any.
  public let reminder: TrackingReminder?
}

extension TrackingFrame {
  /// The frame at `renderTime` of `items`, a Tracking content's carried items, where `isStale`
  /// is the stale flag the system passes to the view.
  public init(_ items: [Item], at renderTime: Date, isStale: Bool) {
    let unended = items.drop { $0.endTime <= renderTime }
    let boundariesPassed = items.count - unended.count
    guard boundariesPassed < 2, let current = unended.first else {
      self.init(current: unended.first { $0.isRunning(at: renderTime) }, next: nil, reminder: .scheduleOutOfDate)
      return
    }

    self.init(
      current: current,
      next: unended.dropFirst().first,
      reminder: boundariesPassed == 1 && isStale ? .nextSwitchNeedsRefresh : nil)
  }
}
