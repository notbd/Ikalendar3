//
//  ClassicMetrics.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import CoreGraphics
import SwiftUI

// MARK: - ClassicMetrics

/// Classic's fixed sizes, as ikalendar 2's style constants set them at `9a99cf3`. Sizes that grow
/// with the cell are `CellShare`s; font sizes scale with Dynamic Type relative to their text style.
enum ClassicMetrics {
  /// The shadow under pictures and icons.
  static let shadowRadius: CGFloat = 2
  /// The line height of a text that wraps, as a multiple of its font size. SplatNet 3's faces set a
  /// line box twice their size, made for their Han glyphs, which leaves wrapped Latin lines about
  /// a line apart.
  static let wrappedLineHeightFactor: CGFloat = 1.2
  /// The largest text size a title in the heavy face grows to, a Challenge's or a Splatfest's: its
  /// longest words then still fit a 390-point iPhone's cell.
  static let displayTitleLargestSize: DynamicTypeSize = .accessibility1
  /// Secondary text in light appearance (`ClassicSecondaryStyle`): 4.5:1 on Classic's white cells
  /// and on the grouped ground around them.
  static let secondaryTextLight: SRGBColor = .init(hex: 0x6C6C70)
  /// What the game's icons sit on in light appearance (`ClassicIconGround`): white reaches 3:1 on
  /// it with room to spare, so the lightest icons keep their edges.
  static let iconGroundLight: SRGBColor = .init(hex: 0x3A3A3C)

  /// A Stage name on its glass label.
  enum StageLabel {
    static let paddingH: CGFloat = 6
    static let paddingV: CGFloat = 3
    static let cornerRadius: CGFloat = 8
  }

  /// A row's header: its tag and its time range.
  enum Header {
    static let spacing: CGFloat = 16
    static let tagCornerRadius: CGFloat = 8
    static let tagFontSize: CGFloat = 16
    static let tagPaddingH: CGFloat = 8
    /// The white rim of a tag, where ikalendar 2's glass caught the light.
    static let tagRimOpacity: Double = 0.25
    static let contentFontSize: CGFloat = 16
    /// Between a progress bar and its time left above it.
    static let progressSpacing: CGFloat = 4
  }

  /// The current Rotation's featured cell.
  enum BattlePrimary {
    static let cellSpacingV: CGFloat = 8
    static let stagesSpacingH: CGFloat = 10
    static let progressBarPaddingBottom: CGFloat = 8
    static let cellPaddingBottom: CGFloat = 6
    static let ruleSectionSpacing: CGFloat = 8
    static let ruleTitleFontSize: CGFloat = 48
    /// The Rule name's size when the cell stacks.
    static let ruleTitleStackedFontSize: CGFloat = 22
    static let ruleTitlePaddingV: CGFloat = 4
    static let remainingTimeFontSize: CGFloat = 15
    static let stageCornerRadius: CGFloat = 12
    static let stageLabelFontSize: CGFloat = 13
    static let stageLabelPaddingLeading: CGFloat = 20
    static let stageLabelPaddingBottomTrailing: CGFloat = 2.5
  }

  /// A later Rotation's cell.
  enum BattleSecondary {
    static let ruleSectionSpacing: CGFloat = 2
    static let ruleImagePadding: CGFloat = 5
    static let ruleImageCornerRadius: CGFloat = 12
    static let ruleFontSize: CGFloat = 18
    static let ruleTitleHeight: CGFloat = 24
    static let ruleSectionPaddingTrailing: CGFloat = 10
    static let stageSpacingV: CGFloat = 4
    static let stageCornerRadius: CGFloat = 12
    static let stageFontSize: CGFloat = 12
  }

  /// The featured place's text when no Rotation or Shift is on.
  enum Status {
    static let fontSize: CGFloat = 26
    static let paddingV: CGFloat = 8
  }

