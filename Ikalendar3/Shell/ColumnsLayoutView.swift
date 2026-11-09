//
//  ColumnsLayoutView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - ColumnsLayoutView

/// The iPad's layout in a landscape window wide enough (`WindowLayout.columns`), and the Mac's
/// Columns view: the event strip over one column per Mode (`Snapshot.columns(at:)`), so
/// everything shows at once.
///
/// Each column is its Mode's screen under a navigation bar of its own, so it shows its Style's
/// iPhone list as on iPhone, with its stamp, title and track button; the screens pick the list by
/// their width (`DetailLayout`). The Anarchy column's header opens the Series and Open menu. On
/// iPad the refresh and Settings buttons sit beside the strip; the Mac's window keeps them in its
/// toolbar and app menu, and scrolls its columns sideways in a narrow window. An event card opens
/// its Schedule in a sheet, which `AppRootView` presents.
struct ColumnsLayoutView: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(AppStatus.self) private var status

  var body: some View {
    VStack(spacing: 0) {
      EventStrip()

      #if os(macOS)
      ScrollView(.horizontal) { columns }
      #else
      columns
      #endif
    }
    #if os(macOS)
    // Each column's screen names its Mode; none names the window.
    .toolbar(removing: .title)
    #endif
    .refreshFailureToast()
    .sensoryFeedback(Haptic.modeSwitch, trigger: status.mode(of: .anarchy))
  }

  /// One column per Mode, side by side.
  private var columns: some View {
    let columns = engine.snapshot.columns(at: clock.now)

    return HStack(spacing: 0) {
      ForEach(columns, id: \.self) { column in
        NavigationStack {
          screen(for: column)
            .columnHeader(column)
        }
        .macColumnWidth(count: columns.count)
      }
    }
  }

  /// `column`'s screen. A Mode picked from the Anarchy menu opens at the top, on its current
  /// Rotation.
  @ViewBuilder
  private func screen(for column: ModeColumn) -> some View {
    switch column {
      case .regularBattle: BattleModeScreenView(mode: .regular)
      case .anarchy: BattleModeScreenView(mode: status.anarchyMode).id(status.anarchyMode)
      case .xBattle: BattleModeScreenView(mode: .x)
      case .splatfestBattle(let form): SplatfestScreenView(form: form)
      case .salmonRun: SalmonRunScreenView()
    }
  }
}

// MARK: - Column width

extension View {
  /// Sets a Mac column's width: an equal share of the window, at least `ColumnWidth.minimum`, so a
  /// narrow window scrolls the columns sideways. iPad columns share the window equally.
  fileprivate func macColumnWidth(count: Int) -> some View {
    #if os(macOS)
    containerRelativeFrame(.horizontal) { length, _ in
      ColumnWidth.width(sharing: length, count: count)
    }
    #else
    self
    #endif
  }
}

// MARK: - Column header

extension View {
  /// Puts the button that opens `column`'s menu, when it has one, at the leading end of the
  /// column's navigation bar. A Mac window has one toolbar for every column, so each Mac column
  /// shows a bar of its own over its screen instead (`MacColumnBar`).
  fileprivate func columnHeader(_ column: ModeColumn) -> some View {
    #if os(macOS)
    safeAreaInset(edge: .top, spacing: 0) {
      MacColumnBar(column: column)
    }
    #else
    toolbar {
      if let menu = column.menu {
        ToolbarItem(placement: .navigation) {
          ColumnMenuButton(menu: menu)
        }
      }
    }
    #endif
  }
}

#if os(macOS)

// MARK: - MacColumnBar

/// What a Mac column shows of the iPad column's navigation bar, on the Style's background: the
/// title where the Style sets it in that bar, Classic's large title, since Ink and Timeline name
/// the Mode in the screen's own heading; and the menu button, when the column has a menu.
private struct MacColumnBar: View {
  @Environment(AppStatus.self) private var status
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language

  let column: ModeColumn

  var body: some View {
    HStack(spacing: 8) {
      if preferences.style == .classic {
        Text(verbatim: column.title(anarchyMode: status.anarchyMode, in: language))
          .font(.title2.bold())
          .lineLimit(1)
          .accessibilityAddTraits(.isHeader)
      }
      Spacer(minLength: 0)
      if let menu = column.menu {
        ColumnMenuButton(menu: menu)
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 44)
    .background { StyleBackground() }
  }
}

// MARK: - ModeColumn

extension ModeColumn {
  /// The title of the column's screen, the Anarchy column's showing `anarchyMode`.
  fileprivate func title(anarchyMode: BattleMode, in language: GameLanguage) -> String {
    switch self {
      case .regularBattle: BattleMode.regular.name(in: language)
      case .anarchy: anarchyMode.name(in: language)
      case .xBattle: BattleMode.x.name(in: language)
      case .splatfestBattle(let form): RotationMode.splatfestBattle(form).name(in: language)
      case .salmonRun: Mode.salmonRun.name(in: language)
    }
  }
}
#endif

// MARK: - ColumnMenuButton

/// A column header's menu button: the form the column shows with a chevron, which opens the
/// iPhone tab's menu (`TabMenuView`) in a popover. Picking an option switches the column.
private struct ColumnMenuButton: View {
  @Environment(AppStatus.self) private var status
  @Environment(\.gameLanguage) private var language

  let menu: TabMenu

  @State private var isPresented = false

  var body: some View {
    let mode = status.mode(of: menu)

    Button { isPresented.toggle() } label: {
      HStack(spacing: 4) {
        Text(verbatim: mode.formName(in: language))
        Image(systemName: "chevron.down")
          .font(.footnote.weight(.semibold))
      }
    }
    .accessibilityLabel(Text(verbatim: mode.name(in: language)))
    .popover(isPresented: $isPresented) {
      TabMenuView(
        menu: menu,
        selection: mode,
        choose: { option in
          status.choose(option)
          isPresented = false
        },
        dismiss: { isPresented = false })
        .presentationCompactAdaptation(.popover)
        // The menu draws its own glass panel.
        .presentationBackground(.clear)
    }
  }
}

// MARK: - RotationMode

extension RotationMode {
  /// The form's own name, Series, Open or Pro, which a column's menu button shows; the full name
  /// of a Mode with one form, which no menu offers.
  fileprivate func formName(in language: GameLanguage) -> String {
    let form: ModeLabel? =
      switch self {
        case .battle(.anarchySeries): .series
        case .battle(.anarchyOpen),
             .splatfestBattle(.open): .open
        case .splatfestBattle(.pro): .pro
        case .battle(.regular),
             .battle(.x): nil
      }
    return form?.text(in: language) ?? name(in: language)
  }
}
