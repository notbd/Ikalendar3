//
//  EventCardGallery.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if DEBUG
import IkaCore
import SwiftUI

// MARK: - EventCardGallery

/// The Debug launch's event card gallery (`--event-cards`): every event the snapshot lists at the
/// app clock's instant as the chosen Style's card, one under the other on that Style's
/// background, so a fixture launch can show each card at an iPhone's width too. The scene runs
/// the effects shell, as it does for the tabs.
struct EventCardGallery: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(PreferenceStore.self) private var preferences

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        ForEach(engine.snapshot.eventItems(at: clock.now) ?? [], id: \.self) { item in
          EventCardView(item: item)
        }
      }
      .padding(16)
    }
    .background { StyleBackground().ignoresSafeArea() }
    .appColorScheme(preferences.colorScheme)
  }
}
#endif
