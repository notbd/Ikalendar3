//
//  CellMetricsTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI
import Testing
@testable import IkaDesign

/// Pins how a cell sizes its parts: shares of the cell's width between a 200 pt floor and a
/// 500 pt ceiling, and the stacked layout from the first accessibility text size.
struct CellMetricsTests {
  private func metrics(width: CGFloat, dynamicTypeSize: DynamicTypeSize = .large) -> CellMetrics {
    .init(width: width, dynamicTypeSize: dynamicTypeSize)
  }

  @Test
  func `Sizes are shares of the cell width between the floor and the ceiling`() {
    #expect(metrics(width: 200).length(.init(0.45)) == 90)
    #expect(metrics(width: 400).length(.init(0.45)) == 180)
    #expect(metrics(width: 500).length(.init(0.45)) == 225)
  }

  @Test(arguments: [200, 260, 343, 390, 440, 500] as [CGFloat])
  func `Proportions between parts hold at every width in range`(width: CGFloat) {
    let cell: CellMetrics = metrics(width: width)

    let ratio: CGFloat = cell.length(.battleRuleSectionWidth) / cell.length(.battleRuleSectionHeight)

    #expect(abs(ratio - 0.45 / 0.115) < 1e-9)
  }

  @Test
  func `Sizes stop shrinking below the floor`() {
    #expect(metrics(width: 120).length(.init(0.5)) == 100)
    #expect(metrics(width: 0).length(.init(0.5)) == 100)
  }

  @Test
  func `Sizes stop growing above the ceiling`() {
    #expect(metrics(width: 980).length(.init(0.5)) == 250)
    #expect(metrics(width: .infinity).length(.init(0.5)) == 250)
  }

  @Test(arguments: DynamicTypeSize.allCases)
  func `Cells stack from the first accessibility text size`(size: DynamicTypeSize) {
    let expected: CellArrangement = size >= .accessibility1 ? .stacked : .sideBySide

    #expect(metrics(width: 390, dynamicTypeSize: size).arrangement == expected)
  }

  @Test
  func `Side by side text shrinks on one line and stacked text wraps at full size`() {
    #expect(CellArrangement.sideBySide.lineLimit == 1)
    #expect(CellArrangement.sideBySide.minimumScaleFactor == 0.3)
    #expect(CellArrangement.stacked.lineLimit == nil)
    #expect(CellArrangement.stacked.minimumScaleFactor == 1)
  }
}
