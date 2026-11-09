//
//  ScheduleWidgetEntry.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import WidgetKit

// MARK: - ScheduleWidgetEntry

/// What a widget or complication shows from `date`: an entry of its `IkaCore` timeline, or nothing
/// before the schedules feed's first good response, with the game's names to write it in.
public struct ScheduleWidgetEntry<Content: Hashable & Sendable>: WidgetKit.TimelineEntry {
  public let date: Date
  /// The timeline entry, or `nil` while the cache holds no schedules feed.
  public let schedule: WidgetEntry<Content>?
  /// The game's names in the app language.
  public let terms: GameTerms

  public init(date: Date, schedule: WidgetEntry<Content>?, terms: GameTerms) {
    self.date = date
    self.schedule = schedule
    self.terms = terms
  }

  /// The entry with nothing to show yet: the placeholder, and the timeline of an empty cache. By
  /// default in the shipped names of the language this process resolves.
  public static func empty(
    at date: Date,
    terms: GameTerms = Snapshot().terms(in: GameLanguage(resolvedFor: .main)))
    -> Self
  {
    ScheduleWidgetEntry(date: date, schedule: nil, terms: terms)
  }
}

extension WidgetKit.Timeline {
  /// WidgetKit's form of an `IkaCore` timeline in `terms`. With none, the empty entry from
  /// `instant`, asking again in an hour as an `IkaCore` timeline of one entry does: every refresh
  /// of the cache reloads the timelines anyway.
  public init<Content>(_ timeline: WidgetTimeline<Content>?, terms: GameTerms, from instant: Date)
    where EntryType == ScheduleWidgetEntry<Content>
  {
    guard let timeline else {
      self.init(entries: [.empty(at: instant, terms: terms)], policy: .after(instant.addingTimeInterval(3600)))
      return
    }

    self.init(
      entries: timeline.entries.map { ScheduleWidgetEntry(date: $0.date, schedule: $0, terms: terms) },
      policy: .after(timeline.reloadDate))
  }
}
