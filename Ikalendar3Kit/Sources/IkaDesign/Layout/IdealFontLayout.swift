//
//  IdealFontLayout.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - IdealFontLayout

/// Shows one text at the size that also fits every other candidate text, so a label keeps one
/// font size whichever value it shows (every Rule name, for example).
///
/// The first subview is the text shown, placed at `anchor`. The other subviews are the candidates:
/// they size the layout but are placed at zero size and stay hidden. Each candidate shrinks with
/// `minimumScaleFactor`, so the smallest ideal height is the font size where all of them fit.
///
/// - Precondition:
///   - The proposed width and height must already be set.
public struct IdealFontLayout: Layout {
  /// Where the shown text sits in the bounds.
  public let anchor: UnitPoint

  /// A layout that places the shown text at `anchor`.
  public init(anchor: UnitPoint) {
    self.anchor = anchor
  }

  public func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache _: inout ())
    -> CGSize
  {
    contentSize(for: proposal, subviews: subviews)
  }

  public func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache _: inout ())
  {
    let contentProposal: ProposedViewSize = .init(contentSize(for: proposal, subviews: subviews))
    let anchorPoint: CGPoint = .init(
      x: bounds.minX + bounds.width * anchor.x,
      y: bounds.minY + bounds.height * anchor.y)

    for index in subviews.indices {
      if index == 0 {
        subviews[index].place(at: anchorPoint, anchor: anchor, proposal: contentProposal)
      }
      else {
        subviews[index].place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center, proposal: .zero)
      }
    }
  }

  /// The widest candidate's width and the smallest candidate's height.
  private func contentSize(for proposal: ProposedViewSize, subviews: Subviews) -> CGSize {
    CGSize(
      width: subviews.maxIdealSize(for: proposal).width,
      height: subviews.minIdealSize(for: proposal).height)
  }
}
