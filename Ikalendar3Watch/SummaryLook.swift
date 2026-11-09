//
//  SummaryLook.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import IkaDesign

// MARK: - SummaryLook

/// What a Now row and a Mode page draw for a summary besides the text: the icon, colour and
/// heading of the Mode or of the Shift kind on, so a running Big Run shows as one, and how far the
/// current item has run.
struct SummaryLook {
  let icon: ModeIcon
  let color: ModeColor
  let heading: InkModeHeading
  /// The current item's progress, or `nil` while none is on.
  let progress: WindowProgress?

  init(_ summary: ModeSummary) {
    progress = summary.progress
    switch summary {
      case .battle(let mode, _):
        icon = ModeIcon(Mode.battle(mode))
        color = ModeColor(mode)
        heading = InkModeHeading(.battle(mode))

      case .splatfestBattle(let form, _):
        // Neither the Now page nor a Mode page shows Splatfest Battle: the Now page shows a
        // Splatfest as its teams on top. It has no colour of its own, so it takes Regular
        // Battle's, whose place it takes.
        icon = ModeIcon(RotationMode.splatfestBattle(form))
        color = .regularBattle
        heading = InkModeHeading(splatfestBattle: form)

      case .salmonRun(.running(let running)):
        icon = ModeIcon(running.item.kind)
        color = ModeColor(running.item.kind)
        heading = InkModeHeading(name: ModeLabel(running.item.kind), form: nil)

      case .salmonRun:
        icon = ModeIcon(Mode.salmonRun)
        color = .salmonRun
        heading = InkModeHeading(.salmonRun)
    }
  }

  /// The text beside the ring: the current Rule or Shift Stage, when the Battle Mode returns, or
  /// that nothing is on.
  func detail(of summary: ModeSummary, terms: GameTerms, format: ScheduleFormat, now: Date) -> String {
    switch summary {
      case .battle(_, .running(let running)),
           .splatfestBattle(_, .running(let running)):
        // A summary's Rotation always plays: a paused window reads as the pause instead.
        running.item.setting.map { terms.name(of: $0.rule) } ?? ""
      case .salmonRun(.running(let running)):
        terms.name(of: running.item.stage)
      case .battle(_, .paused(let returnTime)),
           .splatfestBattle(_, .paused(let returnTime)),
           .salmonRun(.paused(let returnTime)):
        ScreenText.paused.text(in: terms.language, format.time(returnTime, relativeTo: now))
      case .battle(_, .nothingCurrent),
           .splatfestBattle(_, .nothingCurrent),
           .salmonRun(.nothingCurrent):
        ScreenText.nothingCurrent.text(in: terms.language)
    }
  }

  /// The share of the ring drawn: what the current item has run, or none.
  var share: Double {
    progress?.sharePassed ?? 0
  }
}
