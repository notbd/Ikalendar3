//
//  TimelineHeader.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - TimelineHeader

/// SplatNet 3's black header: the Mode stamp and the Mode's name, centred. Its black runs on up
/// behind the navigation bar and the pull-to-refresh space, so the top reads as one header.
struct TimelineHeader: View {
  let icon: ModeIcon
  let name: String
  /// How far the stamp has docked into the navigation bar badge.
  let dockProgress: Double
  let arrangement: CellArrangement

  var body: some View {
    HStack(spacing: 9) {
      TimelineModeStamp(icon: icon, dockProgress: dockProgress)
      Text(verbatim: name)
        .ikaFont(.heavy, size: 19, relativeTo: .title3)
        .scaledLimitedLine(for: arrangement)
        .foregroundStyle(.white)
        .accessibilityAddTraits(.isHeader)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity, minHeight: TimelineMetrics.headerHeight)
    .background(alignment: .bottom) {
      TimelinePalette.header
        .frame(height: Self.backdropHeight)
    }
  }

  /// How far the header's black reaches up past its top edge: beyond any navigation bar and
  /// pull-to-refresh space.
  static private let backdropHeight: CGFloat = 1000
}

// MARK: - TimelineModeStamp

/// A placeholder Mode stamp: the Mode's icon, until ticket 52 draws Timeline's form. As the list
/// scrolls it shrinks toward its top trailing corner and fades with ticket 12's stamp math; under
/// Reduce Motion it only fades.
private struct TimelineModeStamp: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let icon: ModeIcon
  let dockProgress: Double

  var body: some View {
    let style: ModeStampMath.DockStyle = ModeStampMath.dockStyle(progress: dockProgress, reduceMotion: reduceMotion)

    Image(decorative: BundledImage.name(for: icon, size: .large), bundle: BundledImage.catalogBundle)
      .resizable()
      .scaledToFit()
      .frame(width: TimelineMetrics.stampSize, height: TimelineMetrics.stampSize)
      .scaleEffect(style.scale, anchor: .topTrailing)
      .opacity(style.opacity)
  }
}

// MARK: - TimelineModeBadge

/// The 44 pt glass badge at the navigation bar's trailing end that the stamp docks into, as in
/// ikalendar 2. Decoration only: it takes no touches, and the title names the Mode.
struct TimelineModeBadge: View {
  let icon: ModeIcon

  var body: some View {
    Image(decorative: BundledImage.name(for: icon, size: .medium), bundle: BundledImage.catalogBundle)
      .resizable()
      .scaledToFit()
      .frame(width: TimelineMetrics.badgeImageSize, height: TimelineMetrics.badgeImageSize)
      .frame(width: TimelineMetrics.badgeSize, height: TimelineMetrics.badgeSize)
      .adaptiveGlassEffect(isInteractive: false, in: .circle)
  }
}

// MARK: - TimelineFormStrip

/// The Series and Open strip under Anarchy's header, the form shown underlined in the Mode
/// colour. It shows which form the screen holds; ticket 24's tab menu switches it.
struct TimelineFormStrip: View {
  /// The Anarchy form the screen shows.
  let shown: BattleMode
  let language: GameLanguage

  var body: some View {
    HStack(spacing: 28) {
      form(.anarchySeries, label: .series)
      form(.anarchyOpen, label: .open)
    }
    .frame(maxWidth: .infinity, minHeight: TimelineMetrics.stripHeight)
    .background(TimelinePalette.strip)
  }

  private func form(_ mode: BattleMode, label: ModeLabel) -> some View {
    let isShown: Bool = mode == shown

    return Text(verbatim: label.text(in: language))
      .ikaFont(.heavy, size: 14, relativeTo: .subheadline)
      .foregroundStyle(isShown ? .white : TimelinePalette.stripIdle)
      .padding(.vertical, 9)
      .overlay(alignment: .bottom) {
        if isShown {
          Rectangle()
            .fill(Color(ModeColor(mode).base))
            .frame(height: TimelineMetrics.stripUnderline)
        }
      }
      .accessibilityAddTraits(isShown ? .isSelected : [])
  }
}
#endif
