//
//  Ikalendar3WatchApp.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

/// The watch app. It runs without its iPhone.
@main
struct Ikalendar3WatchApp: App {
  /// The one clock the app's screens read.
  @State private var clock: AppClock = .init()

  var body: some Scene {
    WindowGroup {
      Text(verbatim: "ikalendar3")
        .environment(clock)
    }
  }
}
