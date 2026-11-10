//
//  WidgetRotationParts.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if !os(watchOS)
import IkaCore
import SwiftUI
import WidgetKit

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
/// its end; else its time range. VoiceOver reads it as one element, the Rotation's sentence with,
/// for the current one, the countdown as its value (`WidgetAccessibility`).
struct RotationView: View {
  @TimeSettings private var time

  let rotation: Rotation
  let terms: GameTerms
  var stageAxis: Axis = .horizontal
  var ruleStyle: InkTextStyle = .tag
  var showsCountdown = false

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      if let setting = rotation.setting {
        RuleLabel(rule: setting.rule, terms: terms, style: ruleStyle)
        StageCards(stages: setting.stages, terms: terms, axis: stageAxis)
      }
      if showsCountdown {
        InkTimeTag(Text(timerInterval: rotation.startTime ... rotation.endTime))
      }
      else {
        InkTimeTag(Text(verbatim: time.format(terms.language).timeRange(of: rotation)))
      }
    }
    .widgetAccessibility(WidgetAccessibility(rotation, writer: time.writer(terms), isCurrent: showsCountdown))
  }
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
        ModeIconImage(ModeIcon(rotation.mode))
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
    .widgetAccessibility(WidgetAccessibility(rotation, writer: time.writer(terms), isCurrent: false))
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
#endif
