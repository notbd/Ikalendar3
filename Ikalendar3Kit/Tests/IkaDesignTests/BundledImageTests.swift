//
//  BundledImageTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import IkaDesign

/// Pins the bundled image lookup: names carry the decoded feed id and the size, and an id with
/// no bundled image gets its group's placeholder.
struct BundledImageTests {
  @Test
  func `Names carry the decoded feed id and the size`() {
    #expect(BundledImage.name(for: StageID("VnNTdGFnZS0x"), size: .small) == "vsstage-1_small")
    #expect(BundledImage.name(for: StageID("Q29vcFN0YWdlLS0x"), size: .large) == "coopstage-minus1_large")
    #expect(BundledImage.name(for: RuleID("VnNSdWxlLTQ="), size: .medium) == "vsrule-4_medium")
    #expect(BundledImage.name(for: KingSalmonidID("Q29vcEVuZW15LTMw"), size: .small) == "coopenemy-30_small")
    #expect(BundledImage.name(for: WeaponID("e60629ecf35192a1"), size: .large) == "weapon-e60629ecf35192a1_large")
    #expect(BundledImage.name(for: .rareRandom, size: .medium) == "weapon-747937841598fff7_medium")
  }

  @Test
  func `Each Mode has its icon, and both Anarchy Battle Modes share one`() {
    let expected: [Mode: String] = [
      .battle(.regular): "mode-regular_small",
      .battle(.anarchySeries): "mode-anarchy_small",
      .battle(.anarchyOpen): "mode-anarchy_small",
      .battle(.x): "mode-x_small",
      .salmonRun: "mode-salmon-run_small",
    ]

    for mode in Mode.allCases {
      #expect(BundledImage.name(for: ModeIcon(mode), size: .small) == expected[mode])
    }
  }

  @Test(arguments: ModeIcon.allCases)
  func `Every Mode icon is bundled`(icon: ModeIcon) {
    #expect(BundledImage.baseNames[.mode]?[icon.rawValue] != nil)
  }

  @Test(arguments: BundledImage.Size.allCases)
  func `An id with no bundled image gets its group's placeholder`(size: BundledImage.Size) {
    #expect(BundledImage.name(for: StageID("VnNTdGFnZS05OTk="), size: size) == "placeholder-stage_\(size)")
    #expect(BundledImage.name(for: WeaponID("0000000000000000"), size: size) == "placeholder-weapon_\(size)")
    #expect(BundledImage.name(for: RuleID("VnNSdWxlLTk5"), size: size) == "placeholder-rule_\(size)")
    #expect(
      BundledImage.name(for: KingSalmonidID("Q29vcEVuZW15LTk5"), size: size)
        == "placeholder-king-salmonid_\(size)")
  }
}
