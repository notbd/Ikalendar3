//
//  SummaryRing.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - SummaryRing

/// A summary row's mark: the icon inside a progress ring of the share its current item has run,
/// an empty ring while none is on. The sidebar, the Series and Open menu, the Mac menu bar window
/// and Overview cards and the watch's Now rows draw it inside the frame they offer. The row reads its sentence, so
/// VoiceOver skips the mark.
public struct SummaryRing: View {
  private let icon: ModeIcon
  private let share: Double
  private let color: Color
  private let lineWidth: CGFloat
  private let iconInset: CGFloat

  /// `icon` in a ring with `share` of it drawn in `color`, its stroke `lineWidth` wide, the icon
  /// `iconInset` inside the ring's outer edge.
  public init(icon: ModeIcon, share: Double, color: Color, lineWidth: CGFloat, iconInset: CGFloat) {
    self.icon = icon
    self.share = share
    self.color = color
    self.lineWidth = lineWidth
    self.iconInset = iconInset
  }

  /// `content`'s icon in a ring of its progress, drawn in `color`.
  public init(_ content: SummaryRowContent, color: Color, lineWidth: CGFloat, iconInset: CGFloat) {
    self.init(
      icon: content.icon,
      share: content.progress?.sharePassed ?? 0,
      color: color,
      lineWidth: lineWidth,
      iconInset: iconInset)
  }

  public var body: some View {
    ZStack {
      ProgressRing(share: share, color: color, lineWidth: lineWidth)
      Image(decorative: BundledImage.name(for: icon, size: .small), bundle: BundledImage.catalogBundle)
        .resizable()
        .scaledToFit()
        .padding(iconInset)
    }
    .accessibilityHidden(true)
  }
}
