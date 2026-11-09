//
//  AppRootView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - AppRootView

/// The app's root: the iPhone tabs, or on iPad the layout its window's size calls for
/// (`WindowLayout`), around them what every layout shares: Settings, the colour scheme, the
/// refresh haptic and the failed-refresh toast, and over them the welcome screen while the
/// preferences ask for it.
///
/// The welcome screen covers the schedules while the first load runs silently behind it: no
/// refresh haptic and no toast until Get Started. With no network and no cache, the shared empty
/// state shows after it, and the next activation or a pull to refresh tries again.
///
/// The selection lives in `AppStatus`, so it holds while the window switches layouts.
struct AppRootView: View {
  @Environment(AppStatus.self) private var status
  @Environment(PreferenceStore.self) private var preferences

  var body: some View {
    @Bindable var status = status

    ZStack {
      layout
        .settingsPresentation(isPresented: $status.isSettingsPresented)
        .refreshFeedback(isSilent: preferences.shouldShowOnboarding)

      if preferences.shouldShowOnboarding {
        OnboardingView()
          .zIndex(1)
          .transition(.opacity)
      }
    }
    .animation(.default, value: preferences.shouldShowOnboarding)
    .appColorScheme(preferences.colorScheme)
  }

  @ViewBuilder
  private var layout: some View {
    #if os(iOS)
    if UIDevice.current.userInterfaceIdiom == .pad {
      GeometryReader { proxy in
        // The reader fills the safe area; its insets give back the window's full size.
        let insets = proxy.safeAreaInsets
        let windowSize: CGSize = .init(
          width: proxy.size.width + insets.leading + insets.trailing,
          height: proxy.size.height + insets.top + insets.bottom)
        switch WindowLayout(windowSize: windowSize) {
          // The tabs stand in until the columns land.
          case .columns: ModeTabsView()
          case .sidebar: SidebarLayoutView()
        }
      }
    }
    else {
      ModeTabsView()
    }
    #else
    ModeTabsView()
    #endif
  }
}
