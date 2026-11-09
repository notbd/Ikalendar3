//
//  SplatfestScreenView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - SplatfestScreenView

/// The Splatfest screen in the selected Style and Splatfest Battle form, at the app clock's
/// instant. The tab set shows it only while the Splatfest runs, and swaps it back for Regular
/// Battle's screen on the clock's tick at the end, with no fetch.
struct SplatfestScreenView: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language

  /// The form of Splatfest Battle shown.
  let form: SplatfestBattleForm

  var body: some View {
    let snapshot = engine.snapshot
    let now = clock.now
    let title = RotationMode.splatfestBattle(form).name(in: language)

    ScheduleScreen(title: title, content: snapshot.splatfestScreen(of: form, at: now)) { screen in
      let terms = snapshot.terms(in: language)
      let isStale = snapshot.schedules?.isStale ?? false
      // The art joins once the screen value carries it.
      let art: URL? = nil
      switch preferences.style {
        case .classic: ClassicSplatfestScreenView(screen: screen, art: art, terms: terms, now: now, isStale: isStale)
        case .ink: InkSplatfestScreenView(screen: screen, art: art, terms: terms, now: now, isStale: isStale)
        case .timeline: TimelineSplatfestScreenView(screen: screen, art: art, terms: terms, now: now, isStale: isStale)
      }
    }
  }
}
