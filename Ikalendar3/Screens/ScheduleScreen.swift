//
//  ScheduleScreen.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import IkaIntents
import SwiftUI

// MARK: - ScheduleScreen

/// What every shared screen does around its Style's view: the navigation title, pull to
/// refresh through the effects shell, and the shared empty state until the schedules feed's
/// first good response.
///
/// The shared screens own state, navigation and actions, and switch exhaustively over the Style
/// into `IkaDesign`'s per-Style views, which receive only `IkaCore` values and action closures
/// and never read a store. Pull to refresh reaches the Style's list through the `refreshable`
/// action set here.
struct ScheduleScreen<Content, StyleView: View>: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(\.effects) private var effects
  @Environment(AppStatus.self) private var status

  /// The navigation title.
  let title: String
  /// What the screen shows, or `nil` before the schedules feed's first good response.
  let content: Content?
  /// The selected Style's view of the content.
  @ViewBuilder let styleView: (Content) -> StyleView

  var body: some View {
    Group {
      if let content {
        styleView(content)
      }
      else if engine.settledStatus == .loading {
        ProgressView()
      }
      else {
        EmptyScheduleScreenView(title: title)
      }
    }
    .navigationTitle(title)
    .refreshable { await effects?.run(isRequested: true, reportingTo: status) }
  }
}

// MARK: - EmptyScheduleScreenView

/// The shared empty state as a screen, which Try Again and pull to refresh both refresh.
struct EmptyScheduleScreenView: View {
  @Environment(\.effects) private var effects
  @Environment(AppStatus.self) private var status

  /// The navigation title.
  let title: String

  var body: some View {
    ScrollView {
      EmptyScheduleView {
        Task { await refresh() }
      }
      .containerRelativeFrame(.vertical)
    }
    .navigationTitle(title)
    .refreshable { await refresh() }
  }

  private func refresh() async {
    await effects?.run(isRequested: true, reportingTo: status)
  }
}
