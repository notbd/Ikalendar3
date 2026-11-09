//
//  ProgressRing.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - ProgressRing

/// A progress ring drawn like the Apple Watch activity rings (`ProgressRingGeometry`), in one
/// colour, inside the frame it is offered. The watch's Now rows draw it around the Mode icon; the
/// wide detail's current row draws it beside the time left.
///
/// VoiceOver reads it as the time left, never as a percentage. A row that is one VoiceOver
/// element reads its own sentence instead.
public struct ProgressRing: View {
  private let geometry: ProgressRingGeometry
  private let color: Color
  private let lineWidth: CGFloat
  private let timeLeft: String?

  /// A ring with `share` of it drawn in `color`, its stroke `lineWidth` wide.
  ///
  /// - Parameter timeLeft: What VoiceOver reads, as `SentenceWriter.timeLeft(_:)` writes it, or
  ///   `nil` while nothing runs, which hides the ring from VoiceOver.
  public init(share: Double, color: Color, lineWidth: CGFloat, timeLeft: String?) {
    geometry = ProgressRingGeometry(share: share)
    self.color = color
    self.lineWidth = lineWidth
    self.timeLeft = timeLeft
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
    .accessibilityElement()
    .accessibilityLabel(Text(verbatim: timeLeft ?? ""))
    .accessibilityHidden(timeLeft == nil)
  }
}

// MARK: - Previews

#Preview("Progress rings") {
  HStack(spacing: 12) {
    ForEach([0, 0.05, 0.4, 0.75, 1], id: \.self) { share in
      ProgressRing(share: share, color: Color(ModeColor.xBattle.base), lineWidth: 5, timeLeft: nil)
        .frame(width: 40, height: 40)
    }
  }
  .padding()
  .background(.black)
}
