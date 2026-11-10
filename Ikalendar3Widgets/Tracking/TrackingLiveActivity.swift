//
//  TrackingLiveActivity.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import ActivityKit
import AppIntents
import IkaCore
import IkaDesign
import IkaIntents
import SwiftUI
import WidgetKit

// MARK: - TrackingLiveActivity

/// Tracking's Live Activity, always in Ink: on the Lock Screen and in StandBy, in the Dynamic
/// Island, and in the small family that the watch Smart Stack and CarPlay show. Every view picks
/// what it shows by its render time and the system's stale flag (`TrackingRender`); the app's
/// effects shell re-arms the content. The views live in `IkaDesign`, so the app's Debug showcase
/// draws the same ones.
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
          TrackingIsland.leading(render)
        }
        DynamicIslandExpandedRegion(.trailing) {
          TrackingIsland.trailing(render)
        }
        DynamicIslandExpandedRegion(.bottom) {
          TrackingIsland.bottom(render) {
            TrackingRefreshButton(language: render.terms.language)
          }
        }
      } compactLeading: {
        TrackingModeIcon(mode: render.mode)
      } compactTrailing: {
        TrackingIsland.compactTrailing(render)
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
    switch family {
      case .small: TrackingSmallView(render: render)
      case .medium: lockScreen
      @unknown default: lockScreen
    }
  }

  private var lockScreen: some View {
    TrackingLockScreenView(render: render) {
      TrackingRefreshButton(language: render.terms.language)
    }
  }
}

// MARK: - TrackingRefreshButton

/// The Refresh button: the Live Activity intent that runs the app's effects shell, labelled with
/// the word the reminders tell the player to tap.
private struct TrackingRefreshButton: View {
  let language: GameLanguage

  var body: some View {
    Button(intent: RefreshTrackingIntent()) {
      TrackingRefreshLabel(
        title: TrackingText.refresh.text(in: language),
        systemImage: TrackingText.refresh.systemImage)
    }
    .trackingRefreshButtonStyle()
  }
}
#endif
