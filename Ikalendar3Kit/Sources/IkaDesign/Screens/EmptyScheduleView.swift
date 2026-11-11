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
/// first download or until its screen is built. Given a way to retry, it says to check the
/// connection and offers Try Again, since the first download failed.
public struct EmptyScheduleView: View {
  @Environment(\.gameLanguage) private var language

  private let retry: (() -> Void)?

  /// - Parameter retry: Downloads the schedules again; `nil` where nothing can, which leaves only
  ///   the title.
  public init(retry: (() -> Void)? = nil) {
    self.retry = retry
  }

  public var body: some View {
    ContentUnavailableView {
      Label(ScreenText.empty.text(in: language), systemImage: "calendar")
    } description: {
      if retry != nil {
        Text(verbatim: ScreenText.emptyDescription.text(in: language))
      }
    } actions: {
      if let retry {
        Button(ScreenText.tryAgain.text(in: language), action: retry)
          .buttonStyle(.glass)
      }
    }
  }
}
