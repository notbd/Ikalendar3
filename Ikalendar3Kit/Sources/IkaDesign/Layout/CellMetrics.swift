//
//  CellMetrics.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - CellMetrics

/// How a Rotation or Shift cell sizes its parts at one width and text size.
///
/// Every size is a share of the cell's width, as in ikalendar 2, so pictures and text keep their
/// proportions. The width is clamped between `floorWidth` and `ceilingWidth` first, so every part
/// stops shrinking or growing at the same point and the proportions still hold beyond the range.
public struct CellMetrics: Equatable, Sendable {
  /// The narrowest width the parts are sized for.
  static public let floorWidth: CGFloat = 200
  /// The widest width the parts are sized for: wider cells keep the parts at this size.
  static public let ceilingWidth: CGFloat = 500

  /// The cell width the shares apply to, clamped to `floorWidth...ceilingWidth`.
  public let referenceWidth: CGFloat
  /// Side by side, or stacked from the first accessibility text size.
  public let arrangement: CellArrangement

  /// The metrics of a cell `width` points wide at `dynamicTypeSize`.
  public init(width: CGFloat, dynamicTypeSize: DynamicTypeSize) {
    referenceWidth = min(max(width, Self.floorWidth), Self.ceilingWidth)
    arrangement = CellArrangement(dynamicTypeSize)
  }

  /// The length in points that `share` of the reference width gives.
  public func length(_ share: CellShare) -> CGFloat {
    referenceWidth * share.fraction
  }
}

// MARK: - CellShare

/// A share of a cell's width. The named shares are ikalendar 2's cell proportions.
public struct CellShare: Hashable, Sendable {
  /// The share, as a fraction of the width.
  public let fraction: CGFloat

  /// A share of `fraction` of the width.
  public init(_ fraction: CGFloat) {
    self.fraction = fraction
  }
}

extension CellShare {
  /// The current Rotation's Rule icon and name.
  static public let battleRuleSectionWidth: CellShare = .init(0.45)
  /// The height of the current Rotation's Rule section.
  static public let battleRuleSectionHeight: CellShare = .init(0.115)
  /// The current Rotation's time left.
  static public let battleRemainingTimeWidth: CellShare = .init(0.32)
  /// A later Rotation's Rule column.
  static public let battleSecondaryRuleSectionWidth: CellShare = .init(0.16)
  /// The height of a later Rotation's Rule icon.
  static public let battleSecondaryRuleImageHeight: CellShare = .init(0.1)
  /// The height of a Shift's golden egg and salmon icons.
  static public let salmonIconHeight: CellShare = .init(0.065)
}

// MARK: - CellArrangement

/// Where a cell puts its Stage cards, and how its text fits.
public enum CellArrangement: Sendable {
  /// Stage cards beside each other under a one-line Rule row, as in ikalendar 2.
  case sideBySide
  /// Stage cards under the Rule, with text wrapping instead of shrinking.
  case stacked

  /// Side by side, or stacked from the first accessibility text size.
  public init(_ dynamicTypeSize: DynamicTypeSize) {
    self = dynamicTypeSize.isAccessibilitySize ? .stacked : .sideBySide
  }

  /// The most lines a text takes: one side by side, unlimited when stacked.
  public var lineLimit: Int? {
    switch self {
      case .sideBySide: 1
      case .stacked: nil
    }
  }

  /// How far a text may shrink to fit: as in ikalendar 2 side by side, not at all when stacked.
  public var minimumScaleFactor: CGFloat {
    switch self {
      case .sideBySide: 0.3
      case .stacked: 1
    }
  }
}
