//
//  NowPageView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - NowScreen

/// The page the watch app opens on, at the app clock's instant: the Now page while the engine
/// holds a schedule, else the shared empty state, or a spinner until the first refresh ends.
struct NowScreen: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(\.gameLanguage) private var language

  var body: some View {
    let snapshot = engine.snapshot
    let now = clock.now

    Group {
      if let page = snapshot.nowPage(at: now) {
        NowPageView(
          page: page,
          terms: snapshot.terms(in: language),
          now: now,
          isStale: snapshot.schedules?.isStale ?? false)
          #if DEBUG
          .defaultScrollAnchor(WatchDebugLaunch.scrollAnchor())
          #endif
      }
      else if engine.settledStatus == .loading {
        ProgressView()
      }
      else {
        EmptyScheduleView()
      }
    }
    .navigationTitle(WatchText.now.text(in: language))
  }
}

// MARK: - NowPageView

/// The Now page in Ink: a running Splatfest's teams on top, then one panel with a row per Mode,
/// each opening that Mode's page, and the fetch time. It receives `IkaCore` values only and reads
/// no store.
struct NowPageView: View {
  let page: NowPage
  let terms: GameTerms
  let now: Date
  let isStale: Bool

  var body: some View {
    ScrollView {
      VStack(spacing: NowMetrics.rowSpacing) {
        if let splatfest = page.splatfest {
          SplatfestTeamsPanel(splatfest: splatfest, terms: terms, now: now)
        }
        VStack(spacing: NowMetrics.rowSpacing) {
          ForEach(page.summaries, id: \.mode) { summary in
            if summary.mode != page.summaries.first?.mode {
              InkDottedRule()
            }
            NavigationLink(value: summary.mode) {
              NowRow(summary: summary, terms: terms, now: now)
            }
            .buttonStyle(.plain)
          }
        }
        .inkPanel()
        FetchTimeLabel(fetchTime: page.fetchTime, now: now, isStale: isStale)
      }
    }
    .background {
      InkBackground()
        .ignoresSafeArea()
    }
  }
}

// MARK: - ModePagePlaceholder

/// Where a Now row leads until the Mode's own page lands (ticket 46): the Mode's row under its
/// name.
struct ModePagePlaceholder: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(\.gameLanguage) private var language

  let mode: Mode

  var body: some View {
    let snapshot = engine.snapshot
    let now = clock.now

    ScrollView {
      if let summary = snapshot.summary(of: mode, at: now) {
        NowRow(summary: summary, terms: snapshot.terms(in: language), now: now)
          .inkPanel()
      }
    }
    .background {
      InkBackground()
        .ignoresSafeArea()
    }
    .navigationTitle(mode.name(in: language))
  }
}
