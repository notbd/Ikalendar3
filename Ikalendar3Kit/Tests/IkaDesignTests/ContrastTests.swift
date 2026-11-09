//
//  ContrastTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Testing
@testable import IkaDesign

/// Pins WCAG 2's contrast ratio and the tint that makes a colour readable on a background.
struct ContrastTests {
  @Test
  func `Contrast ratio matches WCAG's published values`() {
    #expect(abs(SRGBColor.black.contrastRatio(with: .white) - 21) < 1e-9)
    #expect(SRGBColor.white.contrastRatio(with: .white) == 1)
    // WebAIM's checker: #767676 is the lightest grey that passes 4.5:1 on white, #777777 fails.
    #expect(abs(SRGBColor(hex: 0x767676).contrastRatio(with: .white) - 4.54) < 0.005)
    #expect(abs(SRGBColor(hex: 0x777777).contrastRatio(with: .white) - 4.48) < 0.005)
  }

  @Test
  func `Contrast ratio is the same in both directions`() {
    let orange: SRGBColor = .init(hex: 0xF54910)
    let panel: SRGBColor = .init(hex: 0x383838)

    #expect(orange.contrastRatio(with: panel) == panel.contrastRatio(with: orange))
  }

  @Test
  func `A colour that already reaches the target is kept`() {
    let green: SRGBColor = .init(hex: 0x0FDB9B)

    #expect(green.readableTint(on: Self.darkPanel, for: .text) == green)
  }

  @Test
  func `Too dark a colour on a dark panel turns just light enough, keeping its hue`() {
    let orange: SRGBColor = .init(hex: 0xF54910)
    #expect(orange.contrastRatio(with: Self.darkPanel) < 4.5)

    let tint: SRGBColor = orange.readableTint(on: Self.darkPanel, for: .text)

    #expect(tint.contrastRatio(with: Self.darkPanel) >= 4.5)
    #expect(tint.contrastRatio(with: Self.darkPanel) < 4.6)
    #expect(tint.relativeLuminance > orange.relativeLuminance)
    #expect(tint.red > tint.green && tint.green > tint.blue)
  }

  @Test
  func `Too light a colour on a light panel turns just dark enough, keeping its hue`() {
    let yellow: SRGBColor = .init(hex: 0xEAFF3E)

    let tint: SRGBColor = yellow.readableTint(on: .white, for: .text)

    #expect(tint.contrastRatio(with: .white) >= 4.5)
    #expect(tint.contrastRatio(with: .white) < 4.6)
    #expect(tint.relativeLuminance < yellow.relativeLuminance)
    #expect(tint.green > tint.red && tint.red > tint.blue)
  }

  @Test
  func `Large text and icons need 3 to 1, text 4.5 to 1`() {
    let orange: SRGBColor = .init(hex: 0xF54910)

    #expect(ContrastTarget.text.minimumRatio == 4.5)
    #expect(ContrastTarget.largeTextAndIcons.minimumRatio == 3)
    // Anarchy's orange already reaches 3:1 on the dark panel, so icons keep it.
    #expect(orange.readableTint(on: Self.darkPanel, for: .largeTextAndIcons) == orange)
  }

  @Test(arguments: [0x050505, 0x808080, 0xFAFAFA, 0x000000, 0xFFFFFF] as [UInt32])
  func `Greys from black to white reach the target on dark and light panels`(hex: UInt32) {
    for panel: SRGBColor in [Self.darkPanel, .black, .white, SRGBColor(hex: 0xF2F2F7)] {
      let tint: SRGBColor = .init(hex: hex).readableTint(on: panel, for: .text)

      #expect(tint.contrastRatio(with: panel) >= 4.5, "\(SRGBColor(hex: hex)) on \(panel) gives \(tint)")
    }
  }

  /// The in-game board panel, #383838.
  static private let darkPanel: SRGBColor = .init(hex: 0x383838)
}
