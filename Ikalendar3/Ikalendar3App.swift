//
//  Ikalendar3App.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

/// The app on iPhone, iPad and Mac.
@main
struct Ikalendar3App: App {
  /// The one clock the app's screens read.
  @State private var clock: AppClock = .init()

  var body: some Scene {
    WindowGroup {
      Text(verbatim: "ikalendar3")
        .environment(clock)
    }
  }
}
