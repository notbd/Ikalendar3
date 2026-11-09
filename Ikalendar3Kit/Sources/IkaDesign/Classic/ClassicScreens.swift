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

/// Classic's Battle Mode screen, ikalendar 2's look with Splatoon 3's Mode colours, icons and
/// fonts: the Mode stamp, an announced Splatfest's card on Regular Battle's screen, the current
/// Rotation featured under "Now:" with its progress, then the next and every later Rotation in
/// secondary cells.
///
/// Like every Style's screen, it receives `IkaCore` values only and reads no store. Pull to
/// refresh reaches its list through the `refreshable` action the shared screen sets. A finished
/// Rotation leaves the list as the app clock passes its end, and the next one glides into the
/// featured cell.
public struct ClassicBattleScreenView: View {
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
    let rows: [ClassicBattleRow] = ClassicBattleRow.rows(of: screen)

    ClassicScheduleList(
      icon: ModeIcon(Mode.battle(screen.mode)),
      reflowValue: rows.map(\.id))
    { metrics in
      if let splatfest = screen.announcedSplatfest {
        Section {
          // Team colours only: the screen value carries no art for an announced Splatfest yet.
          SplatfestCardView(splatfest: splatfest, art: nil, terms: terms, style: .classic, now: now)
        }
      }
      ForEach(rows) { row in
        ClassicBattleSection(row: row, mode: screen.mode, terms: terms, now: now, metrics: metrics)
      }
    } footer: {
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
    }
  }
}

// MARK: - ClassicSalmonRunScreenView

/// Classic's Salmon Run screen, ikalendar 2's look with Splatoon 3's Mode colours, icons and
/// fonts: a running or next Eggstra Work on top, then one cell per Shift with its Stage, four weapons,
/// King Salmonid and time range, a Big Run inline where it falls. It receives `IkaCore` values
/// only and reads no store.
public struct ClassicSalmonRunScreenView: View {
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
    let rows: [ClassicSalmonRunRow] = ClassicSalmonRunRow.rows(of: screen)

    ClassicScheduleList(
      icon: ModeIcon(.salmonRun),
      reflowValue: rows.map(\.id))
    { metrics in
      ForEach(rows) { row in
        switch row {
          case .shift(let shift, let progress, let tag):
            ClassicShiftSection(shift: shift, progress: progress, tag: tag, terms: terms, now: now, metrics: metrics)
          case .nothingCurrent:
            Section {
              ClassicStatusCell(
                text: ScreenText.nothingCurrent.text(in: terms.language),
                arrangement: metrics.arrangement)
            }
        }
      }
    } footer: {
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
    }
  }
}

// MARK: - ClassicScheduleList

/// What both Classic screens share: ikalendar 2's inset grouped list with hidden row separators,
/// its rows sized for the list's width and text size, rows moving into place as the clock changes
/// them and, on iPhone and iPad, the Mode stamp docking into its badge.
private struct ClassicScheduleList<Rows: View, Footer: View>: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  let icon: ModeIcon
  let reflowValue: [ClassicRowID]
  @ViewBuilder let rows: (CellMetrics) -> Rows
  @ViewBuilder let footer: () -> Footer

  var body: some View {
    GeometryReader { geometry in
      List {
        rows(CellMetrics(width: geometry.size.width, dynamicTypeSize: dynamicTypeSize))
          .listRowSeparator(.hidden)
        Section { } footer: {
          footer()
        }
      }
      .classicListStyle()
      .listReflow(value: reflowValue)
      #if os(iOS)
      .classicModeStamp(icon)
      #endif
    }
  }
}

// MARK: - View

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
