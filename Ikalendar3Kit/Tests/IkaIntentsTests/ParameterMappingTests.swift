//
//  ParameterMappingTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import Testing
@testable import IkaIntents

struct ParameterMappingTests {
  @Test
  func `Each Mode maps to its own parameter and back`() {
    #expect(Mode.allCases.map { ModeParameter($0).mode } == Mode.allCases)
    #expect(ModeParameter.allCases.map(\.mode) == Mode.allCases)
  }

  @Test
  func `Each Battle Mode maps to its own parameter and back`() {
    #expect(BattleMode.allCases.map { BattleModeParameter($0).battleMode } == BattleMode.allCases)
    #expect(BattleModeParameter.allCases.map(\.battleMode) == BattleMode.allCases)
  }

  /// Pinned: each Rule is Nintendo's id for it, the id the feeds and locale files key it by.
  @Test
  func `Each Rule is Nintendo's id for it`() {
    #expect(RuleParameter.allCases.map(\.rule.rawValue) == [
      "VnNSdWxlLTA=", // VsRule-0, Turf War
      "VnNSdWxlLTE=", // VsRule-1, Splat Zones
      "VnNSdWxlLTI=", // VsRule-2, Tower Control
      "VnNSdWxlLTM=", // VsRule-3, Rainmaker
      "VnNSdWxlLTQ=", // VsRule-4, Clam Blitz
    ])
  }

  /// Pinned: widget and control configurations store the raw values, so renaming one resets
  /// every configuration that chose it.
  @Test
  func `Stored raw values never change`() {
    #expect(ModeParameter.allCases.map(\.rawValue) == [
      "regularBattle", "anarchySeries", "anarchyOpen", "xBattle", "salmonRun",
    ])
    #expect(BattleModeParameter.allCases.map(\.rawValue) == [
      "regularBattle", "anarchySeries", "anarchyOpen", "xBattle",
    ])
    #expect(RuleParameter.allCases.map(\.rawValue) == [
      "turfWar", "splatZones", "towerControl", "rainmaker", "clamBlitz",
    ])
  }
}
