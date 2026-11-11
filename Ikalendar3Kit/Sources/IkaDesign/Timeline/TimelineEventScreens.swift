//
//  TimelineEventScreens.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - TimelineChallengeScreenView

/// Timeline's Challenge screen, after SplatNet 3's schedule page: the black header, then each
/// Challenge with its name, description, Rule and Stages, its six windows on a Challenge-colour
/// time axis under their day marks, the current one's progress filled in and ended ones greyed,
/// and its rules text last: when it runs matters more than its fine print.
///
/// Like every Style's screen, it receives `IkaCore` values only and reads no store.
public struct TimelineChallengeScreenView: View {
  @TimeSettings private var time

  private let screen: ChallengeScreen
  private let terms: GameTerms
  private let now: Date
  private let isStale: Bool

  /// - Parameters:
  ///   - screen: What the screen shows at `now`.
  ///   - terms: The game's names in the app language.
  ///   - now: The app clock's instant.
  ///   - isStale: Whether the last refresh of the schedules feed failed.
  public init(screen: ChallengeScreen, terms: GameTerms, now: Date, isStale: Bool) {
    self.screen = screen
    self.terms = terms
    self.now = now
    self.isStale = isStale
  }

  public var body: some View {
    let format: TimelineFormat = time.timelineFormat(terms.language)
    let writer: SentenceWriter = time.writer(terms)
    let name: String = ModeLabel.challenges.text(in: terms.language)

    TimelineScheduleList(
      icon: .challenge,
      title: name,
      headerName: name,
      reflowValue: screen.challenges.map(\.challenge.id))
    {
      EmptyView()
    } axis: { arrangement in
      if screen.challenges.isEmpty {
        TimelineStatusContent(text: ScreenText.nothingCurrent.text(in: terms.language))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, TimelineMetrics.axisLineLeading)
          .padding(.top, TimelineMetrics.axisTop)
      }
      ForEach(screen.challenges, id: \.challenge.id) { listing in
        TimelineChallengeDetails(challenge: listing.challenge, terms: terms, arrangement: arrangement)
        TimelineAxis(
          entries: TimelineEntry.entries(of: listing),
          format: format,
          arrangement: arrangement)
        { entry in
          if let window = entry.item {
            TimelineChallengeWindowContent(
              window: window,
              progress: entry.progress,
              isOver: window.endTime <= now,
              terms: terms,
              format: format,
              now: now,
              arrangement: arrangement)
          }
        } color: { _ in
          TimelineTint(.challenge)
        } sentence: { entry in
          entry.item.map { writer.sentence(for: $0, at: now) } ?? ""
        }
        TimelineChallengeRules(challenge: listing.challenge, terms: terms)
      }
    } footer: {
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
    }
  }
}

// MARK: - TimelineSplatfestScreenView

/// Timeline's Splatfest screen, after SplatNet 3's schedule page: the black header with the Open
/// and Pro strip, the Splatfest card, then one time axis with Tricolor Turf War on top in the
/// second half, the form's Rotations and Regular Battle's Rotations from the Splatfest's end,
/// each of those marked.
///
/// Tricolor Turf War sits on top at its start, the midterm, which no Rotation on the axis
/// precedes, so it shows right under the card and the axis still reads in time order. The
/// Splatfest's own items take the neutral tint, since no one team's colour stands for them; the
/// teams' colours stay on the card beside their names. It receives `IkaCore` values only and
/// reads no store.
public struct TimelineSplatfestScreenView: View {
  @TimeSettings private var time

  private let screen: SplatfestScreen
  private let terms: GameTerms
  private let now: Date
  private let isStale: Bool

  /// - Parameters:
  ///   - screen: What the screen shows at `now`.
  ///   - terms: The game's names in the app language.
  ///   - now: The app clock's instant.
  ///   - isStale: Whether the last refresh of the schedules feed failed.
  public init(screen: SplatfestScreen, terms: GameTerms, now: Date, isStale: Bool) {
    self.screen = screen
    self.terms = terms
    self.now = now
    self.isStale = isStale
  }

