//
//  SelectedTabColorTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI
import Testing
@testable import Ikalendar3

// MARK: - SelectedTabColorTests

/// Pins the selected tab's colour on the glass each rule assumes, for every Style, appearance and
/// tab, so a Style or appearance the rule forgets shows as a failing row.
struct SelectedTabColorTests {
  @Test(arguments: SelectedTabCase.all)
  func `The selected tab's label reads 4.5 to 1 and its icon 3 to 1 on the glass behind it`(row: SelectedTabCase) {
    let colorScheme: ColorScheme = row.isDark ? .dark : .light
    let barScheme: ColorScheme = AppTab.barColorScheme(style: row.style, in: colorScheme)
    let glass: SRGBColor = AppTab.selectedGlass(style: row.style, in: barScheme)
    // The bar draws a primary label in its own appearance.
    let primary: SRGBColor = barScheme == .dark ? .white : .black

    switch row.tab.selectedColor(style: row.style, in: colorScheme) {
      case .tint(let color):
        #expect(color.contrastRatio(with: glass) >= ContrastTarget.text.minimumRatio)

      case .icon(let color):
        #expect(primary.contrastRatio(with: glass) >= ContrastTarget.text.minimumRatio)
        #expect(color.contrastRatio(with: glass) >= ContrastTarget.largeTextAndIcons.minimumRatio)

      case .primary:
        #expect(primary.contrastRatio(with: glass) >= ContrastTarget.text.minimumRatio)
    }
  }

  @Test(arguments: SelectedTabCase.all)
  func `Each Style and appearance takes its treatment of the selected tab`(row: SelectedTabCase) {
    let color = row.tab.selectedColor(style: row.style, in: row.isDark ? .dark : .light)

    switch (row.tab, row.style, row.isDark) {
      case (.splatfest, _, _):
        #expect(color == .primary)

      case (_, .ink, false),
           (_, .timeline, false):
        guard case .icon = color else {
          Issue.record("\(color) is not a primary label with a coloured icon")
          return
        }

      default:
        guard case .tint = color else {
          Issue.record("\(color) is not a tint")
          return
        }
    }
  }
}

// MARK: - SelectedTabCase

/// One row: a Style, an appearance and a tab.
nonisolated struct SelectedTabCase: CustomTestStringConvertible {
  let style: Style
  let isDark: Bool
  let tab: AppTab

  var testDescription: String {
    "\(style) \(isDark ? "dark" : "light") \(tab)"
  }

  /// Every Style in both appearances with every tab, the Splatfest tab included.
  static let all: [SelectedTabCase] = Style.allCases.flatMap { style in
    [false, true].flatMap { isDark in
      (ModeTab.allCases.map(AppTab.mode) + [.splatfest]).map { SelectedTabCase(style: style, isDark: isDark, tab: $0) }
    }
  }
}
