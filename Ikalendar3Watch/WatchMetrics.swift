//
//  WatchMetrics.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreGraphics

/// The watch pages' sizes, in points at the default text size: Ink's styles scaled to the wrist.
/// Ticket 56 judges them with the real fonts.
enum WatchMetrics {
  /// The space between rows, and between a row's ring and its text.
  static let rowSpacing: CGFloat = 8
  /// The space between a row's lines.
  static let lineSpacing: CGFloat = 4

  /// The ring around a Mode icon.
  static let ringSize: CGFloat = 40
  /// The ring's stroke.
  static let ringLineWidth: CGFloat = 4
  /// The space between the ring and the icon inside it.
  static let iconInset: CGFloat = 3

  /// The Mode's name, in the heavy face.
  static let modeNameSize: CGFloat = 13
  /// The Rule, the Shift's Stage or why nothing is on, in the heavy face.
  static let detailSize: CGFloat = 16
  /// The time left, in the light face.
  static let countdownSize: CGFloat = 13

  /// The white ring around a Mode page's current Rule or Shift Stage.
  static let pageRingSize: CGFloat = 46
  /// A weapon of a Shift on a Mode page or the later list.
  static let weaponSize: CGFloat = 22
  /// A Rule icon beside the next or a later Rotation.
  static let ruleIconSize: CGFloat = 16
  /// A page dot, and the selected page's.
  static let pageDotSize: CGFloat = 5
  static let selectedPageDotSize: CGFloat = 8
  /// The page dots' column, at the screen's trailing edge.
  static let pageDotsWidth: CGFloat = 10
  /// How strong a Mode's tint is at the bottom of its page, over Ink's black; it is full at the top.
  static let pageTintFloor: Double = 0.2
}
