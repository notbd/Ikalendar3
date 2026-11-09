//
//  ScaledLimitedLine.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

extension View {
  /// Caps text at `lineLimit` lines and shrinks it (down to `minScaleFactor`) instead of truncating.
  public func scaledLimitedLine(
    lineLimit: Int? = 1,
    minScaleFactor: CGFloat = 0.3)
    -> some View
  {
    self
      .lineLimit(lineLimit)
      .minimumScaleFactor(minScaleFactor)
  }

  /// Fits a cell's text the way `arrangement` asks: shrunk onto one line side by side, wrapped
  /// at full size when stacked.
  public func scaledLimitedLine(for arrangement: CellArrangement) -> some View {
    scaledLimitedLine(lineLimit: arrangement.lineLimit, minScaleFactor: arrangement.minimumScaleFactor)
  }
}
