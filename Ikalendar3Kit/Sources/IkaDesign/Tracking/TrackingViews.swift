//
//  TrackingViews.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import IkaCore
import SwiftUI

// MARK: - TrackingLockScreenView

/// The Lock Screen and StandBy: the Mode with the Refresh button, the item on with its countdown
/// and Stages, then the next item or the reminder beside the fetch time. The system allows 160
/// points of height, so the reminder gets the full width of its line.
///
/// The widget extension passes the Refresh button, whose intent this module cannot name; the
/// Debug showcase passes its label.
public struct TrackingLockScreenView<Refresh: View>: View {
  let render: TrackingRender
  let refresh: Refresh

  public init(render: TrackingRender, @ViewBuilder refresh: () -> Refresh) {
    self.render = render
    self.refresh = refresh()
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 6) {
        TrackingModeHeading(render: render)
        Spacer(minLength: 4)
        refresh
      }
      TrackingCurrentView(render: render, detail: .cards)
      HStack(spacing: 8) {
        TrackingNextLine(render: render)
        Spacer(minLength: 4)
        TrackingFetchTime(render: render)
      }
    }
    .padding(12)
    .background(InkBackground())
    .trackingEnvironment(render)
  }
}

// MARK: - TrackingSmallView

/// The small family on the watch and in CarPlay, where buttons do nothing: the Mode's icon, the
/// item on and its countdown, or the reminder in their place.
public struct TrackingSmallView: View {
  let render: TrackingRender

  public init(render: TrackingRender) {
    self.render = render
  }

  public var body: some View {
    HStack(spacing: 8) {
      TrackingModeIcon(mode: render.mode)
      VStack(alignment: .leading, spacing: 2) {
        TrackingCurrentView(render: render, detail: .title)
        if let reminder = render.reminder {
          TrackingReminderLabel(reminder: reminder, language: render.terms.language)
        }
        else {
          TrackingCountdown(render: render, isCompact: true)
        }
      }
      Spacer(minLength: 0)
    }
    .padding(8)
    .trackingEnvironment(render)
  }
}

// MARK: - TrackingIsland

/// What each region of the Dynamic Island shows. The Live Activity places these in the system's
/// island, and the Debug showcase in its picture of one, so both show the same views.
@MainActor
public enum TrackingIsland {
  /// The expanded island's leading region: the Mode's icon and name.
  static public func leading(_ render: TrackingRender) -> some View {
    TrackingModeHeading(render: render)
      .trackingEnvironment(render)
  }

  /// The expanded island's trailing region: the countdown, clear of the island's rounded corner.
  static public func trailing(_ render: TrackingRender) -> some View {
    TrackingCountdown(render: render)
      .padding(.trailing, 6)
      .trackingEnvironment(render)
  }

  /// The expanded island's bottom region: the item on with its names and the fetch time, then the
  /// next item or the reminder beside `refresh`.
  static public func bottom(_ render: TrackingRender, @ViewBuilder refresh: () -> some View) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .top, spacing: 8) {
        TrackingCurrentView(render: render, detail: .names)
        Spacer(minLength: 4)
        TrackingFetchTime(render: render)
      }
      HStack(spacing: 8) {
        TrackingNextLine(render: render)
        Spacer(minLength: 4)
        refresh()
      }
    }
    .trackingEnvironment(render)
  }

  /// The compact island's trailing side: the countdown in a smaller face.
  static public func compactTrailing(_ render: TrackingRender) -> some View {
    TrackingCountdown(render: render, isCompact: true)
      .trackingEnvironment(render)
  }
}

// MARK: - Environment

extension View {
  /// The app language, which picks every string, game term and Han face, on Ink's dark materials.
  fileprivate func trackingEnvironment(_ render: TrackingRender) -> some View {
    environment(\.gameLanguage, render.terms.language)
      .environment(\.colorScheme, .dark)
  }
}
#endif
