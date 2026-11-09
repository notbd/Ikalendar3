//
//  TimelineScreens.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - TimelineBattleScreenView

/// Timeline's Battle Mode screen: plain rows hung on a column of start times, a stand-in until
/// ticket 28 draws SplatNet 3's schedule page.
///
/// Like every Style's screen, it receives `IkaCore` values only and reads no store. Pull to
/// refresh reaches its list through the `refreshable` action the shared screen sets.
public struct TimelineBattleScreenView: View {
  @Environment(\.timeZone) private var timeZone

  private let screen: BattleScreen
  private let terms: GameTerms
  private let now: Date
  private let isStale: Bool

  /// - Parameters:
  ///   - screen: What the screen shows at `now`.
  ///   - terms: The game's names in the app language.
  ///   - now: The app clock's instant.
  ///   - isStale: Whether the last refresh of the schedules feed failed.
  public init(screen: BattleScreen, terms: GameTerms, now: Date, isStale: Bool) {
    self.screen = screen
    self.terms = terms
    self.now = now
    self.isStale = isStale
  }

  public var body: some View {
    List {
      if let card = screen.announcedSplatfest {
        SplatfestCardView(splatfest: card.splatfest, art: card.art, terms: terms, style: .timeline, now: now)
      }
      switch screen.current {
        case .running(let running):
          row(running.item, progress: running.progress)
        case .paused(let returnTime):
          Text(verbatim: ScreenText.paused.text(in: terms.language, format.time(returnTime, relativeTo: now)))
        case .nothingCurrent:
          Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
      }
      ForEach([screen.next].compactMap(\.self) + screen.later, id: \.self) { rotation in
        row(rotation, progress: nil)
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

// MARK: - TimelineSalmonRunScreenView

/// Timeline's Salmon Run screen: plain rows hung on a column of start times, a stand-in until
/// ticket 28 draws SplatNet 3's schedule page. It receives `IkaCore` values only and reads no
/// store.
public struct TimelineSalmonRunScreenView: View {
  @Environment(\.timeZone) private var timeZone

  private let screen: SalmonRunScreen
  private let terms: GameTerms
  private let now: Date
  private let isStale: Bool

  /// - Parameters:
  ///   - screen: What the screen shows at `now`.
  ///   - terms: The game's names in the app language.
  ///   - now: The app clock's instant.
  ///   - isStale: Whether the last refresh of the schedules feed failed.
  public init(screen: SalmonRunScreen, terms: GameTerms, now: Date, isStale: Bool) {
    self.screen = screen
    self.terms = terms
    self.now = now
    self.isStale = isStale
  }

  public var body: some View {
    List {
      if let eggstraWork = screen.eggstraWork {
        row(eggstraWork.item, progress: eggstraWork.progress)
      }
      else if let nextEggstraWork = screen.nextEggstraWork {
        row(nextEggstraWork, progress: nil)
      }
      switch screen.current {
        case .running(let running):
          row(running.item, progress: running.progress)
        case .paused,
             .nothingCurrent:
          Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
      }
      ForEach([screen.next].compactMap(\.self) + screen.later, id: \.self) { shift in
        row(shift, progress: nil)
      }
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
        .listRowSeparator(.hidden)
    }
    .listStyle(.plain)
  }

  private func row(_ shift: Shift, progress: WindowProgress?) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Text(verbatim: format.time(shift.startTime, relativeTo: now))
        .font(.subheadline.monospacedDigit().weight(.semibold))
        .frame(minWidth: 52, alignment: .leading)
      VStack(alignment: .leading, spacing: 2) {
        if let label = shift.kind.label {
          Text(verbatim: label.text(in: terms.language))
            .font(.caption.weight(.bold))
        }
        Text(verbatim: terms.name(of: shift.stage))
          .font(.headline)
        Text(verbatim: shift.weapons.map(terms.name(of:)).joined(separator: " · "))
          .font(.subheadline)
        if let progress {
          ProgressView(value: progress.sharePassed)
        }
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: shift, at: now))
  }

  private var format: ScheduleFormat { .init(language: terms.language, timeZone: timeZone) }
  private var writer: SentenceWriter { .init(terms: terms, timeZone: timeZone, hourCycle: Locale.current.hourCycle) }
}
#endif
