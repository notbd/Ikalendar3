//
//  OnNow.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - OnNow

/// What a Mode's screen or summary features as current at an instant: the Rotation or Shift on
/// now with how far it has run, or why none is.
public enum OnNow<Item: TimeWindow & Hashable & Sendable>: Hashable, Sendable {
  /// An item is on.
  case running(Running<Item>)
  /// A Splatfest pauses the Battle Mode, which returns at `returnTime`.
  case paused(returnTime: Date)
  /// Nothing is on: the Schedule ran out (past Rotations never pose as current), or its first
  /// published item has not started.
  case nothingCurrent

  /// What a lineup holds as current at `instant`.
  init(_ current: Lineup<Item>.Current, at instant: Date) {
    switch current {
      case .item(let item): self = .running(Running(item: item, progress: item.progress(at: instant)))
      case .paused(let returnTime): self = .paused(returnTime: returnTime)
      case .gap,
           .ranOut,
           .noneAnnounced: self = .nothingCurrent
    }
  }
}

// MARK: - Running

/// A Rotation or Shift on at an instant, with how far it has run.
public struct Running<Item: TimeWindow & Hashable & Sendable>: Hashable, Sendable {
  /// The item on.
  public let item: Item
  /// Its time left and the share of it passed.
  public let progress: WindowProgress
}
