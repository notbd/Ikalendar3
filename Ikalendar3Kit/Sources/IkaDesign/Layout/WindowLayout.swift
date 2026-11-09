//
//  WindowLayout.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - WindowLayout

/// How an iPad window lays out the Schedules, decided by the window's size and width class: the
/// iPhone tabs at compact width, one column per Mode in a landscape window wide enough for them,
/// else a sidebar of Modes beside one detail column.
public enum WindowLayout: Equatable, Sendable {
  /// The iPhone tabs, as ikalendar 2 shows them in Slide Over or a narrow Split View, where a
  /// sidebar and a detail cannot sit side by side.
  case tabs
  /// One column per Mode, with the event strip above.
  case columns
  /// A sidebar of Modes beside one detail column. Its split view never collapses into one stack:
  /// a window of compact width takes the tabs instead.
  case sidebar

  /// The narrowest window that shows columns.
  static public let minimumColumnsWidth: CGFloat = 1024

  /// The layout of a window of `windowSize` in `horizontalSizeClass`: the tabs at compact width,
  /// columns when it is wider than tall and at least `minimumColumnsWidth` wide, else the
  /// sidebar. A window with no size class, as on the Mac, lays out by its size alone.
  public init(windowSize: CGSize, horizontalSizeClass: UserInterfaceSizeClass?) {
    guard horizontalSizeClass != .compact else {
      self = .tabs
      return
    }

    let isLandscape = windowSize.width > windowSize.height
    self = isLandscape && windowSize.width >= Self.minimumColumnsWidth ? .columns : .sidebar
  }
}
