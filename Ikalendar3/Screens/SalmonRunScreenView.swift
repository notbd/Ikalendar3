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

/// The Salmon Run screen in the selected Style, at the app clock's instant.
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
      switch preferences.style {
        case .classic: ClassicSalmonRunScreenView(screen: screen, terms: terms, now: now, isStale: isStale)
        case .ink: InkSalmonRunScreenView(screen: screen, terms: terms, now: now, isStale: isStale)
        case .timeline: TimelineSalmonRunScreenView(screen: screen, terms: terms, now: now, isStale: isStale)
      }
    }
    .trackButton(for: .salmonRun, language: language)
  }
}
