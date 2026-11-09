//
//  ModeStampMathTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreGraphics
import Testing
@testable import IkaDesign

/// Pins the stamp's tilt math: how each interface orientation remaps the device's gravity deltas
/// into screen axes, and how the 3D angle follows the length of the delta. Also pins the dock
/// math: how scrolling shrinks and fades the stamp into the navigation bar badge.
/// Carried over from ikalendar 2's `ModeIconStampMathTests`.
struct ModeStampMathTests {
  typealias Tilt = ModeStampMath.Tilt
  typealias DockStyle = ModeStampMath.DockStyle

  /// Dock progress from 0 to 1 in steps of 0.05.
  static private let progressSteps: [Double] = (0 ... 20).map { Double($0) / 20 }

  /// The sample device-space tilt (dx 0.3, dy -0.2) remapped for `orientation`.
  private func screenTilt(_ orientation: InterfaceOrientation) -> Tilt {
    ModeStampMath.screenTilt(dx: 0.3, dy: -0.2, orientation: orientation)
  }

  @Test
  func `Portrait and unknown pass the device tilt through unchanged`() {
    let deviceTilt: Tilt = .init(dx: 0.3, dy: -0.2)

    #expect(screenTilt(.portrait) == deviceTilt)
    #expect(screenTilt(.unknown) == deviceTilt)
  }

  @Test
  func `Upside down negates both axes`() {
    #expect(screenTilt(.portraitUpsideDown) == Tilt(dx: -0.3, dy: 0.2))
  }

  @Test
  func `Landscape left turns the tilt a quarter turn`() {
    #expect(screenTilt(.landscapeLeft) == Tilt(dx: -0.2, dy: -0.3))
  }

  @Test
  func `Landscape right is the mirror of landscape left`() {
    let left: Tilt = screenTilt(.landscapeLeft)

    #expect(screenTilt(.landscapeRight) == Tilt(dx: 0.2, dy: 0.3))
    #expect(screenTilt(.landscapeRight) == Tilt(dx: -left.dx, dy: -left.dy))
  }

  @Test(arguments: InterfaceOrientation.allCases)
  func `Every orientation preserves the tilt magnitude`(orientation: InterfaceOrientation) {
    let tilt: Tilt = screenTilt(orientation)

    #expect(abs(hypot(tilt.dx, tilt.dy) - hypot(0.3, -0.2)) < 1e-9)
  }

  @Test
  func `Rotation angle is zero at rest and scales linearly`() {
    #expect(ModeStampMath.rotationAngle(for: Tilt(dx: 0, dy: 0)) == 0)
    // A delta of length 0.5 at 24 degrees per unit.
    #expect(abs(ModeStampMath.rotationAngle(for: Tilt(dx: 0.3, dy: 0.4)) - 12) < 1e-9)
  }

  @Test
  func `Dock progress clamps to the unit range`() {
    // The default dock travel is 44 pt.
    #expect(ModeStampMath.dockProgress(travel: -5) == 0)
    #expect(ModeStampMath.dockProgress(travel: 0) == 0)
    #expect(ModeStampMath.dockProgress(travel: 22) == 0.5)
    #expect(ModeStampMath.dockProgress(travel: 44) == 1)
    #expect(ModeStampMath.dockProgress(travel: 60) == 1)
    #expect(ModeStampMath.dockProgress(travel: 10, dockTravel: 0) == 1)
  }

  @Test
  func `Dock progress is measured from the resting top inset`() {
    // At rest under the expanded large title (168 pt inset).
    #expect(ModeStampMath.dockProgress(contentOffsetY: -168, restingTopInset: 168) == 0)
    // Halfway through the dock travel while the title collapses.
    #expect(ModeStampMath.dockProgress(contentOffsetY: -146, restingTopInset: 168) == 0.5)
    // At the list's new top under a still-collapsed bar (116 pt inset) after rows above were removed.
    #expect(ModeStampMath.dockProgress(contentOffsetY: -116, restingTopInset: 168) == 1)
    // Pulling to refresh leaves the stamp at rest.
    #expect(ModeStampMath.dockProgress(contentOffsetY: -200, restingTopInset: 168) == 0)
  }

  @Test
  func `Dock style is at rest at zero and docked at one`() {
    let docked: DockStyle = ModeStampMath.dockStyle(progress: 1)

    #expect(ModeStampMath.dockStyle(progress: 0) == DockStyle(scale: 1, opacity: 1, parallaxGain: 1))
    #expect(abs(docked.scale - 0.65) < 1e-9)
    #expect(docked.opacity == 0)
    #expect(docked.parallaxGain == 0)
    #expect(ModeStampMath.badgeOpacity(progress: 0) == 0)
    #expect(ModeStampMath.badgeOpacity(progress: 1) == 1)
  }

  @Test
  func `Dock style changes monotonically`() {
    for (lower, upper) in zip(Self.progressSteps, Self.progressSteps.dropFirst()) {
      let before: DockStyle = ModeStampMath.dockStyle(progress: lower)
      let after: DockStyle = ModeStampMath.dockStyle(progress: upper)

      #expect(after.opacity <= before.opacity)
      #expect(after.scale <= before.scale)
      #expect(after.parallaxGain <= before.parallaxGain)
      #expect(ModeStampMath.badgeOpacity(progress: upper) >= ModeStampMath.badgeOpacity(progress: lower))
    }
  }

  @Test
  func `Stamp and badge are never both invisible`() {
    for progress in Self.progressSteps {
      #expect(ModeStampMath.dockStyle(progress: progress).opacity + ModeStampMath.badgeOpacity(progress: progress) > 0)
    }
    // The handover window: the badge starts at 0.5 and the stamp is gone by 0.7.
    #expect(ModeStampMath.dockStyle(progress: 0.7).opacity == 0)
    #expect(ModeStampMath.badgeOpacity(progress: 0.5) == 0)
  }

  // MARK: Reduce Motion

  @Test
  func `Under Reduce Motion the dock is a cross-fade with no scaling or tilt`() {
    for progress in Self.progressSteps {
      let reduced: DockStyle = ModeStampMath.dockStyle(progress: progress, reduceMotion: true)

      #expect(reduced.scale == 1)
      #expect(reduced.parallaxGain == 0)
      #expect(reduced.opacity == ModeStampMath.dockStyle(progress: progress).opacity)
    }
  }

  @Test
  func `Under Reduce Motion the stamp does not tilt`() {
    #expect(ModeStampMath.rotationAngle(for: Tilt(dx: 0.3, dy: 0.4), reduceMotion: true) == 0)
  }
}
