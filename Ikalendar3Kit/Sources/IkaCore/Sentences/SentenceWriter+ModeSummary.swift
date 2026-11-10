//
//  SentenceWriter+ModeSummary.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

extension SentenceWriter {
  /// A Mode summary's sentence, which its row reads as one VoiceOver element: the running
  /// Rotation's or Shift's, with its time left at `instant`, or the pause's with the Battle
  /// Mode's return time. With nothing current, it reads as Siri answers what is on now.
  public func sentence(for summary: ModeSummary, at instant: Date) -> String {
    let name: String =
      switch summary {
        case .battle(let mode, _): mode.name(in: terms.language)
        case .splatfestBattle(let form, _): RotationMode.splatfestBattle(form).name(in: terms.language)
        case .salmonRun: Mode.salmonRun.name(in: terms.language)
      }
    return switch summary {
      case .battle(_, .running(let running)),
           .splatfestBattle(_, .running(let running)): sentence(for: running.item, at: instant)
      case .salmonRun(.running(let running)): sentence(for: running.item, at: instant)
      case .battle(_, .paused(let returnTime)),
           .splatfestBattle(_, .paused(let returnTime)),
           .salmonRun(.paused(let returnTime)): pauseSentence(named: name, returningAt: returnTime)
      case .battle(_, .nothingCurrent),
           .splatfestBattle(_, .nothingCurrent),
           .salmonRun(.nothingCurrent): format("answer.notPublished.now", name)
    }
  }
}
