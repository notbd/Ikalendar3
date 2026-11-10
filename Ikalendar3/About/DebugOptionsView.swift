//
//  DebugOptionsView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import IkaIntents
import SwiftUI

// MARK: - DebugOptionsView

/// The maintainer's options, as ikalendar 2's, for testing first-run paths: show the welcome
/// screen again, and reset the app states, the preferences or both.
///
/// They ship in Release builds, so every reset changes only the preferences store, and the pending
/// reminders that follow its switches: never the feed cache or its attempt records, which would
/// let anyone bypass splatoon3.ink's hourly limit.
/// Show Onboarding Screen and Reset All close Settings, so the welcome screen shows at once.
struct DebugOptionsView: View {
  @Environment(PreferenceStore.self) private var preferences
  @Environment(AppStatus.self) private var status
  @Environment(\.gameLanguage) private var language
  @Environment(\.effects) private var effects
  #if os(macOS)
  @Environment(\.openWindow) private var openWindow
  #endif

  /// What the banner confirms for a moment after a reset that keeps the page open, or `nil` while
  /// it warns.
  @State private var confirmation: AboutText?
  /// Counts the steps done, each of which plays the success haptic.
  @State private var steps = 0

  var body: some View {
    Form {
      Section {
        Button(text(.showOnboarding)) {
          preferences.shouldShowOnboarding = true
          showWelcomeScreen()
        }
      }

      Section {
        Button(text(.resetAppStates)) {
          preferences.resetAppStates()
          confirm(.statesReset)
        }
        Button(text(.resetAppPreferences)) {
          preferences.resetAppPreferences()
          rebuildReminders()
          confirm(.preferencesReset)
        }
        Button(text(.resetAll)) {
          preferences.resetAll()
          rebuildReminders()
          showWelcomeScreen()
        }
      }
    }
    .formStyle(.grouped)
    .navigationTitle(text(.debugOptions))
    .safeAreaBar(edge: .bottom) {
      banner
        .padding()
    }
    .sensoryFeedback(Haptic.done, trigger: steps)
    .task(id: confirmation) {
      guard confirmation != nil, await (try? Task.sleep(for: .seconds(2))) != nil else { return }

      withAnimation { confirmation = nil }
    }
  }

  // MARK: Banner

  private var banner: some View {
    Group {
      if let confirmation {
        Label(text(confirmation), systemImage: "checkmark.circle.fill")
      }
      else {
        Label(text(.warning), systemImage: "exclamationmark.triangle.fill")
          .periodicPulse()
      }
    }
    .font(.system(.body, design: .rounded, weight: .semibold))
    .padding()
    .padding(.horizontal)
    .adaptiveGlassEffect(in: .capsule)
  }

  // MARK: Actions

  /// Replaces the pending reminders after a reset turned their switches off, so none is left
  /// scheduled for a switch that is now off.
  private func rebuildReminders() {
    Task { await effects?.rebuildReminders() }
  }

  private func confirm(_ text: AboutText) {
    steps += 1
    withAnimation { confirmation = text }
  }

  /// Closes Settings, so the welcome screen the preferences now ask for shows: on the Mac, brings
  /// the app's window to the front instead, since Settings has a window of its own.
  private func showWelcomeScreen() {
    steps += 1
    status.isSettingsPresented = false
    #if os(macOS)
    openWindow(id: Ikalendar3App.mainWindowID)
    #endif
  }

  private func text(_ text: AboutText) -> String {
    text.text(in: language)
  }
}
