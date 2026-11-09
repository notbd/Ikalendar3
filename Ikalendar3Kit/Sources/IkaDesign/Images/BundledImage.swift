//
//  BundledImage.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore

// MARK: - BundledImage

/// The names of the pictures in the asset catalog: Stages, weapons, Rules, King Salmonids and
/// Mode icons, each at three pixel sizes.
///
/// `scripts/assets.sh` builds the catalog and the index of bundled ids from
/// `scripts/assets/manifest.json`. An id the catalog lacks, such as a Stage the game added after
/// this build, gets its group's placeholder, so a name always resolves and the cache holds only
/// feeds and Splatfest art. This only names images: the caller loads them from the bundle that
/// ships the catalog.
public enum BundledImage {
  /// The image of a Stage, battle or Salmon Run.
  static public func name(for stage: StageID, size: Size) -> String {
    name(of: stage.rawValue, in: .stage, size: size)
  }

  /// The image of a Salmon Run weapon or random mark.
  static public func name(for weapon: WeaponID, size: Size) -> String {
    name(of: weapon.rawValue, in: .weapon, size: size)
  }

  /// The icon of a Rule.
  static public func name(for rule: RuleID, size: Size) -> String {
    name(of: rule.rawValue, in: .rule, size: size)
  }

  /// The image of a King Salmonid.
  static public func name(for kingSalmonid: KingSalmonidID, size: Size) -> String {
    name(of: kingSalmonid.rawValue, in: .kingSalmonid, size: size)
  }

  /// The image name of a manifest id: `<base name>_<size>`.
  static func name(of id: String, in group: Group, size: Size) -> String {
    "\(baseNames[group]?[id] ?? "placeholder-\(group.rawValue)")_\(size.rawValue)"
  }
}

// MARK: BundledImage.Size

extension BundledImage {
  /// A pixel size. Each group sets its own pixels in the manifest, so widgets, the Live Activity
  /// and the watch draw small images instead of scaling down full-size ones.
  public enum Size: String, CaseIterable, Sendable {
    /// For the watch, complications and the Live Activity.
    case small
    /// For widgets and list rows.
    case medium
    /// For the app's largest pictures.
    case large
  }
}

// MARK: BundledImage.Group

extension BundledImage {
  /// A manifest group: the kind of picture an id names. Raw values are the manifest's keys.
  enum Group: String, CaseIterable {
    case stage
    case weapon
    case rule
    case kingSalmonid = "king-salmonid"
    case mode
  }
}
