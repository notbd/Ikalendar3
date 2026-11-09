//
//  SalmonRunWidget.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - SalmonRunWidgetContent

/// What a Salmon Run widget or complication shows at an entry's date. The Shift carries its
/// Stage, four weapons and King Salmonid as ids, and its end is where the countdown runs to.
public struct SalmonRunWidgetContent: Hashable, Sendable {
  /// The regular Shift or Big Run on from the entry's date, never an Eggstra Work, or nothing
  /// current.
  public let current: WidgetCurrent<Shift>
  /// The Shifts after the current one the Surface shows, in time order.
  public let upcoming: [Shift]
}

// MARK: - Building

extension Snapshot {
  /// The Salmon Run widget's timeline from `instant`, or `nil` before the schedules feed's first
  /// good response. It has an entry at every real Shift boundary and ends with nothing current
  /// past the last published Shift. An Eggstra Work never takes the widget's place.
  public func salmonRunWidgetTimeline(from instant: Date) -> WidgetTimeline<SalmonRunWidgetContent>? {
    salmonRunTimeline(from: instant, upcomingCount: 0)
  }

  /// Salmon Run's timeline from `instant` with `upcomingCount` Shifts after the current one.
  func salmonRunTimeline(from instant: Date, upcomingCount: Int) -> WidgetTimeline<SalmonRunWidgetContent>? {
    guard let schedules else { return nil }

    let feed = schedules.content
    return WidgetTimeline(
      from: instant,
      fetchTime: schedules.fetchTime,
      boundaries: feed.salmonRun.flatMap { [$0.startTime, $0.endTime] })
    { date in
      let lineup = feed.salmonRunLineup(at: date)
      return SalmonRunWidgetContent(
        current: WidgetCurrent(lineup.current),
        upcoming: lineup.upcomingItems(upcomingCount))
    }
  }
}
