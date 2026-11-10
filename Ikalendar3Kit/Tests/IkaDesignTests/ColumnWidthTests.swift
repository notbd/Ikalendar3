//
//  ColumnWidthTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreGraphics
import Testing
@testable import IkaDesign

/// Pins the width of the Mac's columns: an equal share of the window, never narrower than 300 pt,
/// so a narrow window scrolls sideways instead of squeezing the lists.
struct ColumnWidthTests {
  @Test(arguments: [
    // Four columns: wide, exactly at the floor, and the default window.
    (1600, 4, 400),
    (1200, 4, 300),
    (1280, 4, 320),
    // Three columns during a Splatfest share the same window more widely.
    (1200, 3, 400),
  ] as [(CGFloat, Int, CGFloat)])
  func `Columns share a window wide enough for them equally`(_ windowWidth: CGFloat, _ count: Int, _ width: CGFloat) {
    #expect(ColumnWidth.width(sharing: windowWidth, count: count) == width)
  }

  @Test(arguments: [
    (1199, 4),
    (800, 4),
    (640, 3),
  ] as [(CGFloat, Int)])
  func `Columns in a narrow window keep 300 pt and overflow it`(_ windowWidth: CGFloat, _ count: Int) {
    let width: CGFloat = ColumnWidth.width(sharing: windowWidth, count: count)

    #expect(width == 300)
    #expect(width * CGFloat(count) > windowWidth)
  }
}
