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

  /// The space before the Mode name, which lines it up with a panel's content.
  static let headingLeadingPadding: CGFloat = 4
  /// The space between the Mode name and its form tag.
  static let headingSpacing: CGFloat = 8
  /// The splat behind the stamp, square.
  static let splatSize: CGFloat = 156
  /// The Mode icon on the splat, square.
  static let stampIconSize: CGFloat = 68
  /// The black outline around the stamp's icon.
  static let stampOutlineWidth: CGFloat = 2
  /// The stamp's turn at rest.
  static let stampAngle: Angle = .degrees(-10)
  /// How far the splat's shadow falls from it.
  static let splatShadowOffset: CGSize = .init(width: 3, height: 5)
  /// How far the splat runs off the screen's trailing edge: far enough to read as cut on
  /// purpose.
  static let stampBleed: CGFloat = 22
  /// How far the first panel covers the splat's lower edge.
  static let splatPanelOverlap: CGFloat = 30
  /// The width beside the Mode name the stamp takes: the splat's part on the screen and a gap.
  static let stampReserve: CGFloat = splatSize - stampBleed - screenPadding + 6
  /// The heading's least height beside the stamp: the splat's part above the first panel.
  static let headingMinHeight: CGFloat = splatSize - splatPanelOverlap - panelSpacing
  /// The stamp's scale over the Mode name, from the first accessibility text size.
  static let stackedStampScale: CGFloat = 0.72
  /// The navigation bar badge the stamp docks into, round.
  static let badgeSize: CGFloat = 44
  /// The Mode icon in the badge.
  static let badgeIconSize: CGFloat = 28

  // MARK: Note

  /// The space above and below a note's sentence, inside its panel.
  static let notePadding: CGFloat = 8
  /// The distance between a note's hatch stripes.
  static let noteHatchPitch: CGFloat = 18

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

  /// A running text's line height as a multiple of its size. The light face's own line box is
  /// nearly twice its size, which spreads a paragraph apart.
  static let runningTextLineHeight: CGFloat = 1.3

  /// An event card's Mode icon, square, before Dynamic Type.
  static let eventIconSize: CGFloat = 28
  /// A Challenge's Rule icon, square, before Dynamic Type.
  static let challengeRuleIconSize: CGFloat = 26
  /// The space between two of a Challenge's window rows.
  static let windowRowSpacing: CGFloat = 7
  /// The opacity of a Challenge window that has ended.
  static let endedWindowOpacity: Double = 0.45

  // MARK: Progress

  /// The progress bar's height.
  static let progressBarHeight: CGFloat = 7
  /// How far the progress bar leans: the horizontal run per point of height (20 degrees).
  static let progressBarSlant: CGFloat = tan(20 * .pi / 180)
}
