//
//  InkPanel.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI
import WidgetKit

extension View {
  /// Sets this content on Ink's rough-edged dark panel, inset by the panel's padding, in the
  /// panel's text colour. `isTaped` adds the strip of tape that marks the current Rotation or
  /// Shift. The rough edge and the tape are decoration, so VoiceOver skips them.
  public func inkPanel(isTaped: Bool = false) -> some View {
    modifier(InkPanel(isTaped: isTaped))
  }
}

// MARK: - InkPanel

/// The panel behind `inkPanel(isTaped:)`. Its plain form is a rounded rect in the system's
/// quaternary fill, with no tape.
private struct InkPanel: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetRenderingMode) private var renderingMode

  let isTaped: Bool

  func body(content: Content) -> some View {
    let colors: ColorPair = InkPair.panelText.colors(in: colorScheme)
    if renderingMode.drawsInkMaterials {
      content
        .padding(InkMetrics.panelPadding)
        .foregroundStyle(Color(colors.foreground))
        .background {
          RoughRectangle(roughness: InkMetrics.panelRoughness, step: InkMetrics.panelRoughStep)
            .fill(Color(colors.background))
            .accessibilityHidden(true)
        }
        .overlay(alignment: .top) {
          if isTaped {
            InkTape()
              .offset(y: -InkMetrics.tapeSize.height / 2)
          }
        }
    }
    else {
      content
        .padding(InkMetrics.panelPadding)
        .background(.quaternary, in: .rect(cornerRadius: InkMetrics.plainPanelCornerRadius))
    }
  }
}

// MARK: - InkTape

/// A strip of translucent masking tape with torn ends, turned slightly.
private struct InkTape: View {
  var body: some View {
    TornStrip()
      .fill(InkDecoration.tape)
      .frame(width: InkMetrics.tapeSize.width, height: InkMetrics.tapeSize.height)
      .rotationEffect(InkMetrics.tapeAngle)
      .accessibilityHidden(true)
  }
}

// MARK: - TornStrip

/// A strip with straight long edges and zigzag ends, like tape torn off by hand.
private struct TornStrip: Shape {
  /// The teeth on each end.
  private let teeth: Int = 3
  /// How deep each tooth bites into the strip.
  private let depth: CGFloat = 2.5

  func path(in rect: CGRect) -> Path {
    let toothHeight: CGFloat = rect.height / CGFloat(teeth)

    var path: Path = .init()
    path.move(to: CGPoint(x: rect.minX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    for tooth in 0 ..< teeth {
      let top: CGFloat = rect.minY + CGFloat(tooth) * toothHeight
      path.addLine(to: CGPoint(x: rect.maxX - depth, y: top + toothHeight / 2))
      path.addLine(to: CGPoint(x: rect.maxX, y: top + toothHeight))
    }
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    for tooth in (0 ..< teeth).reversed() {
      let top: CGFloat = rect.minY + CGFloat(tooth) * toothHeight
      path.addLine(to: CGPoint(x: rect.minX + depth, y: top + toothHeight / 2))
      path.addLine(to: CGPoint(x: rect.minX, y: top))
    }
    path.closeSubpath()
    return path
  }
}

// MARK: - RoughRectangle

/// A rectangle whose edges wander up to `roughness` from the straight line, with a point every
/// `step` along them, like torn paper. The wander is fixed per point, so a panel keeps its edge
/// from frame to frame, and stays inside the rect.
struct RoughRectangle: Shape {
  let roughness: CGFloat
  let step: CGFloat

  func path(in rect: CGRect) -> Path {
    let inner: CGRect = rect.insetBy(dx: roughness, dy: roughness)
    // Clockwise from the top left corner, each with its edge's outward normal.
    let corners: [(point: CGPoint, normal: CGVector)] = [
      (CGPoint(x: inner.minX, y: inner.minY), CGVector(dx: 0, dy: -1)),
      (CGPoint(x: inner.maxX, y: inner.minY), CGVector(dx: 1, dy: 0)),
      (CGPoint(x: inner.maxX, y: inner.maxY), CGVector(dx: 0, dy: 1)),
      (CGPoint(x: inner.minX, y: inner.maxY), CGVector(dx: -1, dy: 0)),
    ]

    var path: Path = .init()
    var pointIndex = 0
    for (side, corner) in corners.enumerated() {
      let end: CGPoint = corners[(side + 1) % corners.count].point
      let length: CGFloat = hypot(end.x - corner.point.x, end.y - corner.point.y)
      let segments: Int = max(1, Int((length / step).rounded()))

      for segment in 0 ..< segments {
        let share: CGFloat = .init(segment) / CGFloat(segments)
        let wander: CGFloat = Self.unitNoise(pointIndex) * roughness
        let point: CGPoint = .init(
          x: corner.point.x + (end.x - corner.point.x) * share + corner.normal.dx * wander,
          y: corner.point.y + (end.y - corner.point.y) * share + corner.normal.dy * wander)
        if pointIndex == 0 {
          path.move(to: point)
        }
        else {
          path.addLine(to: point)
        }
        pointIndex += 1
      }
    }
    path.closeSubpath()
    return path
  }

  /// A fixed pseudo-random value from -1 to 1 for `index` (SplitMix64's finaliser).
  static private func unitNoise(_ index: Int) -> CGFloat {
    var bits = UInt64(truncatingIfNeeded: index) &* 0x9E37_79B9_7F4A_7C15
    bits = (bits ^ (bits >> 30)) &* 0xBF58_476D_1CE4_E5B9
    bits = (bits ^ (bits >> 27)) &* 0x94D0_49BB_1331_11EB
    bits ^= bits >> 31
    return CGFloat(bits >> 11) / CGFloat(1 << 53) * 2 - 1
  }
}

// MARK: - Previews

#Preview("Panel") {
  InkPreviewGallery {
    VStack(spacing: 18) {
      Text(verbatim: "Current panel, taped")
        .inkFont(.headline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .inkPanel(isTaped: true)
      Text(verbatim: "Later panel")
        .inkFont(.label)
        .frame(maxWidth: .infinity, alignment: .leading)
        .inkPanel()
    }
  }
}
