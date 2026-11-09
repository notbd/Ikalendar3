//
//  AdaptiveGlassTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI
import Testing
@testable import IkaDesign

/// Pins which glass the adaptive glass modifier picks for each colour scheme, as ikalendar 2 does.
struct AdaptiveGlassTests {
  @Test
  func `Dark appearance uses clear glass, because regular glass washes out there`() {
    #expect(AdaptiveGlassVariant(colorScheme: .dark) == .clear)
  }

  @Test
  func `Light appearance uses regular glass`() {
    #expect(AdaptiveGlassVariant(colorScheme: .light) == .regular)
  }
}
