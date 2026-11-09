//
//  SidebarRowFrame.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import SwiftUI

// MARK: - SidebarRowFrame

/// The layout every Style's sidebar row shares: the Mode's icon in a ring of the share passed,
/// beside its name over the summary line, or above them from the first accessibility text size.
/// A Style passes its own fonts and colours. The row is one VoiceOver element, and fades while
/// the Splatfest keeps its Mode from play.
struct SidebarRowFrame<Name: View, Summary: View>: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  @ScaledMetric(relativeTo: .headline) private var ringSize: CGFloat = SidebarMetrics.ringSize

  let content: SidebarRowContent
  /// The ring's colour.
  let ringColor: Color
  /// The name, in the Style's font.
  @ViewBuilder let name: (String) -> Name
  /// The summary line, in the Style's font.
  @ViewBuilder let summary: (String) -> Summary

  var body: some View {
    let layout: AnyLayout =
      switch CellArrangement(dynamicTypeSize) {
        case .sideBySide: .init(HStackLayout(spacing: SidebarMetrics.spacing))
        case .stacked: .init(VStackLayout(alignment: .leading, spacing: SidebarMetrics.spacing / 2))
      }

    layout {
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

      VStack(alignment: .leading, spacing: SidebarMetrics.textSpacing) {
        name(content.name)
        summary(content.summary)
      }
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.vertical, SidebarMetrics.verticalPadding)
    .opacity(content.isDimmed ? SidebarMetrics.dimmedOpacity : 1)
    .contentShape(.rect)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(verbatim: content.accessibilityLabel))
    .accessibilityValue(Text(verbatim: content.accessibilityValue ?? ""))
  }
}

// MARK: - SidebarMetrics

/// The sidebar row's sizes, which every Style shares. Ticket 58 judges them.
enum SidebarMetrics {
  /// The ring's side at the default text size; it scales with the headline.
  static let ringSize: CGFloat = 40
  /// The ring's stroke, as a share of its side.
  static let lineWidthShare: CGFloat = 0.08
  /// The space between the ring and the icon inside it, as a share of the ring's side.
  static let iconInsetShare: CGFloat = 0.2
  /// The space between the ring and the texts.
  static let spacing: CGFloat = 12
  /// The space between the name and the summary line.
  static let textSpacing: CGFloat = 2
  /// The space above and below a row's content.
  static let verticalPadding: CGFloat = 4
  /// A dimmed row's opacity.
  static let dimmedOpacity: Double = 0.4
}
#endif
