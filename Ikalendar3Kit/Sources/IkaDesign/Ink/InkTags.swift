//
//  InkTags.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI
import WidgetKit

// MARK: - InkModeTag

/// The skewed tag in a Mode's colour, such as Series or Open under the Anarchy Battle name.
/// Black or white text, whichever reads on the colour. In accented rendering it takes the accent
/// tint, so it still stands out.
public struct InkModeTag: View {
  private let text: Text
  private let modeColor: ModeColor

  /// A tag reading `text` in `modeColor`.
  public init(_ text: Text, modeColor: ModeColor) {
    self.text = text
    self.modeColor = modeColor
  }

  public var body: some View {
    InkTagLabel(text: text, style: .tag, colors: modeColor.asFill)
      .widgetAccentable()
  }
}

// MARK: - InkTimeTag

/// The skewed black tag for a time: a range, a start time, or the system's timer text for a
/// countdown (`Text(timerInterval:)`), which ticks with no timer of the app's own.
public struct InkTimeTag: View {
  @Environment(\.colorScheme) private var colorScheme

  private let text: Text

  /// A tag reading `text`.
  public init(_ text: Text) {
    self.text = text
  }

  public var body: some View {
    InkTagLabel(text: text, style: .body, colors: InkPair.tagText.colors(in: colorScheme))
  }
}

// MARK: - InkTagLabel

/// A text on a skewed plate: the body of every Ink tag. One line that shrinks to fit, wrapping
/// instead from the first accessibility text size, as cells do. Its plain form is the primary
/// text colour on the system's quaternary fill, because the vibrant mode turns dark text clear.
struct InkTagLabel: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.widgetRenderingMode) private var renderingMode

  let text: Text
  let style: InkTextStyle
  let colors: ColorPair

  var body: some View {
    let plate: SkewedRectangle = .init(slant: InkMetrics.tagSlant)

    if renderingMode.drawsInkMaterials {
      label
        .foregroundStyle(Color(colors.foreground))
        .background(Color(colors.background), in: plate)
    }
    else {
      label
        .background(.quaternary, in: plate)
    }
  }

  private var label: some View {
    text
      .inkFont(style)
      .scaledLimitedLine(for: dynamicTypeSize.isAccessibilitySize ? .stacked : .sideBySide)
      .padding(.horizontal, InkMetrics.tagHorizontalPadding)
      .padding(.vertical, InkMetrics.tagVerticalPadding)
  }
}

// MARK: - SkewedRectangle

/// A rectangle leaning right like italic text: the top edge sits `slant` points to the right per
/// point of height, inside the rect.
struct SkewedRectangle: Shape {
  let slant: CGFloat

  func path(in rect: CGRect) -> Path {
    let run: CGFloat = rect.height * slant

    var path: Path = .init()
    path.move(to: CGPoint(x: rect.minX + run, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX - run, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}

// MARK: - Previews

#Preview("Mode tags") {
  InkPreviewGallery {
    HStack {
      InkModeTag(Text(verbatim: "Series"), modeColor: .anarchy)
      InkModeTag(Text(verbatim: "Open"), modeColor: .anarchy)
      InkModeTag(Text(verbatim: "Now!"), modeColor: .regularBattle)
      InkModeTag(Text(verbatim: "Big Run"), modeColor: .bigRun)
    }
  }
}

#Preview("Time tags") {
  InkPreviewGallery {
    VStack(alignment: .leading) {
      InkTimeTag(Text(verbatim: "8:00 AM - 10:00 AM"))
      InkTimeTag(Text(timerInterval: Date.now ... Date.now.addingTimeInterval(50 * 60)))
    }
  }
}
