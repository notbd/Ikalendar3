//
//  InkSidebar.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - InkSidebarRow

/// Ink's sidebar row on the dotted black background: the Mode's icon in a ring of its accent, the
/// name in the heavy face and the summary in the light face. It receives a sidebar row's content
/// only and reads no store.
public struct InkSidebarRow: View {
  @Environment(\.colorScheme) private var colorScheme

  private let content: SidebarRowContent

  public init(content: SidebarRowContent) {
    self.content = content
  }

  public var body: some View {
    let accent: InkAccent = content.color.map(InkAccent.init) ?? .splatfest

    SidebarRowFrame(content: content, ringColor: Color(accent.base)) { name in
      Text(verbatim: name)
        .inkFont(.tag)
        .foregroundStyle(Color(InkPair.backgroundText.colors(in: colorScheme).foreground))
    } summary: { summary in
      Text(verbatim: summary)
        .inkFont(.caption)
        .foregroundStyle(Color(InkPair.panelSecondaryText.colors(in: colorScheme).foreground))
    }
  }
}

// MARK: - InkSidebarHeader

/// An Ink sidebar group's title, in the heavy face on the dotted background.
public struct InkSidebarHeader: View {
  @Environment(\.colorScheme) private var colorScheme

  private let title: String

  public init(title: String) {
    self.title = title
  }

  public var body: some View {
    Text(verbatim: title)
      .inkFont(.label)
      .foregroundStyle(Color(InkPair.panelSecondaryText.colors(in: colorScheme).foreground))
  }
}

// MARK: - Background

extension View {
  /// Lays a sidebar list on Ink's dotted black background, in the dark appearance Ink draws in
  /// until ticket 56 designs its light look.
  public func inkSidebarBackground() -> some View {
    scrollContentBackground(.hidden)
      .background { InkBackground().ignoresSafeArea() }
      .environment(\.colorScheme, .dark)
  }
}
#endif
