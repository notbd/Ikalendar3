//
//  ModeComplication.swift
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

// MARK: - ModeComplication

/// The complication set to one Mode, in the four families a watch face offers: circular (the Mode
/// icon over the countdown), corner (the Mode icon, the countdown along the bezel), rectangular
/// (the Mode, the current Rule or Shift's Stage and the countdown) and inline (the Rule or Stage
/// and the countdown). A Battle Mode shows Splatfest Battle while a Splatfest replaces it, as
/// every widget set to one does; a Big Run shows as one. Every family marks stale data.
///
/// Its rectangular form stays on the face: the Smart Stack takes `SmartStackWidget` instead.
struct ModeComplication: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: WatchWidgetKind.complication.rawValue,
      intent: ModeWidgetIntent.self,
      provider: ModeTimelineProvider())
    { entry in
      ModeComplicationView(entry: entry)
    }
    .configurationDisplayName(Text("complication.name", tableName: "Widgets"))
    .description(Text("complication.description", tableName: "Widgets"))
    .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryRectangular, .accessoryInline])
    .disfavoredLocations([.smartStack], for: [.accessoryRectangular])
  }
}

// MARK: - ModeComplicationView

/// The complication in the family the system draws it at (`ModeComplicationLayout`).
struct ModeComplicationView: View {
  @Environment(\.widgetFamily) private var family

  let entry: ScheduleWidgetEntry<WatchWidgetContent>

  var body: some View {
    ModeComplicationLayout(entry: entry, family: family)
  }
}

// MARK: - Previews

#if DEBUG
#Preview("Circular", as: .accessoryCircular, using: ModeWidgetIntent(mode: .xBattle)) {
  ModeComplication()
} timelineProvider: {
  ModeTimelineProvider(load: Snapshot.preview(.normalDay))
}

#Preview("Circular, Big Run", as: .accessoryCircular, using: ModeWidgetIntent(mode: .salmonRun)) {
  ModeComplication()
} timelineProvider: {
  ModeTimelineProvider(load: Snapshot.preview(.bigRun))
}

#Preview("Corner", as: .accessoryCorner, using: ModeWidgetIntent(mode: .anarchySeries)) {
  ModeComplication()
} timelineProvider: {
  ModeTimelineProvider(load: Snapshot.preview(.normalDay))
}

#Preview("Rectangular", as: .accessoryRectangular, using: ModeWidgetIntent(mode: .anarchyOpen)) {
  ModeComplication()
} timelineProvider: {
  ModeTimelineProvider(load: Snapshot.preview(.normalDay))
}

#Preview("Rectangular, Salmon Run", as: .accessoryRectangular, using: ModeWidgetIntent(mode: .salmonRun)) {
  ModeComplication()
} timelineProvider: {
  ModeTimelineProvider(load: Snapshot.preview(.normalDay))
}

#Preview("Rectangular, Splatfest", as: .accessoryRectangular, using: ModeWidgetIntent(mode: .xBattle)) {
  ModeComplication()
} timelineProvider: {
  ModeTimelineProvider(load: Snapshot.preview(.splatfestSecondHalf))
}

#Preview("Inline", as: .accessoryInline, using: ModeWidgetIntent(mode: .regularBattle)) {
  ModeComplication()
} timelineProvider: {
  ModeTimelineProvider(load: Snapshot.preview(.normalDay))
}

#Preview("Rectangular, empty", as: .accessoryRectangular, using: ModeWidgetIntent()) {
  ModeComplication()
} timelineProvider: {
  ModeTimelineProvider { Snapshot() }
}
#endif
