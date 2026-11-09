//
//  Ikalendar3WatchApp.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import IkaResources
import SwiftUI

// MARK: - Ikalendar3WatchApp

/// The watch app, and its composition root: the long-lived objects are built here once, for this
/// launch, and injected through the environment. It runs without its iPhone: it fetches on its
/// own and keeps its last good data in the watch's App Group container.
@main
struct Ikalendar3WatchApp: App {
  /// The objects every page reads, or `nil` when the App Group container is missing (logged).
  @State private var services: WatchServices?

  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    WindowGroup {
      Group {
        if let services {
          NavigationStack {
            NowScreen()
              .navigationDestination(for: Mode.self) { mode in
                ModePagePlaceholder(mode: mode)
              }
          }
          .environment(services)
        }
        else {
          // With nowhere to keep data the complications can see, there is nothing to show.
          EmptyScheduleView()
        }
      }
      .environment(\.gameLanguage, WatchServices.language)
    }
    .runningEffects(services, scenePhase: scenePhase)
  }

  /// Registers the fonts and points image lookups at the resource framework before anything draws,
  /// then builds this launch's objects.
  init() {
    BundledResources.load(from: IkaResources.bundle)
    _services = State(initialValue: WatchServices.forThisLaunch())
  }
}

// MARK: - Effects

extension Scene {
  /// Runs the effects shell on the app's transitions: each time it becomes active, launch included
  /// (the gate decides whether a request goes out), and from the background refresh task, asking
  /// for the next background run each time the app moves to the background. Without services, as
  /// when the App Group container is missing, there is nothing to refresh.
  fileprivate func runningEffects(_ services: WatchServices?, scenePhase: ScenePhase) -> some Scene {
    onChange(of: scenePhase, initial: true) { _, phase in
      guard let services else { return }

      switch phase {
        case .active:
          Task { await services.effects.run() }

        case .background:
          WatchBackgroundRefresh.requestNextRun()

        default:
          break
      }
    }
    .backgroundTask(.appRefresh(WatchBackgroundRefresh.identifier)) {
      guard let services else { return }

      await WatchBackgroundRefresh.perform(with: services.effects)
    }
  }
}
