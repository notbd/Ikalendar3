//
//  StylePanel.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

extension Style {
  /// The panel that Mode colours and Splatfest team colours sit on in this Style and
  /// `colorScheme`. Where a Style draws them on two surfaces, it is the one closer to mid-grey,
  /// so a colour readable on it is readable on both.
  ///
  /// Ink and Timeline draw on the game's dark panels in light appearance too, until their light
  /// look is designed.
  public func panel(in colorScheme: ColorScheme) -> SRGBColor {
    switch (self, colorScheme) {
      // ikalendar 2's grouped lists: the grouped background (#ffffff cells sit on it) in light,
      // the cell (on #000000) in dark.
      case (.classic, .light): .init(hex: 0xF2F2F7)
      case (.classic, _): .init(hex: 0x1C1C1E)
      // The in-game board panel.
      case (.ink, _): .init(hex: 0x383838)
      // SplatNet 3's card (on its #292e35 page).
      case (.timeline, _): .init(hex: 0x3A414A)
    }
  }
}
