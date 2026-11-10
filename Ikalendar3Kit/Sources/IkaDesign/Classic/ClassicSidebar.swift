//
//  ClassicSidebar.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - ClassicSidebarRow

/// Classic's sidebar row on the system's sidebar list, as ikalendar 2's lists sit on the system's
/// grouped lists: the Mode's icon in a ring of its colour, the name in the heavy face and the
/// line in the light face. It receives a summary row's content only and reads no store.
public struct ClassicSidebarRow: View {
  @Environment(\.colorScheme) private var colorScheme

  private let content: SummaryRowContent

  public init(content: SummaryRowContent) {
    self.content = content
  }

  public var body: some View {
    SidebarRowFrame(content: content, ringColor: content.classicRingColor(in: colorScheme)) { name in
      Text(verbatim: name)
        .ikaFont(.heavy, size: 17, relativeTo: .headline)
    } line: { line in
      Text(verbatim: line)
        .ikaFont(.light, size: 14, relativeTo: .subheadline)
        .foregroundStyle(.secondary)
    }
  }
}

// MARK: - SummaryRowContent

extension SummaryRowContent {
  /// The ring's colour in Classic's summary rows and Overview cards: the Mode colour, tinted where
  /// it would not read on Classic's panels; the primary colour for the Splatfest's rows.
  func classicRingColor(in colorScheme: ColorScheme) -> Color {
    guard let color else { return .primary }

    return Color(color.onPanel(of: .classic, in: colorScheme, for: .largeTextAndIcons).foreground)
  }
}

// MARK: - ClassicSidebarHeader

/// A Classic sidebar group's title, in the heavy face.
public struct ClassicSidebarHeader: View {
  private let title: String

  public init(title: String) {
    self.title = title
  }

  public var body: some View {
    Text(verbatim: title)
      .ikaFont(.heavy, size: 15, relativeTo: .subheadline)
  }
}
#endif
