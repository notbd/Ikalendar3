//
//  ProgressRing.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - ProgressRing

/// A progress ring drawn like the Apple Watch activity rings, from `ProgressRingGeometry`: a dim
/// full track, then an arc with round caps from twelve o'clock clockwise, deepening into `color`
/// along the arc, and a head cap with a soft shadow at its end. It fills the square it is offered.
///
/// VoiceOver reads it as the time left, never as a percentage.
public struct ProgressRing: View {
  /// How dim the track is.
  static private let trackOpacity: Double = 0.25
  /// How much black the arc's tail mixes in, so the arc deepens towards its head.
  static private let tailDarkening: Double = 0.3

  private let geometry: ProgressRingGeometry
  private let color: Color
  private let lineWidth: CGFloat
  private let timeLeft: String

  /// - Parameters:
  ///   - share: The share of the window passed.
  ///   - color: The ring's colour, usually the Mode's.
  ///   - lineWidth: The stroke's width.
  ///   - timeLeft: What VoiceOver reads, as `SentenceWriter.timeLeft(_:)` writes it.
  public init(share: Double, color: Color, lineWidth: CGFloat, timeLeft: String) {
    geometry = ProgressRingGeometry(share: share)
    self.color = color
    self.lineWidth = lineWidth
    self.timeLeft = timeLeft
  }

  public var body: some View {
    GeometryReader { proxy in
      let rect: CGRect = .init(origin: .zero, size: proxy.size)
      let inset: CGFloat = lineWidth / 2

      ZStack {
        Circle()
          .inset(by: inset)
          .stroke(color.opacity(Self.trackOpacity), lineWidth: lineWidth)
        Circle()
          .inset(by: inset)
          .trim(from: 0, to: geometry.trimEnd)
          .rotation(ProgressRingGeometry.startAngle)
          .stroke(
            AngularGradient(
              colors: [color.mix(with: .black, by: Self.tailDarkening), color],
              center: .center,
              startAngle: ProgressRingGeometry.startAngle,
              endAngle: geometry.endAngle),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        if geometry.showsHead {
          // Over the gradient's seam at twelve o'clock, as the activity rings draw their head.
          Circle()
            .fill(color)
            .frame(width: lineWidth, height: lineWidth)
            .shadow(color: .black.opacity(0.35), radius: lineWidth / 4)
            .position(geometry.headCenter(in: rect, lineWidth: lineWidth))
        }
      }
    }
    .aspectRatio(1, contentMode: .fit)
    .accessibilityElement()
    .accessibilityLabel(Text(verbatim: timeLeft))
  }
}

// MARK: - Previews

#Preview("Progress rings") {
  HStack {
    ForEach([0, 0.25, 0.7, 1] as [Double], id: \.self) { share in
      ProgressRing(share: share, color: .orange, lineWidth: 10, timeLeft: "")
        .frame(width: 64)
    }
  }
  .padding()
}
