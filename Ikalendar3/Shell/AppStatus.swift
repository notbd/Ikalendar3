//
//  AppStatus.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Observation

// MARK: - AppStatus

/// The app's in-session state, which no preference keeps.
@Observable
final class AppStatus {
  /// The place of the selected tab. A place, not a tab, so the selection holds while the
  /// Splatfest tab takes Regular Battle's place and when it gives it back.
  var selectedPlace: ModeTab
  /// Whether Settings is shown on iPhone and iPad.
  var isSettingsPresented = false
  /// The haptic the last refresh run ended with, which the tabs play; `nil` before the first.
  var refreshHaptic: RefreshHaptic?

  /// A status that opens on `selectedPlace`: the default Mode.
  init(selectedPlace: ModeTab) {
    self.selectedPlace = selectedPlace
  }
}
