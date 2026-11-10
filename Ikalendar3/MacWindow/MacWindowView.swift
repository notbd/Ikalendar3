//
//  MacWindowView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(macOS)
import IkaCore
import IkaDesign
import SwiftUI

// MARK: - MacWindowView

/// The Mac window's Schedules in the view the player chose last (`PreferenceStore.macLayout`),
/// Columns until the first choice: Columns and Sidebar as on iPad, or the Overview. The toolbar
/// holds the switch between them, which the View menu repeats with Command-1 to Command-3
/// (`MacWindowCommands`), and the one refresh button every view shares.
struct MacWindowView: View {
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language

  var body: some View {
    @Bindable var preferences = preferences

    Group {
      switch preferences.macLayout {
        case .columns: ColumnsLayoutView()
        case .sidebar: SidebarLayoutView()
        case .overview: OverviewLayoutView()
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        Picker(MacWindowText.view.text(in: language), selection: $preferences.macLayout) {
          ForEach(MacLayout.allCases, id: \.self) { layout in
            Label(layout.title(in: language), systemImage: layout.systemImage)
              .tag(layout)
          }
        }
        .pickerStyle(.segmented)
        .labelStyle(.iconOnly)
      }
      ToolbarItem(placement: .primaryAction) {
        RefreshButton()
      }
    }
    .frame(minWidth: MacWindowMetrics.minimumSize.width, minHeight: MacWindowMetrics.minimumSize.height)
  }
}

// MARK: - MacLayout

extension MacLayout {
  /// The view's name in the toolbar switch and the View menu.
  func title(in language: GameLanguage) -> String {
    let text: MacWindowText =
      switch self {
        case .columns: .columns
        case .sidebar: .sidebar
        case .overview: .overview
      }
    return text.text(in: language)
  }

  /// The view's symbol in the toolbar switch.
  var systemImage: String {
    switch self {
      case .columns: "rectangle.split.3x1"
      case .sidebar: "sidebar.left"
      case .overview: "square.grid.2x2"
    }
  }

  /// The key that picks the view with Command in the View menu: 1 to 3, in the switch's order.
  var keyEquivalent: KeyEquivalent {
    switch self {
      case .columns: "1"
      case .sidebar: "2"
      case .overview: "3"
    }
  }
}

// MARK: - MacWindowMetrics

/// The Mac window's sizes. Ticket 58 judges them.
enum MacWindowMetrics {
  /// The size a new window opens at: four columns a little wider than their minimum.
  static let defaultSize: CGSize = .init(width: 1280, height: 820)
  /// The smallest window: a sidebar beside an iPhone-wide detail. Columns scroll sideways below
  /// their combined minimum width (`ColumnWidth`).
  static let minimumSize: CGSize = .init(width: 640, height: 480)
}
#endif