  public var body: some View {
    let entries: [TimelineEntry<TimelineSplatfestItem>] = TimelineEntry.entries(of: screen)
    let format: TimelineFormat = time.timelineFormat(terms.language)
    let writer: SentenceWriter = time.writer(terms)

    TimelineScheduleList(
      icon: .splatfestBattle,
      title: RotationMode.splatfestBattle(screen.form).name(in: terms.language),
      headerName: ModeLabel.splatfestBattle.text(in: terms.language),
      strip: TimelineFormStrip(shown: screen.form, language: terms.language),
      reflowValue: entries.map(\.id))
    {
      TimelineSplatfestCard(card: screen.card, terms: terms, now: now)
        .padding(.horizontal, TimelineMetrics.contentTrailing)
        .padding(.top, TimelineMetrics.axisTop)
    } axis: { arrangement in
      TimelineAxis(
        entries: entries,
        format: format,
        arrangement: arrangement)
      { entry in
        switch entry {
          case .item(.rotation(let rotation), let progress):
            if let setting = rotation.setting {
              VStack(alignment: .leading, spacing: 8) {
                if rotation.mode == .battle(.regular) {
                  TimelineModeTag(
                    icon: .regularBattle,
                    label: ModeLabel.regularBattle.text(in: terms.language),
                    colors: ModeColor.regularBattle.asFill)
                }
                TimelineRotationContent(
                  setting: setting,
                  progress: progress,
                  color: Self.tint(of: rotation),
                  terms: terms,
                  now: now,
                  arrangement: arrangement)
              }
            }

          case .item(.tricolorTurfWar(let tricolorTurfWar), let progress):
            TimelineTricolorContent(
              tricolorTurfWar: tricolorTurfWar,
              progress: progress,
              terms: terms,
              now: now,
              arrangement: arrangement)

          case .paused,
               .nothingCurrent:
            // A form of Splatfest Battle is never paused: any status is nothing current.
            TimelineStatusContent(text: ScreenText.nothingCurrent.text(in: terms.language))
        }
      } color: { entry in
        if case .rotation(let rotation) = entry.item { Self.tint(of: rotation) } else { .neutral }
      } sentence: { entry in
        switch entry {
          case .item(.rotation(let rotation), _): writer.sentence(for: rotation, at: now)
          case .item(.tricolorTurfWar(let tricolorTurfWar), _): writer.sentence(for: tricolorTurfWar, at: now)
          case .paused,
               .nothingCurrent: ScreenText.nothingCurrent.text(in: terms.language)
        }
      }
    } footer: {
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
    }
  }
}

extension TimelineSplatfestScreenView {
  /// The tint of a Rotation on the axis: Regular Battle's colour after the Splatfest, neutral for
  /// the form's own.
  static private func tint(of rotation: Rotation) -> TimelineTint {
    if case .battle(let battleMode) = rotation.mode { TimelineTint(ModeColor(battleMode)) } else { .neutral }
  }
}

// MARK: - TimelineChallengeDetails

/// What a Challenge's axis hangs under: its name and description, its Rule, and its Stages
/// joined in one strip.
private struct TimelineChallengeDetails: View {
  let challenge: Challenge
  let terms: GameTerms
  let arrangement: CellArrangement

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      TimelineChallengeTitle(challenge: challenge, terms: terms)
        .accessibilityAddTraits(.isHeader)
      Text(verbatim: terms.challenge(challenge.id).displayDescription)
        .ikaFont(.light, size: 14, relativeTo: .subheadline)
        .lineHeight(TimelineMetrics.wrappedLineHeight)
        .foregroundStyle(TimelinePalette.secondaryText)
        .fixedSize(horizontal: false, vertical: true)
      TimelineRuleLabel(rule: challenge.rule, terms: terms, arrangement: arrangement)
      TimelineStageStrip(stages: challenge.stages, terms: terms, arrangement: arrangement)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.leading, TimelineMetrics.axisLineLeading)
    .padding(.trailing, TimelineMetrics.contentTrailing)
    .padding(.top, TimelineMetrics.axisTop + 8)
  }
}

// MARK: - TimelineChallengeRules

/// A Challenge's rules text, under its windows.
private struct TimelineChallengeRules: View {
  let challenge: Challenge
  let terms: GameTerms

  var body: some View {
    Text(verbatim: terms.challenge(challenge.id).displayRulesText)
      .ikaFont(.light, size: 13, relativeTo: .footnote)
      .lineHeight(TimelineMetrics.wrappedLineHeight)
      .foregroundStyle(TimelinePalette.secondaryText)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.leading, TimelineMetrics.axisLineLeading)
      .padding(.trailing, TimelineMetrics.contentTrailing)
  }
}

// MARK: - TimelineChallengeWindowContent

/// A Challenge window's slot: its hours, which its day mark dates, and "Now" with the countdown
/// while it runs; greyed once it has ended.
private struct TimelineChallengeWindowContent: View {
  let window: ChallengeWindow
  let progress: WindowProgress?
  let isOver: Bool
  let terms: GameTerms
  let format: TimelineFormat
  let now: Date
  let arrangement: CellArrangement

  var body: some View {
    TimelineHeadline(arrangement: arrangement) {
      Text(verbatim: format.hourRange(from: window.startTime, to: window.endTime))
        .ikaFont(.light, size: 16, relativeTo: .body)
        .monospacedDigit()
        .scaledLimitedLine(for: arrangement)
        .foregroundStyle(isOver ? TimelinePalette.pastText : .white)
    } trailing: {
      if let progress {
        TimelineNowTag(timeLeft: progress.timeLeft, color: TimelineTint(.challenge), language: terms.language, now: now)
      }
    }
  }
}

// MARK: - TimelineTricolorContent

/// Tricolor Turf War's slot: its tag, "Now" with the countdown, and its Stages joined in one
/// strip.
private struct TimelineTricolorContent: View {
  let tricolorTurfWar: TricolorTurfWar
  let progress: WindowProgress?
  let terms: GameTerms
  let now: Date
  let arrangement: CellArrangement

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      TimelineHeadline(arrangement: arrangement) {
        TimelineModeTag(
          icon: .splatfestBattle,
          label: ModeLabel.tricolor.text(in: terms.language),
          colors: TimelinePalette.idlePin)
      } trailing: {
        if let progress {
          TimelineNowTag(timeLeft: progress.timeLeft, color: .neutral, language: terms.language, now: now)
        }
      }
      TimelineStageStrip(stages: tricolorTurfWar.stages, terms: terms, arrangement: arrangement)
    }
  }
}
#endif
