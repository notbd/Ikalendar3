//
//  BundledImageAlignmentTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import IkaCore
@testable import IkaDesign

// MARK: - BundledImageAlignmentTests

/// Every manifest id must have its image in the asset catalog at each of the three sizes, and
/// every id the recorded feeds carry must be in the manifest: a missing image ships as a
/// placeholder, and nothing else would notice. The manifest, the catalog and the fixtures are read
/// by path: the catalog ships in the app's resource framework, which no package test links.
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
    let files: [String: URL] = try Catalog.imageFiles()
    #expect(!group.images.isEmpty)

    for id in group.images.map(\.id) {
      #expect(BundledImage.baseNames[bundleGroup]?[id] != nil, "\(group.key) \(id) is not in the index")
      for size in BundledImage.Size.allCases {
        let name: String = BundledImage.name(of: id, in: bundleGroup, size: size)
        let pixels: CGSize = try #require(files[name].flatMap(pixelSize(of:)), "\(name) is not in the catalog")
        let box: [Int] = try #require(group.sizes[size.rawValue])
        #expect(Int(pixels.width) <= box[0] && Int(pixels.height) <= box[1], "\(name) is \(pixels)")
      }
    }
  }

  @Test(arguments: BundledImage.Group.allCases)
  func `Every group's placeholder is in the catalog`(group: BundledImage.Group) throws {
    let files: [String: URL] = try Catalog.imageFiles()
    for size in BundledImage.Size.allCases {
      #expect(files["placeholder-\(group.rawValue)_\(size.rawValue)"].flatMap(pixelSize(of:)) != nil)
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

  /// The pixel size of the image file at `url`.
  private func pixelSize(of url: URL) -> CGSize? {
    guard
      let source = CGImageSourceCreateWithURL(url as CFURL, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let width = properties[kCGImagePropertyPixelWidth] as? Int,
      let height = properties[kCGImagePropertyPixelHeight] as? Int
    else {
      return nil
    }

    return CGSize(width: width, height: height)
  }
}

// MARK: - Catalog

/// The asset catalog `scripts/assets.sh` writes, read from its folder.
enum Catalog {
  /// The parts of an image set's `Contents.json` these tests read.
  private struct ImageSet: Decodable {
    struct Image: Decodable {
      let filename: String?
    }

    let images: [Image]
  }

  /// `IkaResources/Images.xcassets` in the repository.
  static let folder: URL = Manifest.packageFolder
    .deletingLastPathComponent()
    .appending(path: "IkaResources/Images.xcassets", directoryHint: .isDirectory)

  /// The file of each image set, by image name (the set's folder name without `.imageset`).
  static func imageFiles() throws -> [String: URL] {
    let sets: [URL] = (FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil)?.allObjects ?? [])
      .compactMap { $0 as? URL }
      .filter { $0.pathExtension == "imageset" }
    return try sets.reduce(into: [:]) { files, set in
      let contents: ImageSet = try JSONDecoder()
        .decode(ImageSet.self, from: Data(contentsOf: set.appending(path: "Contents.json")))
      if let filename = contents.images.lazy.compactMap(\.filename).first {
        files[set.deletingPathExtension().lastPathComponent] = set.appending(path: filename)
      }
    }
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
