//
//  ClassicEventScreens.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - ClassicChallengeScreenView

/// Classic's Challenge screen: each Challenge's texts and windows as plain rows in an inset
/// grouped list, a stand-in until ticket 29 draws ikalendar 2's look. It receives `IkaCore`
/// values only and reads no store.
public struct ClassicChallengeScreenView: View {
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
    List {
      if screen.challenges.isEmpty {
        Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
      }
      ForEach(screen.challenges, id: \.challenge.id) { listing in
        Section {
          details(of: listing.challenge)
          ForEach(listing.windows, id: \.window) { window in
            row(window)
          }
        }
      }
      Section { } footer: {
        FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
      }
    }
    .classicListStyle()
  }

  private func details(of challenge: Challenge) -> some View {
    let texts = terms.challenge(challenge.id)
    let ruleAndStages = [terms.name(of: challenge.rule)] + challenge.stages.map(terms.name(of:))
    return VStack(alignment: .leading, spacing: 4) {
      Text(verbatim: texts.name)
        .font(.headline)
      Text(verbatim: texts.displayDescription)
        .font(.subheadline)
      Text(verbatim: ruleAndStages.joined(separator: " · "))
        .font(.subheadline.weight(.semibold))
      Text(verbatim: texts.displayRulesText)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .accessibilityElement(children: .combine)
  }

  private func row(_ window: ChallengeScreen.MarkedWindow) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(verbatim: format.timeRange(of: window.window, withWeekday: true))
        Spacer()
        if window.mark == .next {
          Text(verbatim: ScreenText.next.text(in: terms.language))
            .font(.caption.weight(.semibold))
        }
      }
      if case .current(let progress) = window.mark {
        ProgressView(value: progress.sharePassed) {
          Text(verbatim: writer.timeLeft(progress))
        }
      }
    }
    .foregroundStyle(window.mark == .over ? .secondary : .primary)
    .accessibilityElement(children: .combine)
  }

  private var format: ScheduleFormat { time.format(terms.language) }
  private var writer: SentenceWriter { time.writer(terms) }
}

// MARK: - ClassicSplatfestScreenView

/// Classic's Splatfest screen: the Splatfest card, the form's Rotations, Tricolor Turf War in the
/// second half and Regular Battle's Rotations after the end, as plain rows in an inset grouped
/// list, a stand-in until ticket 29 draws ikalendar 2's look. It receives `IkaCore` values only
/// and reads no store.
public struct ClassicSplatfestScreenView: View {
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
    List {
      Section {
        SplatfestCardView(splatfest: screen.splatfest, art: screen.art, terms: terms, style: .classic, now: now)
      }
      Section {
        switch screen.current {
          case .running(let running):
            row(running.item)
            ProgressView(value: running.progress.sharePassed) {
              Text(verbatim: writer.timeLeft(running.progress))
            }
            .accessibilityHidden(true)

          case .paused,
               .nothingCurrent:
            Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
        }
        ForEach([screen.next].compactMap(\.self) + screen.later, id: \.self) { rotation in
          row(rotation)
        }
      }
      if let tricolor = screen.tricolorTurfWar {
        Section(ModeLabel.tricolor.text(in: terms.language)) {
          VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: format.dateRange(of: tricolor.item))
              .font(.caption)
              .foregroundStyle(.secondary)
            Text(verbatim: tricolor.item.stages.map(terms.name(of:)).joined(separator: " · "))
              .font(.headline)
          }
          ProgressView(value: tricolor.progress.sharePassed) {
            Text(verbatim: writer.timeLeft(tricolor.progress))
          }
        }
      }
      if !screen.afterwards.isEmpty {
        Section(ModeLabel.regularBattle.text(in: terms.language)) {
          ForEach(screen.afterwards, id: \.self) { rotation in
            row(rotation)
          }
        }
      }
      Section { } footer: {
        FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
      }
    }
    .classicListStyle()
  }

  private func row(_ rotation: Rotation) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(verbatim: format.timeRange(of: rotation))
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(verbatim: rotation.setting.map { terms.name(of: $0.rule) } ?? "")
        .font(.headline)
      Text(verbatim: rotation.setting?.stages.map(terms.name(of:)).joined(separator: " · ") ?? "")
        .font(.subheadline)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: rotation, at: now))
  }

  private var format: ScheduleFormat { time.format(terms.language) }
  private var writer: SentenceWriter { time.writer(terms) }
}
#endif
