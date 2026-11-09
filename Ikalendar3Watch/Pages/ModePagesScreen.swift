//
//  ModePagesScreen.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - ModePagesScreen

/// One page per Mode of the Mode value, in its order, turned with the Digital Crown or a swipe and
/// opened at the Mode whose Now row was tapped, at the app clock's instant. Page dots in each
/// Mode's colour on the trailing edge show where the player is. Tapping a page lists its later
/// Rotations or Shifts.
///
/// The pages are a paging scroll view rather than a vertical page tab view: the tab view's own
/// indicator takes no colours and cannot be hidden.
struct ModePagesScreen: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(\.gameLanguage) private var language

  /// The page in view.
  @State private var selection: Mode?

  /// The pages, opened at `mode`'s.
  init(openedAt mode: Mode) {
    _selection = State(initialValue: mode)
  }

  var body: some View {
    let snapshot = engine.snapshot
    let now = clock.now
    let terms = snapshot.terms(in: language)
    let pages: [ModePage] = Mode.allCases.compactMap { snapshot.modePage(of: $0, at: now) }

    if pages.isEmpty {
      EmptyScheduleView()
    }
    else {
      GeometryReader { proxy in
        // Each page fills the whole screen, under the back button and the rounded bottom too, so
        // the pages turn as one with the paging scroll view, which ignores the safe area.
        let insets = proxy.safeAreaInsets
        let screen: CGSize = .init(
          width: proxy.size.width + insets.leading + insets.trailing,
          height: proxy.size.height + insets.top + insets.bottom)

        ScrollView(.vertical) {
          LazyVStack(spacing: 0) {
            ForEach(pages, id: \.mode) { page in
              NavigationLink(value: WatchRoute.later(page.mode)) {
                ModePageView(page: page, terms: terms, now: now)
                  // Under the back button; the rounded bottom needs only a small inset.
                  .padding(.top, insets.top)
                  .padding(.bottom, WatchMetrics.lineSpacing)
                  .padding(.leading, WatchMetrics.rowSpacing)
                  .padding(.trailing, WatchMetrics.pageDotsWidth)
              }
              .buttonStyle(.plain)
              .frame(width: screen.width, height: screen.height)
              .background {
                ModeTint(color: SummaryLook(page.summary).color)
              }
              .accessibilityHint(WatchText.laterHint(of: page.mode).text(in: language))
            }
          }
          .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $selection)
        .scrollIndicators(.hidden)
        .overlay(alignment: .trailing) {
          PageDots(modes: pages.map(\.mode), selection: selection)
            .padding(.trailing, 2)
        }
        .ignoresSafeArea()
      }
    }
  }
}

// MARK: - ModeTint

/// A Mode page's background: the Mode's colour at full strength on top, fading toward Ink's black
/// at the bottom, where the panel sits. Decoration only.
struct ModeTint: View {
  let color: ModeColor

  var body: some View {
    let base: Color = .init(color.base)

    LinearGradient(
      colors: [base, base.opacity(WatchMetrics.pageTintFloor)],
      startPoint: .top,
      endPoint: .bottom)
      .background(.black)
      .accessibilityHidden(true)
  }
}

// MARK: - PageDots

/// A dot per page in its Mode's colour, one over the other; the page in view has the larger,
/// opaque dot. The dots follow the player's own paging, so they change at once rather than
/// animate. VoiceOver skips them: each page names its Mode.
struct PageDots: View {
  let modes: [Mode]
  let selection: Mode?

  var body: some View {
    VStack(spacing: WatchMetrics.pageDotSize) {
      ForEach(modes, id: \.self) { mode in
        let isSelected = mode == selection
        let side: CGFloat = isSelected ? WatchMetrics.selectedPageDotSize : WatchMetrics.pageDotSize

        Circle()
          .fill(Color(ModeColor(mode).base))
          .opacity(isSelected ? 1 : 0.6)
          .overlay {
            // A thin dark edge keeps a light dot visible on its own Mode's tint.
            Circle().strokeBorder(.black.opacity(0.4), lineWidth: 0.5)
          }
          .frame(width: side, height: side)
      }
    }
    .frame(width: WatchMetrics.pageDotsWidth)
    .accessibilityHidden(true)
  }
}
