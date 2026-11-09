//
//  ScheduleIndependenceTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Testing
@testable import IkaCore

struct ScheduleIndependenceTests {
  /// One part of a fixture broken in memory, and the sections that must fail because of it.
  struct Corruption: CustomTestStringConvertible {
    let fixture: Fixture
    /// Dot-separated keys and array indices, such as `data.xSchedules.nodes.3.startTime`.
    let path: String
    let replacement: Replacement
    let failed: Set<ScheduleFeed.Section>

    var testDescription: String { "\(path) \(replacement)" }
  }

  enum Replacement {
    /// A value of the wrong type: a node's time becomes a number, a list becomes a string.
    case wrongType
    /// An empty list.
    case emptyList
    /// The value removed: a key from its object, an element from its list.
    case removed
  }

  @Test(arguments: [
    Corruption(
      fixture: .normalDay,
      path: "data.regularSchedules.nodes.3.startTime",
      replacement: .wrongType,
      failed: [.rotations(.battle(.regular))]),
    Corruption(
      fixture: .normalDay,
      path: "data.bankaraSchedules",
      replacement: .wrongType,
      failed: [.rotations(.battle(.anarchySeries)), .rotations(.battle(.anarchyOpen))]),
    Corruption(
      fixture: .normalDay,
      path: "data.bankaraSchedules.nodes.5.bankaraMatchSettings.1",
      replacement: .removed,
      failed: [.rotations(.battle(.anarchyOpen))]),
    Corruption(
      fixture: .normalDay,
      path: "data.xSchedules.nodes",
      replacement: .emptyList,
      failed: [.rotations(.battle(.x))]),
    Corruption(
      fixture: .normalDay,
      path: "data.eventSchedules.nodes.1.timePeriods.0.endTime",
      replacement: .wrongType,
      failed: [.challenges]),
    Corruption(
      fixture: .normalDay,
      path: "data.eventSchedules.nodes",
      replacement: .emptyList,
      failed: [.challenges]),
    Corruption(
      fixture: .bigRun,
      path: "data.coopGroupingSchedule.bigRunSchedules.nodes.0.setting.coopStage",
      replacement: .wrongType,
      failed: [.salmonRun]),
    Corruption(
      fixture: .normalDay,
      path: "data.coopGroupingSchedule.regularSchedules.nodes",
      replacement: .emptyList,
      failed: [.salmonRun]),
    Corruption(
      fixture: .eggstraWork,
      path: "data.coopGroupingSchedule.teamContestSchedules.nodes.0.endTime",
      replacement: .wrongType,
      failed: [.eggstraWork]),
    Corruption(
      fixture: .splatfestSecondHalf,
      path: "data.festSchedules.nodes.0.festMatchSettings.1.vsRule",
      replacement: .wrongType,
      failed: [.rotations(.splatfestBattle(.open)), .rotations(.splatfestBattle(.pro))]),
    Corruption(
      fixture: .splatfestSecondHalf,
      path: "data.festSchedules.nodes.0.festMatchSettings.0",
      replacement: .removed,
      failed: [.rotations(.splatfestBattle(.pro))]),
    Corruption(
      fixture: .splatfestSecondHalf,
      path: "data.currentFest.midtermTime",
      replacement: .wrongType,
      failed: [.splatfest]),
  ])
  func `A corrupted part fails only the Schedules it holds and leaves every other Schedule intact`(
    _ corruption: Corruption)
    async throws
  {
    let original = try await ScheduleFeed.decode(from: corruption.fixture.data())
    let feed = try await ScheduleFeed.decode(from: corrupted(corruption))

    #expect(original.failedSections.isEmpty)
    #expect(feed.failedSections == corruption.failed)

    let modes = BattleMode.allCases.map(RotationMode.battle)
      + SplatfestBattleForm.allCases.map(RotationMode.splatfestBattle)
    for mode in modes {
      let expected = corruption.failed.contains(.rotations(mode)) ? [] : original.rotations(for: mode)
      #expect(feed.rotations(for: mode) == expected, "\(mode)")
    }
    #expect(feed.challenges == (corruption.failed.contains(.challenges) ? [] : original.challenges))
    #expect(feed.salmonRun == (corruption.failed.contains(.salmonRun) ? [] : original.salmonRun))
    #expect(feed.eggstraWork == (corruption.failed.contains(.eggstraWork) ? [] : original.eggstraWork))
    #expect(feed.currentSplatfest == (corruption.failed.contains(.splatfest) ? nil : original.currentSplatfest))
  }

  @Test
  func `A body that is not the schedules feed fails as a whole`() async {
    await #expect(throws: DecodingError.self) {
      try await ScheduleFeed.decode(from: Data("<html>Service Unavailable</html>".utf8))
    }
    await #expect(throws: DecodingError.self) {
      try await ScheduleFeed.decode(from: Data(#"{"errors": []}"#.utf8))
    }
  }

  /// The fixture's JSON with the value at the corruption's path replaced or removed.
  private func corrupted(_ corruption: Corruption) throws -> Data {
    let json = try JSONSerialization.jsonObject(with: corruption.fixture.data())
    let replacement: Any? =
      switch corruption.replacement {
        case .wrongType: 42
        case .emptyList: [Any]()
        case .removed: nil
      }
    let path = corruption.path.split(separator: ".").map(String.init)
    return try JSONSerialization.data(withJSONObject: replacing(in: json, at: path[...], with: replacement))
  }

  /// `json` with the value at `path` replaced, or removed when `replacement` is `nil`.
  private func replacing(in json: Any, at path: ArraySlice<String>, with replacement: Any?) -> Any {
    guard let key = path.first else { return replacement as Any }

    let isLast = path.count == 1
    if var object = json as? [String: Any], let child = object[key] {
      object[key] = isLast ? replacement : replacing(in: child, at: path.dropFirst(), with: replacement)
      return object
    }
    if var array = json as? [Any], let index = Int(key), array.indices.contains(index) {
      if isLast, replacement == nil {
        array.remove(at: index)
      }
      else {
        array[index] = replacing(in: array[index], at: path.dropFirst(), with: replacement)
      }
      return array
    }
    Issue.record("No value at \(path.joined(separator: "."))")
    return json
  }
}
