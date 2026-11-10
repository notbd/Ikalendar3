//
//  MacWindowCommands.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(macOS)
import IkaCore
import IkaDesign
import SwiftUI

// MARK: - MacWindowCommands

/// The Mac window's items at the top of the View menu: Columns, Sidebar and Overview with
/// Command-1 to Command-3, the one shown checked, as the toolbar switch picks them, then Refresh
/// with Command-R, which runs the effects shell as the toolbar's refresh button does. All of them
/// are disabled while the welcome screen shows, which the window shows with no view or toolbar
/// items. Without services, as in the unit-test host, the menu has none.
struct MacWindowCommands: Commands {
  let services: AppServices?

  var body: some Commands {
    CommandGroup(before: .toolbar) {
      if let services {
        MacWindowMenuItems(services: services)
      }
    }
  }
}

// MARK: - MacWindowMenuItems

/// The View menu's items, which read the services directly: a menu sees no scene's environment.
private struct MacWindowMenuItems: View {
  let services: AppServices

  private var language: GameLanguage { AppServices.language }

  var body: some View {
    let preferences = services.preferences

    Group {
      ForEach(MacLayout.allCases, id: \.self) { layout in
        Toggle(layout.title(in: language), isOn: Binding {
          preferences.macLayout == layout
        } set: { isOn in
          // Picking the view shown again keeps it.
          if isOn { preferences.macLayout = layout }
        })
        .keyboardShortcut(layout.keyEquivalent)
      }

      Divider()

      Button(SidebarText.refresh.text(in: language)) {
        Task { await services.effects.run(isRequested: true, reportingTo: services.status) }
      }
      .keyboardShortcut("r")
      .disabled(services.engine.status == .loading)

      Divider()
    }
    .disabled(preferences.shouldShowOnboarding)
  }
}
#endif
