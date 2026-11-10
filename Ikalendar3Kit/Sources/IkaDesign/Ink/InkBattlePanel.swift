//
//  InkBattlePanel.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - InkBattlePanel

/// A Rotation's panel, ikalendar 2's primary and secondary cell on Ink's materials. The featured
/// panel (Now) is taped and shows the Rule large over a dotted rule, the two Stages side by side
/// and the progress; later panels put the Rule in a column beside smaller Stages.
///
/// The panel owns the namespaces its Rule icon, Rule name and Stage cards share between the two
/// looks, so when the Rotation becomes current they glide into the featured look. The featured
/// look is the geometry source, as in ikalendar 2: it is the look that stays.
struct InkBattlePanel: View {
  @Environment(\.colorScheme) private var colorScheme

  let entry: InkPanelEntry<Rotation>
  /// The Rotation's Rule and Stages; a lineup's Rotations always play.
  let setting: Rotation.Setting
  let terms: GameTerms
  /// The Battle Mode's colour, or white for Splatfest Battle.
  let accent: InkAccent
  let timeRange: String
  /// Writes the featured panel's countdown.
  let writer: SentenceWriter
  let metrics: CellMetrics

  @Namespace private var ruleIcon
  @Namespace private var ruleName
  @Namespace private var stageA
  @Namespace private var stageB

  var body: some View {
    VStack(alignment: .leading, spacing: InkScreenMetrics.panelRowSpacing) {
      InkPanelHeader(timeRange: timeRange, arrangement: metrics.arrangement) {
        InkStateTag(place: entry.place, accent: accent)
      }
      if let progress = entry.place.progress {
        primary(progress: progress)
      }
      else {
        secondary
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .inkPanel(isTaped: entry.place.progress != nil)
  }

  // MARK: Primary

  private func primary(progress: WindowProgress) -> some View {
    VStack(alignment: .leading, spacing: InkScreenMetrics.panelRowSpacing) {
      HStack(spacing: InkScreenMetrics.cardSpacing) {
        ruleImage
          .frame(height: metrics.length(InkScreenMetrics.ruleIconHeight))
          .matchedGeometryEffect(id: entry.id, in: ruleIcon)
        ruleText(style: .headline)
          .matchedGeometryEffect(id: entry.id, in: ruleName)
      }
      InkDottedRule()
      stages(imageSize: .large, isSource: true)
      InkProgressBar(
        progress: progress,
        countdown: writer.countdown(progress),
        accent: accent,
        arrangement: metrics.arrangement)
    }
  }

  // MARK: Secondary

  @ViewBuilder
  private var secondary: some View {
    switch metrics.arrangement {
      case .sideBySide:
        HStack(spacing: InkScreenMetrics.panelRowSpacing) {
          VStack(spacing: InkScreenMetrics.panelRowSpacing / 2) {
            secondaryRuleImage
            secondaryRuleText
          }
          .frame(width: metrics.length(InkScreenMetrics.secondaryRuleColumnWidth))
          stages(imageSize: .medium, isSource: false)
        }

      case .stacked:
        VStack(alignment: .leading, spacing: InkScreenMetrics.panelRowSpacing) {
          HStack(spacing: InkScreenMetrics.cardSpacing) {
            secondaryRuleImage
            secondaryRuleText
          }
          stages(imageSize: .medium, isSource: false)
        }
    }
  }

  private var secondaryRuleImage: some View {
    ruleImage
      .frame(height: metrics.length(.battleSecondaryRuleImageHeight))
      .matchedGeometryEffect(id: entry.id, in: ruleIcon, isSource: false)
  }

  private var secondaryRuleText: some View {
    ruleText(style: .label)
      .multilineTextAlignment(metrics.arrangement == .sideBySide ? .center : .leading)
      .matchedGeometryEffect(id: entry.id, in: ruleName, isSource: false)
  }

  // MARK: Parts

  private var ruleImage: some View {
    Image(decorative: BundledImage.name(for: setting.rule, size: .medium), bundle: BundledImage.catalogBundle)
      .resizable()
      .scaledToFit()
  }

  /// The Rule's name in the accent, tinted to stay readable on the panel.
  private func ruleText(style: InkTextStyle) -> some View {
    Text(verbatim: terms.name(of: setting.rule))
      .inkFont(style)
      .foregroundStyle(Color(accent.onPanel(in: colorScheme).foreground))
      .scaledLimitedLine(for: metrics.arrangement)
  }

  /// The two Stage cards: side by side at equal width, or one over the other when stacked.
  @ViewBuilder
  private func stages(imageSize: BundledImage.Size, isSource: Bool) -> some View {
    let cards: [(stage: StageID, namespace: Namespace.ID)] = zip(setting.stages, [stageA, stageB])
      .map { (stage: $0, namespace: $1) }

    switch metrics.arrangement {
      case .sideBySide:
        BattleSecondaryStagesLayout {
          ForEach(cards, id: \.namespace) { card in
            stageCard(card.stage, imageSize: imageSize)
              .matchedGeometryEffect(id: entry.id, in: card.namespace, isSource: isSource)
          }
        }

      case .stacked:
        VStack(spacing: InkScreenMetrics.panelRowSpacing) {
          ForEach(cards, id: \.namespace) { card in
            stageCard(card.stage, imageSize: imageSize)
              .matchedGeometryEffect(id: entry.id, in: card.namespace, isSource: isSource)
          }
        }
    }
  }

  private func stageCard(_ stage: StageID, imageSize: BundledImage.Size) -> some View {
    InkStageCard(stage: stage, name: Text(verbatim: terms.name(of: stage)), imageSize: imageSize)
  }
}
#endif
