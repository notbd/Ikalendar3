//
//  Ikalendar3WatchWidgets.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaDesign
import SwiftUI
import WidgetKit

// MARK: - Ikalendar3WatchWidgets

/// The watch widget extension: complications and the Smart Stack.
@main
struct Ikalendar3WatchWidgets: WidgetBundle {
  var body: some Widget {
    PlaceholderWidget()
  }
}

// MARK: - PlaceholderWidget

/// Stands in until the extension's first real widget; an extension must declare at least one.
struct PlaceholderWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "placeholder", provider: PlaceholderProvider()) { entry in
      PlaceholderView(date: entry.date)
    }
    .supportedFamilies([.accessoryRectangular])
  }
}

// MARK: - PlaceholderView

/// Draws Ink's base components until the first real widget replaces it, so this extension builds
/// them.
struct PlaceholderView: View {
  let date: Date

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      InkModeTag(Text(verbatim: "ikalendar3"), modeColor: .anarchy)
      InkTimeTag(Text(date, style: .time))
    }
    .containerBackground(for: .widget) {
      InkBackground()
    }
  }
}

// MARK: - PlaceholderEntry

struct PlaceholderEntry: TimelineEntry {
  let date: Date
}

// MARK: - PlaceholderProvider

struct PlaceholderProvider: TimelineProvider {
  func placeholder(in _: Context) -> PlaceholderEntry {
    PlaceholderEntry(date: .now)
  }

  func getSnapshot(in _: Context, completion: @escaping (PlaceholderEntry) -> Void) {
    completion(PlaceholderEntry(date: .now))
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
    completion(Timeline(entries: [PlaceholderEntry(date: .now)], policy: .never))
  }
}
