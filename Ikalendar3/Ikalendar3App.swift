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
    .runningEffects(AppServices.isTestHost ? nil : services, scenePhase: scenePhase)

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

// MARK: - Effects

extension Scene {
  /// Runs the effects shell on the app's transitions: each time it becomes active, launch included
  /// (the gate decides whether a request goes out), handing how the run ended to the status; on
  /// iOS, from the background refresh task, asking for the next run each time the app moves to
  /// the background. Without services, as in the unit-test host or when the App Group container
  /// is missing, there is nothing to refresh. The Mac has no background refresh task.
  fileprivate func runningEffects(_ services: AppServices?, scenePhase: ScenePhase) -> some Scene {
    let scene = onChange(of: scenePhase, initial: true) { _, phase in
      guard let services else { return }

      switch phase {
        case .active:
          Task { await services.effects.run(isRequested: false, reportingTo: services.status) }

        case .background:
          #if os(iOS)
          Task { await BackgroundRefresh.requestNextRun() }
          #endif

        default:
          break
      }
    }
    #if os(iOS)
    return scene.backgroundTask(.appRefresh(BackgroundRefresh.identifier)) {
      guard let services else { return }

      await BackgroundRefresh.perform(with: services.effects)
    }
    #else
    return scene
    #endif
  }
}
