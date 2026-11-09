//
//  SalmonStageAndWeaponsLayout.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - SalmonStageAndWeaponsLayout

/// Lays out a Shift's Stage card and weapons card side by side with default spacing: the Stage
/// card gets a 16:9 proposal and the weapons card a square one, together filling the width.
///
/// - Precondition:
///   - The proposed width must already be set.
///   - Must have exactly two subviews: one for the Stage and one for the weapons.
public struct SalmonStageAndWeaponsLayout: Layout {
  /// The two cards' sizes for one width.
  struct Split: Equatable {
    let stage: CGSize
    let weapons: CGSize

    /// The split of `width` with `spacing` between the cards.
    init(width: CGFloat, spacing: CGFloat) {
      let height: CGFloat = (width - spacing) * (9 / (16 + 9))
      stage = CGSize(width: height * (16 / 9), height: height)
      weapons = CGSize(width: height, height: height)
    }
  }

  /// The layout.
  public init() { }

  public func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache _: inout ())
    -> CGSize
  {
    guard let proposalWidth = proposal.width, subviews.count == 2 else { return .zero }

    let split: Split = .init(width: proposalWidth, spacing: subviews.horizontalSpacings[0])
    return CGSize(width: proposalWidth, height: split.stage.height)
  }

  public func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache _: inout ())
  {
    guard let proposalWidth = proposal.width, subviews.count == 2 else { return }

    let split: Split = .init(width: proposalWidth, spacing: subviews.horizontalSpacings[0])

    subviews[0].place(
      at: CGPoint(x: bounds.minX, y: bounds.midY),
      anchor: .leading,
      proposal: ProposedViewSize(split.stage))

    subviews[1].place(
      at: CGPoint(x: bounds.maxX, y: bounds.midY),
      anchor: .trailing,
      proposal: ProposedViewSize(split.weapons))
  }
}
