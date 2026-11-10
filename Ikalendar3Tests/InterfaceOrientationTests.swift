//
//  InterfaceOrientationTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import Foundation
import Testing

// MARK: - InterfaceOrientationTests

/// The orientations the built app declares: portrait only on iPhone, as ikalendar 2 at `9a99cf3`,
/// and all four on iPad.
struct InterfaceOrientationTests {
  @Test
  func `The app runs in portrait only on iPhone and in all four orientations on iPad`() throws {
    // The file as built: at run time, `Bundle.infoDictionary` drops the other device family's keys.
    let data: Data = try .init(contentsOf: Bundle.main.bundleURL.appending(path: "Info.plist"))
    let info = try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])

    #expect(info["UISupportedInterfaceOrientations~iphone"] as? [String] == ["UIInterfaceOrientationPortrait"])
    #expect(Set(info["UISupportedInterfaceOrientations~ipad"] as? [String] ?? []) == [
      "UIInterfaceOrientationPortrait",
      "UIInterfaceOrientationPortraitUpsideDown",
      "UIInterfaceOrientationLandscapeLeft",
      "UIInterfaceOrientationLandscapeRight",
    ])
  }
}
#endif
