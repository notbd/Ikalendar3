//
//  SidebarLayoutView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - SidebarLayoutView

/// The iPad's layout in portrait or a narrow window of regular width, and the Mac's Sidebar view:
/// a sidebar of Modes beside one detail column, which shows the selected row's screen. The screens
/// pick the wide detail or the iPhone list by their own width (`DetailLayout`). On iPad the
/// sidebar's toolbar holds the refresh and Settings buttons, and pull to refresh stays on iPhone;
/// the Mac's window keeps them in its toolbar and app menu.
///
/// The split view never collapses into one stack, where a row would have to push its detail: a
/// window of compact width shows the tabs instead (`WindowLayout`).
struct SidebarLayoutView: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(AppStatus.self) private var status
  @Environment(\.gameLanguage) private var language

  var body: some View {
    @Bindable var status = status
    let snapshot = engine.snapshot
    let now = clock.now
    let sidebar = snapshot.sidebar(at: now)
    let shown = status.sidebarItem(selectedTab: snapshot.tab(in: status.selectedPlace, at: now)).shown(in: sidebar)

    NavigationSplitView(columnVisibility: .constant(.all)) {
      SidebarList(sidebar: sidebar, now: now, selection: .init(get: { shown }, set: { $0.map(status.pick) }))
        .toolbar(removing: .sidebarToggle)
        #if os(iOS)
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            RefreshButton()
          }
        }
        #endif
        .settingsButton(isPresented: $status.isSettingsPresented, language: language)
        #if os(macOS)
        // About an iPad sidebar's width, which the rows are drawn for; a Mac window's default is
        // narrower and cuts their names.
        .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        #endif
    } detail: {
      NavigationStack {
        detail(for: shown)
          // Each row opens its screen at the top.
          .id(shown)
      }
      .refreshFailureToast()
    }
    .navigationSplitViewStyle(.balanced)
    .sensoryFeedback(Haptic.modeSwitch, trigger: shown)
  }

  /// The screen of the row `item`. Eggstra Work shows on top of Salmon Run's; the Splatfest and
  /// Tricolor Turf War show on the Splatfest screen in the form last picked, where Tricolor Turf
  /// War sits under the Splatfest's card.
  @ViewBuilder
  private func detail(for item: SidebarItem) -> some View {
    switch item {
      case .mode(.battle(let mode)): BattleModeScreenView(mode: mode)
      case .mode(.salmonRun),
           .eggstraWork: SalmonRunScreenView()
      case .challenge: ChallengeScreenView()
      case .splatfestBattle(let form): SplatfestScreenView(form: form)
      case .splatfest,
           .tricolorTurfWar: SplatfestScreenView(form: status.splatfestForm)
    }
  }
}

// MARK: - SidebarList

/// The sidebar's groups and rows in the selected Style. Before the schedules feed's first good
/// response it lists nothing, and the detail shows the shared empty state.
private struct SidebarList: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language
  @TimeSettings private var time

  let sidebar: Sidebar?
  let now: Date
  @Binding var selection: SidebarItem?

  var body: some View {
    switch preferences.style {
      case .classic:
        list(row: ClassicSidebarRow.init, header: ClassicSidebarHeader.init)

      case .ink:
        list(row: InkSidebarRow.init, header: InkSidebarHeader.init)
          .inkSidebarBackground()

      case .timeline:
        list(row: TimelineSidebarRow.init, header: TimelineSidebarHeader.init)
          .timelineSidebarBackground()
    }
  }

  /// The list with each row drawn by `row` and each group's title by `header`.
  private func list(
    row: @escaping (SummaryRowContent) -> some View,
    header: @escaping (String) -> some View)
    -> some View
  {
    let writer: SentenceWriter = time.writer(engine.snapshot.terms(in: language))
    let format: ScheduleFormat = time.format(language)

    return List(selection: $selection) {
      ForEach(sidebar?.groups ?? [], id: \.kind) { group in
        Section {
          ForEach(group.rows, id: \.item) { sidebarRow in
            row(SummaryRowContent(row: sidebarRow, writer: writer, format: format, now: now))
              .tag(sidebarRow.item)
          }
        } header: {
          header(group.kind.title(in: language))
        }
      }
    }
    .listStyle(.sidebar)
  }
}
