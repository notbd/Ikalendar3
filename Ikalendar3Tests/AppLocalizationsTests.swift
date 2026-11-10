//
//  AppLocalizationsTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import Testing

struct AppLocalizationsTests {
  /// The app and every bundle it embeds (the widget extension; on iOS the watch app and its
  /// widget extension when the build embeds them), each read from the built product.
  static func shippedBundles() -> [Bundle] {
    let app: Bundle = .main
    let watchApps = (try? FileManager.default.contentsOfDirectory(
      at: app.bundleURL.appending(path: "Watch"),
      includingPropertiesForKeys: nil)) ?? []
    return ([app] + watchApps.compactMap(Bundle.init(url:))).flatMap { bundle in
      let plugIns = bundle.builtInPlugInsURL.flatMap {
        try? FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil)
      } ?? []
      // The test bundle sits beside the extensions when it is hosted; it is not shipped.
      return [bundle] + plugIns.filter { $0.pathExtension == "appex" }.compactMap(Bundle.init(url:))
    }
  }

  /// Every process resolves its language from its own bundle (`GameLanguage(resolvedFor:)`), so
  /// each bundle must declare the same 14 localizations, the ones `GameLanguage(localization:)` maps.
  @Test
  func `The app and each bundle it embeds declare the 14 localizations`() {
    let bundles: [Bundle] = Self.shippedBundles()
    let expected: Set = .init(GameLanguage.allCases.map(\.localization))

    #expect(bundles.contains { $0.bundleURL.pathExtension == "appex" }, "no widget extension found")
    for bundle in bundles {
      #expect(Set(bundle.localizations).subtracting(["Base"]) == expected, "\(bundle.bundleURL.lastPathComponent)")
    }
  }
}
