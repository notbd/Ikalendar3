//
//  TrackingParts.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - LiveActivityText

/// The strings the Live Activity writes itself, from `IkaDesign`'s `LiveActivity` string table.
/// The raw value is the catalog key. The reminders are `IkaCore`'s, the Refresh button's word
/// `IkaIntents`' (`TrackingText`), the Next tag Ink's (`InkText`). Strings only, so it builds on
/// every platform and the macOS package tests read it.
enum LiveActivityText: String, CaseIterable {
  /// "Nothing later published yet".
  case nothingLater = "liveActivity.nothingLater"

  /// The string in a text set.
  func text(in language: GameLanguage) -> String {
    Bundle.module.localizedString(forKey: rawValue, table: "LiveActivity", in: language)
  }
}

#if os(iOS)

// MARK: - TrackingModeIcon

/// The tracked Mode's bundled icon: the compact and minimal Dynamic Island, and beside its name.
/// Decorative: the name or the sentence around it says the Mode.
public struct TrackingModeIcon: View {
  @ScaledMetric(relativeTo: .caption) private var side: CGFloat = 20

  let mode: Mode

  public init(mode: Mode) {
    self.mode = mode
  }

  public var body: some View {
    Image(decorative: BundledImage.name(for: ModeIcon(mode), size: .small), bundle: BundledImage.catalogBundle)
      .resizable()
      .scaledToFit()
      .frame(width: side, height: side)
  }
}

// MARK: - TrackingModeHeading

/// The tracked Mode's icon and name.
struct TrackingModeHeading: View {
  let render: TrackingRender

  var body: some View {
    HStack(spacing: 6) {
      TrackingModeIcon(mode: render.mode)
      Text(verbatim: render.mode.name(in: render.terms.language))
        .inkFont(.label)
        .scaledLimitedLine()
    }
    .accessibilityElement(children: .combine)
  }
}

// MARK: - TrackingCountdown

/// The system's countdown to the end of the item shown as on, which ticks with no app code
/// running. With nothing on, a warning mark instead: the reminder says why.
///
/// Timer text takes all the width it is offered and sets its digits at the leading edge, so it
/// is right-aligned in a frame as wide as its longest value.
struct TrackingCountdown: View {
  @ScaledMetric(relativeTo: .subheadline) private var width: CGFloat = 76
  @ScaledMetric(relativeTo: .caption) private var compactWidth: CGFloat = 56

  let render: TrackingRender
  /// Whether it sits in the compact Dynamic Island or another tight place, in a smaller face.
  var isCompact = false

  var body: some View {
    if let window = render.currentWindow {
      Text(timerInterval: window, countsDown: true)
        .monospacedDigit()
        .inkFont(isCompact ? .label : .tag)
        .multilineTextAlignment(.trailing)
        .frame(maxWidth: isCompact ? compactWidth : width, alignment: .trailing)
    }
    else {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.yellow)
        .accessibilityHidden(true)
    }
  }
}

// MARK: - TrackingCurrentView

/// The item shown as on: a Rotation's Rule and Stages, a pause with when the Battle Mode returns,
/// or a Shift's Stage and weapons; or that nothing is on. VoiceOver reads it as one element, the
/// item's sentence, with the countdown it holds as its value, which the system keeps current as
/// widgets do; where the countdown sits beside it, VoiceOver reads the countdown on its own.
struct TrackingCurrentView: View {
  /// How much of the item shows.
  enum Detail {
    /// The Rule, or a Big Run's mark, with the countdown, over the Stages as cards (a Shift's
    /// Stage beside its weapons).
    case cards
    /// The Rule, or the Shift's Stage, over the Stages' or the weapons' names.
    case names
    /// The Rule, or the Shift's Stage, alone.
    case title
  }

  @TimeSettings private var time
  /// How far a card's name tag hangs below its picture: half the tag's height.
  @ScaledMetric(relativeTo: .footnote) private var nameOverhang: CGFloat = 10

  let render: TrackingRender
  let detail: Detail

  var body: some View {
    Group {
      switch detail {
        case .cards:
          VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
              title
              Spacer(minLength: 4)
              TrackingCountdown(render: render)
            }
            pictures
          }

        case .names:
          VStack(alignment: .leading, spacing: 4) {
            title
            names
          }

        case .title:
          title
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(sentence)
    .accessibilityValue(heldCountdown.map { Text(timerInterval: $0) } ?? Text(verbatim: ""))
  }

