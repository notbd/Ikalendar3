//
//  SalmonRunWidget.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI
import WidgetKit

// MARK: - SalmonRunWidget

/// The Salmon Run widget in two sizes on iPhone, iPad and Mac: the current Shift's Stage, four
/// weapons, King Salmonid and the countdown to its end. A Big Run shows as one; an Eggstra Work
/// never takes the widget's place.
struct SalmonRunWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WidgetKind(.salmonRun).rawValue, provider: SalmonRunTimelineProvider()) { entry in
      SalmonRunWidgetView(entry: entry)
    }
    .configurationDisplayName(Text("widget.salmonRun.name", tableName: "Widgets"))
    .description(Text("widget.salmonRun.description", tableName: "Widgets"))
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

// MARK: - SalmonRunTimelineProvider

/// Hands WidgetKit the Salmon Run widget's `IkaCore` timeline, built from the snapshot `load`
/// reads: the App Group cache, or a fixture in previews.
struct SalmonRunTimelineProvider: TimelineProvider {
  typealias Entry = ScheduleWidgetEntry<SalmonRunWidgetContent>

  var load: @Sendable () async -> Snapshot = WidgetData.cachedSnapshot

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
      snapshot.salmonRunWidgetTimeline(from: now),
      terms: snapshot.terms(in: WidgetData.language),
      from: now)
  }
}

// MARK: - Previews

#if DEBUG
#Preview("Small", as: .systemSmall) {
  SalmonRunWidget()
} timelineProvider: {
  SalmonRunTimelineProvider(load: WidgetData.fixture(.normalDay))
}

#Preview("Medium", as: .systemMedium) {
  SalmonRunWidget()
} timelineProvider: {
  SalmonRunTimelineProvider(load: WidgetData.fixture(.normalDay))
}

#Preview("Small, Big Run with random weapons", as: .systemSmall) {
  SalmonRunWidget()
} timelineProvider: {
  SalmonRunTimelineProvider(load: WidgetData.fixture(.bigRun))
}

#Preview("Medium, Big Run with random weapons", as: .systemMedium) {
  SalmonRunWidget()
} timelineProvider: {
  SalmonRunTimelineProvider(load: WidgetData.fixture(.bigRun))
}

#Preview("Small, empty", as: .systemSmall) {
  SalmonRunWidget()
} timelineProvider: {
  SalmonRunTimelineProvider { Snapshot() }
}
#endif
