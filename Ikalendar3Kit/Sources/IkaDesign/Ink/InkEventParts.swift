//
//  InkEventParts.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - InkTitle

/// An event's name on its panel, such as a Challenge's or a Splatfest's title, in the heavy face.
/// It wraps rather than truncates.
struct InkTitle: View {
  let text: String

  var body: some View {
    Text(verbatim: text)
      .inkFont(.tag)
      .lineHeight(.tight)
      .fixedSize(horizontal: false, vertical: true)
  }
}

// MARK: - InkRuleLabel

/// A Challenge's Rule: its icon beside its name in the accent, tinted to read on the panel.
struct InkRuleLabel: View {
  @Environment(\.colorScheme) private var colorScheme

  @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = InkScreenMetrics.challengeRuleIconSize

  let rule: RuleID
  let terms: GameTerms
  let accent: InkAccent
  let arrangement: CellArrangement

  var body: some View {
    HStack(spacing: InkScreenMetrics.cardSpacing) {
      Image(decorative: BundledImage.name(for: rule, size: .medium), bundle: BundledImage.catalogBundle)
        .resizable()
        .scaledToFit()
        .frame(width: iconSize, height: iconSize)
      Text(verbatim: terms.name(of: rule))
        .inkFont(.tag)
        .lineHeight(.tight)
        .foregroundStyle(Color(accent.onPanel(in: colorScheme).foreground))
        .scaledLimitedLine(for: arrangement)
    }
  }
}

// MARK: - InkStageRow

/// Stage cards side by side at equal width, or one over the other when stacked: a Challenge's
/// Stages and Tricolor Turf War's.
struct InkStageRow: View {
  let stages: [StageID]
  let terms: GameTerms
  let imageSize: BundledImage.Size
  let arrangement: CellArrangement

  var body: some View {
    switch arrangement {
      case .sideBySide where stages.count == 2:
        BattleSecondaryStagesLayout { cards }

      case .sideBySide:
        HStack(alignment: .top, spacing: InkScreenMetrics.cardSpacing) { cards }

      case .stacked:
        VStack(spacing: InkScreenMetrics.panelRowSpacing) { cards }
    }
  }

  private var cards: some View {
    ForEach(stages, id: \.self) { stage in
      InkStageCard(
        stage: stage,
        name: Text(verbatim: terms.name(of: stage)),
        imageSize: imageSize,
        nameReachesTrailingEdge: true)
    }
  }
}

// MARK: - InkTeamList

/// A Splatfest's teams, each name on a tag in the team's colour from the feed, as the game shows
/// a team: in one row, or one per line where the row does not fit. Only teams whose names the
/// terms carry are listed (`GameTerms.teams(of:)`), so a colour never stands alone.
struct InkTeamList: View {
  let splatfest: Splatfest
  let terms: GameTerms

  var body: some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: InkScreenMetrics.cardSpacing) { tags }
      VStack(alignment: .leading, spacing: InkScreenMetrics.cardSpacing / 2) { tags }
    }
  }

  private var tags: some View {
    ForEach(Array(terms.teams(of: splatfest).enumerated()), id: \.offset) { _, team in
      InkTeamTag(Text(verbatim: team.name), color: SRGBColor(team.color))
    }
  }
}
#endif
