//
//  InkEventScreens.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - InkChallengeScreenView

/// Ink's Challenge screen, in the look of its Battle Mode screens: the Challenges heading and
/// stamp on the board, then a panel per Challenge with its name, description, Rule and Stages, a
/// time tag per window, the current one tagged "Now!" with its progress and the next one "Next",
/// and its rules text last. The panel holding the current window is taped.
///
/// Like every Style's screen, it receives `IkaCore` values only and reads no store.
public struct InkChallengeScreenView: View {
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
    InkScheduleList(
      heading: .challenges,
      icon: .challenge,
      accent: InkAccent(.challenge),
      title: ModeLabel.challenges.text(in: terms.language),
      reflowValue: screen.challenges.map(\.challenge.id),
      fetchTime: screen.fetchTime,
      now: now,
      isStale: isStale)
    { metrics in
      if screen.challenges.isEmpty {
        InkNote(text: ScreenText.nothingCurrent.text(in: terms.language))
      }
      ForEach(screen.challenges, id: \.challenge.id) { listing in
        InkChallengePanel(listing: listing, terms: terms, now: now, writer: writer, metrics: metrics)
      }
    }
  }

  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - InkSplatfestScreenView

/// Ink's Splatfest screen, in the look of its Battle Mode screens: Splatfest Battle's heading
/// with the form and its stamp, the Splatfest card, Tricolor Turf War in the second half, the
/// form's Rotations with the current one featured and taped, then Regular Battle's Rotations after
/// the end under its name. Splatfest Battle has no Mode colour, so the screen is marked in white;
/// the teams' colours appear on the card beside their names.
///
/// Tricolor Turf War sits right under the card rather than after the form's Rotations, as in
/// Classic: it runs through the whole second half, and up to twelve Rotations would bury it.
///
/// Like every Style's screen, it receives `IkaCore` values only and reads no store.
public struct InkSplatfestScreenView: View {
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
    let mode: RotationMode = .splatfestBattle(screen.form)
    let entries: [InkPanelEntry<Rotation>] = InkPanelEntry.entries(
      current: screen.current,
      next: screen.next,
      later: screen.later)
    let afterwards: [InkPanelEntry<Rotation>] = screen.afterwards.map { InkPanelEntry(item: $0, place: .later) }

    InkScheduleList(
      heading: InkModeHeading(splatfestBattle: screen.form),
      icon: ModeIcon(mode),
      accent: .splatfest,
      title: mode.name(in: terms.language),
      reflowValue: (entries + afterwards).map(\.id),
      fetchTime: screen.fetchTime,
      now: now,
      isStale: isStale)
    { metrics in
      InkEventCard(item: .splatfest(screen.card), terms: terms, now: now)
      if let tricolor = screen.tricolorTurfWar {
        InkTricolorPanel(tricolor: tricolor, terms: terms, now: now, writer: writer, metrics: metrics)
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(writer.sentence(for: tricolor.item, at: now))
      }
      switch screen.current {
        case .running:
          EmptyView()
        case .paused,
             .nothingCurrent:
          InkNote(text: ScreenText.nothingCurrent.text(in: terms.language))
      }
      ForEach(entries) { panel($0, accent: .splatfest, metrics: metrics) }
      if !afterwards.isEmpty {
        InkModeTag(Text(verbatim: ModeLabel.regularBattle.text(in: terms.language)), modeColor: .regularBattle)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, InkScreenMetrics.panelRowSpacing)
          .accessibilityAddTraits(.isHeader)
        ForEach(afterwards) { panel($0, accent: InkAccent(.regularBattle), metrics: metrics) }
      }
    }
  }

  @ViewBuilder
  private func panel(_ entry: InkPanelEntry<Rotation>, accent: InkAccent, metrics: CellMetrics) -> some View {
    // A lineup's Rotations always play: a paused window is never an item.
    if let setting = entry.item.setting {
      InkBattlePanel(
        entry: entry,
        setting: setting,
        terms: terms,
        accent: accent,
        timeRange: format.range(of: entry.item, now: now),
        writer: writer,
        metrics: metrics)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(writer.sentence(for: entry.item, at: now))
    }
  }

  private var format: InkTimeFormat { time.inkFormat(terms.language) }
  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - InkChallengePanel

/// One Challenge's panel: its name, description, Rule over a dotted rule and Stages, then a row
/// per window, and the rules text last, since when it plays matters more than its small print.
/// Taped while one of its windows is on.
private struct InkChallengePanel: View {
  @Environment(\.colorScheme) private var colorScheme
  @TimeSettings private var time

