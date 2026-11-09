//
//  TimelineOverviewCard.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(macOS)
import IkaCore
import SwiftUI

// MARK: - TimelineOverviewCard

/// Timeline's Mac Overview card on its panel, in the dark appearance Timeline draws in: the Mode's
/// icon in a ring of its colour, the name in the heavy face and the summary in the light face. It
/// receives a sidebar row's content only and reads no store.
public struct TimelineOverviewCard: View {
  private let content: SidebarRowContent

  public init(content: SidebarRowContent) {
    self.content = content
  }

  public var body: some View {
    let tint: TimelineTint = content.color.map(TimelineTint.init) ?? .neutral

    TimelineCardPanel {
      OverviewCardFrame(content: content, ringColor: Color(tint.base)) { name in
        Text(verbatim: name)
          .ikaFont(.heavy, size: 18, relativeTo: .headline)
          .foregroundStyle(.white)
      } summary: { summary in
        Text(verbatim: summary)
          .ikaFont(.light, size: 14, relativeTo: .subheadline)
          .foregroundStyle(TimelinePalette.secondaryText)
      }
    }
    .environment(\.colorScheme, .dark)
  }
}
#endif
