//
//  ProgressGeometry.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - ProgressBarGeometry

/// What a horizontal progress bar draws for a share: the current Rotation's bar in list cells.
public struct ProgressBarGeometry: Equatable, Sendable {
  /// The filled share, clamped to 0...1.
  public let share: Double

  /// The bar for `share`, the fraction the caller wants filled. Values outside 0...1 clamp, and
  /// NaN counts as none.
  public init(share: Double) {
    self.share = unitShare(share)
  }

  /// The width of the filled part of a bar `width` points wide.
  public func fillWidth(in width: CGFloat) -> CGFloat {
    width * share
  }
}

// MARK: - ProgressRingGeometry

/// What a progress ring draws for a share, drawn like the Apple Watch activity rings: a dim full
/// track, then an arc with round caps from twelve o'clock clockwise, its gradient running along
/// the arc, and a head cap at the arc's end.
///
/// Angles are in SwiftUI's frame: 0 degrees is three o'clock and angles grow clockwise. A view
/// draws the arc as `Circle().trim(from: 0, to: trimEnd).rotation(startAngle)` and strokes it with
/// an angular gradient from `startAngle` to `endAngle`.
public struct ProgressRingGeometry: Equatable, Sendable {
  /// Where every arc starts: twelve o'clock.
  static public let startAngle: Angle = .degrees(-90)

  /// The drawn share of the circle, clamped to 0...1.
  public let share: Double

  /// The ring for `share`, the fraction the caller wants drawn. Values outside 0...1 clamp, and
  /// NaN counts as none.
  public init(share: Double) {
    self.share = unitShare(share)
  }

  /// The end of the circle's trim.
  public var trimEnd: Double {
    share
  }

  /// Where the arc and its gradient end.
  public var endAngle: Angle {
    Self.startAngle + .degrees(360 * share)
  }

  /// Whether to draw the head cap: an empty ring shows only its track.
  public var showsHead: Bool {
    share > 0
  }

  /// The centre of the head cap for a ring drawn in `rect` with a stroke `lineWidth` wide, on the
  /// middle of the stroke.
  public func headCenter(in rect: CGRect, lineWidth: CGFloat) -> CGPoint {
    let radius: CGFloat = min(rect.width, rect.height) / 2 - lineWidth / 2
    return CGPoint(
      x: rect.midX + radius * cos(endAngle.radians),
      y: rect.midY + radius * sin(endAngle.radians))
  }
}

/// `share` clamped to 0...1, with NaN as 0.
private func unitShare(_ share: Double) -> Double {
  share.isNaN ? 0 : min(max(share, 0), 1)
}
