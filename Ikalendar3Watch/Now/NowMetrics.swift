//
//  NowMetrics.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreGraphics

/// The watch pages' sizes, in points at the default text size: Ink's styles scaled to the wrist.
/// Ticket 56 judges them with the real fonts.
enum NowMetrics {
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

  /// A Splatfest team's colour where the source lacks its name.
  static let teamSwatchSize: CGSize = .init(width: 40, height: 12)
}
