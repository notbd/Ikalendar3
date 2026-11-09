//
//  EmptyScheduleView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - EmptyScheduleView

/// The shared empty state, in every Style: a screen with no schedule to show yet, before the
/// first download or until its screen is built.
public struct EmptyScheduleView: View {
  @Environment(\.gameLanguage) private var language

  public init() { }

  public var body: some View {
    ContentUnavailableView(ScreenText.empty.text(in: language), systemImage: "calendar")
  }
}
