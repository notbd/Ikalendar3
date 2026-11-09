//
//  DetailLayout.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - DetailLayout

/// How a Mode's detail lays out its Schedule, decided by the detail's own width rather than the
/// device: the iPhone list, or on iPad and Mac one wide current row over one table.
///
/// iPhone always gets the list: it runs in portrait only, where every model is narrower than
/// `WideDetailMetrics.minimumWidth`.
public enum DetailLayout: Equatable, Sendable {
  /// The iPhone list, its cells never squeezed.
  case list
  /// The wide current row over one table, in a centred column.
  case wide(WideDetailMetrics)

  /// The layout of a detail `width` points wide at `dynamicTypeSize`. Large text takes the list,
  /// which stacks its cells as on iPhone.
  public init(width: CGFloat, dynamicTypeSize: DynamicTypeSize) {
    guard width >= WideDetailMetrics.minimumWidth, !dynamicTypeSize.isAccessibilitySize else {
      self = .list
      return
    }

    self = .wide(WideDetailMetrics(width: width, dynamicTypeSize: dynamicTypeSize))
  }
}

// MARK: - WideDetailMetrics

/// The wide detail's column at one detail width: it grows with the detail up to
/// `maximumWidth`, then stays there, centred.
public struct WideDetailMetrics: Equatable, Sendable {
  /// The narrowest detail that shows the wide detail.
  static public let minimumWidth: CGFloat = 540
  /// The widest the column grows.
  static public let maximumWidth: CGFloat = 980

  /// The column's width.
  public let columnWidth: CGFloat
  /// The space on each side of the column in a detail wider than `maximumWidth`.
  public let sideMargin: CGFloat
  /// How each half of the current row sizes its parts: as a cell half the column wide, so
  /// pictures and text keep their proportions between `CellMetrics`' floor and ceiling. The
  /// table's thumbnails take their sizes from it too.
  public let half: CellMetrics

  fileprivate init(width: CGFloat, dynamicTypeSize: DynamicTypeSize) {
    columnWidth = min(width, Self.maximumWidth)
    sideMargin = (width - columnWidth) / 2
    half = CellMetrics(width: columnWidth / 2, dynamicTypeSize: dynamicTypeSize)
  }
}

// MARK: - CellShare

extension CellShare {
  /// The wide current row's progress ring, a share of `WideDetailMetrics.half`.
  static public let wideRingSize: CellShare = .init(0.15)
  /// A table row's Rule column, a share of `WideDetailMetrics.half`. Every Style's table lines
  /// its columns up on these shares; the time column takes the rest of the row.
  static public let tableRuleWidth: CellShare = .init(0.46)
  /// A table row's Stage thumbnail, with its name under it.
  static public let tableThumbnailWidth: CellShare = .init(0.36)
  /// A table row's Rule icon.
  static public let tableRuleIconHeight: CellShare = .init(0.1)
  /// A Salmon Run table row's weapon.
  static public let tableWeaponSize: CellShare = .init(0.13)
}
