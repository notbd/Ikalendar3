//
//  Ikalendar3App.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import AppIntents
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

  #if os(macOS)
  @NSApplicationDelegateAdaptor private var appDelegate: MacAppDelegate
  /// The periodic and after-wake runs that stand in for the background refresh task on the Mac;
  /// `nil` without services or in the unit-test host.
  @State private var backgroundRefresh: MacBackgroundRefresh?
  #endif

  @Environment(\.scenePhase) private var scenePhase

  var body: some Scene {
    #if os(macOS)
    // One window, which every launch opens (`MacAppDelegate`) and the menu bar window's button
    // brings back after it closes; the app keeps running in the menu bar.
    Window(Text(verbatim: Self.name), id: Self.mainWindowID) {
      mainWindow
    }
    .defaultSize(MacWindowMetrics.defaultSize)
    .commands { MacWindowCommands(services: AppServices.isTestHost ? nil : services) }
    .runningEffects(AppServices.isTestHost ? nil : services, scenePhase: scenePhase)

    MenuBarExtra(isInserted: .constant(backgroundRefresh != nil)) {
      if let services {
        MenuBarWindow()
          .environment(services)
      }
    } label: {
      // Named for the app, not the symbol, so VoiceOver reads the app's name.
      Image(systemName: "calendar")
        .accessibilityLabel(Text(verbatim: Self.name))
    }
    .menuBarExtraStyle(.window)

    // The standard Settings window, which Command-comma opens.
    Settings {
      if !AppServices.isTestHost, let services {
        SettingsView()
          .environment(services)
      }
    }
    #else
    WindowGroup {
      mainWindow
    }
    .runningEffects(AppServices.isTestHost ? nil : services, scenePhase: scenePhase)
    #endif
  }

  /// The app's window: the schedules, or what stands in for them.
  @ViewBuilder
  private var mainWindow: some View {
    if AppServices.isTestHost {
      TestHostPlaceholder()
    }
    else if let services {
      Group {
        #if DEBUG
        if let showcase = Showcase.requested() {
          ShowcaseView(showcase: showcase)
        }
        else if DebugLaunch.showsEventCards() {
          EventCardGallery()
        }
        else {
          AppRootView()
        }
        #else
        AppRootView()
        #endif
      }
      .environment(services)
      #if DEBUG
      .debugWindow()
      #endif
    }
    else {
      // With nowhere to keep data the widget extension can see, there is nothing to show.
      EmptyScheduleView()
        .environment(\.gameLanguage, AppServices.language)
    }
  }

  /// Registers the fonts and points image lookups at the resource framework before anything draws,
  /// then builds this launch's objects, and has the pending reminders follow their switches for
  /// the app's whole life, whoever writes them.
  init() {
    BundledResources.load(from: IkaResources.bundle)
    let services: AppServices? = .forThisLaunch()
    _services = State(initialValue: services)
    if !AppServices.isTestHost, let services {
      services.effects.followReminderSwitches()
      #if os(macOS)
      _backgroundRefresh = State(initialValue: MacBackgroundRefresh(shell: services.effects))
      #endif
    }
  }
}

#if os(macOS)

// MARK: - MacAppDelegate

/// The Mac app's launch and close behaviour, which its scenes cannot declare:
///
/// - Every launch opens the main window: the app never restores windows. A launch that restores
///   a run whose window was closed (the run ended without a quit, such as a crash or a force quit,
///   or the player keeps windows when quitting) would otherwise open none, only the menu bar
///   entry; `defaultLaunchBehavior(.presented)` on the `Window`, alone or with
///   `restorationBehavior(.disabled)`, does not change that. The window's frame still comes back:
///   AppKit autosaves it in the defaults, outside the restored state.
/// - The app keeps running in the menu bar after its window closes, so the menu bar window and the
///   periodic refresh stay; with a single `Window` scene, SwiftUI would quit the app instead.
final class MacAppDelegate: NSObject, NSApplicationDelegate {
  /// Turns window restoration off before AppKit restores windows, which it does after this call.
  /// A value set in the app's own defaults still wins over this registered one.
  func applicationWillFinishLaunching(_: Notification) {
    UserDefaults.standard.register(defaults: ["ApplePersistenceIgnoreState": true])
  }

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
    false
  }
}

extension Ikalendar3App {
  /// The id of the app's one window, which `openWindow` brings to the front.
  static let mainWindowID = "main"
}
#endif

extension Ikalendar3App {
  /// The app's name, as the menu bar, the window title, About and the welcome screen show it;
  /// never translated.
  static let name = "ikalendar3"
}

// MARK: - AppIntentsPackageList

/// Adds `IkaIntents`' types to the app's App Intents metadata, so the system finds the intents the
/// app's process runs, such as the start-Tracking and Refresh Live Activity intents.
struct AppIntentsPackageList: AppIntentsPackage {
  static var includedPackages: [any AppIntentsPackage.Type] { [IkaIntentsPackage.self] }
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
  /// is missing, there is nothing to refresh. The Mac has no background refresh task: its
  /// periodic and after-wake runs (`MacBackgroundRefresh`) stand in for it.
  fileprivate func runningEffects(_ services: AppServices?, scenePhase: ScenePhase) -> some Scene {
    let scene = onChange(of: scenePhase, initial: true) { _, phase in
      guard let services else { return }

      switch phase {
        case .active:
          Task {
            await services.effects.run(isRequested: false, reportingTo: services.status)
            #if DEBUG && os(iOS)
            await DebugLaunch.restartShortTracking(with: services)
            #endif
          }

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
