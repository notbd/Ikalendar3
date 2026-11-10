//
//  ReminderCenter.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if !os(watchOS)
import Foundation
import IkaCore
import OSLog
import UserNotifications

// MARK: - ReminderCenter

/// The permission the app's event reminders need, which Settings asks for. Which reminders are
/// pending comes from `IkaCore`; `ReminderReplacements` puts them in the system's notification
/// centre. Not on watchOS: the iPhone's reminders reach the watch.
public enum ReminderCenter {
  /// Whether the app may show reminders, asking the player the first time: the system shows its
  /// prompt only while the player has not answered it, so Settings calls this as a switch turns
  /// on, and never before.
  static public func requestPermission() async -> Bool {
    let center: UNUserNotificationCenter = .current()
    guard await center.notificationSettings().authorizationStatus == .notDetermined else {
      return await isAllowed()
    }

    do {
      let isGranted = try await center.requestAuthorization(options: [.alert, .sound])
      Logger.reminders.info("Notification permission \(isGranted ? "granted" : "denied", privacy: .public)")
      return isGranted
    }
    catch {
      Logger.reminders.error("Notification permission request failed: \(error, privacy: .public)")
      return false
    }
  }

  /// Whether the player has turned the app's notifications off: denied at the prompt or later in
  /// the system's settings. `false` before the prompt has been answered.
  static public func isDenied() async -> Bool {
    await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .denied
  }

  /// Whether the system lets the app show notifications now. Provisional delivery counts: its
  /// reminders reach Notification Center quietly.
  static private func isAllowed() async -> Bool {
    let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    return status == .authorized || status == .provisional
  }
}

// MARK: - ReminderReplacements

/// Replacements of the app's pending event reminders: the shell's hands for the reminder part of
/// the effects plan. It decides nothing: which reminders are pending comes from `IkaCore`.
///
/// Each replacement reads the pending requests, removes the stale ones and adds the new ones, and
/// each step suspends. Replacements take turns (`Turns`) across all three steps, in the order the
/// shell calls them, so the reminders of the latest call stand: a replacement planned with a
/// switch still on can never add its kind back after a later one, planned with it off, has run.
@MainActor
final class ReminderReplacements {
  /// The process's replacements, on the system's notification centre. Every effects shell of the
  /// process, the app's and each intent's, replaces through it, so all of them take one set of
  /// turns.
  static let system: ReminderReplacements = .init(center: UNUserNotificationCenter.current())

  private let center: any PendingRequests
  private let turns: Turns = .init()

  /// Replacements of `center`'s pending requests.
  init(center: any PendingRequests) {
    self.center = center
  }

  /// Replaces every pending reminder of the app's with `reminders`, matched by the identifier's
  /// namespace, so any other pending notification stays. An event's identifier is stable, so
  /// adding it again replaces its request in place.
  func replace(with reminders: [EventReminder]) async {
    await turns.run {
      let ids: Set = .init(reminders.map(\.id))
      let stale = await center.pendingIdentifiers()
        .filter { $0.hasPrefix(EventReminder.namespace) && !ids.contains($0) }
      center.removePending(stale)

      for reminder in reminders {
        do {
          try await center.add(reminder)
        }
        catch {
          Logger.reminders.error("Reminder \(reminder.id, privacy: .public) refused: \(error, privacy: .public)")
        }
      }
      Logger.reminders.info("Reminders replaced: \(reminders.count) pending, \(stale.count) removed")
    }
  }
}

// MARK: - PendingRequests

/// The pending notification requests as a replacement reads and edits them: the system's
/// notification centre, or a test's stand-in whose suspension points the test controls.
@MainActor
protocol PendingRequests {
  /// The identifiers of every pending request of the app's.
  func pendingIdentifiers() async -> [String]
  /// Removes the pending requests with these identifiers.
  func removePending(_ identifiers: [String])
  /// Adds `reminder`'s request, replacing a pending one with its identifier.
  func add(_ reminder: EventReminder) async throws
}

extension UNUserNotificationCenter: PendingRequests {
  func pendingIdentifiers() async -> [String] {
    await pendingNotificationRequests().map(\.identifier)
  }

  func removePending(_ identifiers: [String]) {
    removePendingNotificationRequests(withIdentifiers: identifiers)
  }

  func add(_ reminder: EventReminder) async throws {
    try await add(reminder.request)
  }
}

// MARK: - EventReminder

extension EventReminder {
  /// The notification request: the title and body at the fire date, an absolute instant whatever
  /// time zone the device moves to.
  fileprivate var request: UNNotificationRequest {
    let content: UNMutableNotificationContent = .init()
    content.title = title
    content.body = body
    content.sound = .default

    var calendar: Calendar = .init(identifier: .gregorian)
    calendar.timeZone = .gmt
    let components = calendar.dateComponents(
      [.calendar, .timeZone, .year, .month, .day, .hour, .minute, .second],
      from: fireDate)
    return UNNotificationRequest(
      identifier: id,
      content: content,
      trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
  }
}
#endif