  /// A Shift's cell.
  enum Shift {
    static let cellSpacing: CGFloat = 10
    static let cellPaddingV: CGFloat = 6
    static let progressFontSize: CGFloat = 16
    static let currentIconScale: CGFloat = 1.1
    static let iconScale: CGFloat = 0.9
    static let timeTextSpacing: CGFloat = 4
    static let timeTextFontSize: CGFloat = 16
    static let timeTextPaddingH: CGFloat = 6
    static let timeTextPaddingV: CGFloat = 4
    static let timeTextCornerRadius: CGFloat = 6
    static let stageCornerRadius: CGFloat = 12
    static let stageLabelFontSize: CGFloat = 13
    static let overlayPadding: CGFloat = 4
    static let kingSalmonidPadding: CGFloat = 4
    /// The King Salmonid's width as a share of the Stage card's, where ikalendar 2 showed the
    /// reward gear.
    static let kingSalmonidWidthRatio: CGFloat = 0.16
    static let kingSalmonidCornerRadius: CGFloat = 7
    static let weaponPadding: CGFloat = 3
    static let weaponCornerRadius: CGFloat = 12
  }

  /// A Challenge's cell and its windows' rows.
  enum Challenge {
    static let cellSpacingV: CGFloat = 8
    static let cellPaddingV: CGFloat = 6
    static let nameFontSize: CGFloat = 28
    static let descriptionFontSize: CGFloat = 16
    static let rulesTextFontSize: CGFloat = 13
    static let windowSpacingV: CGFloat = 6
  }

  /// The Splatfest card and Tricolor Turf War's cell.
  enum Splatfest {
    static let cellSpacingV: CGFloat = 10
    static let cellPaddingV: CGFloat = 6
    static let artCornerRadius: CGFloat = 12
    static let iconSize: CGFloat = 32
    static let titleFontSize: CGFloat = 24
    static let teamSpacingV: CGFloat = 6
    /// Between teams side by side.
    static let teamSpacingH: CGFloat = 16
    static let teamSwatchSize: CGFloat = 16
    static let teamFontSize: CGFloat = 18
    static let timeFontSize: CGFloat = 15
  }

  /// A compact event card of the iPad event strip and the event sheets.
  enum EventCard {
    static let spacing: CGFloat = 8
    static let padding: CGFloat = 12
    static let cornerRadius: CGFloat = 16
    static let iconSize: CGFloat = 28
    static let titleFontSize: CGFloat = 20
    static let detailFontSize: CGFloat = 15
    static let ruleIconSize: CGFloat = 24
  }

  /// The Mode stamp and the navigation bar badge it docks into.
  enum Stamp {
    static let size: CGFloat = 128
    static let offsetX: CGFloat = -10
    /// From the top of the list, under the inline navigation bar: the stamp's top sits 6 points
    /// over the top of the bar's 44-point row, which holds nothing at its trailing end at rest
    /// since Settings moved to the leading end. ikalendar 2's stamp sat 12 points lower, beside
    /// its Settings button; raised, it needs less room under the heading (`Heading.minimumHeight`).
    static let offsetY: CGFloat = -50
    /// The stamp's resting 2D tilt.
    static let rotationDegrees: Double = 8
    static let badgeSize: CGFloat = 44
    static let badgeImageSize: CGFloat = 27
  }

  /// The screen's name over the list, where ikalendar 2 showed the navigation bar's large title.
  enum Heading {
    /// What the heading leaves free at its trailing end for the stamp: the stamp's width and
    /// inset plus a gap, less the list's own inset of its section headers.
    static let stampClearance: CGFloat = 122
    /// The smallest share a long name shrinks to, so it stays a title.
    static let minimumScaleFactor: CGFloat = 0.6
    /// Between the heading and the first row's header.
    static let sectionSpacing: CGFloat = 8
    /// The heading's least height, so the first row starts under the stamp's visible part at any
    /// width, a narrow iPad column's too, where the row cannot pass beside it: the stamp ends 5%
    /// opaque at 90% of its height, which its tilt lowers to 85 points under the list's top at its
    /// trailing corner, less the 12 points it is raised by; the first row's header starts 22
    /// points under the heading's end.
    static let minimumHeight: CGFloat = 52
  }
}
#endif
