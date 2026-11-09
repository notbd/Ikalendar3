//
//  LockScreenBattleView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import IkaCore
import IkaDesign
import SwiftUI
import WidgetKit

// MARK: - LockScreenBattleView

/// The battle widget on the Lock Screen, in the family the system draws it at: circular (the
/// Battle Mode's icon and the countdown), rectangular (the Battle Mode, the Rule and the
/// countdown) or inline (the Rule and the countdown). It shows Splatfest Battle while a Splatfest
/// replaces the Battle Mode, as every battle widget does, and marks stale data in every family.
struct LockScreenBattleView: View {
  let entry: ScheduleWidgetEntry<BattleWidgetContent>
  let family: WidgetFamily

  var body: some View {
    Group {
      if let schedule = entry.schedule {
        switch family {
          case .accessoryCircular: CircularBattleView(entry: schedule, terms: entry.terms)
          case .accessoryInline: InlineBattleView(entry: schedule, terms: entry.terms)
          default: RectangularBattleView(entry: schedule, terms: entry.terms)
        }
      }
      else {
        Text(verbatim: ScreenText.empty.text(in: entry.terms.language))
          .inkFont(.label)
          .scaledLimitedLine(lineLimit: 2)
          .multilineTextAlignment(.center)
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

// MARK: - CircularBattleView

/// The shown Battle Mode's icon over the system's countdown to the current Rotation's end, or over
/// the return time of a pause. VoiceOver reads it as one element: the Rotation's sentence and its
/// time left, or the pause sentence.
private struct CircularBattleView: View {
  @Environment(\.timeZone) private var timeZone

  let entry: WidgetEntry<BattleWidgetContent>
  let terms: GameTerms

  var body: some View {
    let content = entry.content

    VStack(spacing: 2) {
      ModeIconImage(ModeIcon(content.shownMode), side: 22)
        .overlay(alignment: .topTrailing) {
          FreshnessLabel(entry: entry, showsFetchTime: false)
            .offset(x: 8, y: -4)
        }
      switch content.current {
        case .item(let rotation):
          Text(timerInterval: rotation.startTime ... rotation.endTime)

        case .paused(let returnTime):
          Text(verbatim: ScheduleFormat(language: terms.language, timeZone: timeZone).time(
            returnTime,
            relativeTo: entry.date))

        case .nothingCurrent:
          EmptyView()
      }
    }
    .inkFont(.label)
    .monospacedDigit()
    .scaledLimitedLine(minScaleFactor: 0.5)
    .multilineTextAlignment(.center)
    .padding(4)
    .currentAccessibility(content.current, of: content.mode, terms: terms, isStale: entry.isStale)
  }
}

// MARK: - RectangularBattleView

/// The shown Battle Mode's heading, then the current Rotation's Rule over the system's countdown
/// to its end, or the pause with its return time.
private struct RectangularBattleView: View {
  let entry: WidgetEntry<BattleWidgetContent>
  let terms: GameTerms

  var body: some View {
    let content = entry.content

    VStack(alignment: .leading, spacing: 2) {
      ModeHeading(mode: content.shownMode, in: terms.language) {
        FreshnessLabel(entry: entry, showsFetchTime: false)
      }
      Group {
        switch content.current {
          case .item(let rotation):
            VStack(alignment: .leading, spacing: 1) {
              if let setting = rotation.setting {
                RuleLabel(rule: setting.rule, terms: terms, style: .tag)
              }
              Text(timerInterval: rotation.startTime ... rotation.endTime)
                .inkFont(.body)
                .monospacedDigit()
                .scaledLimitedLine()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

          case .paused(let returnTime):
            PausedView(mode: content.mode, returnTime: returnTime, date: entry.date, terms: terms)

          case .nothingCurrent:
            Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
              .inkFont(.label)
              .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .currentAccessibility(content.current, of: content.mode, terms: terms, isStale: false)
      Spacer(minLength: 0)
    }
  }
}

// MARK: - InlineBattleView

/// One line beside the Lock Screen's date: the current Rotation's Rule and the system's countdown
/// to its end, or the pause with its return time, after a warning sign while the data is stale.
/// The system sets the font and draws only the first text and image.
private struct InlineBattleView: View {
  @Environment(\.timeZone) private var timeZone

  let entry: WidgetEntry<BattleWidgetContent>
  let terms: GameTerms

  var body: some View {
    let content = entry.content

    Group {
      if entry.isStale {
        Label {
          text(content.current)
        } icon: {
          Image(systemName: "exclamationmark.triangle.fill")
        }
      }
      else {
        text(content.current)
      }
    }
    .currentAccessibility(content.current, of: content.mode, terms: terms, isStale: entry.isStale)
  }

  private func text(_ current: WidgetCurrent<Rotation>) -> Text {
    switch current {
      case .item(let rotation):
        let rule: Text = .init(verbatim: rotation.setting.map { terms.name(of: $0.rule) } ?? "")
        // A space joins the two in every text set; the line has no room for more.
        return Text("\(rule) \(Text(timerInterval: rotation.startTime ... rotation.endTime))")

      case .paused(let returnTime):
        let format: ScheduleFormat = .init(language: terms.language, timeZone: timeZone)
        return Text(verbatim: ScreenText.paused.text(
          in: terms.language,
          format.time(returnTime, relativeTo: entry.date)))

      case .nothingCurrent:
        return Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
    }
  }
}

// MARK: - Current accessibility

extension View {
  /// Makes the view one VoiceOver element for what a Battle Mode has on: the Rotation's sentence
  /// with the system's countdown to its end as the value, so VoiceOver hears the time left when
  /// it reads, or the pause sentence, or "Nothing on right now". Where `isStale`, the stale mark's
  /// words follow, for families whose mark sits inside the element.
  fileprivate func currentAccessibility(
    _ current: WidgetCurrent<Rotation>,
    of mode: BattleMode,
    terms: GameTerms,
    isStale: Bool)
    -> some View
  {
    modifier(CurrentAccessibility(current: current, mode: mode, terms: terms, isStale: isStale))
  }
}

// MARK: - CurrentAccessibility

private struct CurrentAccessibility: ViewModifier {
  @Environment(\.timeZone) private var timeZone

  let current: WidgetCurrent<Rotation>
  let mode: BattleMode
  let terms: GameTerms
  let isStale: Bool

  func body(content: Content) -> some View {
    let element = content
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(label)
    if let rotation = current.item {
      element.accessibilityValue(Text(timerInterval: rotation.startTime ... rotation.endTime))
    }
    else {
      element
    }
  }

  private var label: String {
    let writer: SentenceWriter = .init(terms: terms, timeZone: timeZone, hourCycle: Locale.current.hourCycle)
    let sentence =
      switch current {
        case .item(let rotation): writer.sentence(for: rotation)
        case .paused(let returnTime): writer.sentence(forPauseOf: mode, returningAt: returnTime)
        case .nothingCurrent: ScreenText.nothingCurrent.text(in: terms.language)
      }
    return isStale ? "\(sentence) \(WidgetText.stale.text(in: terms.language))" : sentence
  }
}
#endif
