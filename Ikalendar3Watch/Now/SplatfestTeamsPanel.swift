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

/// The running Splatfest on top of the Now page: its three teams, each on a tag in its colour,
/// and the time left. A team whose name the source lacks shows as its colour alone.
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
    // Looked up one by one: the source may lack them.
    let teamNames = terms.splatfest(splatfest.id).teamNames ?? []
    let writer: SentenceWriter = time.writer(terms)

    VStack(alignment: .leading, spacing: NowMetrics.lineSpacing) {
      Text(verbatim: ModeLabel.splatfest.text(in: terms.language))
        .ikaFont(.heavy, size: NowMetrics.modeNameSize, relativeTo: .footnote)
      ForEach(splatfest.teamColors.indices, id: \.self) { index in
        let color: SRGBColor = .init(splatfest.teamColors[index])
        if teamNames.indices.contains(index) {
          InkTeamTag(Text(verbatim: teamNames[index]), color: color)
        }
        else {
          Capsule()
            .fill(Color(color))
            .frame(width: NowMetrics.teamSwatchSize.width, height: NowMetrics.teamSwatchSize.height)
        }
      }
      Text(verbatim: writer.countdown(splatfest.progress(at: now)))
        .ikaFont(.light, size: NowMetrics.countdownSize, relativeTo: .footnote)
        .monospacedDigit()
        .foregroundStyle(Color(InkPair.panelSecondaryText.colors(in: colorScheme).foreground))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .inkPanel()
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(writer.sentence(for: splatfest, at: now))
    .accessibilityValue(teamNames.formatted(.list(type: .and).locale(Locale(identifier: terms.language.rawValue))))
  }
}
