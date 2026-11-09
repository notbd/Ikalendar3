//
//  MenuBarWindow.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(macOS)
import AppKit
import IkaCore
import IkaDesign
import SwiftUI

// MARK: - MenuBarWindow

/// The Mac menu bar entry's window: each Mode of the Mode value at a glance, drawn as the selected
/// Style draws its sidebar rows, the time the schedule was fetched, and a button that brings the
/// app's window to the front. A Battle Mode a Splatfest pauses shows its pause, dimmed, as its
/// summary does everywhere. Before the schedules feed's first good response it shows the shared
/// empty state.
struct MenuBarWindow: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    switch preferences.style {
      case .classic:
        window(row: ClassicSidebarRow.init)

      case .ink:
        window(row: InkSidebarRow.init)
          .inkSidebarBackground()

      case .timeline:
        window(row: TimelineSidebarRow.init)
          .timelineSidebarBackground()
    }
  }

  /// The window with each Mode's row drawn by `row`.
  private func window(row: @escaping (SummaryRowContent) -> some View) -> some View {
    VStack(spacing: MenuBarMetrics.spacing) {
      ModeRows(snapshot: engine.snapshot, now: clock.now, row: row)

      Divider()

      Button {
        openWindow(id: Ikalendar3App.mainWindowID)
        NSApplication.shared.activate()
      } label: {
        Text(verbatim: MenuBarText.openApp.text(in: language))
          .frame(maxWidth: .infinity)
      }
      .controlSize(.large)
    }
    .padding(MenuBarMetrics.padding)
    .frame(width: MenuBarMetrics.width)
  }
}

// MARK: - ModeRows

/// The five Modes' rows and the fetch time under them, or the empty state before the schedules
/// feed's first good response.
private struct ModeRows<Row: View>: View {
  @Environment(\.gameLanguage) private var language
  @TimeSettings private var time

  let snapshot: Snapshot
  let now: Date
  let row: (SummaryRowContent) -> Row

  var body: some View {
    if let pages = snapshot.modePages(at: now), let schedules = snapshot.schedules {
      let writer: SentenceWriter = time.writer(snapshot.terms(in: language))
      let format: ScheduleFormat = time.format(language)

      VStack(alignment: .leading, spacing: 0) {
        ForEach(pages, id: \.mode) { page in
          row(SummaryRowContent(page.summary, writer: writer, format: format, now: now))
        }
      }

      FetchTimeLabel(fetchTime: schedules.fetchTime, now: now, isStale: schedules.isStale)
    }
    else {
      EmptyScheduleView()
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

// MARK: - MenuBarMetrics

/// The menu bar window's sizes. Ticket 58 judges them.
private enum MenuBarMetrics {
  /// The window's width, about an iPad sidebar's, which the rows are drawn for.
  static let width: CGFloat = 320
  /// The space around the window's content.
  static let padding: CGFloat = 16
  /// The space between the rows, the fetch time and the button.
  static let spacing: CGFloat = 12
}
#endif
