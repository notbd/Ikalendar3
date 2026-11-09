//
//  BundledImageAlignmentTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreGraphics
import Foundation
import Testing
@testable import IkaCore
@testable import IkaDesign

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

// MARK: - BundledImageAlignmentTests

/// Every manifest id must have its image in the built catalog at each of the three sizes, and
/// every id the recorded feeds carry must be in the manifest: a missing image ships as a
/// placeholder, and nothing else would notice. The manifest and the fixtures are read by path.
struct BundledImageAlignmentTests {
  @Test
  func `The manifest's groups are the lookup's groups`() throws {
    #expect(try Manifest.load().groups.map(\.key) == BundledImage.Group.allCases.map(\.rawValue))
  }

  @Test(arguments: BundledImage.Group.allCases)
  func `Every manifest image is in the catalog at each size, within its group's pixels`(
    bundleGroup: BundledImage.Group)
    throws
  {
    let group: Manifest.Group = try #require(Manifest.load().groups.first { $0.key == bundleGroup.rawValue })
    #expect(!group.images.isEmpty)

    for id in group.images.map(\.id) {
      #expect(BundledImage.baseNames[bundleGroup]?[id] != nil, "\(group.key) \(id) is not in the index")
      for size in BundledImage.Size.allCases {
        let name: String = BundledImage.name(of: id, in: bundleGroup, size: size)
        let pixels: CGSize = try #require(pixelSize(of: name), "\(name) is not in the catalog")
        let box: [Int] = try #require(group.sizes[size.rawValue])
        #expect(Int(pixels.width) <= box[0] && Int(pixels.height) <= box[1], "\(name) is \(pixels)")
      }
    }
  }

  @Test(arguments: BundledImage.Group.allCases)
  func `Every group's placeholder is in the catalog`(group: BundledImage.Group) {
    for size in BundledImage.Size.allCases {
      #expect(pixelSize(of: "placeholder-\(group.rawValue)_\(size.rawValue)") != nil)
    }
  }

  @Test
  func `Every Stage, weapon, Rule and King Salmonid in the fixtures is in the manifest`() async throws {
    var stages: Set<StageID> = []
    var weapons: Set<WeaponID> = []
    var rules: Set<RuleID> = []
    var kingSalmonids: Set<KingSalmonidID> = []

    for url in try Self.scheduleFixtures() {
      let feed: ScheduleFeed = try await .decode(from: Data(contentsOf: url))
      let settings: [Rotation.Setting] = (BattleMode.allCases.map(RotationMode.battle)
        + SplatfestBattleForm.allCases.map(RotationMode.splatfestBattle))
        .flatMap(feed.rotations(for:))
        .compactMap(\.setting)
      let shifts: [Shift] = feed.salmonRun + feed.eggstraWork

      stages.formUnion(settings.flatMap(\.stages) + feed.challenges.flatMap(\.stages) + shifts.map(\.stage))
      stages.formUnion(feed.currentSplatfest?.splatfest.tricolorStages ?? [])
      weapons.formUnion(shifts.flatMap(\.weapons))
      rules.formUnion(settings.map(\.rule) + feed.challenges.map(\.rule))
      kingSalmonids.formUnion(shifts.compactMap(\.kingSalmonid))
    }
    #expect(!stages.isEmpty && !weapons.isEmpty && !rules.isEmpty && !kingSalmonids.isEmpty)

    let manifestIDs: [String: Set<String>] = try Manifest.load().groups.reduce(into: [:]) { ids, group in
      ids[group.key] = Set(group.images.map(\.id))
    }
    #expect(Set(stages.map(\.rawValue)).subtracting(manifestIDs["stage"] ?? []).isEmpty)
    #expect(Set(weapons.map(\.rawValue)).subtracting(manifestIDs["weapon"] ?? []).isEmpty)
    #expect(Set(rules.map(\.rawValue)).subtracting(manifestIDs["rule"] ?? []).isEmpty)
    #expect(Set(kingSalmonids.map(\.rawValue)).subtracting(manifestIDs["king-salmonid"] ?? []).isEmpty)
  }

  /// Every `schedules-*.json` in the package's `Fixtures` folder.
  static private func scheduleFixtures() throws -> [URL] {
    let folder: URL = Manifest.packageFolder.appending(path: "Fixtures", directoryHint: .isDirectory)
    return try FileManager.default
      .contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
      .filter { $0.lastPathComponent.hasPrefix("schedules-") && $0.pathExtension == "json" }
  }

  /// The pixel size of a catalog image in the built catalog.
  private func pixelSize(of name: String) -> CGSize? {
    #if canImport(UIKit)
    let image: CGImage? = UIImage(named: name, in: BundledImage.catalogBundle, with: nil)?.cgImage
    #else
    let image: CGImage? = BundledImage.catalogBundle
      .image(forResource: name)?
      .cgImage(forProposedRect: nil, context: nil, hints: nil)
    #endif
    return image.map { CGSize(width: $0.width, height: $0.height) }
  }
}

// MARK: - Manifest

/// The parts of `scripts/assets/manifest.json` these tests read.
struct Manifest: Decodable {
  struct Group: Decodable {
    let key: String
    /// `small`, `medium` and `large`, each `[width, height]` in pixels.
    let sizes: [String: [Int]]
    let images: [Image]
  }

  struct Image: Decodable {
    let id: String
  }

  struct FontFile: Decodable {
    let name: String
  }

  /// `Ikalendar3Kit`, found from this file's place in the package.
  static let packageFolder: URL = .init(filePath: #filePath)
    .deletingLastPathComponent() // IkaDesignTests
    .deletingLastPathComponent() // Tests
    .deletingLastPathComponent() // Ikalendar3Kit

  let groups: [Group]
  /// The font files the script builds, one per face.
  let fonts: [FontFile]

  static func load() throws -> Manifest {
    let url: URL = packageFolder.deletingLastPathComponent().appending(path: "scripts/assets/manifest.json")
    return try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: url))
  }
}
