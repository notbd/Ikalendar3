//
//  InkTeamTag.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI
import WidgetKit

// MARK: - InkTeamTag

/// The skewed tag in a Splatfest team's colour from the feed, with the team's name in black or
/// white, whichever reads on the colour (`SRGBColor.labelColor`). In accented rendering it takes
/// the accent tint, as a Mode tag does.
public struct InkTeamTag: View {
  private let text: Text
  private let color: SRGBColor

  /// A tag reading `text` in a team's `color`.
  public init(_ text: Text, color: SRGBColor) {
    self.text = text
    self.color = color
  }

  public var body: some View {
    InkTagLabel(text: text, style: .tag, colors: ColorPair(foreground: color.labelColor, background: color))
      .widgetAccentable()
  }
}

// MARK: - Previews

#Preview("Team tags") {
  InkPreviewGallery {
    VStack(alignment: .leading) {
      InkTeamTag(Text(verbatim: "Wizard"), color: SRGBColor(hex: 0x6E2BD9))
      InkTeamTag(Text(verbatim: "Knight"), color: SRGBColor(hex: 0xD9C61E))
      InkTeamTag(Text(verbatim: "Ninja"), color: SRGBColor(hex: 0x1EB0D9))
    }
  }
}
