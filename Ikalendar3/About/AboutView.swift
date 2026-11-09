//
//  AboutView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - AboutView

/// The About page Settings opens, in the system’s grouped form. It has only its title
/// until the About and Credits pages fill it.
struct AboutView: View {
  @Environment(\.gameLanguage) private var language

  var body: some View {
    Form { }
      .formStyle(.grouped)
      .navigationTitle(SettingsText.about.text(in: language))
  }
}
