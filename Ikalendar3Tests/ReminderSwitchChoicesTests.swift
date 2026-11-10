//
//  ReminderSwitchChoicesTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import Testing
@testable import Ikalendar3

// MARK: - ReminderSwitchChoicesTests

/// Pins that a reminder switch shows the player's choice while the permission prompt is up, and
/// that the store gets it only once the system allows notifications.
struct ReminderSwitchChoicesTests {
  private let suite = "ReminderSwitchChoicesTests-\(UUID().uuidString)"

  @Test(arguments: [true, false])
  func `A switch turned on shows on while the prompt is up, then as the system answered`(isAllowed: Bool) async throws {
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let preferences: PreferenceStore = .init(defaults: defaults)
    let prompt: PermissionPrompt = .init()
    let choices: ReminderSwitchChoices = .init(requestPermission: prompt.ask)

    let choosing = Task { await choices.choose(.bigRun, isOn: true, in: preferences) }
    await prompt.waitUntilUp()
    let isOnWhileAsking = choices.isOn(.bigRun, in: preferences)
    let isStoredWhileAsking = preferences.isBigRunReminderOn
    prompt.answer(isAllowed)
    let stands = await choosing.value

    #expect(isOnWhileAsking)
    #expect(!isStoredWhileAsking)
    #expect(stands == isAllowed)
    #expect(choices.isOn(.bigRun, in: preferences) == isAllowed)
    #expect(preferences.isBigRunReminderOn == isAllowed)
  }

  /// The Mac's prompt is a notification that leaves Settings usable.
  @Test
  func `A switch turned off while the prompt is up stays off, whatever the answer`() async throws {
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let preferences: PreferenceStore = .init(defaults: defaults)
    let prompt: PermissionPrompt = .init()
    let choices: ReminderSwitchChoices = .init(requestPermission: prompt.ask)

    let choosing = Task { await choices.choose(.splatfest, isOn: true, in: preferences) }
    await prompt.waitUntilUp()
    _ = await choices.choose(.splatfest, isOn: false, in: preferences)
    prompt.answer(true)
    _ = await choosing.value

    #expect(!choices.isOn(.splatfest, in: preferences))
    #expect(!preferences.isSplatfestReminderOn)
  }
}

// MARK: - PermissionPrompt

/// The system's permission prompt as a test drives it: `ask()` waits until the test answers.
final private class PermissionPrompt {
  private var pending: CheckedContinuation<Bool, Never>?

  func ask() async -> Bool {
    await withCheckedContinuation { pending = $0 }
  }

  func waitUntilUp() async {
    while pending == nil {
      await Task.yield()
    }
  }

  func answer(_ isAllowed: Bool) {
    pending?.resume(returning: isAllowed)
    pending = nil
  }
}