  let listing: ChallengeScreen.Listing
  let terms: GameTerms
  let now: Date
  let writer: SentenceWriter
  let metrics: CellMetrics

  var body: some View {
    let challenge: Challenge = listing.challenge
    let texts: ChallengeTerms = terms.challenge(challenge.id)
    let accent: InkAccent = .init(.challenge)
    let isOn: Bool = listing.windows.contains { $0.mark.isCurrent }

    VStack(alignment: .leading, spacing: InkScreenMetrics.panelRowSpacing) {
      // Closer than the panel's rows, but clear of each other at the texts' close line heights.
      VStack(alignment: .leading, spacing: InkScreenMetrics.panelRowSpacing * 0.7) {
        Text(verbatim: texts.name)
          .inkFont(.headline)
          .lineHeight(.tight)
          .fixedSize(horizontal: false, vertical: true)
        Text(verbatim: texts.displayDescription)
          .inkFont(.body)
          .lineHeight(.multiple(factor: InkScreenMetrics.runningTextLineHeight))
          .fixedSize(horizontal: false, vertical: true)
      }
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(.isHeader)
      InkRuleLabel(rule: challenge.rule, terms: terms, accent: accent, arrangement: metrics.arrangement)
      InkDottedRule()
      InkStageRow(stages: challenge.stages, terms: terms, imageSize: .medium, arrangement: metrics.arrangement)
      VStack(alignment: .leading, spacing: InkScreenMetrics.windowRowSpacing) {
        ForEach(listing.windows, id: \.window) { window in
          row(window, of: challenge, accent: accent)
        }
      }
      .padding(.top, InkScreenMetrics.panelRowSpacing / 2)
      InkDottedRule()
      Text(verbatim: texts.displayRulesText)
        .inkFont(.caption)
        .lineHeight(.multiple(factor: InkScreenMetrics.runningTextLineHeight))
        .foregroundStyle(Color(InkPair.panelSecondaryText.colors(in: colorScheme).foreground))
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .inkPanel(isTaped: isOn)
  }

  /// A window's time tag with its state tag, and its progress while it runs. An ended window
  /// fades.
  private func row(_ window: ChallengeScreen.MarkedWindow, of challenge: Challenge, accent: InkAccent) -> some View {
    let place: InkPanelPlace? = .init(window.mark)

    return VStack(alignment: .leading, spacing: InkScreenMetrics.panelRowSpacing / 2) {
      InkPanelHeader(
        timeRange: format.range(of: window.window, now: now),
        arrangement: metrics.arrangement)
      {
        if let place {
          InkStateTag(place: place, accent: accent)
        }
      }
      if let progress = place?.progress {
        InkProgressBar(
          progress: progress,
          countdown: writer.countdown(progress),
          accent: accent,
          arrangement: metrics.arrangement)
      }
    }
    .opacity(place == nil ? InkScreenMetrics.endedWindowOpacity : 1)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: ChallengeWindow(challenge: challenge, window: window.window), at: now))
  }

  private var format: InkTimeFormat { time.inkFormat(terms.language) }
}

// MARK: - InkTricolorPanel

/// Tricolor Turf War's panel in the Splatfest's second half: its time tag with its tag and
/// "Now!", its Stages and its progress. Not taped: the tape stays on the form's current Rotation.
private struct InkTricolorPanel: View {
  @TimeSettings private var time

  let tricolor: Running<TricolorTurfWar>
  let terms: GameTerms
  let now: Date
  let writer: SentenceWriter
  let metrics: CellMetrics

  var body: some View {
    VStack(alignment: .leading, spacing: InkScreenMetrics.panelRowSpacing) {
      InkPanelHeader(
        timeRange: time.inkFormat(terms.language).range(of: tricolor.item, now: now),
        arrangement: metrics.arrangement)
      {
        InkModeTag(Text(verbatim: ModeLabel.tricolor.text(in: terms.language)), accent: .splatfest)
        InkStateTag(place: .now(tricolor.progress), accent: .splatfest)
      }
      InkStageRow(stages: tricolor.item.stages, terms: terms, imageSize: .large, arrangement: metrics.arrangement)
      InkProgressBar(
        progress: tricolor.progress,
        countdown: writer.countdown(tricolor.progress),
        accent: .splatfest,
        arrangement: metrics.arrangement)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .inkPanel()
  }
}

// MARK: - WindowMark

extension ChallengeScreen.WindowMark {
  /// Whether the window is on now.
  fileprivate var isCurrent: Bool {
    if case .current = self { true } else { false }
  }
}
#endif
