//
//  WidgetParts.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI
import WidgetKit

// MARK: - WidgetText

/// The strings the widgets write themselves, from this extension's `Widgets` string table. The raw
/// value is the catalog key. Names shown to the system (widget names, the configuration intent)
/// are looked up by key where they are declared.
enum WidgetText: String {
  /// "Schedule may be out of date": what the stale mark reads.
  case stale = "widget.stale"

  /// The string in a text set.
  func text(in language: GameLanguage) -> String {
    Bundle.main.localizedString(forKey: rawValue, table: "Widgets", in: language)
  }
}

// MARK: - ModeHeading

/// A Battle Mode's icon and name over a widget's content or a column of it, with `trailing` at the
/// far end, such as how fresh the data is. VoiceOver reads it as one element.
struct ModeHeading<Trailing: View>: View {
  @Environment(\.gameLanguage) private var language

  let mode: RotationMode
  @ViewBuilder var trailing: Trailing

  var body: some View {
    HStack(spacing: 6) {
      ModeIconImage(mode: mode)
      Text(verbatim: mode.name(in: language))
        .inkFont(.label)
        .scaledLimitedLine()
      Spacer(minLength: 0)
      trailing
    }
    .accessibilityElement(children: .combine)
  }
}

extension ModeHeading where Trailing == EmptyView {
  init(mode: RotationMode) {
    self.init(mode: mode) { EmptyView() }
  }
}

// MARK: - FreshnessLabel

/// How fresh an entry's data is: when it was fetched, where `showsFetchTime` (sizes with room), and
/// in every size a mark while it is stale.
struct FreshnessLabel<Content: Hashable & Sendable>: View {
  @Environment(\.gameLanguage) private var language
  @TimeSettings private var time

  let entry: WidgetEntry<Content>
  let showsFetchTime: Bool

  var body: some View {
    HStack(spacing: 3) {
      if entry.isStale {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(.yellow)
          .widgetAccentable()
          .accessibilityLabel(WidgetText.stale.text(in: language))
      }
      if showsFetchTime {
        let format = time.format(language)
        Text(verbatim: ScreenText.fetchTime.text(in: language, format.time(entry.fetchTime, relativeTo: entry.date)))
          .scaledLimitedLine()
      }
    }
    .font(.caption2)
    .foregroundStyle(.secondary)
  }
}

// MARK: - EmptyWidgetView

/// A widget's empty state before the schedules feed's first good response: the screens' "No
/// schedule yet", in text that fits every size.
struct EmptyWidgetView: View {
  @Environment(\.gameLanguage) private var language

