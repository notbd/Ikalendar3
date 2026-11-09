//
//  BattleOverviewWidget.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI
import WidgetKit
#if DEBUG
import IkaFixtures
#endif

// MARK: - BattleOverviewWidget

/// The extra large widget on iPad and Mac: the current Rotation of each continuous Battle Mode.
/// It is set to no Battle Mode, so while a Splatfest runs each shows paused until it returns.
struct BattleOverviewWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WidgetKind.battleOverview.rawValue, provider: BattleOverviewTimelineProvider()) { entry in
      BattleOverviewView(entry: entry)
    }
    .configurationDisplayName(Text("widget.overview.name", tableName: "Widgets"))
    .description(Text("widget.overview.description", tableName: "Widgets"))
    // The system offers the extra large size on iPad and Mac only.
    .supportedFamilies([.systemExtraLarge])
  }
}

// MARK: - BattleOverviewTimelineProvider

/// Hands WidgetKit the extra large widget's `IkaCore` timeline, built from the snapshot `load`
/// reads: the App Group cache, or a fixture in previews.
struct BattleOverviewTimelineProvider: TimelineProvider {
  typealias Entry = ScheduleWidgetEntry<[BattleWidgetContent]>

  var load: @Sendable () async -> Snapshot = AppGroup.cachedSnapshot

  func placeholder(in _: Context) -> Entry {
    .empty(at: .now)
  }

  func getSnapshot(in _: Context, completion: @escaping @Sendable (Entry) -> Void) {
    Task {
      await completion(timeline().entries.first ?? .empty(at: .now))
    }
  }

  func getTimeline(in _: Context, completion: @escaping @Sendable (Timeline<Entry>) -> Void) {
    Task {
      await completion(timeline())
    }
  }

  private func timeline() async -> Timeline<Entry> {
    let snapshot = await load()
    let now: Date = .now
    return Timeline(
      snapshot.extraLargeBattleWidgetTimeline(from: now),
      terms: snapshot.terms(in: WidgetData.language),
      from: now)
  }
}

// MARK: - Previews

#if DEBUG
#Preview("Extra large", as: .systemExtraLarge) {
  BattleOverviewWidget()
} timelineProvider: {
  BattleOverviewTimelineProvider(load: Snapshot.preview(.normalDay))
}

#Preview("Extra large, Splatfest", as: .systemExtraLarge) {
  BattleOverviewWidget()
} timelineProvider: {
  BattleOverviewTimelineProvider(load: Snapshot.preview(.splatfestSecondHalf))
}
#endif
