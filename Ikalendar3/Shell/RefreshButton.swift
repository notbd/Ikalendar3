//
//  RefreshButton.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import IkaIntents
import SwiftUI

// MARK: - RefreshButton

/// The iPad toolbar's refresh button, as in ikalendar 2: a run of the effects shell the player
/// asked for, under the same gate as every run. While a refresh runs it turns into a pulsing
/// antenna and waits. iPhone refreshes with pull to refresh instead.
struct RefreshButton: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(\.effects) private var effects
  @Environment(AppStatus.self) private var status
  @Environment(\.gameLanguage) private var language

  var body: some View {
    let isRefreshing = engine.status == .loading

    Button {
      Task { await effects?.run(isRequested: true, reportingTo: status) }
    } label: {
      Label {
        Text(verbatim: (isRefreshing ? SidebarText.refreshing : .refresh).text(in: language))
      } icon: {
        Image(systemName: isRefreshing
          ? "antenna.radiowaves.left.and.right"
          : "arrow.trianglehead.2.clockwise.rotate.90")
          .contentTransition(.symbolEffect(.replace.offUp))
          .symbolEffect(.variableColor, options: .speed(2), isActive: isRefreshing)
      }
    }
    .disabled(isRefreshing)
  }
}
