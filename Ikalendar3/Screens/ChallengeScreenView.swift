//
//  ChallengeScreenView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - ChallengeScreenView

/// The Challenge screen in the selected Style, at the app clock's instant.
struct ChallengeScreenView: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language

  var body: some View {
    let snapshot = engine.snapshot
    let now = clock.now

    ScheduleScreen(title: ModeLabel.challenges.text(in: language), content: snapshot.challengeScreen(at: now)) { screen in
      let terms = snapshot.terms(in: language)
      let isStale = snapshot.schedules?.isStale ?? false
      switch preferences.style {
        case .classic: ClassicChallengeScreenView(screen: screen, terms: terms, now: now, isStale: isStale)
        case .ink: InkChallengeScreenView(screen: screen, terms: terms, now: now, isStale: isStale)
        case .timeline: TimelineChallengeScreenView(screen: screen, terms: terms, now: now, isStale: isStale)
      }
    }
  }
}
