//
//  InkShiftPanel.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - InkShiftPanel

/// A Shift's panel: its time range with the weekday, the Stage beside the four weapons, the King
/// Salmonid, and, while it runs, the tape and the progress. A Big Run or an Eggstra Work wears
/// its name on a tag in its colour, which also colours its "Now!".
struct InkShiftPanel: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.gameLanguage) private var language

  let entry: InkPanelEntry<Shift>
  let terms: GameTerms
  let timeRange: String
  /// Writes the featured panel's countdown.
  let writer: SentenceWriter
  let metrics: CellMetrics

  var body: some View {
    let shift: Shift = entry.item
    let modeColor: ModeColor = .init(shift.kind)

    VStack(alignment: .leading, spacing: InkScreenMetrics.panelRowSpacing) {
      InkPanelHeader(timeRange: timeRange, arrangement: metrics.arrangement) {
        if let label = shift.kind.label {
          InkModeTag(Text(verbatim: label.text(in: language)), modeColor: modeColor)
        }
        InkStateTag(place: entry.place, modeColor: modeColor)
      }
      stageAndWeapons(of: shift)
      if let kingSalmonid = shift.kingSalmonid {
        kingSalmonidRow(kingSalmonid)
      }
      if let progress = entry.place.progress {
        InkProgressBar(
          progress: progress,
          countdown: writer.countdown(progress),
          modeColor: modeColor,
          arrangement: metrics.arrangement)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .inkPanel(isTaped: entry.place.progress != nil)
  }

  /// The Stage card with the weapons two by two beside it, or under it as one row when stacked.
  @ViewBuilder
  private func stageAndWeapons(of shift: Shift) -> some View {
    let stageCard: InkStageCard = .init(
      stage: shift.stage,
      name: Text(verbatim: terms.name(of: shift.stage)),
      imageSize: .large)

    switch metrics.arrangement {
      case .sideBySide:
        HStack(alignment: .top, spacing: InkScreenMetrics.cardSpacing) {
          stageCard
          weapons(shift.weapons, columns: 2)
            .frame(width: metrics.length(InkScreenMetrics.weaponsWidth))
        }

      case .stacked:
        VStack(alignment: .leading, spacing: InkScreenMetrics.panelRowSpacing) {
          stageCard
          weapons(shift.weapons, columns: shift.weapons.count)
        }
    }
  }

  /// The weapons on round dark plates, as the game shows them; a random mark is the game's
  /// question mark. Each image is labelled with the weapon's name.
  private func weapons(_ weapons: [WeaponID], columns: Int) -> some View {
    let grid: [GridItem] = .init(
      repeating: GridItem(.flexible(), spacing: InkScreenMetrics.cardSpacing / 2),
      count: max(columns, 1))

    // Keyed by position: a Shift can list one weapon more than once (four golden marks).
    return LazyVGrid(columns: grid, spacing: InkScreenMetrics.cardSpacing / 2) {
      ForEach(Array(weapons.enumerated()), id: \.offset) { _, weapon in
        Image(BundledImage.name(for: weapon, size: .medium), bundle: BundledImage.catalogBundle)
          .resizable()
          .scaledToFit()
          .accessibilityLabel(Text(verbatim: terms.name(of: weapon)))
          .padding(InkScreenMetrics.cardSpacing / 2)
          .background(Color(InkPair.tagText.colors(in: colorScheme).background), in: .circle)
      }
    }
  }

  /// The King Salmonid that can appear at the end of the Shift.
  private func kingSalmonidRow(_ kingSalmonid: KingSalmonidID) -> some View {
    HStack(spacing: InkScreenMetrics.cardSpacing) {
      Image(decorative: BundledImage.name(for: kingSalmonid, size: .small), bundle: BundledImage.catalogBundle)
        .resizable()
        .scaledToFit()
        .frame(width: InkScreenMetrics.kingSalmonidIconSize, height: InkScreenMetrics.kingSalmonidIconSize)
      Text(verbatim: terms.name(of: kingSalmonid))
        .inkFont(.caption)
        .foregroundStyle(Color(InkPair.panelSecondaryText.colors(in: colorScheme).foreground))
        .scaledLimitedLine(for: metrics.arrangement)
    }
  }
}
#endif
