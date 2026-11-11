//
//  TimelineAxis.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - TimelineAxis

/// SplatNet 3's time axis: a Mode-colour line down the left with one slot per entry, each hung on
/// its start pin, a day mark where the axis reaches a new day, and the current item's
/// progress filled in along its slot.
struct TimelineAxis<Item: TimeWindow & Hashable & Sendable, SlotContent: View>: View {
  let entries: [TimelineEntry<Item>]
  let format: TimelineFormat
  let arrangement: CellArrangement
  /// What an entry's slot shows right of the line.
  @ViewBuilder let content: (TimelineEntry<Item>) -> SlotContent
  /// The colour of an entry's stretch of the line and of its pin while it runs.
  let color: (TimelineEntry<Item>) -> TimelineTint
  /// The sentence VoiceOver reads for an entry.
  let sentence: (TimelineEntry<Item>) -> String

  var body: some View {
    VStack(spacing: 0) {
      TimelineTrack(color: entries.first.map(color) ?? .neutral, progress: nil)
        .frame(maxWidth: .infinity, minHeight: TimelineMetrics.axisTop, alignment: .leading)
      ForEach(Array(zip(entries, dayMarks)), id: \.0.id) { entry, dayMark in
        VStack(spacing: 0) {
          if let dayMark {
            TimelineDayMark(text: dayMark, color: color(entry), arrangement: arrangement)
          }
          TimelineSlot(
            color: color(entry),
            pin: entry.item.map { format.pin($0.startTime) },
            progress: entry.progress?.sharePassed,
            arrangement: arrangement)
          {
            content(entry)
          }
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(sentence(entry))
        }
      }
    }
  }

  /// Each entry's day mark, where its start falls on a new day after the start above it.
  private var dayMarks: [String?] {
    var previous: Date?
    return entries.map { entry in
      guard let start = entry.item?.startTime else { return nil }

      defer { previous = start }
      return format.startsNewDay(start, after: previous) ? format.day(start) : nil
    }
  }
}

// MARK: - TimelineSlot

/// One entry on the axis: its content right of the line, its pin on the line (inside the slot
/// when stacked, where a large pin would cover the content), and its stretch of the line, which
/// spans the space below it so the line runs on unbroken.
private struct TimelineSlot<Content: View>: View {
  let color: TimelineTint
  let pin: AttributedString?
  /// The share of the item passed while it runs, or `nil`.
  let progress: Double?
  let arrangement: CellArrangement
  @ViewBuilder let content: Content

  var body: some View {
    let isStacked: Bool = arrangement == .stacked

    VStack(alignment: .leading, spacing: 8) {
      if isStacked, let pin {
        TimelinePin(text: pin, color: color, isCurrent: progress != nil)
      }
      content
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.leading, isStacked ? TimelineMetrics.stackedContentLeading : TimelineMetrics.contentLeading)
    .padding(.trailing, TimelineMetrics.contentTrailing)
    .padding(.bottom, TimelineMetrics.slotSpacing)
    .background(alignment: .topLeading) {
      TimelineTrack(color: color, progress: progress)
    }
    .overlay(alignment: .topLeading) {
      if !isStacked, let pin {
        TimelinePin(text: pin, color: color, isCurrent: progress != nil)
          .frame(
            maxWidth: TimelineMetrics.contentLeading - TimelineMetrics.pinLeading * 2,
            alignment: .leading)
          .padding(.leading, TimelineMetrics.pinLeading)
          .offset(y: -1)
      }
    }
  }
}

// MARK: - TimelineTrack

/// A stretch of the axis line: the Mode colour, dimmed, with the passed share of a running item
/// filled in from the top.
private struct TimelineTrack: View {
  let color: TimelineTint
  /// The share filled in, or `nil` for none.
  let progress: Double?

  var body: some View {
    let base: Color = .init(color.base)

    ZStack(alignment: .top) {
      Rectangle()
        .fill(base.opacity(TimelinePalette.trackOpacity))
      if let progress {
        Rectangle()
          .fill(base)
          .scaleEffect(x: 1, y: ProgressBarGeometry(share: progress).share, anchor: .top)
      }
    }
    .frame(width: TimelineMetrics.axisLineWidth)
    .padding(.leading, TimelineMetrics.axisLineLeading)
    .accessibilityHidden(true)
  }
}

// MARK: - TimelinePin

/// A start time on the axis: in the Mode colour while its item runs, light grey otherwise. Every
/// pin is at least the pin column's width with its time centred, so 12-hour times of different
/// lengths line up; their AM or PM is set smaller, as a clock face sets it.
struct TimelinePin: View {
  @Environment(\.gameLanguage) private var language
  @ScaledMetric(relativeTo: .subheadline) private var dayPeriodSize: CGFloat = 11

  let text: AttributedString
  let color: TimelineTint
  let isCurrent: Bool

  var body: some View {
    let colors: ColorPair = isCurrent ? color.asFill : TimelinePalette.idlePin

    Text(styledText)
      .ikaFont(.heavy, size: 15, relativeTo: .subheadline)
      .monospacedDigit()
      .scaledLimitedLine(lineLimit: 1, minScaleFactor: 0.5)
      .foregroundStyle(Color(colors.foreground))
      .padding(.horizontal, 7)
      .padding(.vertical, 2)
      .frame(minWidth: TimelineMetrics.pinWidth)
      .background(Color(colors.background), in: .rect(cornerRadius: TimelineMetrics.pinCornerRadius))
  }

  /// The time with its AM or PM in the smaller size.
  private var styledText: AttributedString {
    var text = text
    let dayPeriod: Font = FontCascade(role: .heavy, language: language, registered: FontRegistry.registered)
      .font(size: dayPeriodSize)
    for run in text.runs where run.foundation.dateField == .amPM {
      text[run.range].swiftUI.font = dayPeriod
    }
    return text
  }
}

// MARK: - TimelineDayMark

/// The weekday and date where the axis reaches a new day. VoiceOver reads it as a heading, since
/// a Rotation's sentence carries no date.
private struct TimelineDayMark: View {
  let text: String
  let color: TimelineTint
  let arrangement: CellArrangement

  var body: some View {
    Text(verbatim: text)
      .ikaFont(.light, size: 14, relativeTo: .footnote)
      .foregroundStyle(TimelinePalette.secondaryText)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(
        .leading,
        arrangement == .stacked
          ? TimelineMetrics.stackedContentLeading
          : TimelineMetrics.contentLeading)
        .padding(.bottom, TimelineMetrics.slotSpacing / 2)
        .background(alignment: .topLeading) {
          TimelineTrack(color: color, progress: nil)
        }
        .accessibilityAddTraits(.isHeader)
  }
}
#endif
