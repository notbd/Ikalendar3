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

// MARK: - SmartStackView

/// The Smart Stack widget in Ink, or "No schedule yet" before the first good response.
struct SmartStackView: View {
  let entry: ScheduleWidgetEntry<WatchWidgetContent>

  var body: some View {
    Group {
      if let schedule = entry.schedule {
        content(schedule)
      }
      else {
        WatchEmptyView(language: entry.terms.language)
      }
    }
    .environment(\.gameLanguage, entry.terms.language)
    .containerBackground(for: .widget) {
      InkBackground()
    }
  }

  private func content(_ schedule: WidgetEntry<WatchWidgetContent>) -> some View {
    let terms = entry.terms

    return VStack(alignment: .leading, spacing: 3) {
      ModeHeading(schedule.content, in: terms.language) {
        FreshnessLabel(entry: schedule, showsFetchTime: false)
      }
      CurrentRow(entry: schedule, terms: terms)
      if let next = schedule.content.next(in: terms) {
        NextRow(item: next, content: schedule.content, date: schedule.date, terms: terms)
      }
      Spacer(minLength: 0)
    }
  }
}

// MARK: - CurrentRow

/// The current Rule or Shift's Stage beside the system's countdown to its end; or the pause with
/// its return time; or "Nothing on right now".
private struct CurrentRow: View {
  let entry: WidgetEntry<WatchWidgetContent>
  let terms: GameTerms

  var body: some View {
    Group {
      switch entry.content.current(in: terms) {
        case .item(let item):
          HStack(spacing: 4) {
            WatchItemLabel(item: item, terms: terms, style: .tag)
            Spacer(minLength: 0)
            InkTimeTag(Text(timerInterval: item.window))
              .monospacedDigit()
          }

        case .paused(let mode, let returnTime):
          PausedView(mode: mode, returnTime: returnTime, date: entry.date, terms: terms)
            .fixedSize(horizontal: false, vertical: true)

        case .nothing:
          Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
            .inkFont(.label)
            .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .currentAccessibility(entry, terms: terms, readsStale: false)
  }
}

// MARK: - NextRow

/// The next Rotation's Rule or Shift's Stage after its start, with its weekday when that is not on
/// the entry's day, as a Shift's often is. VoiceOver reads its sentence, with its time range.
private struct NextRow: View {
  @TimeSettings private var time

  let item: WatchItem
  let content: WatchWidgetContent
  let date: Date
  let terms: GameTerms

  var body: some View {
    HStack(spacing: 4) {
      Text(verbatim: time.format(terms.language).time(item.startTime, relativeTo: date))
        .inkFont(.caption)
        .foregroundStyle(.secondary)
        .monospacedDigit()
        .scaledLimitedLine(minScaleFactor: 0.6)
      WatchItemLabel(item: item, terms: terms, style: .label)
        .layoutPriority(1)
      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(content.nextAccessibility(writer: time.writer(terms))?.label ?? item.title)
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
