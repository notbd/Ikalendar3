//
//  Ikalendar3WatchWidgets.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import IkaResources
import SwiftUI
import WidgetKit

// MARK: - Ikalendar3WatchWidgets

/// The watch widget extension: complications and the Smart Stack.
@main
struct Ikalendar3WatchWidgets: WidgetBundle {
  /// Registers the fonts and points image lookups at the resource framework before anything draws.
  init() {
    BundledResources.load(from: IkaResources.bundle)
  }

  var body: some Widget {
    PlaceholderWidget()
  }
}

extension Ikalendar3WatchWidgets {
  /// The app language: the text set of the localization the system resolved for this extension's
  /// bundle. It declares the watch app's 14 localizations, so it resolves the watch app's.
  static let language: GameLanguage = .init(localization: Bundle.main.preferredLocalizations.first ?? "en")
}

// MARK: - PlaceholderWidget

/// Stands in until the extension's first real widget; an extension must declare at least one.
struct PlaceholderWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "placeholder", provider: PlaceholderProvider()) { entry in
      PlaceholderView(date: entry.date)
        .environment(\.gameLanguage, Ikalendar3WatchWidgets.language)
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
