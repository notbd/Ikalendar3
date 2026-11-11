//
//  ClassicWideScreens.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - ClassicWideBattleScreenView

/// Classic's wide Battle Mode detail on iPad and Mac: the list's own sections in a centred
/// column, with the current Rotation as one wide row (tag and time range, Rule, progress ring and
/// time left beside both Stages) over one table of every later Rotation. An announced
/// Splatfest's card, a pause and nothing current show as in the iPhone list.
///
/// It receives `IkaCore` values only and reads no store.
public struct ClassicWideBattleScreenView: View {
  private let screen: BattleScreen
  private let terms: GameTerms
  private let now: Date
  private let isStale: Bool
  private let wide: WideDetailMetrics

  /// - Parameters:
  ///   - screen: What the screen shows at `now`.
  ///   - terms: The game's names in the app language.
  ///   - now: The app clock's instant.
  ///   - isStale: Whether the last refresh of the schedules feed failed.
  ///   - wide: The wide detail's column.
  public init(screen: BattleScreen, terms: GameTerms, now: Date, isStale: Bool, wide: WideDetailMetrics) {
    self.screen = screen
    self.terms = terms
    self.now = now
    self.isStale = isStale
    self.wide = wide
  }

  public var body: some View {
    let rows: [ClassicBattleRow] = ClassicBattleRow.rows(of: screen)
    let mode: RotationMode = .battle(screen.mode)

    ClassicScheduleList(
      icon: ModeIcon(Mode.battle(screen.mode)),
      heading: ClassicHeading(.battle(screen.mode), in: terms.language),
      reflowValue: rows.map(\.id))
    { metrics in
      if let card = screen.announcedSplatfest {
        Section {
          ClassicSplatfestCard(card: card, terms: terms, now: now, metrics: metrics)
        }
      }
      ForEach(rows.filter { !$0.isUpcoming }) { row in
        if case .current(let running) = row {
          Section {
            ClassicWideBattleCell(running: running, mode: mode, terms: terms, now: now, wide: wide)
          }
        }
        else {
          ClassicBattleSection(row: row, mode: mode, terms: terms, now: now, metrics: metrics)
        }
      }
      Section {
        ForEach(rows.filter(\.isUpcoming)) { row in
          if case .upcoming(let rotation, let isNext) = row {
            ClassicBattleTableRow(rotation: rotation, isNext: isNext, terms: terms, now: now, wide: wide)
          }
        }
      }
    } footer: {
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
    }
    .contentMargins(.horizontal, wide.sideMargin, for: .scrollContent)
  }
}

// MARK: - ClassicWideSalmonRunScreenView

/// Classic's wide Salmon Run detail on iPad and Mac: each running Shift (an Eggstra Work beside a
/// regular one included) as one wide row (tags and time range, progress ring and time left beside
/// the Stage with its King Salmonid and the four weapons), over one table of every other Shift
/// with its tag, time range, Stage and weapons.
///
/// It receives `IkaCore` values only and reads no store.
public struct ClassicWideSalmonRunScreenView: View {
  private let screen: SalmonRunScreen
  private let terms: GameTerms
  private let now: Date
  private let isStale: Bool
  private let wide: WideDetailMetrics

  /// - Parameters:
  ///   - screen: What the screen shows at `now`.
  ///   - terms: The game's names in the app language.
  ///   - now: The app clock's instant.
  ///   - isStale: Whether the last refresh of the schedules feed failed.
  ///   - wide: The wide detail's column.
  public init(screen: SalmonRunScreen, terms: GameTerms, now: Date, isStale: Bool, wide: WideDetailMetrics) {
    self.screen = screen
    self.terms = terms
    self.now = now
    self.isStale = isStale
    self.wide = wide
  }

  public var body: some View {
    let rows: [ClassicSalmonRunRow] = ClassicSalmonRunRow.rows(of: screen)

    ClassicScheduleList(
      icon: ModeIcon(.salmonRun),
      heading: ClassicHeading(.salmonRun, in: terms.language),
      reflowValue: rows.map(\.id))
    { metrics in
      ForEach(rows.filter { !$0.isTableRow }) { row in
        switch row {
          case .shift(let shift, let progress?, let tag):
            Section {
              ClassicWideShiftCell(shift: shift, progress: progress, tag: tag, terms: terms, now: now, wide: wide)
            }

          case .shift:
            // A Shift that does not run: in the table below.
            EmptyView()

          case .nothingCurrent:
            Section {
              ClassicStatusCell(
                text: ScreenText.nothingCurrent.text(in: terms.language),
                arrangement: metrics.arrangement)
            }
        }
      }
      Section {
        ForEach(rows.filter(\.isTableRow)) { row in
          if case .shift(let shift, _, let tag) = row {
            ClassicShiftTableRow(shift: shift, tag: tag, terms: terms, now: now, wide: wide)
          }
        }
      }
    } footer: {
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
    }
    .contentMargins(.horizontal, wide.sideMargin, for: .scrollContent)
  }
}

// MARK: - ClassicBattleRow

extension ClassicBattleRow {
  /// Whether the row is a later Rotation, which the wide detail lists in its table.
  fileprivate var isUpcoming: Bool {
    if case .upcoming = self { true } else { false }
  }
}

// MARK: - ClassicSalmonRunRow

extension ClassicSalmonRunRow {
  /// Whether the row is a Shift that does not run, which the wide detail lists in its table.
  fileprivate var isTableRow: Bool {
    if case .shift(_, nil, _) = self { true } else { false }
  }
}
#endif
