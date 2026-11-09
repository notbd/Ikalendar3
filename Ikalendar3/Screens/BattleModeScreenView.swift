//
//  BattleModeScreenView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - BattleModeScreenView

/// A continuous Battle Mode's screen in the selected Style, at the app clock's instant.
struct BattleModeScreenView: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language

  /// The Battle Mode shown.
  let mode: BattleMode

  var body: some View {
    let snapshot = engine.snapshot
    let now = clock.now

    ScheduleScreen(title: mode.name(in: language), content: snapshot.battleScreen(of: mode, at: now)) { screen in
      let terms = snapshot.terms(in: language)
      let isStale = snapshot.schedules?.isStale ?? false
      switch preferences.style {
        case .classic: ClassicBattleScreenView(screen: screen, terms: terms, now: now, isStale: isStale)
        case .ink: InkBattleScreenView(screen: screen, terms: terms, now: now, isStale: isStale)
        case .timeline: TimelineBattleScreenView(screen: screen, terms: terms, now: now, isStale: isStale)
      }
    }
    .trackButton(for: .battle(mode), language: language)
  }
}
