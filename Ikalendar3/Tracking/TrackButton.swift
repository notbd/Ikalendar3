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
  /// which Siri and the Control Center control run too, where `screenButtonPlacement` says: beside
  /// Settings. Ticket 58 judges its final place. A Mac cannot start a Live Activity, so it has
  /// none.
  ///
  /// Like the control, it shows no Tracking state: it offers to start whether or not the Mode is
  /// Tracked, an activity the player dismissed included, and a start replaces a running Tracking
  /// of the Mode. A Debug launch on unrebased fixtures hides it (`DebugLaunch.hidesTrackButton`).
  func trackButton(for mode: Mode, language: GameLanguage) -> some View {
    #if os(iOS)
    modifier(TrackToolbarItem(mode: mode, language: language))
    #else
    self
    #endif
  }
}

#if os(iOS)
/// The toolbar item `trackButton(for:language:)` adds, where `screenButtonPlacement` says.
private struct TrackToolbarItem: ViewModifier {
  @Environment(\.screenButtonPlacement) private var placement

  let mode: Mode
  let language: GameLanguage

  func body(content: Content) -> some View {
    content.toolbar {
      ToolbarItem(placement: placement) {
        if showsTrackButton {
          Button(intent: StartTrackingIntent(mode: ModeParameter(mode))) {
            Label(TrackingText.startTracking.text(in: language), systemImage: TrackingText.startTracking.systemImage)
          }
        }
      }
    }
  }
}

/// Whether the track button shows: always, but in a Debug launch that hides it.
private var showsTrackButton: Bool {
  #if DEBUG
  !DebugLaunch.hidesTrackButton()
  #else
  true
  #endif
}
#endif
