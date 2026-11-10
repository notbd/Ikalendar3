//
//  EventItem.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - EventItem

/// One event the iPad event strip and the event sheets show: a Challenge, a Splatfest, a Big Run
/// or an Eggstra Work, running or next, with its times. IDs and times only; names resolve at
/// display time.
public enum EventItem: TimeWindow, Hashable, Sendable {
  /// The Challenge window on now or next; the Challenge carries all its windows.
  case challenge(ChallengeWindow)
  /// The Splatfest, announced or running, as its card with the stored art.
  case splatfest(SplatfestCard)
  /// The Big Run running or next.
  case bigRun(Shift)
  /// The Eggstra Work running or next.
  case eggstraWork(Shift)

  /// When the event, or the Challenge's window, starts.
  public var startTime: Date {
    switch self {
      case .challenge(let window): window.startTime
      case .splatfest(let card): card.splatfest.startTime
      case .bigRun(let shift),
           .eggstraWork(let shift): shift.startTime
    }
  }

  /// When the event, or the Challenge's window, ends.
  public var endTime: Date {
    switch self {
      case .challenge(let window): window.endTime
      case .splatfest(let card): card.splatfest.endTime
      case .bigRun(let shift),
           .eggstraWork(let shift): shift.endTime
    }
  }
}

extension Snapshot {
  /// The events at `instant` in the strip's fixed order: Challenge, Splatfest, Big Run, Eggstra
  /// Work. Each is the one running or else the next, and is left out when the feed publishes
  /// none still to end. `nil` before the schedules feed's first good response.
  public func eventItems(at instant: Date) -> [EventItem]? {
    guard let schedules else { return nil }

    let feed = schedules.content
    let challenges = feed.challengeLineup(at: instant)
    let eggstraWorks = feed.eggstraWorkLineup(at: instant)
    let challenge = (challenges.current.item ?? challenges.next).map(EventItem.challenge)
    let splatfest = splatfest.flatMap { $0.phase(at: instant) == .over ? nil : EventItem.splatfest(card(of: $0)) }
    let bigRun = feed.salmonRun.first { $0.kind == .bigRun && instant < $0.endTime }.map(EventItem.bigRun)
    let eggstraWork = (eggstraWorks.current.item ?? eggstraWorks.next).map(EventItem.eggstraWork)
    return [challenge, splatfest, bigRun, eggstraWork].compactMap(\.self)
  }
}
