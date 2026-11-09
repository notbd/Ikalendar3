//
//  WindowLayoutTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI
import Testing
@testable import IkaDesign

/// Pins how an iPad window lays out the Schedules: the iPhone tabs at compact width, one column
/// per Mode when it is wider than tall and at least 1024 pt wide, otherwise a sidebar beside one
/// detail column.
struct WindowLayoutTests {
  /// A window size and the layout it takes.
  struct SizeCase: CustomTestStringConvertible {
    let width: CGFloat
    let height: CGFloat
    let layout: WindowLayout

    var testDescription: String { "\(width) x \(height)" }
  }

  @Test(arguments: [
    // The boundary: exactly 1024 pt wide and wider than tall.
    SizeCase(width: 1024, height: 768, layout: .columns),
    SizeCase(width: 1024, height: 1023, layout: .columns),
    // Just short of either condition.
    SizeCase(width: 1023.5, height: 768, layout: .sidebar),
    SizeCase(width: 1024, height: 1024, layout: .sidebar),
    SizeCase(width: 1024, height: 1366, layout: .sidebar),
    // iPad Pro 13-inch and iPad mini, in landscape and in portrait.
    SizeCase(width: 1376, height: 1032, layout: .columns),
    SizeCase(width: 1032, height: 1376, layout: .sidebar),
    SizeCase(width: 1133, height: 744, layout: .columns),
    SizeCase(width: 744, height: 1133, layout: .sidebar),
    // Half of a landscape iPad Pro 13-inch in Split View, and a short, narrow window.
    SizeCase(width: 684, height: 1032, layout: .sidebar),
    SizeCase(width: 900, height: 500, layout: .sidebar),
  ])
  func `A window takes columns only when it is wider than tall and at least 1024 pt wide`(_ size: SizeCase) {
    let windowSize: CGSize = .init(width: size.width, height: size.height)

    #expect(WindowLayout(windowSize: windowSize, horizontalSizeClass: .regular) == size.layout)
  }

  @Test(arguments: [
    // Slide Over, a third of a landscape iPad Pro 13-inch in Split View, and an iPhone-sized window.
    CGSize(width: 320, height: 1032),
    CGSize(width: 438, height: 1032),
    CGSize(width: 375, height: 667),
    // A compact window wide enough for columns by its size alone.
    CGSize(width: 1376, height: 1032),
  ])
  func `A window of compact width takes the iPhone tabs, whatever its size`(_ windowSize: CGSize) {
    #expect(WindowLayout(windowSize: windowSize, horizontalSizeClass: .compact) == .tabs)
  }

  @Test
  func `A window with no size class, as on the Mac, lays out by its size`() {
    #expect(WindowLayout(windowSize: CGSize(width: 1376, height: 1032), horizontalSizeClass: nil) == .columns)
    #expect(WindowLayout(windowSize: CGSize(width: 800, height: 600), horizontalSizeClass: nil) == .sidebar)
  }
}
