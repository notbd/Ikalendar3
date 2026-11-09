//
//  SplatfestTeamsPanel.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - SplatfestTeamsPanel

/// The running Splatfest on top of the Now page: its teams, each on a tag in its colour, and the
/// time left. Only teams whose names the terms carry are listed (`GameTerms.teams(of:)`), so a
/// colour never stands alone.
///
/// It is one VoiceOver element reading the Splatfest's sentence, with the team names as its
/// value. It receives `IkaCore` values only.
struct SplatfestTeamsPanel: View {
  @Environment(\.colorScheme) private var colorScheme
  @TimeSettings private var time

  let splatfest: Splatfest
  let terms: GameTerms
  let now: Date

  var body: some View {
    let writer: SentenceWriter = time.writer(terms)

    VStack(alignment: .leading, spacing: WatchMetrics.lineSpacing) {
      Text(verbatim: ModeLabel.splatfest.text(in: terms.language))
        .ikaFont(.heavy, size: WatchMetrics.modeNameSize, relativeTo: .footnote)
      ForEach(Array(terms.teams(of: splatfest).enumerated()), id: \.offset) { _, team in
        InkTeamTag(Text(verbatim: team.name), color: SRGBColor(team.color))
      }
      Text(verbatim: writer.countdown(splatfest.progress(at: now)))
        .ikaFont(.light, size: WatchMetrics.countdownSize, relativeTo: .footnote)
        .monospacedDigit()
        .foregroundStyle(Color(InkPair.panelSecondaryText.colors(in: colorScheme).foreground))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .inkPanel()
    .splatfestAccessibility(splatfest, writer: writer, at: now)
  }
}
