//
//  DetailLayoutTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI
import Testing
@testable import IkaDesign

// MARK: - DetailLayoutTests

/// Pins how a Mode's detail lays out by its own width: the iPhone list below 540 pt, the wide
/// detail from there, stopping at 980 pt and centred, and the iPhone list again at large text;
/// and that a place that chose the list gets it at any width.
struct DetailLayoutTests {
  private func layout(width: CGFloat, dynamicTypeSize: DynamicTypeSize = .large) -> DetailLayout {
    .init(width: width, dynamicTypeSize: dynamicTypeSize)
  }

  @Test(arguments: [0, 320, 375, 440, 539.5] as [CGFloat])
  func `A detail narrower than 540 pt uses the iPhone list`(width: CGFloat) {
    #expect(layout(width: width) == .list)
  }

  @Test
  func `A detail 540 pt wide uses the wide detail at its full width`() {
    guard case .wide(let wide) = layout(width: 540) else {
      Issue.record("540 pt is wide")
      return
    }

    #expect(wide.columnWidth == 540)
    #expect(wide.sideMargin == 0)
  }

  @Test
  func `The wide detail grows with the detail up to 980 pt`() {
    guard case .wide(let wide) = layout(width: 980) else {
      Issue.record("980 pt is wide")
      return
    }

    #expect(wide.columnWidth == 980)
    #expect(wide.sideMargin == 0)
  }

  @Test
  func `The wide detail stops at 980 pt and is centred in a wider detail`() {
    guard case .wide(let wide) = layout(width: 1366) else {
      Issue.record("1366 pt is wide")
      return
    }

    #expect(wide.columnWidth == 980)
    #expect(wide.sideMargin == 193)
  }

  @Test(arguments: [320, 540, 700, 1366] as [CGFloat])
  func `A place that chose the list gets the list at any width`(width: CGFloat) {
    #expect(DetailLayout(.list, width: width, dynamicTypeSize: .large) == .list)
    #expect(DetailLayout(.byWidth, width: width, dynamicTypeSize: .large) == layout(width: width))
  }

  /// The Salmon Run event sheet is a form sheet, 540 pt wide on iPad: it must show the list there
  /// because its place chose it, not because of its width.
  @MainActor
  @Test
  func `A reader shows the layout its place chose`() throws {
    let byWidth = try layouts(width: 700) { $0 }
    let chosen = try layouts(width: 700) { $0.detailLayout(.list) }

    #expect(byWidth.allSatisfy { if case .wide = $0 { true } else { false } })
    #expect(!byWidth.isEmpty)
    #expect(!chosen.isEmpty)
    #expect(chosen.allSatisfy { $0 == .list })
  }

  @Test(arguments: [DynamicTypeSize.accessibility1, .accessibility5])
  func `Large text uses the iPhone list at any width`(size: DynamicTypeSize) {
    #expect(layout(width: 1366, dynamicTypeSize: size) == .list)
  }

  @Test
  func `Each half of the wide row sizes its parts as a cell half the column wide`() {
    guard case .wide(let narrow) = layout(width: 540), case .wide(let capped) = layout(width: 2000) else {
      Issue.record("both widths are wide")
      return
    }

    #expect(narrow.half.referenceWidth == 270)
    #expect(capped.half.referenceWidth == 490)
    #expect(capped.half.arrangement == .sideBySide)
  }

  /// The layouts a reader gives its content when it is rendered `width` points wide, in the place
  /// `place` puts it.
  @MainActor
  private func layouts(width: CGFloat, place: (AnyView) -> some View) throws -> [DetailLayout] {
    let log: LayoutLog = .init()
    let reader = DetailLayoutReader { layout -> Color in
      log.layouts.append(layout)
      return .clear
    }
    let renderer: ImageRenderer = .init(content: place(AnyView(reader.frame(width: width, height: 100))))
    _ = try #require(renderer.cgImage)
    return log.layouts
  }
}

// MARK: - LayoutLog

/// The layouts a reader handed its content, in order.
@MainActor
final private class LayoutLog {
  var layouts: [DetailLayout] = []
}