  /// The window of the countdown the view holds: the cards' countdown, while an item is on.
  private var heldCountdown: ClosedRange<Date>? {
    detail == .cards ? render.currentWindow : nil
  }

  /// The Rule, the pause's return or a Shift's Stage, which a card names instead; a Big Run's
  /// mark before it.
  @ViewBuilder private var title: some View {
    switch render.frame {
      case .battle(_, let frame):
        if let rotation = frame.current {
          if let setting = rotation.setting {
            RuleLabel(rule: setting.rule, terms: terms, style: detail == .cards ? .tag : .label)
          }
          else {
            label(ScreenText.paused.text(
              in: terms.language,
              format.time(rotation.endTime, relativeTo: render.renderTime)))
          }
        }
        else {
          label(ScreenText.nothingCurrent.text(in: terms.language))
        }

      case .salmonRun(let frame):
        if let shift = frame.current {
          HStack(spacing: 6) {
            if shift.isBigRun {
              InkModeTag(Text(verbatim: ModeLabel.bigRun.text(in: terms.language)), modeColor: .bigRun)
            }
            if detail != .cards {
              label(terms.name(of: shift.stage))
            }
          }
        }
        else {
          label(ScreenText.nothingCurrent.text(in: terms.language))
        }
    }
  }

  /// The Stages as cards, or a Shift's Stage as a card beside its weapons.
  @ViewBuilder private var pictures: some View {
    switch render.frame {
      case .battle(_, let frame):
        if let stages = frame.current?.setting?.stages {
          HStack(spacing: 6) {
            ForEach(stages, id: \.self) { stage in
              InkStageCard(stage: stage, name: Text(verbatim: terms.name(of: stage)), imageSize: .small)
            }
            Spacer(minLength: 0)
          }
          .stageCardRow(overhang: nameOverhang)
        }

      case .salmonRun(let frame):
        if let shift = frame.current {
          HStack(alignment: .top, spacing: 8) {
            InkStageCard(stage: shift.stage, name: Text(verbatim: terms.name(of: shift.stage)), imageSize: .small)
            TrackingWeapons(weapons: shift.weapons)
            Spacer(minLength: 0)
          }
          .stageCardRow(overhang: nameOverhang)
        }
    }
  }

  /// The Stages' or the weapons' names on one line.
  @ViewBuilder private var names: some View {
    let names: [String]? =
      switch render.frame {
        case .battle(_, let frame): frame.current?.setting?.stages.map(terms.name(of:))
        case .salmonRun(let frame): frame.current?.weapons.map(terms.name(of:))
      }
    if let names {
      Text(verbatim: names.joined(separator: " · "))
        .inkFont(.caption)
        .foregroundStyle(.secondary)
        .scaledLimitedLine(minScaleFactor: 0.6)
    }
  }

  /// What VoiceOver reads: the item's sentence, or that nothing is on.
  private var sentence: String {
    switch render.frame {
      case .battle(let mode, let frame):
        frame.current.map { writer.sentence(for: $0, of: mode) } ?? ScreenText.nothingCurrent.text(in: terms.language)
      case .salmonRun(let frame):
        frame.current.map { writer.sentence(for: $0) } ?? ScreenText.nothingCurrent.text(in: terms.language)
    }
  }

  private func label(_ text: String) -> some View {
    Text(verbatim: text)
      .inkFont(.label)
      .scaledLimitedLine(lineLimit: 2)
  }

  private var terms: GameTerms { render.terms }
  private var format: ScheduleFormat { time.format(terms.language) }
  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - Stage card row

extension View {
  /// Caps a row of Stage cards so the Lock Screen view stays within the 160 points the system
  /// allows, and keeps room below for the name tags that straddle the pictures' bottom edge.
  fileprivate func stageCardRow(overhang: CGFloat) -> some View {
    frame(maxHeight: 54)
      .padding(.bottom, overhang)
  }
}

// MARK: - TrackingWeapons

/// A Shift's four weapons as bundled pictures. Decorative: the Shift's sentence names them.
private struct TrackingWeapons: View {
  @ScaledMetric(relativeTo: .body) private var side: CGFloat = 30

