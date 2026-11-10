//
//  TeamColorTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import SwiftUI
import Testing
@testable import IkaDesign

/// Pins that text in a Splatfest team's colour stays readable on every Style's panel after its
/// run-time tint, for every team colour the recorded payloads hold and for colours none holds.
struct TeamColorTests {
  /// Every panel a team colour sits on: each Style's, in light and dark appearance.
  static private let panels: [SRGBColor] = Style.allCases.flatMap { style in
    ColorScheme.allCases.map { style.panel(in: $0) }
  }

  @Test
  func `Feed team colours convert to 8-bit channels`() async throws {
    let file: URL = Self.fixtures.appending(path: "schedules-2026-11-01-splatfest-second-half.json")
    let schedules: ScheduleFeed = try await ScheduleFeed.decode(from: Data(contentsOf: file))
    let snapshot: Snapshot = .init(schedules: .init(content: schedules, fetchTime: .now))
    let splatfest: Splatfest = try #require(snapshot.splatfest)

    #expect(splatfest.teamColors.map(SRGBColor.init) == [
      SRGBColor(hex: 0x0CA34B),
      SRGBColor(hex: 0xB04F23),
      SRGBColor(hex: 0x964996),
    ])
  }

  @Test
  func `Every fixture team colour reaches 4.5 to 1 as text after its tint`() throws {
    let teamColors: Set<SRGBColor> = try Self.fixtureTeamColors()
    // Checks that the payloads were read: the first Splatfest's Team Gear, and the 68 distinct
    // colours `jq` counts in the payloads of 2026-11-01.
    #expect(teamColors.contains(SRGBColor(hex: 0x8A19F8)))
    #expect(teamColors.count >= 68)

    for teamColor in teamColors {
      for panel in Self.panels {
        let tint: SRGBColor = teamColor.readableTint(on: panel, for: .text)

        #expect(tint.contrastRatio(with: panel) >= 4.5, "\(teamColor) on \(panel) gives \(tint)")
      }
    }
  }

  @Test(arguments: [0x0A0A0A, 0x1A0F2E, 0x7F7F7F, 0x6A8A4F, 0xF5F5F5, 0xFFFBE0] as [UInt32])
  func `Made-up team colours from near black to near white reach 4.5 to 1 after the tint`(hex: UInt32) {
    for panel in Self.panels {
      let tint: SRGBColor = .init(hex: hex).readableTint(on: panel, for: .text)

      #expect(tint.contrastRatio(with: panel) >= 4.5, "\(SRGBColor(hex: hex)) on \(panel) gives \(tint)")
    }
  }

  /// `Ikalendar3Kit/Fixtures`, found from this file's place in the package.
  static private let fixtures: URL = .init(filePath: #filePath)
    .deletingLastPathComponent() // IkaDesignTests
    .deletingLastPathComponent() // Tests
    .deletingLastPathComponent() // Ikalendar3Kit
    .appending(path: "Fixtures", directoryHint: .isDirectory)

  /// Every colour object (`r`, `g`, `b`) in the recorded payloads: the team colours of every
  /// Splatfest in `festivals.json` and of each schedules feed's current Splatfest.
  static private func fixtureTeamColors() throws -> Set<SRGBColor> {
    func colors(in value: Any) -> [SRGBColor] {
      switch value {
        case let object as [String: Any]:
          if let red = object["r"] as? Double, let green = object["g"] as? Double, let blue = object["b"] as? Double {
            return [SRGBColor(red: red, green: green, blue: blue)]
          }
          return object.values.flatMap(colors)

        case let array as [Any]:
          return array.flatMap(colors)

        default:
          return []
      }
    }

    let files: [URL] = try FileManager.default.contentsOfDirectory(at: fixtures, includingPropertiesForKeys: nil)
    return try Set(files.filter { $0.pathExtension == "json" }.flatMap { file in
      try colors(in: JSONSerialization.jsonObject(with: Data(contentsOf: file)))
    })
  }
}
