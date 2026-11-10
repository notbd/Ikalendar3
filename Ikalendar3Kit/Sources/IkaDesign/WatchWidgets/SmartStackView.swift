//
//  SmartStackView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(watchOS)
import IkaCore
import SwiftUI
import WidgetKit

// MARK: - SmartStackView

/// The Smart Stack widget in Ink, or "No schedule yet" before the first good response.
public struct SmartStackView: View {
  let entry: ScheduleWidgetEntry<WatchWidgetContent>

  public init(entry: ScheduleWidgetEntry<WatchWidgetContent>) {
    self.entry = entry
  }

  public var body: some View {
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
#endif
