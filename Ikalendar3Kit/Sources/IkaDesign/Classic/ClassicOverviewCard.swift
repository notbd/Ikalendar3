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
/// a ring of its colour, the name in the heavy face and the line in the light face. It receives a
/// summary row's content only and reads no store.
public struct ClassicOverviewCard: View {
  @Environment(\.colorScheme) private var colorScheme

  private let content: SummaryRowContent

  public init(content: SummaryRowContent) {
    self.content = content
  }

  public var body: some View {
    OverviewCardFrame(content: content, ringColor: content.classicRingColor(in: colorScheme)) { name in
      Text(verbatim: name)
        .ikaFont(.heavy, size: 20, relativeTo: .title3)
    } line: { line in
      Text(verbatim: line)
        .ikaFont(.light, size: 15, relativeTo: .subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(OverviewCardMetrics.padding)
    .background(ClassicEventCard.background, in: .rect(cornerRadius: ClassicMetrics.EventCard.cornerRadius))
  }
}
#endif
