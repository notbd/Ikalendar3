//
//  TrackingControl.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import AppIntents
import IkaCore
import IkaDesign
import IkaIntents
import SwiftUI
import WidgetKit

// MARK: - TrackingControl

/// The Control Center control that starts Tracking the Mode a player chooses, so a Live Activity is
/// one tap away. Its button runs `IkaIntents`' start-Tracking intent, which the system runs in the
/// app's process. It reads as the Mode's name beside the track button's symbol, which takes the
/// Mode's colour while pressed: Control Center draws only symbols, so the bundled Mode icon cannot
/// show there. Its name, its configuration's title and its Mode setting are `IkaIntents`' own
/// words, read from the copy of that module's `Localizable` table the extension carries, so they
/// always match the intent's; only the description is the control's. iOS only, as Tracking is.
struct TrackingControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    AppIntentControlConfiguration(kind: WidgetKind.tracking.rawValue, provider: TrackingControlProvider()) { mode in
      ControlWidgetButton(action: StartTrackingIntent(mode: mode)) {
        Label(mode.mode.name(in: WidgetData.language), systemImage: TrackingText.startTracking.systemImage)
      }
      .tint(Color(ModeColor(mode.mode).base))
    }
    .displayName(LocalizedStringResource("Start Tracking"))
    .description(LocalizedStringResource("control.tracking.description", table: "Controls"))
    .promptsForUserConfiguration()
  }
}

// MARK: - TrackingControlIntent

/// The control's configuration: the Mode it starts Tracking.
struct TrackingControlIntent: ControlConfigurationIntent {
  static let title: LocalizedStringResource = .init("Start Tracking")

  @Parameter(title: LocalizedStringResource("Mode"), default: .regularBattle)
  var mode: ModeParameter

  init() { }
}

// MARK: - TrackingControlProvider

/// Hands the control its configured Mode. The control shows no state, so the preview and the
/// current value are both the configuration's Mode.
struct TrackingControlProvider: AppIntentControlValueProvider {
  func previewValue(configuration: TrackingControlIntent) -> ModeParameter {
    configuration.mode
  }

  func currentValue(configuration: TrackingControlIntent) async throws -> ModeParameter {
    configuration.mode
  }
}
#endif
