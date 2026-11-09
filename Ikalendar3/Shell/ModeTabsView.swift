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
/// Settings from each tab's toolbar. A second tap on the selected Anarchy or Splatfest tab shows
/// the Series and Open (or Open and Pro) menu above it.
struct ModeTabsView: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(AppStatus.self) private var status
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// A new value for each failed refresh; the toast shows while it is set.
  @State private var failureToast: UUID?

  var body: some View {
    @Bindable var status = status
    let snapshot = engine.snapshot
    let now = clock.now
    let selectedTab = snapshot.tab(in: status.selectedPlace, at: now)
    // Every tap on a tab bar item reaches the setter, a second tap on the selected tab included
    // unless the interceptor below keeps it from the system.
    let selection: Binding = .init(
      get: { status.selectedPlace },
      set: { status.select(snapshot.tab(in: $0, at: now)) })

    TabView(selection: selection) {
      ForEach(snapshot.tabs(at: now), id: \.self) { tab in
        Tab(value: tab.place) {
          NavigationStack {
            screen(for: tab)
              .settingsButton(isPresented: $status.isSettingsPresented, language: language)
          }
          .overlay(alignment: .bottomLeading) {
            tabMenu(for: tab)
              .animation(menuAnimation, value: status.presentedMenu)
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
    .interceptingTabReselection(isEnabled: selectedTab.repeatedSelectionAction != .scrollToTop) {
      status.select(selectedTab)
    }
    .minimizingTabBar(preferences.shouldMinimizeTabBar)
    .settingsPresentation(isPresented: $status.isSettingsPresented)
    .appColorScheme(preferences.colorScheme)
    .sensoryFeedback(Haptic.modeSwitch, trigger: status.selectedPlace)
    .sensoryFeedback(Haptic.modeSwitch, trigger: status.mode(of: .anarchy))
    .sensoryFeedback(Haptic.modeSwitch, trigger: status.mode(of: .splatfestBattle))
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

  /// `tab`'s screen. A Mode picked from the menu opens at the top, on its current Rotation.
  @ViewBuilder
  private func screen(for tab: AppTab) -> some View {
    switch tab {
      case .mode(.regularBattle): BattleModeScreenView(mode: .regular)
      case .mode(.anarchy): BattleModeScreenView(mode: status.anarchyMode).id(status.anarchyMode)
      case .mode(.xBattle): BattleModeScreenView(mode: .x)
      case .mode(.challenge): ChallengeScreenView()
      case .mode(.salmonRun): SalmonRunScreenView()
      case .splatfest: SplatfestScreenView(form: status.splatfestForm).id(status.splatfestForm)
    }
  }

  /// `tab`'s menu while it is shown, over a layer that closes it on a tap anywhere else above the
  /// tab bar. VoiceOver skips the layer: the menu is modal and closes with the escape gesture.
  @ViewBuilder
  private func tabMenu(for tab: AppTab) -> some View {
    if let menu = status.presentedMenu, tab.repeatedSelectionAction == .openMenu(menu) {
      ZStack(alignment: .bottomLeading) {
        Color.clear
          .contentShape(.rect)
          .ignoresSafeArea(edges: .top)
          .onTapGesture { status.dismissMenu() }
          .accessibilityHidden(true)

        TabMenuView(menu: menu, selection: status.mode(of: menu), choose: status.choose, dismiss: status.dismissMenu)
          .padding([.horizontal, .bottom], 16)
          .transition(menuTransition)
      }
    }
  }

  /// The menu grows from the selected tab, or fades under Reduce Motion.
  private var menuTransition: AnyTransition {
    reduceMotion ? .opacity : .scale(scale: 0.6, anchor: .bottomLeading).combined(with: .opacity)
  }

  private var menuAnimation: Animation {
    reduceMotion ? Motion.crossFade : .snappy
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
