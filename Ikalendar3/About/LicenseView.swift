//
//  LicenseView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - LicenseView

/// A licence's full text, read from the app's bundle so it shows offline, under a banner with the
/// licence's name and the work it covers. The toolbar button opens the work's repository.
///
/// Licence files wrap their lines at about 80 columns, which a phone's width would break again
/// mid-line, so the page joins each paragraph's lines and lets the text wrap to the width.
struct LicenseView: View {
  @Environment(\.gameLanguage) private var language
  @Environment(\.openURL) private var openURL

  let license: CreditedLicense

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        banner
        Text(license.text.map(\.reflowed) ?? "")
          .font(.footnote)
          .textSelection(.enabled)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
    }
    .navigationTitle(license.work)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button(AboutText.viewRepository.text(in: language), systemImage: "arrow.up.forward.app.fill") {
          openURL(license.repository)
        }
      }
    }
  }

  private var banner: some View {
    HStack {
      Image(systemName: "doc.text")
        .font(.largeTitle.weight(.medium))
        .accessibilityHidden(true)

      VStack(alignment: .leading) {
        Text(verbatim: String(license.repository.path(percentEncoded: false).trimmingPrefix("/")))
          .font(.caption)
          .foregroundStyle(.readableSecondary)
        Text(verbatim: license.name)
          .font(.title3.bold())
      }
    }
  }
}

// MARK: - Reflow

extension String {
  /// The text with each paragraph's hard line breaks joined into spaces; paragraphs stay apart.
  fileprivate var reflowed: String {
    split(separator: /\n[ \t]*\n/)
      .lazy
      .map { paragraph in
        paragraph
          .split(separator: "\n")
          .lazy
          .map { $0.trimmingCharacters(in: .whitespaces) }
          .joined(separator: " ")
      }
      .joined(separator: "\n\n")
  }
}
