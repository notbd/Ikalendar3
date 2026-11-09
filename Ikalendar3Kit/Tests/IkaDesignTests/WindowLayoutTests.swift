//
//  WindowLayoutTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreGraphics
import Testing
@testable import IkaDesign

/// Pins how an iPad window lays out the Schedules: one column per Mode when it is wider than tall
/// and at least 1024 pt wide, otherwise a sidebar beside one detail column.
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
    #expect(WindowLayout(windowSize: CGSize(width: size.width, height: size.height)) == size.layout)
  }
}
