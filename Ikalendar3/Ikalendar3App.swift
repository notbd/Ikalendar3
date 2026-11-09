//
//  Ikalendar3App.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import IkaIntents
import IkaResources
import SwiftUI

// MARK: - Ikalendar3App

/// The app on iPhone, iPad and Mac, and its composition root: the long-lived objects are built
/// here once, for this launch, and injected through the environment. No singletons.
@main
struct Ikalendar3App: App {
  /// The objects every screen reads, or `nil` when the App Group container is missing (logged).
  @State private var services: AppServices?

  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    WindowGroup {
      if AppServices.isTestHost {
        TestHostPlaceholder()
      }
      else if let services {
        ModeTabsView()
          .environment(services)
      }
      else {
        // With nowhere to keep data the widget extension can see, there is nothing to show.
        EmptyScheduleView()
          .environment(\.gameLanguage, AppServices.language)
      }
    }
    .refreshingInBackground(services?.effects, scenePhase: scenePhase)

    #if os(macOS)
    // The standard Settings window, which Command-comma opens.
    Settings {
      if !AppServices.isTestHost, let services {
        SettingsView()
          .environment(services)
      }
    }
    #endif
  }

  /// Registers the fonts and points image lookups at the resource framework before anything draws,
  /// then builds this launch's objects.
  init() {
    BundledResources.load(from: IkaResources.bundle)
    _services = State(initialValue: AppServices.forThisLaunch())
  }
}

// MARK: - TestHostPlaceholder

/// What the app shows while it hosts unit tests: no animations, no timers and no refresh, so
/// nothing contends with the tests for the main actor.
private struct TestHostPlaceholder: View {
  var body: some View {
    Text(verbatim: "ikalendar3 unit test host")
      .foregroundStyle(.secondary)
  }
}

// MARK: - Background refresh

extension Scene {
  /// On iOS, runs the effects shell from the background refresh task and asks for the next run
  /// each time the app moves to the background. Without a shell, as when the App Group container
  /// is missing, there is nothing to refresh. The Mac has no background refresh task.
  fileprivate func refreshingInBackground(_ effects: EffectsShell?, scenePhase: ScenePhase) -> some Scene {
    #if os(iOS)
    onChange(of: scenePhase) { _, phase in
      guard effects != nil, phase == .background else { return }

      Task { await BackgroundRefresh.requestNextRun() }
    }
    .backgroundTask(.appRefresh(BackgroundRefresh.identifier)) {
      guard let effects else { return }

      await BackgroundRefresh.perform(with: effects)
    }
    #else
    self
    #endif
  }
}
