//
//  TimelineSidebar.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - TimelineSidebarRow

/// Timeline's sidebar row on SplatNet 3's page colour: the Mode's icon in a ring of its colour,
/// the name in the heavy face and the line in the light face. It receives a summary row's
/// content only and reads no store.
public struct TimelineSidebarRow: View {
  private let content: SummaryRowContent

  public init(content: SummaryRowContent) {
    self.content = content
  }

  public var body: some View {
    let tint: TimelineTint = content.color.map(TimelineTint.init) ?? .neutral

    SidebarRowFrame(content: content, ringColor: Color(tint.base)) { name in
      Text(verbatim: name)
        .ikaFont(.heavy, size: 16, relativeTo: .headline)
        .foregroundStyle(.white)
    } line: { line in
      Text(verbatim: line)
        .ikaFont(.light, size: 13, relativeTo: .subheadline)
        .foregroundStyle(TimelinePalette.secondaryText)
    }
  }
}

// MARK: - TimelineSidebarHeader

/// A Timeline sidebar group's title, in the heavy face in SplatNet 3's quiet grey.
public struct TimelineSidebarHeader: View {
  private let title: String

  public init(title: String) {
    self.title = title
  }

  public var body: some View {
    Text(verbatim: title)
      .ikaFont(.heavy, size: 13, relativeTo: .footnote)
      .foregroundStyle(TimelinePalette.stripIdle)
  }
}

// MARK: - Background

extension View {
  /// Lays a sidebar list on SplatNet 3's page colour, in the dark appearance Timeline draws in.
  public func timelineSidebarBackground() -> some View {
    scrollContentBackground(.hidden)
      .background(TimelinePalette.page)
      .environment(\.colorScheme, .dark)
  }
}
#endif
