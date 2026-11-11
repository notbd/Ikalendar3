//
//  ReadableSecondary.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - ReadableSecondary

/// Secondary text that reads as text (4.5:1) where the system's secondary does not: a share of the
/// primary colour. The system's reads 3.4:1 on a white cell and 3.3:1 on the grouped ground in
/// light appearance; this reads 6.2:1 and 6.0:1 there, 7.3:1 on a dark cell, 7.8:1 on black and
/// 6.3:1 on Timeline's page (`ReadableSecondaryTests`). The fetch time label and Settings, About,
/// Credits and the licence page draw their secondary text in it. Classic keeps its own secondary
/// (`ClassicSecondaryStyle`), which matches ikalendar 2's rendered grey.
public enum ReadableSecondary {
  /// The share of the primary colour the text is drawn with.
  static public let primaryShare: Double = 0.62
}

extension ShapeStyle where Self == Color {
  /// Secondary text that reads 4.5:1 (`ReadableSecondary`).
  static public var readableSecondary: Color { Color.primary.opacity(ReadableSecondary.primaryShare) }
}