  var body: some View {
    VStack(spacing: 6) {
      Image(systemName: "calendar")
        .font(.title2)
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
      Text(verbatim: ScreenText.empty.text(in: language))
        .inkFont(.label)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - ModeIconImage

/// A Battle Mode's bundled icon, at the size of the text beside it. Decorative: the name beside it
/// or the sentence around it says the Battle Mode.
struct ModeIconImage: View {
  @ScaledMetric(relativeTo: .caption) private var side: CGFloat = 16

  let mode: RotationMode

  var body: some View {
    Image(decorative: BundledImage.name(for: ModeIcon(mode), size: .small), bundle: BundledImage.catalogBundle)
      .resizable()
      .scaledToFit()
      .frame(width: side, height: side)
  }
}

// MARK: - CurrentView

/// What a Battle Mode has on from the entry's date: its Rotation with the Rule, both Stages and the
/// system's countdown to its end; its pause with the return time; or nothing.
struct CurrentView: View {
  let current: WidgetCurrent<Rotation>
  /// The Battle Mode the widget or row is set to, which a pause names.
  let mode: BattleMode
  let date: Date
  let terms: GameTerms
  /// How the two Stage cards sit.
  var stageAxis: Axis = .horizontal
  /// The Rule name's style.
  var ruleStyle: InkTextStyle = .headline

  var body: some View {
    switch current {
      case .item(let rotation):
        RotationView(rotation: rotation, terms: terms, stageAxis: stageAxis, ruleStyle: ruleStyle, showsCountdown: true)
      case .paused(let returnTime):
        PausedView(mode: mode, returnTime: returnTime, date: date, terms: terms)
      case .nothingCurrent:
        Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
          .inkFont(.label)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

// MARK: - RotationView

/// A Rotation's Rule, its two Stages as cards and, for the current one, the system's countdown to
/// its end; else its time range. VoiceOver reads it as one element: the Rotation's sentence, then,
/// for the current one, the countdown as its value. The sentence carries no time left, because
/// the system draws a widget ahead of the moment VoiceOver reads it; the system's timer text
/// stays current.
struct RotationView: View {
  @TimeSettings private var time

  let rotation: Rotation
  let terms: GameTerms
  var stageAxis: Axis = .horizontal
  var ruleStyle: InkTextStyle = .tag
  var showsCountdown = false

  var body: some View {
    let countdown: Text? = showsCountdown ? Text(timerInterval: rotation.startTime ... rotation.endTime) : nil

    VStack(alignment: .leading, spacing: 6) {
      if let setting = rotation.setting {
        RuleLabel(rule: setting.rule, terms: terms, style: ruleStyle)
        StageCards(stages: setting.stages, terms: terms, axis: stageAxis)
      }
      if let countdown {
        InkTimeTag(countdown)
      }
      else {
        InkTimeTag(Text(verbatim: time.format(terms.language).timeRange(of: rotation)))
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: rotation))
    .accessibilityValue(countdown ?? Text(verbatim: ""))
  }

  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - RotationRow

/// A later Rotation in a row: its time range, then its Rule over its Stages' names, with its
/// Battle Mode's icon when that is not the widget's, as after a Splatfest. VoiceOver reads it as one
/// element, the Rotation's sentence.
struct RotationRow: View {
  @TimeSettings private var time

  let rotation: Rotation
  let terms: GameTerms
  /// The Battle Mode the widget names.
  let shownMode: RotationMode

  var body: some View {
    HStack(spacing: 8) {
      InkTimeTag(Text(verbatim: time.format(terms.language).timeRange(of: rotation)))
      if rotation.mode != shownMode {
        ModeIconImage(mode: rotation.mode)
      }
      if let setting = rotation.setting {
        VStack(alignment: .leading, spacing: 1) {
          RuleLabel(rule: setting.rule, terms: terms, style: .label)
          Text(verbatim: setting.stages.map(terms.name(of:)).joined(separator: " · "))
            .inkFont(.caption)
            .foregroundStyle(.secondary)
            .scaledLimitedLine(minScaleFactor: 0.6)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: rotation))
  }

  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - PausedView

/// A Battle Mode a Splatfest pauses, with when it returns. VoiceOver reads its pause sentence.
struct PausedView: View {
  @TimeSettings private var time

  let mode: BattleMode
  let returnTime: Date
  let date: Date
  let terms: GameTerms

  var body: some View {
    let format = time.format(terms.language)
    Text(verbatim: ScreenText.paused.text(in: terms.language, format.time(returnTime, relativeTo: date)))
      .inkFont(.label)
      .scaledLimitedLine(lineLimit: 3)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(writer.sentence(forPauseOf: mode, returningAt: returnTime))
  }

  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - RuleLabel

/// A Rule's icon and name in `style`, the icon as tall as the text.
struct RuleLabel: View {
  @ScaledMetric private var side: CGFloat

  private let rule: RuleID
  private let terms: GameTerms
  private let style: InkTextStyle

  init(rule: RuleID, terms: GameTerms, style: InkTextStyle) {
    self.rule = rule
    self.terms = terms
    self.style = style
    _side = ScaledMetric(wrappedValue: style.size, relativeTo: style.textStyle)
  }

  var body: some View {
    HStack(spacing: 4) {
      Image(decorative: BundledImage.name(for: rule, size: .small), bundle: BundledImage.catalogBundle)
        .resizable()
        .scaledToFit()
        .frame(width: side, height: side)
      Text(verbatim: terms.name(of: rule))
        .inkFont(style)
        .scaledLimitedLine()
    }
  }
}

// MARK: - StageCards

/// A Rotation's two Stages as Ink cards, side by side or stacked.
struct StageCards: View {
  let stages: [StageID]
  let terms: GameTerms
  let axis: Axis

  var body: some View {
    let layout: AnyLayout = axis == .horizontal
      ? AnyLayout(HStackLayout(spacing: 6))
      : AnyLayout(VStackLayout(spacing: 12))
    layout {
      ForEach(stages, id: \.self) { stage in
        InkStageCard(stage: stage, name: Text(verbatim: terms.name(of: stage)), imageSize: .medium)
      }
    }
  }
}
