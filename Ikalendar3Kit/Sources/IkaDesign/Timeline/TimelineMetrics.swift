//
//  TimelineMetrics.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - TimelineMetrics

/// Timeline's sizes, after SplatNet 3's schedule page as the owner's chosen prototype draws it
/// (`prototypes/15-visual/`, Style C). Ticket 57 settles the final look.
enum TimelineMetrics {
  /// Space between the screen's edge and the axis line.
  static let axisLineLeading: CGFloat = 24
  /// The axis line's width.
  static let axisLineWidth: CGFloat = 8
  /// Where a slot's content starts, side by side: right of the pins.
  static let contentLeading: CGFloat = 76
  /// Where a slot's content starts when stacked: right of the line, the pin moving into the slot.
  static let stackedContentLeading: CGFloat = 44
  /// Space between the content and the screen's trailing edge.
  static let contentTrailing: CGFloat = 14
  /// Space between two slots, which the axis line spans.
  static let slotSpacing: CGFloat = 18
  /// Space above the first slot.
  static let axisTop: CGFloat = 18
  /// A pin's leading edge.
  static let pinLeading: CGFloat = 8
  /// The rounding of pins and tags.
  static let pinCornerRadius: CGFloat = 6
  /// The rounding of a picture strip's outer corners.
  static let pictureCornerRadius: CGFloat = 10
  /// The gap between the two Stage pictures of a strip.
  static let pictureGap: CGFloat = 3
  /// A Stage picture's shape.
  static let pictureAspectRatio: CGFloat = 16 / 9
  /// A Rule icon's side.
  static let ruleIconSize: CGFloat = 26
  /// A weapon's or the King Salmonid's side.
  static let weaponSize: CGFloat = 40
  /// The header's height, without the Series and Open strip.
  static let headerHeight: CGFloat = 54
  /// The Mode stamp's side in the header.
  static let stampSize: CGFloat = 32
  /// The navigation bar badge's side, as in ikalendar 2.
  static let badgeSize: CGFloat = 44
  /// The Mode icon's side inside the badge.
  static let badgeImageSize: CGFloat = 28
  /// The Series and Open strip's height.
  static let stripHeight: CGFloat = 40
  /// The thickness of the line under the shown Anarchy form.
  static let stripUnderline: CGFloat = 3
}

// MARK: - TimelinePalette

/// SplatNet 3's page colours. Timeline draws on them in light appearance too, until ticket 57
/// designs its light look (ticket 11's Timeline panel says the same).
enum TimelinePalette {
  /// The page behind the axis.
  static let page: Color = .init(SRGBColor(hex: 0x292E35))
  /// The header behind the Mode's name.
  static let header: Color = .black
  /// The Series and Open strip.
  static let strip: Color = .init(SRGBColor(hex: 0x16191D))
  /// The form not shown on the strip.
  static let stripIdle: Color = .init(SRGBColor(hex: 0x8D949C))
  /// A pin of a Rotation or Shift that does not run now.
  static let idlePin: ColorPair = .init(foreground: .black, background: SRGBColor(hex: 0xEAEAEA))
  /// Light text beside white text, such as the countdown.
  static let secondaryText: Color = .init(SRGBColor(hex: 0xD8DDE3))
  /// The axis track's opacity before and after the current item's progress.
  static let trackOpacity: Double = 0.35
}
#endif
