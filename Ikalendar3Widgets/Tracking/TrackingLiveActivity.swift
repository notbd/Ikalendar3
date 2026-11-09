//
//  TrackingLiveActivity.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import ActivityKit
import IkaCore
import IkaDesign
import IkaIntents
import SwiftUI
import WidgetKit

// MARK: - TrackingLiveActivity

/// Tracking's Live Activity, always in Ink: on the Lock Screen and in StandBy, in the Dynamic
/// Island, and in the small family that the watch Smart Stack and CarPlay show. Every view picks
/// what it shows by its render time and the system's stale flag (`TrackingRender`); the app's
/// effects shell re-arms the content.
struct TrackingLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: TrackingAttributes.self) { context in
      TrackingFamilyView(render: TrackingRender(context))
        .activityBackgroundTint(.black)
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      let render: TrackingRender = .init(context)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          TrackingModeHeading(render: render)
            .trackingEnvironment(render)
        }
        DynamicIslandExpandedRegion(.trailing) {
          // Clear of the island's rounded corner.
          TrackingCountdown(render: render)
            .padding(.trailing, 6)
            .trackingEnvironment(render)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
              TrackingCurrentView(render: render, detail: .names)
              Spacer(minLength: 4)
              TrackingFetchTime(render: render)
            }
            HStack(spacing: 8) {
              TrackingNextLine(render: render)
              Spacer(minLength: 4)
              TrackingRefreshButton(language: render.terms.language)
            }
          }
          .trackingEnvironment(render)
        }
      } compactLeading: {
        TrackingModeIcon(mode: render.mode)
      } compactTrailing: {
        TrackingCountdown(render: render, isCompact: true)
          .trackingEnvironment(render)
      } minimal: {
        TrackingModeIcon(mode: render.mode)
      }
      .keylineTint(Color(ModeColor(render.mode).base))
    }
    .supplementalActivityFamilies([.small])
  }
}

// MARK: - TrackingFamilyView

/// The activity's own view in the family the system asks for: the Lock Screen's, or the small
/// one of the watch Smart Stack and CarPlay.
private struct TrackingFamilyView: View {
  @Environment(\.activityFamily) private var family

  let render: TrackingRender

  var body: some View {
    Group {
      switch family {
        case .small: TrackingSmallView(render: render)
        case .medium: TrackingLockScreenView(render: render)
        @unknown default: TrackingLockScreenView(render: render)
      }
    }
    .trackingEnvironment(render)
  }
}

// MARK: - TrackingLockScreenView

/// The Lock Screen and StandBy: the Mode with the Refresh button, the item on with its countdown
/// and Stages, then the next item or the reminder beside the fetch time. The system allows 160
/// points of height, so the reminder gets the full width of its line.
private struct TrackingLockScreenView: View {
  let render: TrackingRender

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 6) {
        TrackingModeHeading(render: render)
        Spacer(minLength: 4)
        TrackingRefreshButton(language: render.terms.language)
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
  }
}

// MARK: - TrackingSmallView

/// The small family on the watch and in CarPlay, where buttons do nothing: the Mode's icon, the
/// item on and its countdown, or the reminder in their place.
private struct TrackingSmallView: View {
  let render: TrackingRender

  var body: some View {
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
