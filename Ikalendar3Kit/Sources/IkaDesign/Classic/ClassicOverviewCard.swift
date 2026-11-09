//
//  ClassicOverviewCard.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(macOS)
import IkaCore
import SwiftUI

// MARK: - ClassicOverviewCard

/// Classic's Mac Overview card on a list cell's colour, as its event cards sit: the Mode's icon in
/// a ring of its colour, the name in the heavy face and the summary in the light face. It receives
/// a sidebar row's content only and reads no store.
public struct ClassicOverviewCard: View {
  @Environment(\.colorScheme) private var colorScheme

  private let content: SidebarRowContent

  public init(content: SidebarRowContent) {
    self.content = content
  }

  public var body: some View {
    OverviewCardFrame(content: content, ringColor: ringColor) { name in
      Text(verbatim: name)
        .ikaFont(.heavy, size: 20, relativeTo: .title3)
    } summary: { summary in
      Text(verbatim: summary)
        .ikaFont(.light, size: 15, relativeTo: .subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(OverviewCardMetrics.padding)
    .background(ClassicEventCard.background, in: .rect(cornerRadius: ClassicMetrics.EventCard.cornerRadius))
  }

  /// The Mode colour, tinted where it would not read on the card; the primary colour for the
  /// Splatfest's rows.
  private var ringColor: Color {
    guard let color = content.color else { return .primary }

    return Color(color.onPanel(of: .classic, in: colorScheme, for: .largeTextAndIcons).foreground)
  }
}
#endif
