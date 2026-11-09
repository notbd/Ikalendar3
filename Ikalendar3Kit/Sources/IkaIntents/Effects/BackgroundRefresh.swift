//
//  BackgroundRefresh.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import BackgroundTasks
import Foundation
import IkaCore
import OSLog

// MARK: - BackgroundRefresh

/// The app's background refresh task, which runs the effects shell about every two hours so
/// widgets stay fresh while the app is not opened, and at each boundary of a running Tracking so
/// its Live Activity moves on. Best effort: the system decides when a run happens, and runs none
/// while background refresh is off or after the player quits the app from the app switcher. The
/// Mac has no such task; `MacBackgroundRefresh` stands in for it.
///
/// The app registers `perform(with:)` as the task's handler and asks for the next run each time
/// it moves to the background, which starts the chain that every run then continues.
public enum BackgroundRefresh {
  /// The task's identifier, which the app's Info.plist permits.
  static public let identifier = "io.tianwei.ikalendar3.refresh"

  /// The task's work: asks for the next run first, so the chain holds even when the system cuts
  /// this one short, then runs the shell, which asks again from the Tracking it re-armed.
  static public func perform(with shell: EffectsShell) async {
    await requestNextRun()
    await shell.run()
  }

  /// Asks for the next run after `now`: at the next boundary of a running Tracking, or two hours
  /// on if that is sooner (`EffectsPlan.nextBackgroundRun`).
  static public func requestNextRun(after now: Date = Date()) async {
    await requestRun(at: EffectsPlan.nextBackgroundRun(after: now, trackingBoundaries: TrackingActivities.boundaries()))
  }

  /// Asks for a run at `date` or as soon after as the system allows. The system holds one pending
  /// request for the task, so this one replaces it: every caller asks for the earliest run
  /// needed. A refused request is logged; the Simulator refuses every one.
  @concurrent
  static func requestRun(at date: Date) async {
    let request: BGAppRefreshTaskRequest = .init(identifier: identifier)
    request.earliestBeginDate = date
    do {
      if #available(iOS 27, *) {
        try await BGTaskScheduler.shared.submitTaskRequest(request)
      }
      else {
        try BGTaskScheduler.shared.submit(request)
      }
      Logger.background.info("Next run asked for \(date, privacy: .public)")
    }
    catch {
      Logger.background.error("Run at \(date, privacy: .public) refused: \(error, privacy: .public)")
    }
  }
}
#endif
