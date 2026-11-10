//
//  EventSheet.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - EventSheet

/// The full Schedule an event card opens in a sheet: the Challenge screen, the Splatfest screen,
/// or the Salmon Run screen, which holds a Big Run among its Shifts and an Eggstra Work on top.
///
/// It names the screen, not the event, so an open sheet follows the clock as the screen does.
enum EventSheet: Hashable, Identifiable {
  /// The Challenge screen.
  case challenge
  /// The Splatfest screen, announced or running, in the form last picked.
  case splatfest
  /// The Salmon Run screen, for a Big Run or an Eggstra Work.
  case salmonRun

  /// The sheet `item`'s card opens.
  init(_ item: EventItem) {
    switch item {
      case .challenge: self = .challenge
      case .splatfest: self = .splatfest
      case .bigRun,
           .eggstraWork: self = .salmonRun
    }
  }

  var id: Self { self }
}

// MARK: - Presentation

extension View {
  /// Presents the event sheet `item` holds as a form sheet: its screen under its own navigation
  /// bar with a close button, the failed-refresh toast over it. A form sheet keeps the Challenge
  /// and Splatfest screens, which have only the iPhone list, near an iPhone's width. The Salmon
  /// Run screen also has a wide detail, from 540 pt, which an iPad form sheet is: the sheet
  /// chooses the iPhone list (`detailLayout(.list)`), so all three show it. A Mac form sheet is far
  /// shorter than an iPad's, so a Mac sheet takes an iPhone list's size instead.
  func eventSheetPresentation(item: Binding<EventSheet?>) -> some View {
    sheet(item: item) { sheet in
      EventSheetView(sheet: sheet)
        #if os(macOS)
        .frame(minWidth: 420, idealWidth: 480, minHeight: 400, idealHeight: 720)
        .presentationSizing(.fitted)
        #else
        .presentationSizing(.form)
        #endif
    }
  }
}

// MARK: - EventSheetView

/// An event sheet's screen in the selected Style.
private struct EventSheetView: View {
  @Environment(AppStatus.self) private var status
  @Environment(\.dismiss) private var dismiss

  let sheet: EventSheet

  var body: some View {
    NavigationStack {
      screen
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) { dismiss() }
          }
        }
    }
    .detailLayout(.list)
    .refreshFailureToast()
  }

  @ViewBuilder private var screen: some View {
    switch sheet {
      case .challenge: ChallengeScreenView()
      case .splatfest: SplatfestScreenView(form: status.splatfestForm)
      case .salmonRun: SalmonRunScreenView()
    }
  }
}
