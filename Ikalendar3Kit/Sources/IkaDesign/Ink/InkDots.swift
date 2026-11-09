//
//  InkDots.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI
import WidgetKit

// MARK: - InkBackground

/// Ink's dotted black background, behind a screen or as a widget's container background. Its
/// plain form is empty: the system draws the Lock Screen's and tinted backgrounds itself.
public struct InkBackground: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetRenderingMode) private var renderingMode

  public init() { }

  public var body: some View {
    if renderingMode.drawsInkMaterials {
      Color(InkPair.backgroundText.colors(in: colorScheme).background)
        .overlay {
          DotPattern(pitch: InkMetrics.backgroundDotPitch, radius: InkMetrics.backgroundDotRadius)
            .fill(InkDecoration.backgroundDot)
        }
        .accessibilityHidden(true)
    }
    else {
      Color.clear
    }
  }
}

// MARK: - InkDottedRule

/// The dotted rule under a panel's Rule name, as wide as it is offered. Decoration only, so
/// VoiceOver skips it.
public struct InkDottedRule: View {
  @Environment(\.widgetRenderingMode) private var renderingMode

  public init() { }

  public var body: some View {
    let dots: DotPattern = .init(pitch: InkMetrics.ruleDotPitch, radius: InkMetrics.ruleDotRadius)

    Group {
      if renderingMode.drawsInkMaterials {
        dots.fill(InkDecoration.ruleDot)
      }
      else {
        dots.fill(.tertiary)
      }
    }
    .frame(height: InkMetrics.ruleDotRadius * 2)
    .accessibilityHidden(true)
  }
}

// MARK: - DotPattern

/// Dots on a square grid of `pitch`, centred in the rect so the margins match on both sides. A
/// rect lower than one pitch gets one row along its middle, which makes a dotted rule.
struct DotPattern: Shape {
  let pitch: CGFloat
  let radius: CGFloat

  func path(in rect: CGRect) -> Path {
    let columns: Int = max(1, Int(rect.width / pitch))
    let rows: Int = max(1, Int(rect.height / pitch))
    let firstCenter: CGPoint = .init(
      x: rect.midX - CGFloat(columns - 1) * pitch / 2,
      y: rect.midY - CGFloat(rows - 1) * pitch / 2)

    var path: Path = .init()
    for row in 0 ..< rows {
      for column in 0 ..< columns {
        let center: CGPoint = .init(
          x: firstCenter.x + CGFloat(column) * pitch,
          y: firstCenter.y + CGFloat(row) * pitch)
        path.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
      }
    }
    return path
  }
}

// MARK: - Previews

#Preview("Background") {
  InkPreviewGallery {
    InkBackground()
      .frame(height: 120)
  }
}

#Preview("Dotted rule") {
  InkPreviewGallery {
    VStack(alignment: .leading, spacing: 6) {
      Text(verbatim: "Rainmaker")
        .inkFont(.headline)
      InkDottedRule()
    }
    .inkPanel()
  }
}
