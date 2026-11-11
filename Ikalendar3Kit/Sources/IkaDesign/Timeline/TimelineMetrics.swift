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
  /// A pin's width side by side: the space left of the content, less a margin on each side.
  static let pinWidth: CGFloat = contentLeading - pinLeading * 2
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
  /// The Mode stamp's side in the navigation bar.
  static let barStampSize: CGFloat = 26
  /// The navigation bar badge's side, as in ikalendar 2.
  static let badgeSize: CGFloat = 44
  /// The Mode icon's side inside the badge.
  static let badgeImageSize: CGFloat = 28
  /// The Series and Open strip's height.
  static let stripHeight: CGFloat = 40
  /// The thickness of the line under the shown form.
  static let stripUnderline: CGFloat = 3
  /// The line height of text that wraps: SplatNet 3's faces carry a tall line gap of their own,
  /// which leaves wrapped lines standing apart.
  static let wrappedLineHeight: AttributedString.LineHeight = .multiple(factor: 1.2)
  /// The space inside a card's edge.
  static let cardPadding: CGFloat = 12
  /// The space above and below a status panel's text.
  static let statusPadding: CGFloat = 18
  /// The distance between two stripes of a status panel's hatching.
  static let hatchPitch: CGFloat = 14
  /// A Splatfest team's colour swatch.
  static let teamSwatchSize: CGFloat = 14
  /// The band of team colours a Splatfest card shows while its art is not downloaded.
  static let teamBandHeight: CGFloat = 8
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
  /// The stripes over a status panel.
  static let hatch: Color = .white.opacity(0.05)
  /// The text of a Challenge window that has ended.
  static let pastText: Color = .init(SRGBColor(hex: 0x8D949C))
  /// The axis track's opacity before and after the current item's progress.
  static let trackOpacity: Double = 0.35
}

// MARK: - TimelineTint

/// The colour of a stretch of the axis, its pin while its item runs, and its "Now": the item's
/// Mode colour, or neutral where none stands for it. Splatfest Battle and Tricolor Turf War have
/// no Mode colour, and no one team's colour stands for them.
struct TimelineTint: Hashable {
  /// The colour at full strength.
  let base: SRGBColor

  /// A Mode's or an event's colour.
  init(_ color: ModeColor) {
    base = color.base
  }

  private init(base: SRGBColor) {
    self.base = base
  }

  /// White, for what no Mode colour stands for.
  static let neutral: Self = .init(base: .white)

  /// The colour as a fill, such as a pin, with black or white text on it.
  var asFill: ColorPair {
    ColorPair(foreground: base.labelColor, background: base)
  }

  /// The colour as text on Timeline's panel in `colorScheme`: the base colour, or its nearest
  /// tint that reads there.
  func onPanel(in colorScheme: ColorScheme) -> ColorPair {
    let panel: SRGBColor = Style.timeline.panel(in: colorScheme)
    return ColorPair(foreground: base.readableTint(on: panel, for: .text), background: panel)
  }
}
#endif
