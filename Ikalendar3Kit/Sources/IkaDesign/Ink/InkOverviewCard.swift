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
/// the name in the heavy face and the line in the light face. It receives a summary row's content
/// only and reads no store.
public struct InkOverviewCard: View {
  @Environment(\.colorScheme) private var colorScheme

  private let content: SummaryRowContent

  public init(content: SummaryRowContent) {
    self.content = content
  }

  public var body: some View {
    let accent: InkAccent = .init(content.color)

    OverviewCardFrame(content: content, ringColor: Color(accent.base)) { name in
      Text(verbatim: name)
        .inkFont(.tag)
    } line: { line in
      Text(verbatim: line)
        .inkFont(.body)
        .foregroundStyle(Color(InkPair.panelSecondaryText.colors(in: colorScheme).foreground))
    }
    .inkPanel()
  }
}
#endif
