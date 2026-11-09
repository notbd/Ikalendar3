//
//  InkOverviewCard.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(macOS)
import IkaCore
import SwiftUI

// MARK: - InkOverviewCard

/// Ink's Mac Overview card on its rough-edged dark panel: the Mode's icon in a ring of its accent,
/// the name in the heavy face and the summary in the light face. It receives a sidebar row's
/// content only and reads no store.
public struct InkOverviewCard: View {
  @Environment(\.colorScheme) private var colorScheme

  private let content: SidebarRowContent

  public init(content: SidebarRowContent) {
    self.content = content
  }

  public var body: some View {
    let accent: InkAccent = content.color.map(InkAccent.init) ?? .splatfest

    OverviewCardFrame(content: content, ringColor: Color(accent.base)) { name in
      Text(verbatim: name)
        .inkFont(.tag)
    } summary: { summary in
      Text(verbatim: summary)
        .inkFont(.body)
        .foregroundStyle(Color(InkPair.panelSecondaryText.colors(in: colorScheme).foreground))
    }
    .inkPanel()
  }
}
#endif
