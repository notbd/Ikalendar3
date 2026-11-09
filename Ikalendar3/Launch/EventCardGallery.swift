//
//  EventCardGallery.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if DEBUG
import IkaCore
import IkaDesign
import IkaIntents
import SwiftUI

// MARK: - EventCardGallery

/// The Debug launch's event card gallery (`--event-cards`): every event the snapshot lists at the
/// app clock's instant as the chosen Style's card, one under the other on that Style's
/// background, so a fixture launch can show each card before the iPad event strip does.
struct EventCardGallery: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(\.effects) private var effects
  @Environment(AppClock.self) private var clock
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language

  var body: some View {
    let snapshot = engine.snapshot
    let now = clock.now
    let terms = snapshot.terms(in: language)

    ScrollView {
      VStack(spacing: 16) {
        ForEach(snapshot.eventItems(at: now) ?? [], id: \.self) { item in
          switch preferences.style {
            case .classic: ClassicEventCard(item: item, terms: terms, now: now)
            case .ink: InkEventCard(item: item, terms: terms, now: now)
            case .timeline: TimelineEventCard(item: item, terms: terms, now: now)
          }
        }
      }
      .padding(16)
    }
    .background {
      switch preferences.style {
        case .classic: classicBackground.ignoresSafeArea()
        case .ink: InkBackground().ignoresSafeArea()
        case .timeline: TimelineBackground().ignoresSafeArea()
      }
    }
    .appColorScheme(preferences.colorScheme)
    .task { await effects?.run() }
  }

  /// What a Classic list's cells sit on.
  private var classicBackground: Color {
    #if os(iOS)
    Color(uiColor: .systemGroupedBackground)
    #else
    Color(nsColor: .windowBackgroundColor)
    #endif
  }
}
#endif
