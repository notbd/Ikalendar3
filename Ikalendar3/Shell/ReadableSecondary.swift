//
//  ReadableSecondary.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

extension ShapeStyle where Self == Color {
  /// Secondary text on Settings, About, Credits and the licence page. The system's secondary reads
  /// 3.4:1 on a white cell in light appearance; this share of the primary reads 6.2:1 there,
  /// 5.5:1 on the grouped ground, and 7.3:1 on a dark cell.
  static var readableSecondary: Color { Color.primary.opacity(0.62) }
}