  let weapons: [WeaponID]

  var body: some View {
    HStack(spacing: 4) {
      ForEach(Array(weapons.enumerated()), id: \.offset) { _, weapon in
        Image(decorative: BundledImage.name(for: weapon, size: .small), bundle: BundledImage.catalogBundle)
          .resizable()
          .scaledToFit()
          .frame(width: side, height: side)
      }
    }
  }
}

// MARK: - TrackingNextLine

/// What follows the item on: the reminder while one shows, else the next item after its tag, or
/// that nothing later is published yet.
struct TrackingNextLine: View {
  @TimeSettings private var time

  let render: TrackingRender

  var body: some View {
    if let reminder = render.reminder {
      TrackingReminderLabel(reminder: reminder, language: language)
    }
    else {
      switch render.frame {
        case .battle(let mode, let frame):
          if let next = frame.next {
            tagged(writer.sentence(for: next, of: mode)) {
              if let setting = next.setting {
                RuleLabel(rule: setting.rule, terms: render.terms, style: .label)
              }
              else {
                Text(verbatim: ModeLabel.splatfest.text(in: language))
                  .inkFont(.label)
              }
            }
          }
          else {
            nothingLater
          }

        case .salmonRun(let frame):
          if let next = frame.next {
            tagged(writer.sentence(for: next)) {
              Text(verbatim: render.terms.name(of: next.stage))
                .inkFont(.label)
                .scaledLimitedLine()
            }
          }
          else {
            nothingLater
          }
      }
    }
  }

  /// The next item after its tag, read by VoiceOver as the tag and the item's sentence.
  private func tagged(_ sentence: String, @ViewBuilder item: () -> some View) -> some View {
    let tag = InkText.next.text(in: language)
    return HStack(spacing: 6) {
      InkModeTag(Text(verbatim: tag), modeColor: ModeColor(render.mode))
      item()
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(tag): \(sentence)")
  }

  private var nothingLater: some View {
    Text(verbatim: LiveActivityText.nothingLater.text(in: language))
      .font(.caption)
      .foregroundStyle(.secondary)
      .scaledLimitedLine()
  }

  private var language: GameLanguage { render.terms.language }
  private var writer: SentenceWriter { time.writer(render.terms) }
}

// MARK: - TrackingReminderLabel

/// A reminder that the schedule moved on without an update, with a warning mark. VoiceOver reads
/// the reminder's phrase.
struct TrackingReminderLabel: View {
  let reminder: TrackingReminder
  let language: GameLanguage

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 4) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.yellow)
        .accessibilityHidden(true)
      Text(verbatim: reminder.text(in: language))
        .scaledLimitedLine(lineLimit: 2)
    }
    .font(.caption.weight(.semibold))
  }
}

// MARK: - TrackingFetchTime

/// When the schedules feed shown was last confirmed (ticket 19's decision for the Live Activity:
/// no three-hour mark, since the stale date already marks a passed boundary).
struct TrackingFetchTime: View {
  @TimeSettings private var time

  let render: TrackingRender

  var body: some View {
    let language = render.terms.language
    let format = time.format(language)
    Text(verbatim: ScreenText.fetchTime.text(
      in: language,
      format.time(render.fetchTime, relativeTo: render.renderTime)))
      .font(.caption2)
      .foregroundStyle(.secondary)
      .scaledLimitedLine()
  }
}

// MARK: - TrackingRefreshLabel

/// The Refresh button's label, with the word the reminders tell the player to tap. The widget
/// extension puts it in a button that runs the Refresh intent, which this module cannot name; both
/// that button and the Debug showcase's take `trackingRefreshButtonStyle()`.
public struct TrackingRefreshLabel: View {
  let title: String
  let systemImage: String

  public init(title: String, systemImage: String) {
    self.title = title
    self.systemImage = systemImage
  }

  public var body: some View {
    Label(title, systemImage: systemImage)
      .font(.caption.weight(.semibold))
      .lineLimit(1)
  }
}

extension View {
  /// The Refresh button's look: bordered, in white on Ink's dark materials.
  public func trackingRefreshButtonStyle() -> some View {
    buttonStyle(.bordered)
      .tint(.white)
  }
}
#endif
