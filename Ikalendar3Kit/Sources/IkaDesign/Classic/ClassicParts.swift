//
//  ClassicParts.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - ClassicTag

/// ikalendar 2's grey tag that leads a row's header: "Now:", "Next:", "Open!", "Soon:", or an
/// event's name where it has no Mode colour, such as Tricolor Turf War.
///
/// ikalendar 2 drew it as clear glass tinted grey, which rendered a light grey under its dark
/// text. The same glass renders a dark grey on later systems, where the dark text reads as
/// disabled, so the tag fills that light grey itself (`ColorPair.classicTag(in:)`) and keeps the
/// glass's light rim.
struct ClassicTag: View {
  @Environment(\.colorScheme) private var colorScheme

  let text: String

  var body: some View {
    let pair: ColorPair = .classicTag(in: colorScheme)
    let shape: RoundedRectangle = .rect(cornerRadius: ClassicMetrics.Header.tagCornerRadius)

    Text(verbatim: text)
      .ikaFont(.heavy, size: ClassicMetrics.Header.tagFontSize, relativeTo: .title2)
      .foregroundStyle(Color(pair.foreground))
      .padding(.horizontal, ClassicMetrics.Header.tagPaddingH)
      .background(Color(pair.background), in: shape)
      .overlay(shape.strokeBorder(.white.opacity(ClassicMetrics.Header.tagRimOpacity), lineWidth: 1))
  }
}

// MARK: - ClassicKindTag

/// The tag that marks a kind by its name on its Mode colour, as ticket 11's fill pair draws it: a
/// Big Run or an Eggstra Work among the Shifts, Regular Battle after a Splatfest, an event card.
struct ClassicKindTag: View {
  let text: String
  let color: ModeColor

  var body: some View {
    let pair: ColorPair = color.asFill

    Text(verbatim: text)
      .ikaFont(.heavy, size: ClassicMetrics.Header.tagFontSize, relativeTo: .title2)
      .foregroundStyle(Color(pair.foreground))
      .padding(.horizontal, ClassicMetrics.Header.tagPaddingH)
      .background(Color(pair.background), in: .rect(cornerRadius: ClassicMetrics.Header.tagCornerRadius))
  }
}

// MARK: - ClassicStageLabel

/// A Stage's name on ikalendar 2's glass label, laid over the Stage's picture.
struct ClassicStageLabel: View {
  let name: String
  let fontSize: CGFloat
  let arrangement: CellArrangement

  var body: some View {
    Text(verbatim: name)
      .classicLines(for: arrangement)
      .ikaFont(.light, size: fontSize, relativeTo: .body)
      .padding(.horizontal, ClassicMetrics.StageLabel.paddingH)
      .padding(.vertical, ClassicMetrics.StageLabel.paddingV)
      .glassEffect(.regular.interactive(), in: .rect(cornerRadius: ClassicMetrics.StageLabel.cornerRadius))
  }
}

// MARK: - ClassicIconGround

/// What one of the game's icons sits on, a Rule's or a weapon's: ikalendar 2's adaptive glass in
/// dark appearance, and a solid dark grey in light. The game draws its icons for its dark grounds,
/// and some, such as Turf War's white and lime or the silver weapons, all but vanish on light
/// glass.
///
/// An icon that stands on the panel itself in ikalendar 2, as the featured Rule's does, keeps
/// doing so in dark appearance and gets the grey, `padding` wider than the icon, in light only.
private struct ClassicIconGround<GroundShape: Shape>: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme

  let shape: GroundShape
  /// Whether dark appearance draws the glass, as under an icon on a tile.
  let isTiledInDark: Bool
  /// How far the light ground reaches past an icon that stands on the panel in dark appearance.
  let padding: CGFloat

  func body(content: Content) -> some View {
    switch (colorScheme, isTiledInDark) {
      case (.dark, true):
        content.adaptiveGlassEffect(in: shape)
      case (.dark, false):
        content
      case (_, true):
        content.background(Color(ClassicMetrics.iconGroundLight), in: shape)
      case (_, false):
        content
          .padding(padding)
          .background(Color(ClassicMetrics.iconGroundLight), in: shape)
    }
  }
}

