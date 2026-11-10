//
//  RefreshFeedback.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

extension View {
  /// What every layout shows as refreshes run, for the screens below: the haptic each run hands
  /// the status, and after each refresh that fails, the toast `refreshFailureToast()` shows for
  /// three seconds while the screens keep their data. While `isSilent`, as while the welcome
  /// screen shows, neither plays.
  func refreshFeedback(isSilent: Bool = false) -> some View {
    modifier(RefreshFeedback(isSilent: isSilent))
  }

  /// Shows the failed-refresh toast over the bottom of this view while `refreshFeedback()` above
  /// shows it: over each tab above the tab bar on iPhone, over the detail column on iPad.
  func refreshFailureToast() -> some View {
    overlay(alignment: .bottom) {
      RefreshFailureToastSlot()
    }
  }
}

// MARK: - RefreshFeedback

/// Plays the refresh haptic and keeps whether the failed-refresh toast shows, which it hands down
/// through the environment.
private struct RefreshFeedback: ViewModifier {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppStatus.self) private var status

  /// Whether the haptic and the toast stay off.
  let isSilent: Bool

  /// A new value for each failed refresh; the toast shows while it is set.
  @State private var failure: UUID?

  func body(content: Content) -> some View {
    content
      .environment(\.showsRefreshFailureToast, failure != nil)
      .sensoryFeedback(trigger: status.refreshHaptic) { _, new in
        isSilent ? nil : new?.feedback
      }
      .onChange(of: engine.status) { old, new in
        if old == .loading, new == .failed, !isSilent {
          withAnimation { failure = UUID() }
        }
      }
      .task(id: failure) {
        guard failure != nil, await (try? Task.sleep(for: .seconds(3))) != nil else { return }

        withAnimation { failure = nil }
      }
  }
}

// MARK: - RefreshFailureToastSlot

/// The toast while `RefreshFeedback` shows it.
private struct RefreshFailureToastSlot: View {
  @Environment(\.showsRefreshFailureToast) private var isShown

  var body: some View {
    if isShown {
      RefreshFailureToast()
        .padding(.bottom, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
  }
}

extension EnvironmentValues {
  /// Whether the failed-refresh toast shows.
  @Entry fileprivate var showsRefreshFailureToast = false
}
