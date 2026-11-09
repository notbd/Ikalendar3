// swift-tools-version: 6.2

import PackageDescription

/// Swift 6 language mode (the tools version's default) plus the two upcoming features that Xcode's
/// Approachable Concurrency setting adds on top of it, so the modules compile like the app targets.
/// Default isolation stays nonisolated.
let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
  name: "Ikalendar3Kit",
  defaultLocalization: "en",
  platforms: [.iOS(.v26), .macOS(.v26), .watchOS(.v26)],
  products: [
    .library(name: "IkaCore", targets: ["IkaCore"]),
    .library(name: "IkaDesign", targets: ["IkaDesign"]),
    .library(name: "IkaIntents", targets: ["IkaIntents"]),
    .library(name: "IkaFixtures", targets: ["IkaFixtures"]),
  ],
  targets: [
    // Domain, data and every Surface's content. Foundation only (a SwiftLint rule enforces it).
    .target(name: "IkaCore", resources: [.process("Resources")], swiftSettings: swiftSettings),
    // Design system. Linked by every product target, the watch ones included. The build copies its
    // `Resources` into every product that links it, so they hold only string tables; the fonts and
    // the image catalog ship once per app in the project's IkaResources framework.
    .target(
      name: "IkaDesign",
      dependencies: ["IkaCore"],
      resources: [.process("Resources")],
      swiftSettings: swiftSettings),
    // Siri, App Shortcuts and the effects shell. iOS and macOS; Live Activity parts behind `#if os(iOS)`.
    .target(
      name: "IkaIntents",
      dependencies: ["IkaCore"],
      resources: [.process("Resources")],
      swiftSettings: swiftSettings),
    // Test support, not a product module: the scripted transport, the settable clock and the fixture
    // loader for package tests, Debug fixture launches and previews. Release code never calls it,
    // and it holds no fixture file.
    .target(name: "IkaFixtures", dependencies: ["IkaCore"], swiftSettings: swiftSettings),
    .testTarget(name: "IkaCoreTests", dependencies: ["IkaCore", "IkaFixtures"], swiftSettings: swiftSettings),
    .testTarget(name: "IkaDesignTests", dependencies: ["IkaDesign", "IkaCore"], swiftSettings: swiftSettings),
    .testTarget(name: "IkaIntentsTests", dependencies: ["IkaIntents"], swiftSettings: swiftSettings),
  ])
