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
      InkStageCard(stage: stage, name: Text(verbatim: terms.name(of: stage)), imageSize: imageSize)
    }
  }
}

// MARK: - InkTeamList

/// A Splatfest's teams, one per line: a swatch of the team's colour from the feed, then the team's
/// name in that colour, tinted to read on Ink's panel. Only teams whose names the terms carry are
/// listed, so a colour never stands alone.
struct InkTeamList: View {
  @Environment(\.colorScheme) private var colorScheme

  let splatfest: Splatfest
  let terms: GameTerms

  var body: some View {
    let panel: SRGBColor = Style.ink.panel(in: colorScheme)

    VStack(alignment: .leading, spacing: InkScreenMetrics.cardSpacing / 2) {
      ForEach(Array(Self.teams(of: splatfest, terms: terms).enumerated()), id: \.offset) { _, team in
        HStack(spacing: InkScreenMetrics.cardSpacing) {
          SkewedRectangle(slant: InkMetrics.tagSlant)
            .fill(Color(team.color))
            .frame(width: InkScreenMetrics.teamSwatchSize.width, height: InkScreenMetrics.teamSwatchSize.height)
            .accessibilityHidden(true)
          Text(verbatim: team.name)
            .inkFont(.tag)
            .foregroundStyle(Color(team.color.readableTint(on: panel, for: .text)))
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }

  /// The team names as one list in the terms' language, for VoiceOver.
  static func names(of splatfest: Splatfest, terms: GameTerms) -> String {
    teams(of: splatfest, terms: terms)
      .map(\.name)
      .formatted(.list(type: .and).locale(Locale(identifier: terms.language.rawValue)))
  }

  /// Each named team with its colour, in the feed's order.
  static private func teams(of splatfest: Splatfest, terms: GameTerms) -> [(name: String, color: SRGBColor)] {
    zip(terms.splatfest(splatfest.id).teamNames ?? [], splatfest.teamColors).map { (name: $0, color: SRGBColor($1)) }
  }
}
#endif
