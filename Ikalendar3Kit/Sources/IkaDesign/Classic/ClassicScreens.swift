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
/// fonts: the Mode stamp, the current Rotation featured under "Now:" with its progress, an
/// announced Splatfest's card on Regular Battle's screen, then the next and every later Rotation
/// in secondary cells.
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
      heading: ClassicHeading(.battle(screen.mode), in: terms.language),
      reflowValue: rows.map(\.id))
    { metrics in
      // One `ForEach`, so a Rotation keeps its row, and its glide, as it passes the card.
      ForEach(ClassicBattleScreenItem.items(rows: rows, announcedSplatfest: screen.announcedSplatfest)) { item in
        switch item {
          case .row(let row):
            ClassicBattleSection(row: row, mode: .battle(screen.mode), terms: terms, now: now, metrics: metrics)
          case .announcedSplatfest(let card):
            ClassicSplatfestSection(card: card, terms: terms, now: now, metrics: metrics)
        }
      }
    } footer: {
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
    }
  }
}

// MARK: - ClassicBattleScreenItem

/// A section of Classic's Battle Mode screen: a Rotation's row, or an announced Splatfest's card,
/// which follows the featured row. The Splatfest is a week away; what is on now comes first.
private enum ClassicBattleScreenItem: Identifiable {
  case row(ClassicBattleRow)
  case announcedSplatfest(SplatfestCard)

  /// What keeps a section's identity: a row's own, or the card's.
  enum Identity: Hashable {
    case row(ClassicRowID)
    case announcedSplatfest
  }

  /// `rows` with `announcedSplatfest`'s card after the first.
  static func items(rows: [ClassicBattleRow], announcedSplatfest: SplatfestCard?) -> [ClassicBattleScreenItem] {
    let card: [ClassicBattleScreenItem] = announcedSplatfest.map { [.announcedSplatfest($0)] } ?? []
    return rows.prefix(1).map(Self.row) + card + rows.dropFirst().map(Self.row)
  }

  var id: Identity {
    switch self {
      case .row(let row): .row(row.id)
      case .announcedSplatfest: .announcedSplatfest
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
      heading: ClassicHeading(.salmonRun, in: terms.language),
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

/// What every Classic screen shares: ikalendar 2's inset grouped list with hidden row
/// separators, its rows sized for the list's width and text size, rows moving into place as the
/// clock changes them and, on iPhone and iPad, the screen's name over the list with the Mode stamp
/// that docks into its badge. The Mac window names the screen itself.
struct ClassicScheduleList<ReflowValue: Equatable, Rows: View, Footer: View>: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  let icon: ModeIcon
  let heading: ClassicHeading
  /// The rows' identities: the rows move into place when it changes.
  let reflowValue: ReflowValue
  @ViewBuilder let rows: (CellMetrics) -> Rows
  @ViewBuilder let footer: () -> Footer

  var body: some View {
    GeometryReader { geometry in
      let metrics: CellMetrics = .init(width: geometry.size.width, dynamicTypeSize: dynamicTypeSize)

      List {
        #if os(iOS)
        Section { } header: {
          ClassicHeadingView(heading: heading, arrangement: metrics.arrangement)
        }
        .listSectionSpacing(ClassicMetrics.Heading.sectionSpacing)
        #endif
        rows(metrics)
          .listRowSeparator(.hidden)
        Section { } footer: {
          footer()
        }
      }
      .classicListStyle()
      .listReflow(value: reflowValue)
      #if os(iOS)
      .classicModeStamp(icon, title: heading.title)
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
