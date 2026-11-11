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

/// Classic's Challenge screen, in the look of its Battle Mode screens: the Challenge Mode stamp,
/// then per Challenge a cell with its name, description, Rule, Stages and rules text, and a row
/// per window, the current one tagged "Now:" with its progress and the next one "Next:".
///
/// Like every Style's screen, it receives `IkaCore` values only and reads no store.
public struct ClassicChallengeScreenView: View {
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
    ClassicScheduleList(
      icon: .challenge,
      heading: .challenges(in: terms.language),
      reflowValue: screen.challenges.map(\.challenge.id))
    { metrics in
      if screen.challenges.isEmpty {
        Section {
          ClassicStatusCell(text: ScreenText.nothingCurrent.text(in: terms.language), arrangement: metrics.arrangement)
        }
      }
      ForEach(screen.challenges, id: \.challenge.id) { listing in
        ClassicChallengeSection(listing: listing, terms: terms, now: now, metrics: metrics)
      }
    } footer: {
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
    }
  }
}

// MARK: - ClassicSplatfestScreenView

/// Classic's Splatfest screen, in the look of its Battle Mode screens: the Splatfest card, then
/// Tricolor Turf War in the second half, the form's Rotations with the current one featured under
/// "Now:", and Regular Battle's Rotations after the end in secondary cells.
///
/// Tricolor Turf War sits right under the card rather than after the form's Rotations: it runs
/// through the whole second half, and up to twelve Rotations would bury it.
///
/// Like every Style's screen, it receives `IkaCore` values only and reads no store.
public struct ClassicSplatfestScreenView: View {
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
    let rows: [ClassicBattleRow] = ClassicBattleRow.rows(of: screen)
    let afterwards: [ClassicBattleRow] = ClassicBattleRow.afterwardsRows(of: screen)

    ClassicScheduleList(
      icon: ModeIcon(RotationMode.splatfestBattle(screen.form)),
      heading: ClassicHeading(splatfestBattle: screen.form, in: terms.language),
      reflowValue: (rows + afterwards).map(\.id))
    { metrics in
      Section {
        ClassicSplatfestCard(card: screen.card, terms: terms, now: now, metrics: metrics)
      }
      if let tricolor = screen.tricolorTurfWar {
        ClassicTricolorSection(tricolor: tricolor, terms: terms, now: now, metrics: metrics)
      }
      ForEach(rows) { row in
        ClassicBattleSection(
          row: row,
          mode: .splatfestBattle(screen.form),
          terms: terms,
          now: now,
          metrics: metrics)
      }
      ForEach(afterwards) { row in
        ClassicBattleSection(
          row: row,
          mode: .battle(.regular),
          terms: terms,
          now: now,
          metrics: metrics,
          showsModeTag: row.id == afterwards.first?.id)
      }
    } footer: {
      FetchTimeLabel(fetchTime: screen.fetchTime, now: now, isStale: isStale)
    }
  }
}
#endif
