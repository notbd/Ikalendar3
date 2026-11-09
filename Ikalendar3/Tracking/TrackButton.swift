//
//  TrackButton.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaIntents
import SwiftUI

extension View {
  /// The toolbar button that starts Tracking `mode` on iPhone and iPad: the start-Tracking intent,
  /// which Siri and the Control Center control run too. Ticket 58 judges its final place. A Mac
  /// cannot start a Live Activity, so it has none.
  func trackButton(for mode: Mode, language: GameLanguage) -> some View {
    #if os(iOS)
    toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button(intent: StartTrackingIntent(mode: ModeParameter(mode))) {
          Label(TrackingText.startTracking.text(in: language), systemImage: "dot.radiowaves.left.and.right")
        }
      }
    }
    #else
    self
    #endif
  }
}
