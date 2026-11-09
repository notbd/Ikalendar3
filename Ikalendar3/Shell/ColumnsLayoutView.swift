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

/// The iPad's layout in a landscape window wide enough (`WindowLayout.columns`): the event strip
/// over one column per Mode (`Snapshot.columns(at:)`), so everything shows at once.
///
/// Each column is its Mode's screen under a navigation bar of its own, so it shows its Style's
/// iPhone list as on iPhone, with its stamp, title and track button; the screens pick the list by
/// their width (`DetailLayout`). The Anarchy column's header opens the Series and Open menu. The
/// refresh and Settings buttons sit beside the strip, and an event card opens its Schedule in a
/// sheet, which `AppRootView` presents.
struct ColumnsLayoutView: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(AppStatus.self) private var status

  var body: some View {
    VStack(spacing: 0) {
      EventStrip()

      HStack(spacing: 0) {
        ForEach(engine.snapshot.columns(at: clock.now), id: \.self) { column in
          NavigationStack {
            screen(for: column)
              .columnMenu(column.menu)
          }
        }
      }
    }
    .refreshFailureToast()
    .sensoryFeedback(Haptic.modeSwitch, trigger: status.mode(of: .anarchy))
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

// MARK: - EventStrip

/// The band over the columns: the card of each event the snapshot lists, in the strip's fixed
/// order, each opening its Schedule in a sheet, then the refresh and Settings buttons the sidebar
/// keeps in its toolbar. Four cards share the band's width; while none is listed, only the
/// buttons show.
private struct EventStrip: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock
  @Environment(AppStatus.self) private var status
  @Environment(\.gameLanguage) private var language

  static private let spacing: CGFloat = 12

  var body: some View {
    @Bindable var status = status

    HStack(alignment: .top, spacing: Self.spacing) {
      ScrollView(.horizontal) {
        HStack(alignment: .top, spacing: Self.spacing) {
          ForEach(engine.snapshot.eventItems(at: clock.now) ?? [], id: \.self) { item in
            Button { status.presentedEvent = EventSheet(item) } label: {
              EventCardView(item: item)
            }
            .buttonStyle(.plain)
            .containerRelativeFrame(.horizontal, count: 4, spacing: Self.spacing)
          }
        }
      }
      .scrollIndicators(.hidden)
      // As tall as the tallest card, so the columns take the rest.
      .fixedSize(horizontal: false, vertical: true)

      GlassEffectContainer {
        HStack(spacing: Self.spacing) {
          RefreshButton()
          SettingsButton(isPresented: $status.isSettingsPresented, language: language)
        }
      }
      .buttonStyle(.glass)
      .labelStyle(.iconOnly)
    }
    .padding(16)
    .background { StyleBackground().ignoresSafeArea() }
  }
}

// MARK: - Column menu

extension View {
  /// Puts the button that opens `menu` at the leading end of a column's navigation bar, when the
  /// column has one.
  fileprivate func columnMenu(_ menu: TabMenu?) -> some View {
    toolbar {
      if let menu {
        ToolbarItem(placement: .navigation) {
          ColumnMenuButton(menu: menu)
        }
      }
    }
  }
}

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
      TabMenuView(menu: menu, selection: mode) { chosen in
        status.choose(chosen)
        isPresented = false
      }
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
