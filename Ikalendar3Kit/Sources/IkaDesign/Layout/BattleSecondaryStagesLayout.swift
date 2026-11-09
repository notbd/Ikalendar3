//
//  BattleSecondaryStagesLayout.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - BattleSecondaryStagesLayout

/// Lays out a later Rotation's two Stage cards side by side at equal width, so their pictures
/// line up even when one name shrinks more than the other.
///
/// Both cards get the smaller of their two ideal heights. The picture has a higher layout
/// priority than the name, so equal widths keep the pictures aligned.
///
/// - Precondition:
///   - The proposed width must already be set.
///   - Must have exactly two subviews: the Stage A card and the Stage B card.
public struct BattleSecondaryStagesLayout: Layout {
  /// The layout.
  public init() { }

  public func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache _: inout ())
    -> CGSize
  {
    guard let proposalWidth = proposal.width, subviews.count == 2 else { return .zero }

    let cardSize: CGSize = cardSize(proposalWidth: proposalWidth, proposalHeight: proposal.height, subviews: subviews)
    return CGSize(width: proposalWidth, height: cardSize.height)
  }

  public func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache _: inout ())
  {
    guard let proposalWidth = proposal.width, subviews.count == 2 else { return }

    let cardSize: CGSize = cardSize(proposalWidth: proposalWidth, proposalHeight: proposal.height, subviews: subviews)

    subviews[0].place(
      at: CGPoint(x: bounds.minX, y: bounds.midY),
      anchor: .leading,
      proposal: ProposedViewSize(cardSize))

    subviews[1].place(
      at: CGPoint(x: bounds.maxX, y: bounds.midY),
      anchor: .trailing,
      proposal: ProposedViewSize(cardSize))
  }

  /// The size both cards get: the smallest ideal size for half the width left after spacing.
  private func cardSize(proposalWidth: CGFloat, proposalHeight: CGFloat?, subviews: Subviews) -> CGSize {
    let halfProposal: ProposedViewSize = .init(
      width: (proposalWidth - subviews.horizontalSpacings[0]) / 2,
      height: proposalHeight)
    return subviews.minIdealSize(for: halfProposal)
  }
}
