//
//  WidgetTimeline.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - WidgetTimeline

/// A widget's or complication's timeline: what it shows from an instant on, with an entry
/// wherever that changes, so it moves from Rotation to Rotation, or Shift to Shift, on time with
/// no app code running. The widget extensions hand it to WidgetKit as it is.
public struct WidgetTimeline<Content: Hashable & Sendable>: Hashable, Sendable {
  /// The entries in time order. The first is at the instant the timeline was built for.
  public let entries: [WidgetEntry<Content>]
  /// When the system should ask for a new timeline: at the last entry, or an hour after the
  /// first when no other follows.
  public let reloadDate: Date
}

// MARK: - WidgetEntry

/// What a widget shows from `date` until the next entry, with how fresh its data is.
///
/// Every system Surface shows when its data was fetched (ADR 0003): families with room (medium
/// and larger widgets, and any watch family with room) write `fetchTime`, and every family marks
/// `isStale`. The expanded Live Activity writes the schedules feed's fetch time too, with no
/// three-hour mark: its stale date already marks a passed boundary (`TrackingContent.staleDate`).
/// That time travels in ticket 37's content-state wrapper beside `TrackingContent`, taken from
/// `snapshot.schedules.fetchTime` at each update, so `TrackingContent` stays as it is.
public struct WidgetEntry<Content: Hashable & Sendable>: Hashable, Sendable {
  /// When the entry starts to show.
  public let date: Date
  /// What it shows.
  public let content: Content
  /// When the schedules feed shown was last confirmed.
  public let fetchTime: Date
  /// Whether the data is at least `staleAge` old at `date`.
  public let isStale: Bool

  /// How old data is when a widget marks it stale: three hours, past the hourly refresh gate and
  /// one missed background refresh, which runs about every two hours.
  static var staleAge: TimeInterval { 3 * 3600 }
}

// MARK: - WidgetCurrent

/// What a widget features as current from an entry's date on: an item, whose start and end feed
/// the system's timer text and progress, or why none is. It holds no progress, which would be
/// right only at the entry's date.
public enum WidgetCurrent<Item: TimeWindow & Hashable & Sendable>: Hashable, Sendable {
  /// An item is on.
  case item(Item)
  /// A Splatfest pauses the Battle Mode, which returns at `returnTime`.
  case paused(returnTime: Date)
  /// Nothing is on: the Schedule ran out (past items never pose as current), or its first
  /// published item has not started.
  case nothingCurrent

  /// The item on, or `nil` when none is.
  public var item: Item? {
    if case .item(let item) = self { item } else { nil }
  }

  /// What a lineup holds as current.
  init(_ current: Lineup<Item>.Current) {
    switch current {
      case .item(let item): self = .item(item)
      case .paused(let returnTime): self = .paused(returnTime: returnTime)
      case .gap,
           .ranOut,
           .noneAnnounced: self = .nothingCurrent
    }
  }
}

// MARK: - Building

extension WidgetTimeline {
  /// The timeline from `instant` of data fetched at `fetchTime`, with an entry at `instant`, at
  /// each of `boundaries` after it and when the data turns stale, each showing `content` at its
  /// date. `boundaries` may hold extra dates: an entry that would show what the one before it
  /// shows is left out.
  ///
  /// It asks for a reload at its last entry, or an hour on when that is the first: a reload
  /// sooner would read the same cache, and every refresh of it reloads the timelines anyway.
  init(from instant: Date, fetchTime: Date, boundaries: some Sequence<Date>, content: (Date) -> Content) {
    let staleDate = fetchTime.addingTimeInterval(WidgetEntry<Content>.staleAge)
    func entry(at date: Date) -> WidgetEntry<Content> {
      WidgetEntry(date: date, content: content(date), fetchTime: fetchTime, isStale: staleDate <= date)
    }

    var entries = [entry(at: instant)]
    for date in Set(Array(boundaries) + [staleDate]).filter({ instant < $0 }).sorted() {
      let next = entry(at: date)
      let last = entries[entries.count - 1]
      if next.content != last.content || next.isStale != last.isStale { entries.append(next) }
    }
    self.entries = entries
    reloadDate = entries.count > 1 ? entries[entries.count - 1].date : instant.addingTimeInterval(3600)
  }
}

extension WidgetTimeline {
  /// The same timeline with each entry's content transformed.
  func map<Other>(_ transform: (Content) -> Other) -> WidgetTimeline<Other> {
    WidgetTimeline<Other>(
      entries: entries.map { entry in
        WidgetEntry<Other>(
          date: entry.date,
          content: transform(entry.content),
          fetchTime: entry.fetchTime,
          isStale: entry.isStale)
      },
      reloadDate: reloadDate)
  }
}

extension Lineup {
  /// The first `count` items after the current one, in time order.
  func upcomingItems(_ count: Int) -> [Item] {
    Array(([next].compactMap(\.self) + later).prefix(count))
  }
}
