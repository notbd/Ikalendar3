//
//  WatchBackgroundRefresh.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import OSLog
import WatchKit

// MARK: - WatchBackgroundRefresh

/// The watch's background refresh task, which runs the effects shell about every two hours, five
/// minutes past a Rotation boundary (`WatchRefreshSchedule`), so the complications stay fresh while
/// the app is not opened. Best effort: the system decides when a run happens, within the budget it
/// grants an app with a complication on the active face.
///
/// The app registers `perform(with:)` as the task's handler and asks for the next run each time it
/// moves to the background, which starts the chain that every run then continues.
enum WatchBackgroundRefresh {
  /// The task's identifier, which the request carries as its user info so that SwiftUI hands the
  /// run to the handler registered under it.
  static let identifier = "io.tianwei.ikalendar3.watchkitapp.refresh"

  /// The task's work: asks for the next run first, so the chain holds even when the system cuts
  /// this one short, then runs the shell.
  static func perform(with shell: WatchEffectsShell) async {
    requestNextRun()
    await shell.run()
  }

  /// Asks for the next run after `now`, as `WatchRefreshSchedule` places it. The system holds one
  /// pending request, so this one replaces it. A refused request is logged.
  static func requestNextRun(after now: Date = Date()) {
    let date: Date = WatchRefreshSchedule.nextRun(after: now)
    // The system may call back on any thread, so the completion keeps off the main actor.
    WKApplication.shared().scheduleBackgroundRefresh(
      withPreferredDate: date,
      userInfo: identifier as NSString)
    { @Sendable error in
      if let error {
        Logger.background.error("Run at \(date, privacy: .public) refused: \(error, privacy: .public)")
      }
      else {
        Logger.background.info("Next run asked for \(date, privacy: .public)")
      }
    }
  }
}
