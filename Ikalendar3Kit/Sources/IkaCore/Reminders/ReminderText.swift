//
//  ReminderText.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - ReminderText

/// The strings of event reminders, from `IkaCore`'s `Reminders` string table: the notification's
/// title and what Settings shows while notifications are off. The raw value is the catalog key.
public enum ReminderText: String, CaseIterable, Sendable {
  /// "%@ starts now", a reminder's title around the event's name.
  case startsNow = "reminders.startsNow"
  /// The note under the switches while the system does not allow the app's notifications.
  case notificationsOff = "reminders.notificationsOff"
  /// The row that opens the app's notification settings.
  case notificationSettings = "reminders.notificationSettings"

  /// The string in a text set.
  public func text(in language: GameLanguage) -> String {
    Bundle.module.localizedString(forKey: rawValue, table: "Reminders", in: language)
  }

  /// The template in a text set, filled in with `argument`.
  func text(in language: GameLanguage, _ argument: String) -> String {
    String(format: text(in: language), locale: Locale(identifier: language.rawValue), argument)
  }
}
