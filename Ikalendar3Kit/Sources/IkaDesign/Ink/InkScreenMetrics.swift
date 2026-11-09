//
//  InkScreenMetrics.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

/// The fixed sizes of Ink's Battle Mode and Salmon Run screens, from the visual prototype's Ink
/// screen (the planning folder's `prototypes/15-visual`, style B) and ikalendar 2's stamp and
/// badge. The base components' own sizes are `InkMetrics`'; sizes that follow a panel's width
/// are `CellShare`s. Ticket 56 judges the final values.
enum InkScreenMetrics {
  // MARK: List

  /// The space between the screen's edges and its panels.
  static let screenPadding: CGFloat = 14
  /// The space between two panels.
  static let panelSpacing: CGFloat = 14
  /// The space between the rows inside a panel.
  static let panelRowSpacing: CGFloat = 10
  /// The space between two Stage cards, or between a card and the weapons.
  static let cardSpacing: CGFloat = 9

  // MARK: Heading and stamp

  /// The space above the Mode heading and below it, before the first panel.
  static let headingPadding: EdgeInsets = .init(top: 10, leading: 4, bottom: 24, trailing: 0)
  /// The space between the Mode name and its form tag.
  static let headingSpacing: CGFloat = 9
  /// The splat behind the stamp, square.
  static let splatSize: CGFloat = 190
  /// The Mode icon on the splat, square.
  static let stampIconSize: CGFloat = 100
  /// The black outline around the stamp's icon.
  static let stampOutlineWidth: CGFloat = 2.5
  /// The stamp's turn at rest.
  static let stampAngle: Angle = .degrees(-10)
  /// How far the stamp reaches past the screen's trailing edge.
  static let stampTrailingOverhang: CGFloat = 4
  /// The share of the screen's width the heading leaves to the stamp beside it.
  static let stampReservedShare: CGFloat = 0.42
  /// How far the splat's lower edge may reach over the first panel's tape.
  static let splatPanelOverlap: CGFloat = 24
  /// The navigation bar badge the stamp docks into, round.
  static let badgeSize: CGFloat = 44
  /// The Mode icon in the badge.
  static let badgeIconSize: CGFloat = 28

  // MARK: Panels

  /// How far a state tag ("Now!", "Next") is turned.
  static let stateTagAngle: Angle = .degrees(-4)
  /// The current Rotation's Rule icon height, as a share of the panel's width.
  static let ruleIconHeight: CellShare = .battleRuleSectionHeight
  /// A later Rotation's Rule column, as a share of the panel's width.
  static let secondaryRuleColumnWidth: CellShare = .init(0.2)
  /// A Shift's weapons, two by two, as a share of the panel's width.
  static let weaponsWidth: CellShare = .init(0.34)
  /// A Shift's King Salmonid icon.
  static let kingSalmonidIconSize: CGFloat = 26

  // MARK: Events

  /// An event card's Mode icon, square, before Dynamic Type.
  static let eventIconSize: CGFloat = 28
  /// A Challenge's Rule icon, square, before Dynamic Type.
  static let challengeRuleIconSize: CGFloat = 26
  /// The swatch of a Splatfest team's colour before its name, at the default text size.
  static let teamSwatchSize: CGSize = .init(width: 22, height: 12)
  /// The opacity of a Challenge window that has ended.
  static let endedWindowOpacity: Double = 0.45

  // MARK: Progress

  /// The progress bar's height.
  static let progressBarHeight: CGFloat = 7
  /// How far the progress bar leans: the horizontal run per point of height (20 degrees).
  static let progressBarSlant: CGFloat = tan(20 * .pi / 180)
}
