//
//  OverviewLayoutView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(macOS)
import IkaCore
import IkaDesign
import SwiftUI

// MARK: - OverviewLayoutView

/// The Mac's Overview: the event strip over a card per Mode of the Mode value, each its summary
/// in the selected Style (`Snapshot.summaries(at:)`). A Battle Mode a Splatfest pauses shows its
/// pause, dimmed, as its summary does everywhere; the Splatfest's own card is on the strip.
///
/// A card opens its Mode's Schedule in the window, with a back button to the cards, and picks the
/// Mode's sidebar row, so the Sidebar view shows the same Mode. Before the schedules feed's first
/// good response it shows the shared empty state.
struct OverviewLayoutView: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(AppStatus.self) private var status

  /// The Mode whose Schedule is open over the cards, if any.
  @State private var path: [Mode] = []

  var body: some View {
    NavigationStack(path: $path) {
      Group {
        if let summaries = engine.snapshot.summaries(at: clock.now) {
          ScrollView {
            VStack(spacing: 0) {
              EventStrip()
              OverviewCards(summaries: summaries, now: clock.now, open: open)
            }
          }
          .background { StyleBackground().ignoresSafeArea() }
        }
        else {
          EmptyScheduleView()
        }
      }
      .navigationDestination(for: Mode.self, destination: screen)
    }
    .refreshFailureToast()
  }

  /// Opens `mode`'s Schedule and picks its sidebar row.
  private func open(_ mode: Mode) {
    status.pick(.mode(mode))
    path = [mode]
  }

  /// `mode`'s screen.
  @ViewBuilder
  private func screen(for mode: Mode) -> some View {
    switch mode {
      case .battle(let mode): BattleModeScreenView(mode: mode)
      case .salmonRun: SalmonRunScreenView()
    }
  }
}

// MARK: - OverviewCards

/// The Modes' cards in the selected Style, as many to a row as the window fits.
private struct OverviewCards: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language
  @TimeSettings private var time

  let summaries: [ModeSummary]
  let now: Date
  let open: (Mode) -> Void

  var body: some View {
    let writer: SentenceWriter = time.writer(engine.snapshot.terms(in: language))
    let format: ScheduleFormat = time.format(language)

    LazyVGrid(columns: OverviewMetrics.columns, spacing: OverviewMetrics.spacing) {
      ForEach(summaries, id: \.mode) { summary in
        if let mode = summary.mode {
          Button { open(mode) } label: {
            card(SidebarRowContent(row: .mode(summary), writer: writer, format: format, now: now))
          }
          .buttonStyle(.plain)
        }
      }
    }
    .padding(OverviewMetrics.spacing)
  }

  @ViewBuilder
  private func card(_ content: SidebarRowContent) -> some View {
    switch preferences.style {
      case .classic: ClassicOverviewCard(content: content)
      case .ink: InkOverviewCard(content: content)
      case .timeline: TimelineOverviewCard(content: content)
    }
  }
}

// MARK: - OverviewMetrics

/// The Overview's sizes. Ticket 58 judges them.
private enum OverviewMetrics {
  /// The space between the cards and around them, as around the event strip's.
  static let spacing: CGFloat = 16
  /// As many cards to a row as fit at 220 pt or wider.
  static let columns: [GridItem] = [GridItem(.adaptive(minimum: 220), spacing: spacing)]
}
#endif
