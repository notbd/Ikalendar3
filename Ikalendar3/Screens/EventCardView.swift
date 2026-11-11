//
//  EventCardView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - EventCardView

/// An event's card in the selected Style, at the app clock's instant, as the iPad event strip and
/// the Debug card gallery show it.
struct EventCardView: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language

  /// The event.
  let item: EventItem

  var body: some View {
    let snapshot = engine.snapshot
    let now = clock.now
    let terms = snapshot.terms(in: language)

    switch preferences.style {
      case .classic: ClassicEventCard(item: item, terms: terms, now: now)
      case .ink: InkEventCard(item: item, terms: terms, now: now)
      case .timeline: TimelineEventCard(item: item, terms: terms, now: now)
    }
  }
}

// MARK: - StyleBackground

/// What the selected Style's screens sit on, for what shows outside a screen: the iPad event strip
/// and the Debug card gallery.
struct StyleBackground: View {
  @Environment(PreferenceStore.self) private var preferences

  var body: some View {
    switch preferences.style {
      case .classic: Self.classic
      case .ink: InkBoard()
      case .timeline: TimelineBackground()
    }
  }

  /// What a Classic list's cells sit on.
  static private var classic: Color {
    #if os(iOS)
    Color(uiColor: .systemGroupedBackground)
    #else
    Color(nsColor: .windowBackgroundColor)
    #endif
  }
}
