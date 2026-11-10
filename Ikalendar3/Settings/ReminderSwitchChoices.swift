//
//  ReminderSwitchChoices.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaIntents
import Observation

// MARK: - ReminderSwitchChoices

/// What Settings' reminder switches show while the system answers the permission request: each
/// shows the store's switch, or on from the tap that turns it on until the answer, so it never
/// reads off while the prompt is up. The store gets a switch only once the system allows
/// notifications, so it never holds one the system refused as it was turned on.
@Observable
final class ReminderSwitchChoices {
  /// The kinds turned on whose permission answer is still to come.
  private var asking: Set<EventReminder.Kind> = []
  @ObservationIgnored private let requestPermission: () async -> Bool

  /// - Parameter requestPermission: Asks the system whether the app may notify: the notification
  ///   centre's prompt (`ReminderCenter`), or a test's.
  init(requestPermission: @escaping () async -> Bool = ReminderCenter.requestPermission) {
    self.requestPermission = requestPermission
  }

  /// Whether `kind`'s switch shows on.
  func isOn(_ kind: EventReminder.Kind, in preferences: PreferenceStore) -> Bool {
    asking.contains(kind) || preferences.reminderKinds.contains(kind)
  }

  /// Turns `kind`'s switch on or off as the player chose. Turning one on asks for permission the
  /// first time and writes the switch once the system allows notifications, unless the player has
  /// turned it off again meanwhile.
  ///
  /// - Returns: `false` when the system refused notifications to the switch turned on, which then
  ///   shows off again.
  func choose(_ kind: EventReminder.Kind, isOn: Bool, in preferences: PreferenceStore) async -> Bool {
    guard isOn else {
      asking.remove(kind)
      preferences.reminderKinds.remove(kind)
      return true
    }

    asking.insert(kind)
    let isAllowed = await requestPermission()
    guard asking.remove(kind) != nil else { return true }

    if isAllowed {
      preferences.reminderKinds.insert(kind)
    }
    return isAllowed
  }
}
