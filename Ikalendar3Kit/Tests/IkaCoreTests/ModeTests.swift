//
//  ModeTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Testing
@testable import IkaCore

struct ModeTests {
  /// Pinned: every Surface that lists the Modes lists them in this order.
  @Test
  func `The five Modes are the four continuous Battle Modes, then Salmon Run`() {
    #expect(Mode.allCases == [
      .battle(.regular),
      .battle(.anarchySeries),
      .battle(.anarchyOpen),
      .battle(.x),
      .salmonRun,
    ])
  }

  /// Pinned: each raw value names the locale file fetched for that text set.
  @Test
  func `The 14 game text sets are named by splatoon3 ink's locale codes`() {
    #expect(GameLanguage.allCases.map(\.rawValue) == [
      "en-US", "en-GB", "es-ES", "es-MX", "fr-FR", "fr-CA", "de-DE",
      "it-IT", "nl-NL", "ru-RU", "ja-JP", "ko-KR", "zh-CN", "zh-TW",
    ])
  }
}
