//
//  FetchTimeLabel.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - FetchTimeLabel

/// When the schedule shown was last fetched, and whether the last refresh of it failed, so the
/// player can judge how current it is.
public struct FetchTimeLabel: View {
  @Environment(\.gameLanguage) private var language
  @TimeSettings private var time

  private let fetchTime: Date
  private let now: Date
  private let isStale: Bool

  /// - Parameters:
  ///   - fetchTime: The schedules feed's fetch time.
  ///   - now: The current instant, which decides whether the date is written.
  ///   - isStale: Whether the last refresh of the feed failed.
  public init(fetchTime: Date, now: Date, isStale: Bool) {
    self.fetchTime = fetchTime
    self.now = now
    self.isStale = isStale
  }

  public var body: some View {
    let format = time.format(language)
    VStack(spacing: 2) {
      Text(verbatim: ScreenText.fetchTime.text(in: language, format.time(fetchTime, relativeTo: now)))
      if isStale {
        Label {
          Text(verbatim: ScreenText.refreshFailed.text(in: language))
        } icon: {
          Image(systemName: "exclamationmark.triangle.fill")
        }
      }
    }
    .font(.footnote)
    .foregroundStyle(.readableSecondary)
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .combine)
  }
}
