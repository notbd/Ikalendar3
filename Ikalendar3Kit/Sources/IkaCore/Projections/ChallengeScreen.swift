//
//  ChallengeScreen.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - ChallengeScreen

/// What the Challenge screen shows at an instant: each published Challenge that still has a
/// window on or to come, with all its windows marked. It holds ids and times only; the name,
/// description and rules text resolve at display time from the Challenge's id.
public struct ChallengeScreen: Hashable, Sendable {
  /// The Challenges with a window on or to come, in the order their first windows open. Empty
  /// once none is announced, or when the Challenges failed to decode: tell the two apart by the
  /// schedules feed's `failedSections` before saying none is announced.
  public let challenges: [Listing]
  /// When the schedules feed shown was last confirmed.
  public let fetchTime: Date
}

// MARK: ChallengeScreen.Listing

extension ChallengeScreen {
  /// One Challenge with every window it is held in.
  public struct Listing: Hashable, Sendable {
    /// The Challenge, with its Rule and Stages.
    public let challenge: Challenge
    /// All its windows in time order, past ones included.
    public let windows: [MarkedWindow]
  }

  /// A Challenge window with where it stands at the instant.
  public struct MarkedWindow: Hashable, Sendable {
    /// The window.
    public let window: Challenge.Window
    /// Where it stands.
    public let mark: WindowMark
  }

  /// Where a Challenge window stands at an instant. Across the screen, at most one window is
  /// current and at most one is next, which may belong to the following Challenge.
  public enum WindowMark: Hashable, Sendable {
    /// Ended.
    case over
    /// On now, with how far it has run.
    case current(WindowProgress)
    /// The first window after the current one, or after the instant when none is current.
    case next
    /// After the next window.
    case later
  }
}

extension Snapshot {
  /// The Challenge screen at `instant`, or `nil` before the schedules feed's first good
  /// response.
  public func challengeScreen(at instant: Date) -> ChallengeScreen? {
    guard let schedules else { return nil }

    let feed = schedules.content
    let lineup = feed.challengeLineup(at: instant)
    func mark(of item: ChallengeWindow) -> ChallengeScreen.WindowMark {
      if item == lineup.current.item { .current(item.progress(at: instant)) }
      else if item == lineup.next { .next }
      else if item.endTime <= instant { .over }
      else { .later }
    }

    let listings = feed.challenges
      .filter { challenge in challenge.windows.contains { instant < $0.endTime } }
      .map { challenge in
        ChallengeScreen.Listing(challenge: challenge, windows: challenge.windows.map { window in
          .init(window: window, mark: mark(of: ChallengeWindow(challenge: challenge, window: window)))
        })
      }
    return ChallengeScreen(challenges: listings, fetchTime: schedules.fetchTime)
  }
}
