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

/// Timeline's Challenge screen: each Challenge's texts, then its windows hung on a column of
/// start times, a stand-in until ticket 31 draws SplatNet 3's schedule page. It receives
/// `IkaCore` values only and reads no store.
public struct TimelineChallengeScreenView: View {
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
    List {
      if screen.challenges.isEmpty {
        Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
      }
      ForEach(screen.challenges, id: \.challenge.id) { listing in
        details(of: listing.challenge)
        ForEach(listing.windows, id: \.window) { window in
          row(window)
        }
      }
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
        .listRowSeparator(.hidden)
    }
    .listStyle(.plain)
  }

  private func details(of challenge: Challenge) -> some View {
    let texts = terms.challenge(challenge.id)
    let ruleAndStages = [terms.name(of: challenge.rule)] + challenge.stages.map(terms.name(of:))
    return VStack(alignment: .leading, spacing: 4) {
      Text(verbatim: texts.name)
        .font(.title3.weight(.bold))
      Text(verbatim: texts.description)
        .font(.subheadline)
      Text(verbatim: ruleAndStages.joined(separator: " · "))
        .font(.subheadline.weight(.semibold))
      Text(verbatim: texts.rulesText)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.top, 8)
    .accessibilityElement(children: .combine)
  }

  private func row(_ window: ChallengeScreen.MarkedWindow) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Text(verbatim: format.time(window.window.startTime, relativeTo: now))
        .font(.subheadline.monospacedDigit().weight(.semibold))
        .frame(minWidth: 52, alignment: .leading)
      VStack(alignment: .leading, spacing: 2) {
        Text(verbatim: format.timeRange(of: window.window))
          .font(.subheadline)
        if case .current(let progress) = window.mark {
          ProgressView(value: progress.sharePassed)
        }
      }
      Spacer()
      if window.mark == .next {
        Text(verbatim: ScreenText.next.text(in: terms.language))
          .font(.caption.weight(.bold))
      }
    }
    .foregroundStyle(window.mark == .over ? .secondary : .primary)
    .accessibilityElement(children: .combine)
  }

  private var format: ScheduleFormat { .init(language: terms.language, timeZone: timeZone) }
}

// MARK: - TimelineSplatfestScreenView

/// Timeline's Splatfest screen: the Splatfest card, then the form's Rotations, Tricolor Turf War
/// in the second half and Regular Battle's Rotations after the end, hung on a column of start
/// times, a stand-in until ticket 31 draws SplatNet 3's schedule page. It receives `IkaCore`
/// values only and reads no store.
public struct TimelineSplatfestScreenView: View {
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
    List {
      SplatfestCardView(splatfest: screen.splatfest, art: art, terms: terms, style: .timeline, now: now)
      switch screen.current {
        case .running(let running):
          row(running.item, progress: running.progress)
        case .paused,
             .nothingCurrent:
          Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
      }
      ForEach([screen.next].compactMap(\.self) + screen.later, id: \.self) { rotation in
        row(rotation, progress: nil)
      }
      if let tricolor = screen.tricolorTurfWar {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
          Text(verbatim: format.time(tricolor.item.startTime, relativeTo: now))
            .font(.subheadline.monospacedDigit().weight(.semibold))
            .frame(minWidth: 52, alignment: .leading)
          VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: ModeLabel.tricolor.text(in: terms.language))
              .font(.caption.weight(.bold))
            Text(verbatim: tricolor.item.stages.map(terms.name(of:)).joined(separator: " · "))
              .font(.headline)
            ProgressView(value: tricolor.progress.sharePassed)
          }
        }
        .accessibilityElement(children: .combine)
      }
      if !screen.afterwards.isEmpty {
        Text(verbatim: ModeLabel.regularBattle.text(in: terms.language))
          .font(.headline)
          .accessibilityAddTraits(.isHeader)
        ForEach(screen.afterwards, id: \.self) { rotation in
          row(rotation, progress: nil)
        }
      }
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
        .listRowSeparator(.hidden)
    }
    .listStyle(.plain)
  }

  private func row(_ rotation: Rotation, progress: WindowProgress?) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Text(verbatim: format.time(rotation.startTime, relativeTo: now))
        .font(.subheadline.monospacedDigit().weight(.semibold))
        .frame(minWidth: 52, alignment: .leading)
      VStack(alignment: .leading, spacing: 2) {
        Text(verbatim: rotation.setting.map { terms.name(of: $0.rule) } ?? "")
          .font(.headline)
        Text(verbatim: rotation.setting?.stages.map(terms.name(of:)).joined(separator: " · ") ?? "")
          .font(.subheadline)
        if let progress {
          ProgressView(value: progress.sharePassed)
        }
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: rotation, at: now))
  }

  private var format: ScheduleFormat { .init(language: terms.language, timeZone: timeZone) }
  private var writer: SentenceWriter { .init(terms: terms, timeZone: timeZone, hourCycle: Locale.current.hourCycle) }
}
#endif
