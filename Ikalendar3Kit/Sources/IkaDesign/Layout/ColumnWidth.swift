//
//  ColumnWidth.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreGraphics

// MARK: - ColumnWidth

/// The width of each column in the Mac's Columns view, and of each card on the event strip above
/// it: an equal share of the width they share, never narrower than `minimum`, so a narrow window
/// scrolls them sideways instead of squeezing the lists and cards.
public enum ColumnWidth {
  /// The narrowest column, about an iPhone list's width.
  static public let minimum: CGFloat = 300

  /// Each of `count` columns' width in `available` points.
  static public func width(sharing available: CGFloat, count: Int) -> CGFloat {
    max(minimum, available / CGFloat(max(count, 1)))
  }
}
