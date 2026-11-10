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

/// The app's root: the iPhone tabs, on iPad the layout its window's size and width class call for
/// (`WindowLayout`), or on the Mac the view the player picked (`MacWindowView`), around them what
/// every layout shares: Settings, the event sheet, the colour scheme, the refresh haptic and the
/// failed-refresh toast, and over them the welcome screen while the preferences ask for it.
///
/// The welcome screen covers the schedules while the first load runs silently behind it: no
/// refresh haptic and no toast until Get Started. With no network and no cache, the shared empty
/// state shows after it, and the next activation or a pull to refresh tries again.
///
/// The layouts share one selection in `AppStatus`: a sidebar pick selects its tab and a tab or
/// menu choice moves the sidebar, so a window that crosses a layout boundary shows the player's
/// last choice. The open sheets live there too and stay open across the switch.
struct AppRootView: View {
  @Environment(AppStatus.self) private var status
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  var body: some View {
    @Bindable var status = status

    ZStack {
      layout
        .settingsPresentation(isPresented: $status.isSettingsPresented)
        .eventSheetPresentation(item: $status.presentedEvent)
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
        switch WindowLayout(windowSize: windowSize, horizontalSizeClass: horizontalSizeClass) {
          case .tabs: ModeTabsView()
          case .columns: ColumnsLayoutView()
          case .sidebar: SidebarLayoutView()
        }
      }
    }
    else {
      ModeTabsView()
    }
    #else
    MacWindowView()
    #endif
  }
}
