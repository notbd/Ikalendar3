//
//  EventReminder.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - EventReminder

/// One local notification at the start of an event: a Big Run, an Eggstra Work, a Splatfest or a
/// Challenge's first window. Plain values; the effects shell hands them to the system.
public struct EventReminder: Hashable, Sendable {
  /// The notification's identifier: the app's namespace, the kind and the start, so a rebuild
  /// gives an event the same identifier and replacing the app's reminders touches nothing else.
  public let id: String
  /// The kind of event.
  public let kind: Kind
  /// When the notification fires: the event's start.
  public let fireDate: Date
  /// "Big Run starts now", with the Challenge's own name for a Challenge.
  public let title: String
  /// The event's sentence at its start, as VoiceOver reads it.
  public let body: String

  /// The prefix of every reminder's identifier.
  static public let namespace = "io.tianwei.ikalendar3.reminder."

  /// The identifier of the reminder of a `kind` of event starting at `startTime`.
  static fileprivate func identifier(of kind: Kind, startingAt startTime: Date) -> String {
    namespace + "\(kind.rawValue).\(Int(startTime.timeIntervalSince1970))"
  }

  /// The most reminders pending at once, far below the system's 64 per app. The feed publishes a
  /// few events at a time, so it never binds; it only bounds what a malformed feed could ask for.
  static public let maximumCount = 16
}

// MARK: EventReminder.Kind

extension EventReminder {
  /// An event a reminder switch covers.
  public enum Kind: String, CaseIterable, Hashable, Sendable {
    case bigRun
    case eggstraWork
    case splatfest
    case challenge
  }
}

// MARK: - ReminderSettings

/// What reminders are built from besides the snapshot: the switches that are on, and the text
/// set, time zone and hour cycle their text reads in.
public struct ReminderSettings: Hashable, Sendable {
  /// The kinds whose switch is on.
  public var kinds: Set<EventReminder.Kind>
  /// The app language.
  public var language: GameLanguage
  /// The time zone times are written in: the device's.
  public var timeZone: TimeZone
  /// The hour cycle times are written in: the device's.
  public var hourCycle: Locale.HourCycle

  public init(kinds: Set<EventReminder.Kind>, language: GameLanguage, timeZone: TimeZone, hourCycle: Locale.HourCycle) {
    self.kinds = kinds
    self.language = language
    self.timeZone = timeZone
    self.hourCycle = hourCycle
  }
}

// MARK: - Snapshot

extension Snapshot {
  /// The reminders to have pending after `instant`: one per start of each event of a kind that is
  /// on, still to start, in time order. A Challenge's reminder fires as its first window opens;
  /// one whose first window has opened gets none. Empty before the schedules feed's first good
  /// response.
  ///
  /// Two events of one kind that start together get one reminder, named for the first in the feed.
  public func eventReminders(for settings: ReminderSettings, after instant: Date) -> [EventReminder] {
    let writer: SentenceWriter = .init(
      terms: terms(in: settings.language),
      timeZone: settings.timeZone,
      hourCycle: settings.hourCycle)
    var ids: Set<String> = []
    return remindableEvents
      .filter { settings.kinds.contains($0.reminderKind) && $0.startTime > instant }
      .sorted { $0.startTime < $1.startTime }
      .compactMap { event in
        let id: String = EventReminder.identifier(of: event.reminderKind, startingAt: event.startTime)
        guard ids.insert(id).inserted else { return nil }

        return EventReminder(
          id: id,
          kind: event.reminderKind,
          fireDate: event.startTime,
          title: ReminderText.startsNow.text(in: settings.language, event.name(in: writer.terms)),
          body: writer.sentence(for: event, at: event.startTime))
      }
      .prefix(EventReminder.maximumCount)
      .map(\.self)
  }

  /// Every published event a reminder can cover, each as it starts: every Big Run and Eggstra
  /// Work, the Splatfest, and each Challenge in its first window.
  private var remindableEvents: [EventItem] {
    guard let feed = schedules?.content else { return [] }

    let bigRuns = feed.salmonRun.filter { $0.kind == .bigRun }.map(EventItem.bigRun)
    let eggstraWorks = feed.eggstraWork.map(EventItem.eggstraWork)
    let splatfests = [splatfest.map { EventItem.splatfest(card(of: $0)) }].compactMap(\.self)
    let challenges = feed.challenges.compactMap { challenge in
      challenge.windows.first.map { EventItem.challenge(ChallengeWindow(challenge: challenge, window: $0)) }
    }
    return bigRuns + eggstraWorks + splatfests + challenges
  }
}

// MARK: - EventItem

extension EventItem {
  /// The switch that covers the event.
  fileprivate var reminderKind: EventReminder.Kind {
    switch self {
      case .challenge: .challenge
      case .splatfest: .splatfest
      case .bigRun: .bigRun
      case .eggstraWork: .eggstraWork
    }
  }

  /// The name a reminder's title gives the event: a Challenge's own, else its kind's.
  fileprivate func name(in terms: GameTerms) -> String {
    switch self {
      case .challenge(let window): terms.challenge(window.challenge.id).name
      case .splatfest: ModeLabel.splatfest.text(in: terms.language)
      case .bigRun: ModeLabel.bigRun.text(in: terms.language)
      case .eggstraWork: ModeLabel.eggstraWork.text(in: terms.language)
    }
  }
}
