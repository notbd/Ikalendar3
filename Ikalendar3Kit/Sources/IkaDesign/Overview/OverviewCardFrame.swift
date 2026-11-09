//
//  OverviewCardFrame.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(macOS)
import SwiftUI

// MARK: - OverviewCardFrame

/// The layout every Style's Mac Overview card shares: a Mode's summary as its sidebar row shows
/// it, with the icon in a larger ring over the name and the summary line, filling the card's
/// width. A Style passes its own fonts and colours and sets the frame on its panel. The card is
/// one VoiceOver element, and its content fades while the Splatfest keeps its Mode from play.
struct OverviewCardFrame<Name: View, Summary: View>: View {
  @ScaledMetric(relativeTo: .title) private var ringSize: CGFloat = OverviewCardMetrics.ringSize

  let content: SidebarRowContent
  /// The ring's colour.
  let ringColor: Color
  /// The name, in the Style's font.
  @ViewBuilder let name: (String) -> Name
  /// The summary line, in the Style's font.
  @ViewBuilder let summary: (String) -> Summary

  var body: some View {
    VStack(alignment: .leading, spacing: OverviewCardMetrics.spacing) {
      ZStack {
        ProgressRing(
          share: content.progress?.sharePassed ?? 0,
          color: ringColor,
          lineWidth: ringSize * SidebarMetrics.lineWidthShare,
          timeLeft: nil)
        Image(decorative: BundledImage.name(for: content.icon, size: .small), bundle: BundledImage.catalogBundle)
          .resizable()
          .scaledToFit()
          .padding(ringSize * SidebarMetrics.iconInsetShare)
      }
      .frame(width: ringSize, height: ringSize)

      VStack(alignment: .leading, spacing: OverviewCardMetrics.textSpacing) {
        name(content.name)
        summary(content.summary)
          // Two lines on every card, so the cards in a row are as tall as each other.
          .lineLimit(2, reservesSpace: true)
      }
      .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .opacity(content.isDimmed ? SidebarMetrics.dimmedOpacity : 1)
    .contentShape(.rect)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(verbatim: content.accessibilityLabel))
    .accessibilityValue(Text(verbatim: content.accessibilityValue ?? ""))
  }
}

// MARK: - OverviewCardMetrics

/// The Overview card's sizes, which every Style shares; the ring's stroke and icon inset and the
/// dimmed opacity are the sidebar row's (`SidebarMetrics`). Ticket 58 judges them.
enum OverviewCardMetrics {
  /// The ring's side at the default text size; it scales with the title.
  static let ringSize: CGFloat = 64
  /// The space between the ring and the texts.
  static let spacing: CGFloat = 14
  /// The space between the name and the summary line.
  static let textSpacing: CGFloat = 4
  /// The space inside a card whose Style sets no padding of its own.
  static let padding: CGFloat = 16
}
#endif
