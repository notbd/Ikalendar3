//
//  InkTextStyle.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - InkTextStyle

/// Ink's text styles: SplatNet 3's heavy face for names and tags, its light face for times and
/// Stage names, at the round 3 mock's sizes. Each scales with Dynamic Type relative to a system
/// text style. Ticket 56 judges the faces and sizes with the real fonts.
public enum InkTextStyle: CaseIterable, Sendable {
  /// The Mode name over the list.
  case title
  /// The Rule name on the current panel.
  case headline
  /// Tags: Series, Open, Now!, Next.
  case tag
  /// The Rule name on a later panel.
  case label
  /// Times.
  case body
  /// Stage names and the time left.
  case caption

  /// The face.
  public var role: FontRole {
    switch self {
      case .title,
           .headline,
           .tag,
           .label:
        .heavy
      case .body,
           .caption:
        .light
    }
  }

  /// The size in points at the default text size.
  public var size: CGFloat {
    switch self {
      case .title: 31
      case .headline: 26
      case .tag: 15
      case .label: 12
      case .body: 14
      case .caption: 13
    }
  }

  /// The system text style the size scales with.
  public var textStyle: Font.TextStyle {
    switch self {
      case .title: .largeTitle
      case .headline: .title
      case .tag: .subheadline
      case .label: .caption
      case .body: .subheadline
      case .caption: .footnote
    }
  }
}

extension View {
  /// Sets text in Ink's `style`, through `ikaFont`, so it follows the app language's font
  /// cascade and Dynamic Type.
  public func inkFont(_ style: InkTextStyle) -> some View {
    ikaFont(style.role, size: style.size, relativeTo: style.textStyle)
  }
}
