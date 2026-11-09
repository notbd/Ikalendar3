//
//  ProgressGeometryTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI
import Testing
@testable import IkaDesign

/// Pins what the progress bar and the activity-style ring draw for a share.
struct ProgressGeometryTests {
  @Test
  func `Bar fills none, part and all of its width`() {
    #expect(ProgressBarGeometry(share: 0).fillWidth(in: 300) == 0)
    #expect(ProgressBarGeometry(share: 0.25).fillWidth(in: 300) == 75)
    #expect(ProgressBarGeometry(share: 1).fillWidth(in: 300) == 300)
  }

  @Test
  func `Shares outside the unit range clamp, and NaN counts as none`() {
    #expect(ProgressBarGeometry(share: -0.5).share == 0)
    #expect(ProgressBarGeometry(share: 1.5).share == 1)
    #expect(ProgressBarGeometry(share: .nan).share == 0)
    #expect(ProgressRingGeometry(share: 2).trimEnd == 1)
  }

  @Test
  func `Empty ring draws only its track`() {
    let ring: ProgressRingGeometry = .init(share: 0)

    #expect(ring.trimEnd == 0)
    #expect(!ring.showsHead)
  }

  @Test
  func `Ring starts at twelve o'clock and runs clockwise`() {
    let ring: ProgressRingGeometry = .init(share: 0.25)

    #expect(ProgressRingGeometry.startAngle == .degrees(-90))
    #expect(ring.trimEnd == 0.25)
    #expect(ring.showsHead)
    // A quarter of the way round, the head sits at three o'clock (SwiftUI's 0 degrees).
    #expect(ring.endAngle == .degrees(0))
    let head: CGPoint = ring.headCenter(in: CGRect(x: 0, y: 0, width: 100, height: 100), lineWidth: 10)
    #expect(abs(head.x - 95) < 1e-9)
    #expect(abs(head.y - 50) < 1e-9)
  }

  @Test
  func `Full ring closes with its head back at twelve o'clock`() {
    let ring: ProgressRingGeometry = .init(share: 1)

    #expect(ring.trimEnd == 1)
    #expect(ring.showsHead)
    #expect(ring.endAngle == .degrees(270))
    let head: CGPoint = ring.headCenter(in: CGRect(x: 0, y: 0, width: 100, height: 100), lineWidth: 10)
    #expect(abs(head.x - 50) < 1e-9)
    #expect(abs(head.y - 5) < 1e-9)
  }
}
