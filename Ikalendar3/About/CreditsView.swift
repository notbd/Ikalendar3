//
//  CreditsView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - CreditsView

/// The Credits page Settings opens, in the system's grouped form: splatoon3.ink as the data
/// source, every licence the app ships with its text, the official Splatoon 3 site, whose fonts
/// the text uses and that the app is not affiliated with Nintendo.
///
/// The app links no third-party library, so the licences are ikalendar 3's own and splatoon3.ink's
/// site strings'; a library that ships later adds its case to `CreditedLicense`.
struct CreditsView: View {
  @Environment(\.gameLanguage) private var language

  var body: some View {
    Form {
      Section(text(.dataSource)) {
        CreditsLinkRow(title: "splatoon3.ink", url: AboutLink.splatoon3Ink)
      }

      Section {
        ForEach(CreditedLicense.allCases, id: \.self) { license in
          NavigationLink {
            LicenseView(license: license)
          } label: {
            CreditsRowText(title: license.work, subtitle: license.name)
          }
        }
      } header: {
        Text(text(.licenses))
      } footer: {
        Text(text(.siteStrings))
      }

      Section {
        CreditsLinkRow(title: text(.officialSite), url: language.officialSplatoon3Site)
      } header: {
        Text(text(.splatoon3))
      } footer: {
        VStack(alignment: .leading, spacing: 12) {
          Text(text(.fontNote))
          Text(text(.disclaimer))
            .ikaFont(.light, size: 13, relativeTo: .footnote)
        }
      }
    }
    .formStyle(.grouped)
    .navigationTitle(SettingsText.credits.text(in: language))
  }

  private func text(_ text: AboutText) -> String {
    text.text(in: language)
  }
}

// MARK: - CreditsRowText

/// A Credits row's two lines: a name and, under it, an address or a licence.
private struct CreditsRowText: View {
  let title: String
  let subtitle: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .foregroundStyle(Color.primary)
        .font(.system(.subheadline, design: .rounded, weight: .bold))
      Text(subtitle)
        .foregroundStyle(.secondary)
        .font(.system(.footnote, design: .rounded))
    }
  }
}

// MARK: - CreditsLinkRow

/// A Credits row that opens a site in the browser, showing its address.
private struct CreditsLinkRow: View {
  @Environment(\.openURL) private var openURL

  let title: String
  let url: URL

  var body: some View {
    Button {
      openURL(url)
    } label: {
      HStack {
        CreditsRowText(title: title, subtitle: url.shortened)
        Spacer()
        Image(systemName: "arrow.up.forward.app.fill")
          .symbolRenderingMode(.hierarchical)
          .foregroundStyle(.secondary)
      }
    }
  }
}

// MARK: - Display

extension URL {
  /// The address as a row shows it: host and path, without the scheme, `www.` or a trailing slash.
  fileprivate var shortened: String {
    let host = (host() ?? "").replacing(/^www\./, with: "")
    let path = path(percentEncoded: false)
    return path == "/" ? host : host + path.replacing(/\/$/, with: "")
  }
}

extension GameLanguage {
  /// Splatoon 3's official website for the text set: Nintendo's regional page where one exists for
  /// the language, the global site otherwise.
  fileprivate var officialSplatoon3Site: URL {
    switch self {
      case .jaJP: URL(string: "https://www.nintendo.com/jp/switch/av5ja/index.html")!
      case .koKR: URL(string: "https://www.nintendo.com/kr/switch/av5ja/")!
      case .zhCN,
           .zhTW: URL(string: "https://www.nintendo.com/tw/switch/av5ja/")!
      case .enUS,
           .enGB,
           .esES,
           .esMX,
           .frFR,
           .frCA,
           .deDE,
           .itIT,
           .nlNL,
           .ruRU: URL(string: "https://splatoon.nintendo.com/")!
    }
  }
}
