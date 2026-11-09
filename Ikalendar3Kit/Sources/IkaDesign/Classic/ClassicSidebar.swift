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
/// summary in the light face. It receives a sidebar row's content only and reads no store.
public struct ClassicSidebarRow: View {
  @Environment(\.colorScheme) private var colorScheme

  private let content: SidebarRowContent

  public init(content: SidebarRowContent) {
    self.content = content
  }

  public var body: some View {
    SidebarRowFrame(content: content, ringColor: ringColor) { name in
      Text(verbatim: name)
        .ikaFont(.heavy, size: 17, relativeTo: .headline)
    } summary: { summary in
      Text(verbatim: summary)
        .ikaFont(.light, size: 14, relativeTo: .subheadline)
        .foregroundStyle(.secondary)
    }
  }

  /// The Mode colour, tinted where it would not read on the list; the primary colour for the
  /// Splatfest's rows.
  private var ringColor: Color {
    guard let color = content.color else { return .primary }

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
