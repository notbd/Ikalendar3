//
//  LaterListScreen.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - LaterListScreen

/// A Mode's later Rotations or Shifts, every one after its page's next, at the app clock's
/// instant, under the Mode's name on its tint, then the fetch time. The name heads the list
/// rather than the navigation bar, whose title would sit on the tint in the tint's own colour.
struct LaterListScreen: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(\.gameLanguage) private var language

  let mode: Mode

  var body: some View {
    let snapshot = engine.snapshot
    let now = clock.now

    Group {
      if let page = snapshot.modePage(of: mode, at: now) {
        LaterListView(
          page: page,
          terms: snapshot.terms(in: language),
          now: now,
          isStale: snapshot.schedules?.isStale ?? false)
          #if DEBUG
          .defaultScrollAnchor(WatchDebugLaunch.scrollAnchor())
          #endif
      }
      else {
        EmptyScheduleView()
      }
    }
  }
}

// MARK: - LaterListView

/// The later Rotations or Shifts in Ink, one panel each, then the fetch time. It receives
/// `IkaCore` values only and reads no store.
struct LaterListView: View {
  let page: ModePage
  let terms: GameTerms
  let now: Date
  let isStale: Bool

  var body: some View {
    ScrollView {
      VStack(spacing: WatchMetrics.rowSpacing) {
        PageHeading(heading: InkModeHeading(page.mode), color: ModeColor(page.mode), language: terms.language)
          .padding(.leading, WatchMetrics.rowSpacing)
        switch page {
          case .battle(let screen):
            ForEach(screen.later, id: \.startTime) { rotation in
              RotationRow(rotation: rotation, terms: terms, now: now, isNext: false)
                .inkPanel()
            }

          case .salmonRun(let screen):
            ForEach(screen.later, id: \.startTime) { shift in
              ShiftRow(shift: shift, terms: terms, now: now, isNext: false)
                .inkPanel()
            }
        }
        FetchTimeLabel(fetchTime: fetchTime, now: now, isStale: isStale)
      }
    }
    .background {
      ModeTint(color: ModeColor(page.mode))
        .ignoresSafeArea()
    }
  }

  private var fetchTime: Date {
    switch page {
      case .battle(let screen): screen.fetchTime
      case .salmonRun(let screen): screen.fetchTime
    }
  }
}
