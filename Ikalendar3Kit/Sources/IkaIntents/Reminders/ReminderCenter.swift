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

/// The app's event reminders in the system's notification centre: the shell's hands for the
/// reminder part of the effects plan, and the permission Settings asks for. It decides nothing:
/// which reminders are pending comes from `IkaCore`. Not on watchOS: the iPhone's reminders reach
/// the watch.
public enum ReminderCenter {
  /// Replaces every pending reminder of the app's with `reminders`, matched by the identifier's
  /// namespace, so any other pending notification stays. An event's identifier is stable, so
  /// adding it again replaces its request in place.
  static func replace(with reminders: [EventReminder]) async {
    let center: UNUserNotificationCenter = .current()
    let ids: Set = .init(reminders.map(\.id))
    let stale = await center.pendingNotificationRequests()
      .map(\.identifier)
      .filter { $0.hasPrefix(EventReminder.namespace) && !ids.contains($0) }
    center.removePendingNotificationRequests(withIdentifiers: stale)

    for reminder in reminders {
      do {
        try await center.add(reminder.request)
      }
      catch {
        Logger.reminders.error("Reminder \(reminder.id, privacy: .public) refused: \(error, privacy: .public)")
      }
    }
    Logger.reminders.info("Reminders replaced: \(reminders.count) pending, \(stale.count) removed")
  }

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
