//
//  MacBackgroundRefresh.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(macOS)
import AppKit
import Foundation
import IkaCore
import OSLog

// MARK: - MacBackgroundRefresh

/// The Mac's stand-in for the background refresh task macOS lacks. While the app runs, with its
/// window open or only its menu bar entry, it runs the effects shell about every two hours, as the
/// iOS task asks to, and shortly after each wake from sleep, so the desktop widgets reload after
/// each refresh that commits a feed. Every run goes through the shell and so through its hourly
/// gate, which keeps a wake soon after a refresh from the network. Nothing runs after the player
/// quits the app.
///
/// The app makes one at launch and keeps it for the process's life.
@MainActor
final public class MacBackgroundRefresh {
  /// The system's scheduler of the periodic run, which picks a moment within the tolerance when
  /// the Mac is idle and runs an overdue run soon after a wake.
  private let scheduler: NSBackgroundActivityScheduler = .init(identifier: "io.tianwei.ikalendar3.refresh")
  private let wakeObserver: any NSObjectProtocol

  /// Starts the periodic run and the run after each wake, both through `shell`.
  public init(shell: EffectsShell) {
    scheduler.repeats = true
    scheduler.interval = EffectsPlan.backgroundRefreshInterval
    scheduler.tolerance = Self.tolerance
    scheduler.qualityOfService = .utility
    // The system calls back on a queue of its own, so neither closure takes the main actor's
    // isolation; each hops to it for the run.
    scheduler.schedule { @Sendable completion in
      Task { @MainActor in
        Logger.background.info("Periodic run")
        await shell.run()
        completion(.finished)
      }
    }
    wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.didWakeNotification,
      object: nil,
      queue: .main)
    { @Sendable _ in
      Task { @MainActor in
        Logger.background.info("Woke: run in \(Self.wakeDelay, privacy: .public)")
        try? await Task.sleep(for: Self.wakeDelay)
        await shell.run()
      }
    }
  }

  isolated deinit {
    scheduler.invalidate()
    NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
  }

  /// How far the periodic run may move from its interval, so the system can join it with other
  /// work.
  static private let tolerance: TimeInterval = 10 * 60
  /// How long the run after a wake waits for the network to come back. A request with no answer
  /// would back the gate off.
  static private let wakeDelay: Duration = .seconds(30)
}
#endif
