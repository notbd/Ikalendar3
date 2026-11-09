//
//  SplatfestBattleSummary.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - SplatfestBattleSummary

/// One form of Splatfest Battle at a glance, for the Open and Pro menu: its current Rotation with
/// the time left and the share passed, or nothing current. It is the current item of that form's
/// Splatfest screen, so the two always agree.
public struct SplatfestBattleSummary: Hashable, Sendable {
  /// The form summarized.
  public let form: SplatfestBattleForm
  /// Its Rotation on now with how far it has run, or nothing current.
  public let current: OnNow<Rotation>
}

extension Snapshot {
  /// `form`'s summary at `instant`, or `nil` whenever there is no Splatfest screen.
  public func splatfestBattleSummary(of form: SplatfestBattleForm, at instant: Date) -> SplatfestBattleSummary? {
    splatfestScreen(of: form, at: instant).map { SplatfestBattleSummary(form: form, current: $0.current) }
  }
}
