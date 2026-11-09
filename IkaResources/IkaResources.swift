//
//  IkaResources.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - IkaResources

/// The framework that ships SplatNet 3's fonts and the image catalog, once per app.
///
/// The app and the watch app each embed it; their widget extensions link the host app's copy
/// through their run path instead of carrying one. Each of the four targets passes `bundle` to
/// `BundledResources.load(from:)` once at start.
public enum IkaResources {
  /// This framework's bundle: the image catalog and the font files sit in its resources.
  static public let bundle: Bundle = .init(for: Anchor.self)
}

// MARK: - Anchor

/// A class compiled into this framework, so `Bundle(for:)` finds the framework's bundle.
final private class Anchor { }
