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
/// failed-refresh toast. While the preferences ask for the welcome screen, it shows instead of the
/// layout.
///
/// The first load runs silently while the welcome screen shows (the scene's effects run it, not
/// the layout): no refresh haptic and no toast until Get Started. The layout is not built until
/// then, so VoiceOver, Full Keyboard Access, the Tab key and the Mac toolbar reach nothing but the
/// welcome screen; the layout appears at once under it as it fades. The sheets hang on the root,
/// so Settings stays open when Debug Options shows the welcome screen again. With no network and
/// no cache, the shared empty state shows after it, and the next activation or a pull to refresh
/// tries again.
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
      if preferences.shouldShowOnboarding {
        OnboardingView()
          .zIndex(1)
          .transition(.opacity)
      }
      else {
        layout
          .transition(.identity)
      }
    }
    .settingsPresentation(isPresented: $status.isSettingsPresented)
    .eventSheetPresentation(item: $status.presentedEvent)
    .refreshFeedback(isSilent: preferences.shouldShowOnboarding)
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
