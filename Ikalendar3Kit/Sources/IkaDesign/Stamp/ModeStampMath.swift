//
//  ModeStampMath.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreGraphics

// MARK: - ModeStampMath

/// The numbers behind the Mode stamp, as ikalendar 2 computes them: how it tilts with the device
/// and how it docks into the navigation bar badge as the list scrolls. The stamp view only
/// applies them.
public enum ModeStampMath {
  /// Degrees of 3D tilt per unit of gravity delta.
  static public let rotation3dIntensity: Double = 24
  /// The scroll distance over which the stamp docks into the badge.
  static public let dockTravel: CGFloat = 44
  /// The stamp's scale once docked.
  static public let dockedScale: Double = 0.65
  /// The dock progress by which the stamp has faded out.
  static public let dockFadeOutEnd: Double = 0.7
  /// The dock progress from which the badge fades in.
  static public let badgeFadeInStart: Double = 0.5
}

// MARK: - Tilt

extension ModeStampMath {
  /// A gravity delta in the interface's axes: `dx` toward the screen's right edge, `dy` toward its top.
  public struct Tilt: Equatable, Sendable {
    /// Toward the screen's right edge.
    public var dx: CGFloat
    /// Toward the screen's top edge.
    public var dy: CGFloat

    /// A tilt of `dx` and `dy`.
    public init(dx: CGFloat, dy: CGFloat) {
      self.dx = dx
      self.dy = dy
    }
  }

  /// Remaps the device-space gravity deltas into the interface's axes for `orientation`, so the
  /// stamp tilts with the physical device. Each mapping only swaps and negates the axes, so the
  /// magnitude is unchanged.
  static public func screenTilt(
    dx: CGFloat,
    dy: CGFloat,
    orientation: InterfaceOrientation)
    -> Tilt
  {
    switch orientation {
      case .unknown,
           .portrait:
        .init(dx: dx, dy: dy)
      case .portraitUpsideDown:
        .init(dx: -dx, dy: -dy)
      case .landscapeLeft:
        .init(dx: dy, dy: -dx)
      case .landscapeRight:
        .init(dx: -dy, dy: dx)
    }
  }

  /// The 3D tilt in degrees: proportional to the length of the gravity delta, and none under
  /// Reduce Motion.
  static public func rotationAngle(for tilt: Tilt, reduceMotion: Bool = false) -> Double {
    guard DecorativeMotion.stampTilt.form(reduceMotion: reduceMotion) == .full else { return 0 }

    return Double(hypot(tilt.dx, tilt.dy)) * rotation3dIntensity
  }
}

// MARK: - Dock

extension ModeStampMath {
  /// How the stamp looks at a dock progress: `parallaxGain` scales both the 2D and the 3D tilt.
  public struct DockStyle: Equatable, Sendable {
    /// The stamp's scale, anchored at its top-trailing corner.
    public var scale: Double
    /// The stamp's opacity.
    public var opacity: Double
    /// How much of the stamp's tilt remains.
    public var parallaxGain: Double

    /// A style with these values.
    public init(scale: Double, opacity: Double, parallaxGain: Double) {
      self.scale = scale
      self.opacity = opacity
      self.parallaxGain = parallaxGain
    }
  }

  /// The share of `dockTravel` scrolled, clamped to 0...1. Pulling to refresh (negative travel)
  /// leaves the stamp at rest.
  static public func dockProgress(
    travel: CGFloat,
    dockTravel: CGFloat = dockTravel)
    -> Double
  {
    guard dockTravel > 0 else { return 1 }

    return min(max(Double(travel / dockTravel), 0), 1)
  }

  /// The dock progress for a content offset, with the travel measured from where the list rests
  /// under the expanded large title (`restingTopInset`) rather than from the current inset. The
  /// inset shrinks by the title height as the title collapses, and stays shrunk when rows above
  /// the viewport are removed while scrolled (a Rotation rolling off): the list then sits at its
  /// new top under a collapsed bar, which the current inset reads as no travel at all.
  static public func dockProgress(
    contentOffsetY: CGFloat,
    restingTopInset: CGFloat,
    dockTravel: CGFloat = dockTravel)
    -> Double
  {
    dockProgress(travel: contentOffsetY + restingTopInset, dockTravel: dockTravel)
  }

  /// The stamp shrinks toward its top-trailing corner, is gone by `dockFadeOutEnd`, and stops
  /// tilting once docked. Under Reduce Motion it only cross-fades: no scaling, no tilt.
  static public func dockStyle(progress: Double, reduceMotion: Bool = false) -> DockStyle {
    let opacity: Double = 1 - min(progress / dockFadeOutEnd, 1)

    switch DecorativeMotion.stampDock.form(reduceMotion: reduceMotion) {
      case .full:
        return .init(
          scale: 1 - (1 - dockedScale) * progress,
          opacity: opacity,
          parallaxGain: 1 - progress)

      case .crossFade,
           .still:
        return .init(scale: 1, opacity: opacity, parallaxGain: 0)
    }
  }

  /// The badge fades in from `badgeFadeInStart`, before the stamp has faded out, so the two
  /// overlap and the Mode never disappears.
  static public func badgeOpacity(progress: Double) -> Double {
    max(0, (progress - badgeFadeInStart) / (1 - badgeFadeInStart))
  }
}
