//
//  Fixture.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - Fixture

/// A recorded splatoon3.ink payload in the package's `Fixtures` folder, read by path so every
/// target that needs one reads the same copy. The schedules feeds are byte for byte the hourly
/// archive's snapshot (`data-archive.splatoon3.ink`) of the hour named, except the live one.
enum Fixture: String, CaseIterable {
  /// A normal day: the archive's 2026-10-20 12:00 UTC.
  case normalDay = "schedules-2026-10-20-normal-day.json"
  /// A Splatfest in its second half, fetched live 2026-11-01 05:23 UTC.
  case splatfestSecondHalf = "schedules-2026-11-01-splatfest-second-half.json"
  /// A Splatfest's last hours: the archive's 2026-08-23 20:00 UTC.
  case splatfestEnd = "schedules-2026-08-23-splatfest-end.json"
  /// A Big Run announced: the archive's 2026-09-07 12:00 UTC.
  case bigRun = "schedules-2026-09-07-big-run.json"
  /// An Eggstra Work announced: the archive's 2026-08-28 12:00 UTC.
  case eggstraWork = "schedules-2026-08-28-eggstra-work.json"
  /// The Splatfest of 2026-10-31 00:00 UTC announced: the archive's 2026-10-30 12:00 UTC.
  case splatfestAnnounced = "schedules-2026-10-30-splatfest-announced.json"
  /// That Splatfest's first half: the archive's 2026-10-31 12:00 UTC.
  case splatfestFirstHalf = "schedules-2026-10-31-splatfest-first-half.json"
  /// `festivals.json`, fetched 2026-11-01.
  case festivals = "festivals-2026-11-01.json"
  /// Locale files, fetched 2026-11-01.
  case localeEnUS = "locale-2026-11-01-en-US.json"
  case localeJaJP = "locale-2026-11-01-ja-JP.json"
  case localeKoKR = "locale-2026-11-01-ko-KR.json"
  case localeZhCN = "locale-2026-11-01-zh-CN.json"
  case localeZhTW = "locale-2026-11-01-zh-TW.json"

  /// `Ikalendar3Kit/Fixtures`, found from this file's place in the package.
  static let folder: URL = .init(filePath: #filePath)
    .deletingLastPathComponent() // IkaCoreTests
    .deletingLastPathComponent() // Tests
    .deletingLastPathComponent() // Ikalendar3Kit
    .appending(path: "Fixtures", directoryHint: .isDirectory)

  var url: URL { Self.folder.appending(path: rawValue) }

  func data() throws -> Data { try Data(contentsOf: url) }
}
