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
/// app clock's instant as its Ink card, one under the other on Ink's background, so a fixture
/// launch can show each card before the iPad event strip does. Classic's and Timeline's cards
/// join it when they land.
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
          InkEventCard(item: item, art: snapshot.splatfestArt, terms: terms, now: now)
        }
      }
      .padding(16)
    }
    .background { InkBackground().ignoresSafeArea() }
    .appColorScheme(preferences.colorScheme)
    .task { await effects?.run() }
  }
}
#endif
