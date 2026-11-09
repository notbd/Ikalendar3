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

/// Ink's Challenge screen: each Challenge's texts and windows on Ink's panels and dotted
/// background, a stand-in until ticket 30 draws the full layout. It receives `IkaCore` values
/// only and reads no store.
public struct InkChallengeScreenView: View {
  @Environment(\.timeZone) private var timeZone

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
    ScrollView {
      LazyVStack(spacing: 12) {
        if screen.challenges.isEmpty {
          Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
            .inkFont(.label)
            .frame(maxWidth: .infinity, alignment: .leading)
            .inkPanel(isTaped: true)
        }
        ForEach(screen.challenges, id: \.challenge.id) { listing in
          panel(listing)
        }
        FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
      }
      .padding()
    }
    .background(InkBackground())
  }

  /// A Challenge's panel; it is taped while one of its windows is on.
  private func panel(_ listing: ChallengeScreen.Listing) -> some View {
    let challenge = listing.challenge
    let texts = terms.challenge(challenge.id)
    let ruleAndStages = [terms.name(of: challenge.rule)] + challenge.stages.map(terms.name(of:))
    let isOn = listing.windows.contains { if case .current = $0.mark { true } else { false } }
    return VStack(alignment: .leading, spacing: 4) {
      Text(verbatim: texts.name)
        .inkFont(.headline)
      Text(verbatim: texts.displayDescription)
        .inkFont(.body)
      Text(verbatim: ruleAndStages.joined(separator: " · "))
        .inkFont(.label)
      Text(verbatim: texts.displayRulesText)
        .inkFont(.caption)
      ForEach(listing.windows, id: \.window) { window in
        row(window)
      }
      .padding(.top, 4)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .inkPanel(isTaped: isOn)
  }

  private func row(_ window: ChallengeScreen.MarkedWindow) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(verbatim: format.timeRange(of: window.window, withWeekday: true))
          .inkFont(.body)
        Spacer()
        if window.mark == .next {
          Text(verbatim: ScreenText.next.text(in: terms.language))
            .inkFont(.tag)
        }
      }
      if case .current(let progress) = window.mark {
        ProgressView(value: progress.sharePassed) {
          Text(verbatim: writer.timeLeft(progress))
            .inkFont(.caption)
        }
      }
    }
    .opacity(window.mark == .over ? 0.5 : 1)
    .accessibilityElement(children: .combine)
  }

  private var format: ScheduleFormat { .init(language: terms.language, timeZone: timeZone) }
  private var writer: SentenceWriter { .init(terms: terms, timeZone: timeZone, hourCycle: Locale.current.hourCycle) }
}

// MARK: - InkSplatfestScreenView

/// Ink's Splatfest screen: the Splatfest card, the form's Rotations, Tricolor Turf War in the
/// second half and Regular Battle's Rotations after the end, on Ink's panels and dotted
/// background, a stand-in until ticket 30 draws the full layout. It receives `IkaCore` values
/// only and reads no store.
public struct InkSplatfestScreenView: View {
  @Environment(\.timeZone) private var timeZone

  private let screen: SplatfestScreen
  private let art: URL?
  private let terms: GameTerms
  private let now: Date
  private let isStale: Bool

  /// - Parameters:
  ///   - screen: What the screen shows at `now`.
  ///   - art: The Splatfest's stored art, or `nil` while none is downloaded.
  ///   - terms: The game's names in the app language.
  ///   - now: The app clock's instant.
  ///   - isStale: Whether the last refresh of the schedules feed failed.
  public init(screen: SplatfestScreen, art: URL?, terms: GameTerms, now: Date, isStale: Bool) {
    self.screen = screen
    self.art = art
    self.terms = terms
    self.now = now
    self.isStale = isStale
  }

  public var body: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        SplatfestCardView(splatfest: screen.splatfest, art: art, terms: terms, style: .ink, now: now)
          .inkPanel()
        switch screen.current {
          case .running(let running):
            panel(running.item, progress: running.progress)
          case .paused,
               .nothingCurrent:
            Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
              .inkFont(.label)
              .frame(maxWidth: .infinity, alignment: .leading)
              .inkPanel(isTaped: true)
        }
        ForEach([screen.next].compactMap(\.self) + screen.later, id: \.self) { rotation in
          panel(rotation, progress: nil)
        }
        if let tricolor = screen.tricolorTurfWar {
          VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: format.dateRange(of: tricolor.item))
              .inkFont(.body)
            Text(verbatim: ModeLabel.tricolor.text(in: terms.language))
              .inkFont(.tag)
            Text(verbatim: tricolor.item.stages.map(terms.name(of:)).joined(separator: " · "))
              .inkFont(.headline)
            ProgressView(value: tricolor.progress.sharePassed) {
              Text(verbatim: writer.timeLeft(tricolor.progress))
                .inkFont(.caption)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .inkPanel(isTaped: true)
          .accessibilityElement(children: .combine)
        }
        if !screen.afterwards.isEmpty {
          Text(verbatim: ModeLabel.regularBattle.text(in: terms.language))
            .inkFont(.label)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
          ForEach(screen.afterwards, id: \.self) { rotation in
            panel(rotation, progress: nil)
          }
        }
        FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
      }
      .padding()
    }
    .background(InkBackground())
  }

  /// A Rotation's panel; the current one is taped and carries its progress.
  private func panel(_ rotation: Rotation, progress: WindowProgress?) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(verbatim: format.timeRange(of: rotation))
        .inkFont(.body)
      Text(verbatim: rotation.setting.map { terms.name(of: $0.rule) } ?? "")
        .inkFont(progress == nil ? .label : .headline)
      Text(verbatim: rotation.setting?.stages.map(terms.name(of:)).joined(separator: " · ") ?? "")
        .inkFont(.caption)
      if let progress {
        ProgressView(value: progress.sharePassed) {
          Text(verbatim: writer.timeLeft(progress))
            .inkFont(.caption)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .inkPanel(isTaped: progress != nil)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: rotation, at: now))
  }

  private var format: ScheduleFormat { .init(language: terms.language, timeZone: timeZone) }
  private var writer: SentenceWriter { .init(terms: terms, timeZone: timeZone, hourCycle: Locale.current.hourCycle) }
}
#endif
