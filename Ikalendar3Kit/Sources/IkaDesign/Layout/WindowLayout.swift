//
//  WindowLayout.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreGraphics

// MARK: - WindowLayout

/// How an iPad window lays out the Schedules, decided by the window's size: one column per Mode
/// in a landscape window wide enough for them, else a sidebar of Modes beside one detail column.
public enum WindowLayout: Equatable, Sendable {
  /// One column per Mode, with the event strip above.
  case columns
  /// A sidebar of Modes beside one detail column.
  case sidebar

  /// The narrowest window that shows columns.
  static public let minimumColumnsWidth: CGFloat = 1024

  /// The layout of a window of `windowSize`: columns when it is wider than tall and at least
  /// `minimumColumnsWidth` wide, else the sidebar.
  public init(windowSize: CGSize) {
    let isLandscape = windowSize.width > windowSize.height
    self = isLandscape && windowSize.width >= Self.minimumColumnsWidth ? .columns : .sidebar
  }
}
