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
/// (`WindowLayout`), around them what every layout shares: Settings, the event sheet, the colour
/// scheme, the refresh haptic and the failed-refresh toast.
///
/// The selection and the open sheets live in `AppStatus`, so they hold while the window switches
/// layouts.
struct AppRootView: View {
  @Environment(AppStatus.self) private var status
  @Environment(PreferenceStore.self) private var preferences

  var body: some View {
    @Bindable var status = status

    layout
      .settingsPresentation(isPresented: $status.isSettingsPresented)
      .eventSheetPresentation(item: $status.presentedEvent)
      .appColorScheme(preferences.colorScheme)
      .refreshFeedback()
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
          case .columns: ColumnsLayoutView()
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
