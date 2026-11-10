//
//  BundledResources.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import OSLog

// MARK: - BundledResources

/// Where this process's fonts and pictures come from: the resource framework that the app and the
/// watch app each embed once, and that their widget extensions load from the host app.
///
/// Each of the four targets calls `load(from:)` once at start, before it draws anything; nothing
/// else registers fonts. Package tests and previews never call it, so they draw no bundled image
/// and set text in the system font.
public enum BundledResources {
  /// Points `BundledImage.catalogBundle` at `bundle`, registers the font faces in its resources,
  /// and logs where both come from.
  static public func load(from bundle: Bundle) {
    BundledImage.catalog.withLock { $0 = bundle }
    if bundle.url(forResource: "Assets", withExtension: "car") == nil {
      Logger.images.error("No image catalog in \(bundle.bundlePath, privacy: .public); bundled images draw nothing")
    }
    else {
      Logger.images.notice("Bundled images load from \(bundle.bundlePath, privacy: .public)")
    }
    FontRegistry.register(from: bundle.resourceURL ?? bundle.bundleURL)
  }
}
