//
//  ScheduleFeed+Lineup.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

extension ScheduleFeed {
  /// A Battle Mode's lineup at `instant`.
  ///
  /// - A continuous Battle Mode is paused while a Splatfest runs, until the Splatfest ends, even
  ///   past its last published window. Its paused windows are never items, so next and later
  ///   hold only Rotations it plays. Past its last Rotation it ran out.
  /// - Splatfest Battle runs out past its last Rotation while its Splatfest still runs; once the
  ///   Splatfest is over, none is announced.
  public func battleLineup(of mode: RotationMode, at instant: Date) -> Lineup<Rotation> {
    let rotations = rotations(for: mode)
    let runningSplatfest = runningSplatfest(at: instant)
    switch mode {
      case .battle:
        let played = rotations.filter { !$0.isPaused }
        guard let returnTime = runningSplatfest?.endTime ?? Self.endOfPause(in: rotations, at: instant) else {
          return Lineup(played, at: instant, pastLast: .ranOut)
        }

        return Lineup(current: .paused(returnTime: returnTime), upcoming: played.filter { instant < $0.startTime })

      case .splatfestBattle:
        return Lineup(rotations, at: instant, pastLast: runningSplatfest == nil ? .noneAnnounced : .ranOut)
    }
  }

  /// The Splatfest running at `instant`, if any.
  func runningSplatfest(at instant: Date) -> Splatfest? {
    guard let splatfest = currentSplatfest?.splatfest, splatfest.isRunning(at: instant) else { return nil }

    return splatfest
  }

  /// The end of the paused windows from `instant` on, or `nil` when the window at `instant` is
  /// not paused. Stands in for the Splatfest's end when the Splatfest failed to decode.
  static private func endOfPause(in rotations: [Rotation], at instant: Date) -> Date? {
    guard let index = rotations.firstIndex(where: { $0.isRunning(at: instant) }) else { return nil }

    return rotations[index...].prefix(while: \.isPaused).last?.endTime
  }

  /// Salmon Run's lineup at `instant`: its regular Shifts and Big Runs with their real
  /// boundaries. An Eggstra Work runs beside them and is never one of them
  /// (`eggstraWorkLineup(at:)`).
  public func salmonRunLineup(at instant: Date) -> Lineup<Shift> {
    Lineup(salmonRun, at: instant, pastLast: .ranOut)
  }

  /// The Eggstra Works' lineup at `instant`, apart from Salmon Run's. Past the last one, none is
  /// announced.
  public func eggstraWorkLineup(at instant: Date) -> Lineup<Shift> {
    Lineup(eggstraWork, at: instant, pastLast: .noneAnnounced)
  }

  /// The Challenges' lineup at `instant`: every window of every published Challenge in time
  /// order, so the next window may belong to the next Challenge. Past the last window, none is
  /// announced.
  public func challengeLineup(at instant: Date) -> Lineup<ChallengeWindow> {
    let windows = challenges
      .flatMap { challenge in challenge.windows.map { ChallengeWindow(challenge: challenge, window: $0) } }
      .sorted { $0.startTime < $1.startTime }
    return Lineup(windows, at: instant, pastLast: .noneAnnounced)
  }
}

// MARK: - ChallengeWindow

/// A Challenge in one of its windows: an item of the Challenges' lineup.
public struct ChallengeWindow: TimeWindow, Hashable, Sendable {
  /// The Challenge held in the window.
  public let challenge: Challenge
  /// The window.
  public let window: Challenge.Window

  /// `challenge` in `window`, as a Surface listing a Challenge's windows reads each of them.
  public init(challenge: Challenge, window: Challenge.Window) {
    self.challenge = challenge
    self.window = window
  }

  /// When the window opens.
  public var startTime: Date { window.startTime }
  /// When the window closes.
  public var endTime: Date { window.endTime }
}