extension View {
  /// Sets one of the game's icons on a tile of Classic's ground for it in `shape`
  /// (`ClassicIconGround`).
  func classicIconGround(in shape: some Shape) -> some View {
    modifier(ClassicIconGround(shape: shape, isTiledInDark: true, padding: 0))
  }

  /// Sets one of the game's icons that stands on the panel in dark appearance on Classic's ground
  /// for it in light, `padding` wider than the icon (`ClassicIconGround`).
  func classicIconGroundInLight(padding: CGFloat, in shape: some Shape) -> some View {
    modifier(ClassicIconGround(shape: shape, isTiledInDark: false, padding: padding))
  }
}

// MARK: - View

extension View {
  /// Fits a text the way `arrangement` asks (`scaledLimitedLine(for:)`): shrunk onto one line side
  /// by side; wrapped at full size when stacked, with its lines at Classic's line height and all
  /// of them shown, however little height its stack offers.
  func classicLines(for arrangement: CellArrangement) -> some View {
    scaledLimitedLine(for: arrangement)
      .lineHeight(arrangement == .stacked ? .multiple(factor: ClassicMetrics.wrappedLineHeightFactor) : nil)
      .fixedSize(horizontal: false, vertical: arrangement == .stacked)
  }
}

// MARK: - ClassicPicture

/// A bundled picture, fitted to the space it is offered as ikalendar 2's `ikaFitted()` does.
/// Decorative: the cell's sentence names what it shows.
struct ClassicPicture: View {
  let name: String

  var body: some View {
    Image(decorative: name, bundle: BundledImage.catalogBundle)
      .antialiased(true)
      .resizable()
      .scaledToFit()
  }
}

// MARK: - ClassicStatusCell

/// The featured place when no Rotation or Shift is on: why, in the cell's own words.
struct ClassicStatusCell: View {
  let text: String
  let arrangement: CellArrangement

  var body: some View {
    Text(verbatim: text)
      .classicLines(for: arrangement)
      .ikaFont(.light, size: ClassicMetrics.Header.contentFontSize, relativeTo: .headline)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, ClassicMetrics.Shift.cellPaddingV)
  }
}

// MARK: - ColorPair

extension ColorPair {
  /// `ClassicTag`'s text on its fill in `colorScheme`: ikalendar 2's tag as it rendered, dark
  /// text on a light grey in dark appearance and light text on a darker grey in light. Each
  /// reaches 4.5:1.
  static func classicTag(in colorScheme: ColorScheme) -> ColorPair {
    switch colorScheme {
      case .dark: ColorPair(foreground: .black, background: SRGBColor(hex: 0x93939A))
      default: ColorPair(foreground: .white, background: SRGBColor(hex: 0x6C6C70))
    }
  }
}

// MARK: - ClassicSecondaryStyle

/// A Classic screen's secondary text, such as a row's time range or a countdown: the system's
/// secondary colour in dark appearance, as ikalendar 2 drew it, and a darker grey in light, where
/// the system's reaches only about 3.4:1 on Classic's cells and ground, short of the 4.5:1 text
/// needs.
struct ClassicSecondaryStyle: ShapeStyle {
  func resolve(in environment: EnvironmentValues) -> Color {
    environment.colorScheme == .dark ? .secondary : Color(ClassicMetrics.secondaryTextLight)
  }
}

extension ShapeStyle where Self == ClassicSecondaryStyle {
  /// A Classic screen's secondary text (`ClassicSecondaryStyle`).
  static var classicSecondary: ClassicSecondaryStyle { .init() }
}

// MARK: - ModeColor

extension ModeColor {
  /// The colour as a progress bar's tint on Classic's panel in `colorScheme`: a graphic, so it
  /// needs the 3:1 of icons.
  func classicTint(in colorScheme: ColorScheme) -> Color {
    Color(onPanel(of: .classic, in: colorScheme, for: .largeTextAndIcons).foreground)
  }
}
#endif
