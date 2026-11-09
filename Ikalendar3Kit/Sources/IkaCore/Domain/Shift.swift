//
//  Shift.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - Shift

/// A Salmon Run window with one Stage and one set of four weapons.
public struct Shift: Hashable, Sendable {
  /// A regular Shift, a Big Run or an Eggstra Work.
  public let kind: Kind
  /// When the Shift starts.
  public let startTime: Date
  /// When the Shift ends: usually 40 hours after its start, 48 for a Big Run or an Eggstra Work.
  public let endTime: Date
  /// The Stage.
  public let stage: StageID
  /// The four weapons in the feed's order. Any of them may be a random mark (`WeaponID.random`
  /// or `WeaponID.rareRandom`).
  public let weapons: [WeaponID]
  /// The King Salmonid that can appear at the end, absent on an Eggstra Work.
  public let kingSalmonid: KingSalmonidID?
}

// MARK: Shift.Kind

extension Shift {
  /// What a Shift is.
  public enum Kind: Hashable, Sendable {
    /// A regular Salmon Run Shift.
    case regular
    /// A Big Run: a Shift on a battle Stage.
    case bigRun
    /// An Eggstra Work: a contest that runs beside the regular Shifts.
    case eggstraWork
  }
}

// MARK: - Random marks

extension WeaponID {
  /// The green question mark: each player gets a random weapon.
  static public let random: WeaponID = .init("01b960996da8ed63")
  /// The golden question mark: each player gets a random Grizzco weapon.
  static public let rareRandom: WeaponID = .init("747937841598fff7")
}
