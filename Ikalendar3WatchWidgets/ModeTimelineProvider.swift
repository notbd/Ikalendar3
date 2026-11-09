//
//  ModeTimelineProvider.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import AppIntents
import IkaCore
import IkaDesign
import IkaIntents
import SwiftUI
import WidgetKit

// MARK: - ModeWidgetIntent

/// A watch widget's configuration: the Mode it shows, one of the Mode value's five members.
struct ModeWidgetIntent: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = .init("intent.mode.title", table: "Widgets")
  static let description: IntentDescription = .init(LocalizedStringResource(
    "intent.mode.description",
    table: "Widgets"))

  @Parameter(title: LocalizedStringResource("intent.mode.mode", table: "Widgets"), default: .regularBattle)
  var mode: ModeParameter

  init() { }

  init(mode: ModeParameter) {
    self.mode = mode
  }
}

// MARK: - ModeTimelineProvider

/// Hands WidgetKit a watch widget's `IkaCore` timeline for its Mode, built from the snapshot `load`
/// reads: the watch's App Group cache, which the watch app fills, or a fixture in previews.
struct ModeTimelineProvider: AppIntentTimelineProvider {
  typealias Entry = ScheduleWidgetEntry<WatchWidgetContent>

  var load: @Sendable () async -> Snapshot = AppGroup.cachedSnapshot

  /// One choice per Mode, which the complication editor and the Smart Stack list by the Mode's
  /// name. A new member of the Mode value appears here with no change.
  func recommendations() -> [AppIntentRecommendation<ModeWidgetIntent>] {
    Mode.allCases.map { mode in
      AppIntentRecommendation(
        intent: ModeWidgetIntent(mode: ModeParameter(mode)),
        description: Text(verbatim: mode.name(in: Ikalendar3WatchWidgets.language)))
    }
  }

  func placeholder(in _: Context) -> Entry {
    .empty(at: .now)
  }

  func snapshot(for configuration: ModeWidgetIntent, in context: Context) async -> Entry {
    await timeline(for: configuration, in: context).entries.first ?? .empty(at: .now)
  }

  func timeline(for configuration: ModeWidgetIntent, in _: Context) async -> Timeline<Entry> {
    let snapshot = await load()
    let now: Date = .now
    return Timeline(
      snapshot.watchWidgetTimeline(of: configuration.mode.mode, from: now),
      terms: snapshot.terms(in: Ikalendar3WatchWidgets.language),
      from: now)
  }
}
