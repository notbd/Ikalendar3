//
//  ClassicScreens.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - ClassicBattleScreenView

/// Classic's Battle Mode screen: plain rows in an inset grouped list, a stand-in until ticket 26
/// draws ikalendar 2's look.
///
/// Like every Style's screen, it receives `IkaCore` values only and reads no store. Pull to
/// refresh reaches its list through the `refreshable` action the shared screen sets.
public struct ClassicBattleScreenView: View {
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
      if let splatfest = screen.announcedSplatfest {
        Section {
          // Team colours only: the screen value carries no art for an announced Splatfest yet.
          SplatfestCardView(splatfest: splatfest, art: nil, terms: terms, style: .classic, now: now)
        }
      }
      Section {
        switch screen.current {
          case .running(let running):
            row(running.item)
            ProgressView(value: running.progress.sharePassed) {
              Text(verbatim: writer.timeLeft(running.progress))
            }
            .accessibilityHidden(true)

          case .paused(let returnTime):
            Text(verbatim: ScreenText.paused.text(in: terms.language, format.time(returnTime, relativeTo: now)))

          case .nothingCurrent:
            Text(verbatim: ScreenText.nothingCurrent.text(in: terms.language))
        }
      }
      ForEach([screen.next].compactMap(\.self) + screen.later, id: \.self) { rotation in
        row(rotation)
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

  private var format: ScheduleFormat { .init(language: terms.language, timeZone: timeZone) }
  private var writer: SentenceWriter { .init(terms: terms, timeZone: timeZone, hourCycle: Locale.current.hourCycle) }
}

// MARK: - ClassicSalmonRunScreenView

/// Classic's Salmon Run screen: plain rows in an inset grouped list, a stand-in until ticket 26
/// draws ikalendar 2's look. It receives `IkaCore` values only and reads no store.
public struct ClassicSalmonRunScreenView: View {
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
      if let eggstraWork = screen.eggstraWork?.item ?? screen.nextEggstraWork {
        Section { row(eggstraWork) }
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
      }
      ForEach([screen.next].compactMap(\.self) + screen.later, id: \.self) { shift in
        row(shift)
      }
      Section { } footer: {
        FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
      }
    }
    .classicListStyle()
  }

  private func row(_ shift: Shift) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(verbatim: format.timeRange(of: shift, withWeekday: true))
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(verbatim: terms.name(of: shift.stage))
        .font(.headline)
      Text(verbatim: shift.weapons.map(terms.name(of:)).joined(separator: " · "))
        .font(.subheadline)
      if shift.kind != .regular || shift.kingSalmonid != nil {
        Text(verbatim: [shift.kind.label?.text(in: terms.language), shift.kingSalmonid.map(terms.name(of:))]
          .compactMap(\.self)
          .joined(separator: " · "))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: shift, at: now))
  }

  private var format: ScheduleFormat { .init(language: terms.language, timeZone: timeZone) }
  private var writer: SentenceWriter { .init(terms: terms, timeZone: timeZone, hourCycle: Locale.current.hourCycle) }
}

// MARK: - List style

extension View {
  /// Classic's list: inset grouped on iPhone and iPad, inset on the Mac.
  func classicListStyle() -> some View {
    #if os(iOS)
    listStyle(.insetGrouped)
    #else
    listStyle(.inset)
    #endif
  }
}
#endif
