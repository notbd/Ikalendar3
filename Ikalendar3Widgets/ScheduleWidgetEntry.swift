//
//  ScheduleWidgetEntry.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import IkaFixtures
import WidgetKit

// MARK: - ScheduleWidgetEntry

/// What a widget shows from `date`: an entry of its `IkaCore` timeline, or nothing before the
/// schedules feed's first good response, with the game's names to write it in.
struct ScheduleWidgetEntry<Content: Hashable & Sendable>: TimelineEntry {
  let date: Date
  /// The timeline entry, or `nil` while the cache holds no schedules feed.
  let schedule: WidgetEntry<Content>?
  /// The game's names in the app language.
  let terms: GameTerms

  /// The entry with nothing to show yet: the placeholder, and the timeline of an empty cache.
  static func empty(at date: Date, terms: GameTerms = Snapshot().terms(in: WidgetData.language)) -> Self {
    ScheduleWidgetEntry(date: date, schedule: nil, terms: terms)
  }
}

extension Timeline {
  /// WidgetKit's form of an `IkaCore` timeline in `terms`. With none, the empty entry from
  /// `instant`, asking again in an hour as an `IkaCore` timeline of one entry does: every refresh
  /// of the cache reloads the timelines anyway.
  init<Content>(_ timeline: WidgetTimeline<Content>?, terms: GameTerms, from instant: Date)
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

// MARK: - WidgetData

/// Where the widgets' data and language come from.
enum WidgetData {
  /// The app language: the text set of the localization the system resolved for this
  /// extension's bundle. The extension declares the app's 14, so it resolves the app's.
  static let language: GameLanguage = .init(localization: Bundle.main.preferredLocalizations.first ?? "en")

  /// The App Group cache as the app and the intents last wrote it, read afresh for every timeline.
  /// The extension never fetches. With no App Group container (an unsigned build; logged), the
  /// cache is empty.
  @concurrent
  static func cachedSnapshot() async -> Snapshot {
    guard let container = AppGroup.container() else { return Snapshot() }

    return await FeedCache(directory: AppGroup.feedDirectory(in: container)).snapshot()
  }
}

extension WidgetData {
  /// Previews: a loader of a recorded day, moved so that a moment of it is now: the normal day
  /// mid-Rotation, or the Splatfest in its second half.
  static func fixture(_ schedules: Fixture) -> @Sendable () async -> Snapshot {
    let recordedAt =
      switch schedules {
        case .splatfestSecondHalf: "2026-11-01T05:30:00Z"
        default: "2026-10-20T13:15:00Z"
      }
    return {
      guard let instant = try? Date(recordedAt, strategy: .iso8601) else { return Snapshot() }

      return await (try? Snapshot.fixture(schedules, recordedAt: instant, shownAt: .now)) ?? Snapshot()
    }
  }
}
