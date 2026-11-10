//
//  WatchRoute.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - WatchRoute

/// Where the watch app's navigation stack leads from the Now page.
enum WatchRoute: Hashable {
  /// The Mode pages, turned with the Digital Crown, opened at a Mode's: where a Now row leads.
  case modePages(Mode)
  /// A Mode's later Rotations or Shifts: where a tap on its page leads.
  case later(Mode)

  /// The page the route shows.
  @ViewBuilder
  var destination: some View {
    switch self {
      case .modePages(let mode): ModePagesScreen(openedAt: mode)
      case .later(let mode): LaterListScreen(mode: mode)
    }
  }
}
