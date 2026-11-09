//
//  ResourcePackagingTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaDesign
import IkaResources
import OSLog
import Testing

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

// MARK: - ResourcePackagingTests

/// The fonts and the image catalog ship once per app, in `IkaResources.framework`, and the app
/// loads both from there at start. Read from the built product and this process's log.
///
/// Under `xcodebuild test`, dyld loads the framework from the build folder (Xcode sets
/// `DYLD_FRAMEWORK_PATH`), so these tests compare with the loaded framework, not with the copy in
/// `Frameworks`; an installed app loads that copy through its run path.
struct ResourcePackagingTests {
  @Test
  func `The app loads its pictures from the resource framework`() {
    let picture: String = BundledImage.name(for: ModeIcon.regularBattle, size: .small)

    #expect(BundledImage.catalogBundle.bundleURL == IkaResources.bundle.bundleURL)
    #expect(hasImage(named: picture, in: BundledImage.catalogBundle))
  }

  @Test
  func `The app registers fonts from the resource framework at start`() throws {
    let folder: URL = try #require(IkaResources.bundle.resourceURL)
    let store: OSLogStore = try .init(scope: .currentProcessIdentifier)

    let fontLog: [String] = try store.getEntries()
      .compactMap { $0 as? OSLogEntryLog }
      .filter { $0.category == "fonts" }
      .map(\.composedMessage)

    #expect(fontLog.contains { $0.contains(" from \(folder.path)") }, "\(fontLog)")
  }

  /// A second copy in the app, its widget extension or a package resource bundle would ship
  /// silently and only cost size. The watch app's own copy is its framework's.
  @Test
  func `No other bundle in the app holds the pictures or a font`() throws {
    let picture: String = BundledImage.name(for: ModeIcon.regularBattle, size: .small)
    var bundles: [URL] = []
    var fontsOutsideFrameworks: [String] = []

    let files = try #require(FileManager.default.enumerator(at: Bundle.main.bundleURL, includingPropertiesForKeys: nil))
    for case let url as URL in files {
      let path: String = url.resolvingSymlinksInPath().path
      if ["ttf", "otf"].contains(url.pathExtension), !path.contains("/IkaResources.framework/") {
        fontsOutsideFrameworks.append(path)
      }
      // Bundles built for this platform; the watch app's are not loadable here.
      if ["app", "appex", "bundle"].contains(url.pathExtension), !path.contains("/Watch/") {
        bundles.append(url)
      }
    }

    #expect(fontsOutsideFrameworks.isEmpty)
    #expect(!bundles.isEmpty)
    for bundle in [Bundle.main] + bundles.compactMap(Bundle.init(url:)) {
      #expect(!hasImage(named: picture, in: bundle), "\(bundle.bundleURL.lastPathComponent)")
    }
  }

  /// Whether `bundle`'s own asset catalog has the image `name`.
  private func hasImage(named name: String, in bundle: Bundle) -> Bool {
    guard bundle.url(forResource: "Assets", withExtension: "car") != nil else { return false }

    #if canImport(UIKit)
    return UIImage(named: name, in: bundle, with: nil) != nil
    #else
    return bundle.image(forResource: name) != nil
    #endif
  }
}
