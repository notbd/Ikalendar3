//
//  EventStrip.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - EventStrip

/// The band over the iPad columns and the Mac's Columns and Overview: the card of each event the
/// snapshot lists, in the strip's fixed order, each opening its Schedule in a sheet. Four cards
/// share the band's width.
///
/// On iPad the refresh and Settings buttons the sidebar keeps in its toolbar follow the cards, so
/// only they show while no event is listed. The Mac keeps both in its window's toolbar and app
/// menu, so its strip shows only while an event is listed.
struct EventStrip: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(AppStatus.self) private var status
  @Environment(\.gameLanguage) private var language

  static private let spacing: CGFloat = 12

  var body: some View {
    let items = engine.snapshot.eventItems(at: clock.now) ?? []

    #if os(iOS)
    @Bindable var status = status

    band {
      cards(items)

      GlassEffectContainer {
        HStack(spacing: Self.spacing) {
          RefreshButton()
          SettingsButton(isPresented: $status.isSettingsPresented, language: language)
        }
      }
      .buttonStyle(.glass)
      .labelStyle(.iconOnly)
    }
    #else
    if !items.isEmpty {
      band { cards(items) }
    }
    #endif
  }

  /// `content` in a row on the selected Style's background.
  private func band(@ViewBuilder _ content: () -> some View) -> some View {
    HStack(alignment: .top, spacing: Self.spacing, content: content)
      .padding(16)
      .background { StyleBackground().ignoresSafeArea() }
  }

  /// The cards of `items`, scrolling sideways past the fourth.
  private func cards(_ items: [EventItem]) -> some View {
    ScrollView(.horizontal) {
      HStack(alignment: .top, spacing: Self.spacing) {
        ForEach(items, id: \.self) { item in
          Button { status.presentedEvent = EventSheet(item) } label: {
            EventCardView(item: item)
          }
          .buttonStyle(.plain)
          .containerRelativeFrame(.horizontal, count: 4, spacing: Self.spacing)
        }
      }
    }
    .scrollIndicators(.hidden)
    // As tall as the tallest card, so the columns take the rest.
    .fixedSize(horizontal: false, vertical: true)
  }
}
