//
//  SmartStackWidget.swift
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

// MARK: - SmartStackWidget

/// The Smart Stack widget set to one Mode: the Mode heading with the stale mark, the current Rule
/// or Shift's Stage with the countdown to its end, then the next one with its start time. A
/// Battle Mode shows Splatfest Battle while a Splatfest replaces it; a Big Run shows as one.
///
/// It stays in the Smart Stack: the watch face takes `ModeComplication`'s rectangular form instead.
struct SmartStackWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: WatchWidgetKind.smartStack.rawValue,
      intent: ModeWidgetIntent.self,
      provider: ModeTimelineProvider())
    { entry in
      SmartStackView(entry: entry)
    }
    .configurationDisplayName(Text("smartStack.name", tableName: "Widgets"))
    .description(Text("smartStack.description", tableName: "Widgets"))
    .supportedFamilies([.accessoryRectangular])
    .disfavoredLocations([.watchFace], for: [.accessoryRectangular])
  }
}

// MARK: - Previews

#if DEBUG
#Preview("Battle", as: .accessoryRectangular, using: ModeWidgetIntent(mode: .xBattle)) {
  SmartStackWidget()
} timelineProvider: {
  ModeTimelineProvider(load: Snapshot.preview(.normalDay))
}

#Preview("Salmon Run", as: .accessoryRectangular, using: ModeWidgetIntent(mode: .salmonRun)) {
  SmartStackWidget()
} timelineProvider: {
  ModeTimelineProvider(load: Snapshot.preview(.normalDay))
}

#Preview("Big Run", as: .accessoryRectangular, using: ModeWidgetIntent(mode: .salmonRun)) {
  SmartStackWidget()
} timelineProvider: {
  ModeTimelineProvider(load: Snapshot.preview(.bigRun))
}

#Preview("Splatfest", as: .accessoryRectangular, using: ModeWidgetIntent(mode: .anarchySeries)) {
  SmartStackWidget()
} timelineProvider: {
  ModeTimelineProvider(load: Snapshot.preview(.splatfestSecondHalf))
}

#Preview("Empty", as: .accessoryRectangular, using: ModeWidgetIntent()) {
  SmartStackWidget()
} timelineProvider: {
  ModeTimelineProvider { Snapshot() }
}
#endif
