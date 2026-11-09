//
//  SentenceWriter+SidebarRow.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

extension SentenceWriter {
  /// A sidebar row's sentence, which the row reads as one VoiceOver element: its current item's,
  /// with the time left at `instant`; the next one's, with its times; or why none is on, naming
  /// the row's Mode.
  ///
  /// Every sentence but a Challenge window's names the row's Mode first. A Challenge window's
  /// names the Challenge, so its row reads its own name before it.
  public func sentence(for row: SidebarRow, at instant: Date) -> String {
    switch row {
      case .mode(let summary):
        sentence(for: summary, at: instant)

      case .challenge(.running(let running)?):
        sentence(for: running.item, at: instant)

      case .challenge(.next(let window)?):
        sentence(for: window, at: instant)

      case .challenge(nil):
        format("answer.noneAnnounced", ModeLabel.challenges.text(in: terms.language))

      case .eggstraWork(let running):
        sentence(for: running.item, at: instant)

      case .splatfest(let running):
        sentence(for: running.item, at: instant)

      case .splatfestBattle(_, .running(let running)):
        sentence(for: running.item, at: instant)

      case .splatfestBattle(let form, .paused(let returnTime)):
        pauseSentence(
          named: RotationMode.splatfestBattle(form).name(in: terms.language),
          returningAt: returnTime)

      case .splatfestBattle(let form, .nothingCurrent):
        format("answer.notPublished.now", RotationMode.splatfestBattle(form).name(in: terms.language))

      case .tricolorTurfWar(.running(let running)):
        sentence(for: running.item, at: instant)

      case .tricolorTurfWar(.next(let tricolorTurfWar)):
        sentence(for: tricolorTurfWar, at: instant)
    }
  }
}
