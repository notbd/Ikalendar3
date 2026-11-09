//
//  CreditedLicenseTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import Testing
@testable import Ikalendar3

// MARK: - CreditedLicenseTests

/// About and Credits show every licence from the app itself, offline, so each text must ship.
struct CreditedLicenseTests {
  /// The opening words of each licence's text. A new licence without an entry fails, which forces
  /// a check of what ships.
  static private let openings: [CreditedLicense: String] = [
    .ikalendar3: "GNU GENERAL PUBLIC LICENSE\n                       Version 3, 29 June 2007",
    .splatoon3InkSiteStrings: "MIT License\n\nCopyright (c) 2022 Matt Isenhower",
  ]

  @Test(arguments: CreditedLicense.allCases)
  func `Every credited licence text is in the bundle`(license: CreditedLicense) throws {
    let text: String = try #require(license.text, "\(license)")
    let opening: String = try #require(Self.openings[license], "\(license)")

    #expect(text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(opening))
  }
}
