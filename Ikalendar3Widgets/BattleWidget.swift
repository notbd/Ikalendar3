//
//  BattleWidget.swift
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

// MARK: - BattleWidget

/// The battle widget set to one Battle Mode, in three sizes on iPhone, iPad and Mac, the small one
/// in StandBy too: the current Rotation with its countdown, plus the next one (medium), plus the
/// three after that (large). While a Splatfest replaces the Battle Mode it shows Splatfest Battle.
struct BattleWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: "battle",
      intent: BattleWidgetIntent.self,
      provider: BattleTimelineProvider())
    { entry in
      BattleWidgetView(entry: entry)
    }
    .configurationDisplayName(Text("widget.battle.name", tableName: "Widgets"))
    .description(Text("widget.battle.description", tableName: "Widgets"))
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

// MARK: - BattleWidgetIntent

/// The battle widget's configuration: the Battle Mode it shows.
struct BattleWidgetIntent: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = .init("intent.battle.title", table: "Widgets")
  static let description: IntentDescription = .init(LocalizedStringResource(
    "intent.battle.description",
    table: "Widgets"))

  @Parameter(title: LocalizedStringResource("intent.battle.battleMode", table: "Widgets"), default: .regularBattle)
  var battleMode: BattleModeParameter

  init() { }

  init(battleMode: BattleModeParameter) {
    self.battleMode = battleMode
  }
}

// MARK: - BattleTimelineProvider

/// Hands WidgetKit the battle widget's `IkaCore` timeline for its Battle Mode and size, built from
/// the snapshot `load` reads: the App Group cache, or a fixture in previews.
struct BattleTimelineProvider: AppIntentTimelineProvider {
  typealias Entry = ScheduleWidgetEntry<BattleWidgetContent>

  var load: @Sendable () async -> Snapshot = WidgetData.cachedSnapshot

  func placeholder(in _: Context) -> Entry {
    .empty(at: .now)
  }

  func snapshot(for configuration: BattleWidgetIntent, in context: Context) async -> Entry {
    await timeline(for: configuration, in: context).entries.first ?? .empty(at: .now)
  }

  func timeline(for configuration: BattleWidgetIntent, in context: Context) async -> Timeline<Entry> {
    let snapshot = await load()
    let now: Date = .now
    return Timeline(
      snapshot.battleWidgetTimeline(
        of: configuration.battleMode.battleMode,
        family: BattleWidgetFamily(context.family),
        from: now),
      terms: snapshot.terms(in: WidgetData.language),
      from: now)
  }
}

extension BattleWidgetFamily {
  /// The battle family of a Home Screen size. The battle widget offers only those three.
  init(_ family: WidgetFamily) {
    switch family {
      case .systemMedium: self = .medium
      case .systemLarge: self = .large
      default: self = .small
    }
  }
}

// MARK: - Previews

#if DEBUG
#Preview("Small", as: .systemSmall, using: BattleWidgetIntent(battleMode: .anarchySeries)) {
  BattleWidget()
} timelineProvider: {
  BattleTimelineProvider(load: WidgetData.fixture(.normalDay))
}

#Preview("Medium", as: .systemMedium, using: BattleWidgetIntent(battleMode: .xBattle)) {
  BattleWidget()
} timelineProvider: {
  BattleTimelineProvider(load: WidgetData.fixture(.normalDay))
}

#Preview("Large", as: .systemLarge, using: BattleWidgetIntent(battleMode: .regularBattle)) {
  BattleWidget()
} timelineProvider: {
  BattleTimelineProvider(load: WidgetData.fixture(.normalDay))
}

#Preview("Large, Splatfest", as: .systemLarge, using: BattleWidgetIntent(battleMode: .anarchySeries)) {
  BattleWidget()
} timelineProvider: {
  BattleTimelineProvider(load: WidgetData.fixture(.splatfestSecondHalf))
}

#Preview("Small, empty", as: .systemSmall, using: BattleWidgetIntent()) {
  BattleWidget()
} timelineProvider: {
  BattleTimelineProvider { Snapshot() }
}
#endif
