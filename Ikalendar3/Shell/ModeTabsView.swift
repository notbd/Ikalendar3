//
//  ModeTabsView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import IkaIntents
import SwiftUI

// MARK: - ModeTabsView

/// The iPhone tabs in the native Liquid Glass tab bar: Regular Battle, Anarchy, X Battle,
/// Challenge and Salmon Run, with the Splatfest tab in Regular Battle's place while a Splatfest
/// runs. iPad and Mac show them too until their own navigation lands.
///
/// It plays the haptics of ikalendar 2's table, the refresh haptic as each run hands it to the
/// status, reports a failed refresh in a toast while the screens keep their data, and shows
/// Settings from each tab's toolbar.
struct ModeTabsView: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(AppStatus.self) private var status
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language

  /// A new value for each failed refresh; the toast shows while it is set.
  @State private var failureToast: UUID?

  var body: some View {
    @Bindable var status = status

    TabView(selection: $status.selectedPlace) {
      ForEach(engine.snapshot.tabs(at: clock.now), id: \.self) { tab in
        Tab(value: tab.place) {
          NavigationStack {
            screen(for: tab)
              .settingsButton(isPresented: $status.isSettingsPresented, language: language)
          }
          .overlay(alignment: .bottom) {
            if failureToast != nil {
              RefreshFailureToast()
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
          }
        } label: {
          Label(tab.title(in: language), systemImage: tab.systemImage)
        }
      }
    }
    .minimizingTabBar(preferences.shouldMinimizeTabBar)
    .settingsPresentation(isPresented: $status.isSettingsPresented)
    .appColorScheme(preferences.colorScheme)
    .sensoryFeedback(Haptic.modeSwitch, trigger: status.selectedPlace)
    .sensoryFeedback(trigger: status.refreshHaptic) { _, new in
      new?.feedback
    }
    .onChange(of: engine.status) { old, new in
      if old == .loading, new == .failed {
        withAnimation { failureToast = UUID() }
      }
    }
    .task(id: failureToast) {
      guard failureToast != nil, await (try? Task.sleep(for: .seconds(3))) != nil else { return }

      withAnimation { failureToast = nil }
    }
  }

  @ViewBuilder
  private func screen(for tab: AppTab) -> some View {
    switch tab {
      case .mode(.regularBattle): BattleModeScreenView(mode: .regular)
      // Anarchy Open joins with the Series and Open menu.
      case .mode(.anarchy): BattleModeScreenView(mode: .anarchySeries)
      case .mode(.xBattle): BattleModeScreenView(mode: .x)
      case .mode(.challenge): ChallengeScreenView()
      case .mode(.salmonRun): SalmonRunScreenView()
      // Pro joins with the Open and Pro menu.
      case .splatfest: SplatfestScreenView(form: .open)
    }
  }
}

// MARK: - Tab bar minimizing

extension View {
  /// Minimizes the iPhone tab bar while a list scrolls down, when the player asks for it.
  fileprivate func minimizingTabBar(_ isOn: Bool) -> some View {
    #if os(iOS)
    tabBarMinimizeBehavior(isOn ? .onScrollDown : .automatic)
    #else
    self
    #endif
  }
}
