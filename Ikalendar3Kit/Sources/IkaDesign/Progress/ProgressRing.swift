//
//  ProgressRing.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - ProgressRing

/// A progress ring drawn like the Apple Watch activity rings (`ProgressRingGeometry`), in one
/// colour, inside the frame it is offered. Summary rows draw it around the Mode icon; the wide
/// detail's current row draws it beside the time left.
///
/// VoiceOver skips it: every ring sits in a row that is one VoiceOver element and reads its own
/// sentence, time left included, never a percentage.
public struct ProgressRing: View {
  private let geometry: ProgressRingGeometry
  private let color: Color
  private let lineWidth: CGFloat

  /// A ring with `share` of it drawn in `color`, its stroke `lineWidth` wide.
  public init(share: Double, color: Color, lineWidth: CGFloat) {
    geometry = ProgressRingGeometry(share: share)
    self.color = color
    self.lineWidth = lineWidth
  }

  public var body: some View {
    let circle = Circle().inset(by: lineWidth / 2)

    ZStack {
      circle
        .stroke(color.opacity(0.25), lineWidth: lineWidth)
      circle
        .trim(from: 0, to: geometry.trimEnd)
        .rotation(ProgressRingGeometry.startAngle)
        .stroke(
          AngularGradient(
            colors: [color.opacity(0.75), color],
            center: .center,
            startAngle: ProgressRingGeometry.startAngle,
            endAngle: geometry.endAngle),
          style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
      if geometry.showsHead {
        // The arc's round end cap would take the gradient's start colour where it wraps around;
        // the head covers it in the end colour.
        GeometryReader { proxy in
          Circle()
            .fill(color)
            .frame(width: lineWidth, height: lineWidth)
            .position(geometry.headCenter(in: CGRect(origin: .zero, size: proxy.size), lineWidth: lineWidth))
        }
      }
    }
    .accessibilityHidden(true)
  }
}

// MARK: - Previews

#Preview("Progress rings") {
  HStack(spacing: 12) {
    ForEach([0, 0.05, 0.4, 0.75, 1], id: \.self) { share in
      ProgressRing(share: share, color: Color(ModeColor.xBattle.base), lineWidth: 5)
        .frame(width: 40, height: 40)
    }
  }
  .padding()
  .background(.black)
}
