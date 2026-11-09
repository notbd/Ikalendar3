//
//  CreditsView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - CreditsView

/// The Credits page Settings opens, in the system’s grouped form. It has only its title
/// until the About and Credits pages fill it.
struct CreditsView: View {
  @Environment(\.gameLanguage) private var language

  var body: some View {
    Form { }
      .formStyle(.grouped)
      .navigationTitle(SettingsText.credits.text(in: language))
  }
}
