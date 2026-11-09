//
//  FontManifestTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Testing
@testable import IkaDesign

/// The asset script writes one file per face the manifest lists, named for the face, and
/// registration looks for exactly `FontFace.allCases`. The two lists must agree, or a face is built
/// and never registered, or looked for and never built. Reads the manifest by path; needs no font.
struct FontManifestTests {
  @Test
  func `The manifest builds exactly the faces registration looks for`() throws {
    let built: [String] = try Manifest.load().fonts.map(\.name)

    #expect(built.sorted() == FontFace.allCases.map(\.name).sorted())
  }
}
