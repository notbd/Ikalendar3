//
//  AboutLinks.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore

// MARK: - AboutLink

/// Every address About and Credits open. Each opens in the browser, Mail or the App Store; the
/// app fetches nothing from these hosts itself. Fixed literals, so each always parses.
enum AboutLink {
  /// The app's website.
  static let website: URL = AppContact.website
  /// The privacy policy (ADR 0004).
  static let privacyPolicy: URL = AppContact.website.appending(path: "privacy-policy")
  /// A new mail to the developer.
  static let email: URL = .init(string: "mailto:\(AppContact.email)")!
  /// The app's Twitter handle, as the Contact row shows it.
  static let twitterHandle = "@ikalendar_app"
  /// The app's Twitter profile.
  static let twitter: URL = .init(string: "https://twitter.com/ikalendar_app")!
  /// splatoon3.ink, the data source.
  static let splatoon3Ink: URL = .init(string: "https://splatoon3.ink")!
}

// MARK: - AppStoreApp

/// An app's App Store pages, by its App Store id.
struct AppStoreApp {
  /// The App Store id, digits only.
  let id: String

  /// ikalendar 3, or `nil` until its App Store Connect record exists: the id is filled in at
  /// release (ticket 65). Until then the rows that need it are disabled.
  static let ikalendar3: AppStoreApp? = nil
  /// ikalendar 2, which the About footer points back to.
  static let ikalendar2: AppStoreApp = .init(id: "1529193361")

  /// The product page, which the system opens in the App Store.
  var page: URL {
    URL(string: "https://apps.apple.com/app/id\(id)")!
  }

  /// The product page opened on its review sheet.
  var writeReview: URL {
    page.appending(queryItems: [URLQueryItem(name: "action", value: "write-review")])
  }
}

// MARK: - CreditedLicense

/// Every licence About and Credits show, its text bundled with the app so it reads offline. Each
/// text has one home in the repository, which the app target lists as a resource.
enum CreditedLicense: CaseIterable {
  /// ikalendar 3's own source code: the repository's `LICENSE`.
  case ikalendar3
  /// splatoon3.ink's site strings, which give the Mode names and labels the locale files lack.
  case splatoon3InkSiteStrings

  /// The work the licence covers, as its row names it. Never translated.
  var work: String {
    switch self {
      case .ikalendar3: "ikalendar3"
      case .splatoon3InkSiteStrings: "splatoon3.ink"
    }
  }

  /// The licence's name, as its text titles it. Never translated.
  var name: String {
    switch self {
      case .ikalendar3: "GNU General Public License v3.0"
      case .splatoon3InkSiteStrings: "MIT License"
    }
  }

  /// The repository of the work.
  var repository: URL {
    switch self {
      case .ikalendar3: URL(string: "https://github.com/notbd/Ikalendar3")!
      case .splatoon3InkSiteStrings: URL(string: "https://github.com/misenhower/splatoon3.ink")!
    }
  }

  /// The licence text as bundled, or `nil` if the build left it out.
  var text: String? {
    Bundle.main
      .url(forResource: fileName, withExtension: nil)
      .flatMap { try? String(contentsOf: $0, encoding: .utf8) }
  }

  /// The bundled file's name.
  private var fileName: String {
    switch self {
      case .ikalendar3: "LICENSE"
      case .splatoon3InkSiteStrings: "splatoon3.ink-LICENSE.txt"
    }
  }
}
