//
//  LayoutSubviews+Ext.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

extension LayoutSubviews {
  /// The preferred horizontal spacing between each subview and the next one; the last entry is 0.
  var horizontalSpacings: [CGFloat] {
    indices.map { index in
      guard index < count - 1 else { return 0 }

      return self[index].spacing.distance(to: self[index + 1].spacing, along: .horizontal)
    }
  }

  /// The smallest width and the smallest height among the subviews' sizes for `proposal`,
  /// taken independently.
  func minIdealSize(for proposal: ProposedViewSize) -> CGSize {
    map { $0.sizeThatFits(proposal) }
      .reduce(CGSize(width: CGFloat.infinity, height: CGFloat.infinity)) { currentMin, nextSize in
        CGSize(
          width: Swift.min(currentMin.width, nextSize.width),
          height: Swift.min(currentMin.height, nextSize.height))
      }
  }

  /// The largest width and the largest height among the subviews' sizes for `proposal`,
  /// taken independently.
  func maxIdealSize(for proposal: ProposedViewSize) -> CGSize {
    map { $0.sizeThatFits(proposal) }
      .reduce(CGSize.zero) { currentMax, nextSize in
        CGSize(
          width: Swift.max(currentMax.width, nextSize.width),
          height: Swift.max(currentMax.height, nextSize.height))
      }
  }
}
