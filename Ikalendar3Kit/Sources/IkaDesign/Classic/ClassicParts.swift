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

/// ikalendar 2's grey glass tag that leads a row's header: "Now:", "Next:", "Open!", "Soon:", or
/// an event's name where it has no Mode colour, such as Tricolor Turf War.
struct ClassicTag: View {
  @Environment(\.colorScheme) private var colorScheme

  let text: String

  var body: some View {
    Text(verbatim: text)
      .ikaFont(.heavy, size: ClassicMetrics.Header.tagFontSize, relativeTo: .title2)
      // The system background's colour: white on light, black on dark.
      .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
      .padding(.horizontal, ClassicMetrics.Header.tagPaddingH)
      .adaptiveGlassEffect(tint: .gray, in: .rect(cornerRadius: ClassicMetrics.Header.tagCornerRadius))
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
      .scaledLimitedLine(for: arrangement)
      .ikaFont(.light, size: fontSize, relativeTo: .body)
      .padding(.horizontal, ClassicMetrics.StageLabel.paddingH)
      .padding(.vertical, ClassicMetrics.StageLabel.paddingV)
      .glassEffect(.regular.interactive(), in: .rect(cornerRadius: ClassicMetrics.StageLabel.cornerRadius))
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
      .scaledLimitedLine(for: arrangement)
      .ikaFont(.light, size: ClassicMetrics.Header.contentFontSize, relativeTo: .headline)
      .foregroundStyle(.secondary)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, ClassicMetrics.Shift.cellPaddingV)
  }
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
