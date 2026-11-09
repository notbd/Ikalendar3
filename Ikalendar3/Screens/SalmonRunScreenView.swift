//
//  SalmonRunScreenView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - SalmonRunScreenView

/// The Salmon Run screen in the selected Style, at the app clock's instant: the iPhone list, or
/// the wide detail where the screen is wide enough (`DetailLayout`).
struct SalmonRunScreenView: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language

  var body: some View {
    let snapshot = engine.snapshot
    let now = clock.now

    ScheduleScreen(title: Mode.salmonRun.name(in: language), content: snapshot.salmonRunScreen(at: now)) { screen in
      let terms = snapshot.terms(in: language)
      let isStale = snapshot.schedules?.isStale ?? false
      DetailLayoutReader { layout in
        switch (preferences.style, layout) {
          case (.classic, .list):
            ClassicSalmonRunScreenView(screen: screen, terms: terms, now: now, isStale: isStale)
          case (.classic, .wide(let wide)):
            ClassicWideSalmonRunScreenView(screen: screen, terms: terms, now: now, isStale: isStale, wide: wide)
          case (.ink, .list):
            InkSalmonRunScreenView(screen: screen, terms: terms, now: now, isStale: isStale)
          case (.ink, .wide(let wide)):
            InkWideSalmonRunScreenView(screen: screen, terms: terms, now: now, isStale: isStale, wide: wide)
          case (.timeline, .list):
            TimelineSalmonRunScreenView(screen: screen, terms: terms, now: now, isStale: isStale)
          case (.timeline, .wide(let wide)):
            TimelineWideSalmonRunScreenView(screen: screen, terms: terms, now: now, isStale: isStale, wide: wide)
        }
      }
    }
  }
}
