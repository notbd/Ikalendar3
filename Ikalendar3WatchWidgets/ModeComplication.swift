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

/// The complication in the family the system draws it at, or "No schedule yet" before the first
/// good response.
struct ModeComplicationView: View {
  @Environment(\.widgetFamily) private var family

  let entry: ScheduleWidgetEntry<WatchWidgetContent>

  var body: some View {
    Group {
      if let schedule = entry.schedule {
        switch family {
          case .accessoryCircular: CircularView(entry: schedule, terms: entry.terms)
          case .accessoryCorner: CornerView(entry: schedule, terms: entry.terms)
          case .accessoryInline: InlineView(entry: schedule, terms: entry.terms)
          default: RectangularView(entry: schedule, terms: entry.terms)
        }
      }
      else {
        WatchEmptyView(language: entry.terms.language)
      }
    }
    .environment(\.gameLanguage, entry.terms.language)
    .containerBackground(for: .widget) {
      if family == .accessoryCircular {
        AccessoryWidgetBackground()
      }
    }
  }
}

// MARK: - CircularView

/// The Mode icon, with the stale mark at its corner, over the system's countdown to the current
/// item's end, or over the return time of a pause.
private struct CircularView: View {
  @TimeSettings private var time

  let entry: WidgetEntry<WatchWidgetContent>
  let terms: GameTerms

  var body: some View {
    VStack(spacing: 1) {
      ModeIconImage(entry.content.icon, side: 20)
        .overlay(alignment: .topTrailing) {
          FreshnessLabel(entry: entry, showsFetchTime: false)
            .offset(x: 8, y: -4)
        }
      switch entry.content.current(in: terms) {
        case .item(let item):
          Text(timerInterval: item.window)
        case .paused(_, let returnTime):
          Text(verbatim: time.format(terms.language).time(returnTime, relativeTo: entry.date))
        case .nothing:
          EmptyView()
      }
    }
    .inkFont(.label)
    .monospacedDigit()
    .scaledLimitedLine(minScaleFactor: 0.5)
    .multilineTextAlignment(.center)
    .padding(4)
    .currentAccessibility(entry, terms: terms)
  }
}

// MARK: - CornerView

/// The Mode icon in the corner, with the countdown, or the return time of a pause, along the bezel
/// after the stale mark.
private struct CornerView: View {
  let entry: WidgetEntry<WatchWidgetContent>
  let terms: GameTerms

  var body: some View {
    ModeIconImage(entry.content.icon, side: 24)
      .widgetLabel {
        StatusLine(entry: entry, terms: terms, showsTitle: false)
      }
      .currentAccessibility(entry, terms: terms)
  }
}

// MARK: - RectangularView

/// The Mode heading with the stale mark, then the current Rule or Shift's Stage over the system's
/// countdown to its end, or the pause with its return time.
private struct RectangularView: View {
  let entry: WidgetEntry<WatchWidgetContent>
  let terms: GameTerms

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      ModeHeading(entry.content, in: terms.language) {
        FreshnessLabel(entry: entry, showsFetchTime: false)
      }
      Group {
        switch entry.content.current(in: terms) {
          case .item(let item):
            VStack(alignment: .leading, spacing: 1) {
              WatchItemLabel(item: item, terms: terms, style: .tag)
              Text(timerInterval: item.window)
                .inkFont(.body)
                .monospacedDigit()
                .scaledLimitedLine()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

          case .paused(let mode, let returnTime):
            PausedView(mode: mode, returnTime: returnTime, date: entry.date, terms: terms)

          case .nothing:
            Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
              .inkFont(.label)
              .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .currentAccessibility(entry, terms: terms, readsStale: false)
      Spacer(minLength: 0)
    }
  }
}

// MARK: - InlineView

/// One line of the face: the current Rule or Shift's Stage and the system's countdown to its end,
/// or the pause with its return time, after the stale mark. The system sets the font.
private struct InlineView: View {
  let entry: WidgetEntry<WatchWidgetContent>
  let terms: GameTerms

  var body: some View {
    StatusLine(entry: entry, terms: terms, showsTitle: true)
      .currentAccessibility(entry, terms: terms)
  }
}

// MARK: - StatusLine

/// What a Mode has on as one line of text, for the families that draw only text: the item's
/// title, where `showsTitle`, and the system's countdown to its end; or the pause with its return
/// time; or "Nothing on right now". A warning sign leads it while the data is stale.
private struct StatusLine: View {
  @TimeSettings private var time

  let entry: WidgetEntry<WatchWidgetContent>
  let terms: GameTerms
  let showsTitle: Bool

  var body: some View {
    if entry.isStale {
      Text("\(Image(systemName: "exclamationmark.triangle.fill")) \(status)")
    }
    else {
      status
    }
  }

  private var status: Text {
    switch entry.content.current(in: terms) {
      case .item(let item):
        let countdown: Text = .init(timerInterval: item.window)
        // A space joins the two in every text set; the line has no room for more.
        return showsTitle ? Text("\(Text(verbatim: item.title)) \(countdown)") : countdown

      case .paused(_, let returnTime):
        let format = time.format(terms.language)
        return Text(verbatim: ScreenText.paused.text(
          in: terms.language,
          format.time(returnTime, relativeTo: entry.date)))

      case .nothing:
        return Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
    }
  }
}

// MARK: - Current accessibility

extension View {
  /// Makes the view one VoiceOver element for what a watch widget's Mode has on: the item's
  /// sentence with the system's countdown to its end as the value, the pause sentence, or
  /// "Nothing on right now" (`WidgetAccessibility`). Where `readsStale` and the data is stale, the
  /// stale mark's words follow, for families whose mark sits inside the element.
  func currentAccessibility(
    _ entry: WidgetEntry<WatchWidgetContent>,
    terms: GameTerms,
    readsStale: Bool = true)
    -> some View
  {
    modifier(CurrentAccessibility(
      content: entry.content,
      terms: terms,
      isStale: readsStale && entry.isStale))
  }
}

// MARK: - CurrentAccessibility

private struct CurrentAccessibility: ViewModifier {
  @TimeSettings private var time

  let content: WatchWidgetContent
  let terms: GameTerms
  let isStale: Bool

  func body(content view: Content) -> some View {
    view.widgetAccessibility(WidgetAccessibility(
      content,
      writer: time.writer(terms),
      note: isStale ? WidgetText.stale.text(in: terms.language) : nil))
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
