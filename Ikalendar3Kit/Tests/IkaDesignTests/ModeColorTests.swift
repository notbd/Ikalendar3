//
//  ModeColorTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI
import Testing
@testable import IkaDesign

/// Pins SplatNet 3's Mode colours and that every pair the palette hands a view is readable, for
/// every Style in light and dark appearance.
struct ModeColorTests {
  @Test
  func `Palette holds SplatNet 3's colours`() {
    #expect(ModeColor.regularBattle.base == SRGBColor(hex: 0xEAFF3E))
    #expect(ModeColor.anarchy.base == SRGBColor(hex: 0xF54910))
    #expect(ModeColor.xBattle.base == SRGBColor(hex: 0x0FDB9B))
    #expect(ModeColor.challenge.base == SRGBColor(hex: 0xF02D7D))
    #expect(ModeColor.salmonRun.base == SRGBColor(hex: 0xFF5033))
    #expect(ModeColor.bigRun.base == SRGBColor(hex: 0xB322FF))
    #expect(ModeColor.eggstraWork.base == SRGBColor(hex: 0xFDD400))
  }

  @Test
  func `Every Mode takes its colour, both Anarchy forms the same`() {
    #expect(ModeColor(.battle(.regular)) == .regularBattle)
    #expect(ModeColor(.battle(.anarchySeries)) == .anarchy)
    #expect(ModeColor(.battle(.anarchyOpen)) == .anarchy)
    #expect(ModeColor(.battle(.x)) == .xBattle)
    #expect(ModeColor(.salmonRun) == .salmonRun)
  }

  /// A view draws the colour with the icon, so one kind reads alike in both.
  @Test
  func `Every colour's kind has an icon of the same case name`() {
    let iconNames = Set(ModeIcon.allCases.map { String(describing: $0) })

    #expect(ModeColor.allCases.allSatisfy { iconNames.contains(String(describing: $0)) })
  }

  @Test
  func `Big Run and Eggstra Work take their own colours, regular Shifts Salmon Run's`() {
    #expect(ModeColor(Shift.Kind.regular) == .salmonRun)
    #expect(ModeColor(Shift.Kind.bigRun) == .bigRun)
    #expect(ModeColor(Shift.Kind.eggstraWork) == .eggstraWork)
  }

  @Test(arguments: ModeColor.allCases, Style.allCases)
  func `Mode colour on every Style's panel reaches its target in both appearances`(
    modeColor: ModeColor,
    style: Style)
  {
    for colorScheme: ColorScheme in ColorScheme.allCases {
      for target: ContrastTarget in ContrastTarget.allCases {
        let pair: ColorPair = modeColor.onPanel(of: style, in: colorScheme, for: target)

        #expect(pair.background == style.panel(in: colorScheme))
        #expect(
          pair.contrastRatio >= target.minimumRatio,
          "\(pair.foreground) on \(pair.background) (\(colorScheme), \(target)): \(pair.contrastRatio)")
      }
    }
  }

  @Test
  func `Mode colour that is readable on the panel is drawn as is`() {
    let pair: ColorPair = ModeColor.xBattle.onPanel(of: .ink, in: .dark, for: .text)

    #expect(pair.foreground == ModeColor.xBattle.base)
  }

  @Test
  func `Anarchy text on Ink's dark panel needs a tint, as the spec's #ff7a45 example shows`() {
    let panel: SRGBColor = Style.ink.panel(in: .dark)

    #expect(ModeColor.anarchy.base.contrastRatio(with: panel) < 4.5)
    #expect(SRGBColor(hex: 0xFF7A45).contrastRatio(with: panel) >= 4.5)
    #expect(ModeColor.anarchy.onPanel(of: .ink, in: .dark, for: .text).foreground != ModeColor.anarchy.base)
  }

  @Test(arguments: ModeColor.allCases)
  func `Text on a Mode-colour fill is black or white and reaches 4.5 to 1`(modeColor: ModeColor) {
    let pair: ColorPair = modeColor.asFill

    #expect(pair.background == modeColor.base)
    #expect([SRGBColor.black, .white].contains(pair.foreground))
    #expect(pair.contrastRatio >= ContrastTarget.text.minimumRatio, "\(pair.foreground) on \(pair.background)")
  }

  @Test
  func `Regular Battle's yellow carries black text`() {
    #expect(ModeColor.regularBattle.asFill.foreground == .black)
  }

  @Test
  func `Ink and Timeline keep their dark panels in light appearance, Classic follows it`() {
    #expect(Style.ink.panel(in: .light) == Style.ink.panel(in: .dark))
    #expect(Style.timeline.panel(in: .light) == Style.timeline.panel(in: .dark))
    #expect(Style.classic.panel(in: .light).relativeLuminance > 0.5)
    #expect(Style.classic.panel(in: .dark).relativeLuminance < 0.05)
  }
}
