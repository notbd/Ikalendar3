//
//  WidgetRenderingMode+Ink.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import WidgetKit

extension WidgetRenderingMode {
  /// Whether Ink draws its materials: fills, rough edges, tape and dots. Only in full colour,
  /// which is also the mode everywhere outside a widget. The accented and vibrant modes of the
  /// Lock Screen, tinted Home Screens and watch faces turn colours into tints or luminance, so
  /// there Ink draws its plain forms: system hierarchical fills and the primary text colour.
  var drawsInkMaterials: Bool {
    self == .fullColor
  }
}
