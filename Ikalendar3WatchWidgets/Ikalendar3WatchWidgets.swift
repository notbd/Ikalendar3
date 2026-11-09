//
//  Ikalendar3WatchWidgets.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

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
    StaticConfiguration(kind: "placeholder", provider: PlaceholderProvider()) { _ in
      Text(verbatim: "ikalendar3")
        .containerBackground(.black, for: .widget)
    }
    .supportedFamilies([.accessoryRectangular])
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
