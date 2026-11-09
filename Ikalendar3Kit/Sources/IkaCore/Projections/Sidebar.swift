//
//  Sidebar.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation

// MARK: - Sidebar

/// What the iPad sidebar lists at an instant, mirroring the game's lobby: Battle, Events and
/// Salmon Run, an Eggstra Work row while one runs, and while a Splatfest runs a Splatfest group on
/// top, with the Battle Modes it pauses dimmed. Each row is one Mode's summary at a glance.
public struct Sidebar: Hashable, Sendable {
  /// The groups in sidebar order.
  public let groups: [SidebarGroup]

  /// Whether a row of `item` is listed.
  public func lists(_ item: SidebarItem) -> Bool {
    groups.contains { $0.rows.contains { $0.item == item } }
  }
}

extension Snapshot {
  /// The sidebar at `instant`, or `nil` before the schedules feed's first good response. Every
  /// row is the current item of its Mode's screen, so the two always agree.
  public func sidebar(at instant: Date) -> Sidebar? {
    guard let schedules else { return nil }

    let feed = schedules.content
    let battle: [SidebarRow] = BattleMode.allCases
      .compactMap { summary(of: .battle($0), at: instant).map(SidebarRow.mode) }
    let challenges = feed.challengeLineup(at: instant)
    let challenge: RunningOrNext<ChallengeWindow>? = .init(challenges.current.item, next: challenges.next, at: instant)
    let eggstraWork: SidebarRow? = feed.eggstraWorkLineup(at: instant)
      .current
      .item
      .map { .eggstraWork(Running(item: $0, progress: $0.progress(at: instant))) }
    let salmonRun: [SidebarRow] = [summary(of: .salmonRun, at: instant).map(SidebarRow.mode), eggstraWork]
      .compactMap(\.self)

    let groups: [SidebarGroup] = [
      splatfestGroup(at: instant),
      SidebarGroup(kind: .battle, rows: battle),
      SidebarGroup(kind: .events, rows: [.challenge(challenge)]),
      SidebarGroup(kind: .salmonRun, rows: salmonRun),
    ].compactMap(\.self)
    return Sidebar(groups: groups)
  }

  /// The Splatfest group while the Splatfest runs: the Splatfest, its two forms of Splatfest
  /// Battle and Tricolor Turf War, which waits for the midterm time in the first half.
  private func splatfestGroup(at instant: Date) -> SidebarGroup? {
    guard let splatfest, splatfest.isRunning(at: instant) else { return nil }

    let forms: [SidebarRow] = SplatfestBattleForm.allCases.compactMap { form in
      splatfestScreen(of: form, at: instant).map { .splatfestBattle(form, $0.current) }
    }
    let tricolorTurfWar = splatfest.tricolorTurfWar
    let tricolor: RunningOrNext<TricolorTurfWar> =
      tricolorTurfWar.isRunning(at: instant)
        ? .running(Running(item: tricolorTurfWar, progress: tricolorTurfWar.progress(at: instant)))
        : .next(tricolorTurfWar)
    let rows: [SidebarRow] = [.splatfest(Running(item: splatfest, progress: splatfest.progress(at: instant)))]
      + forms
      + [.tricolorTurfWar(tricolor)]
    return SidebarGroup(kind: .splatfest, rows: rows)
  }
}

// MARK: - SidebarGroup

/// A titled group of sidebar rows.
public struct SidebarGroup: Hashable, Sendable {
  /// Which group it is, which names it.
  public let kind: Kind
  /// Its rows in order.
  public let rows: [SidebarRow]
}

// MARK: SidebarGroup.Kind

extension SidebarGroup {
  /// The sidebar's groups, in sidebar order.
  public enum Kind: Hashable, Sendable {
    /// The Splatfest, its two forms of Splatfest Battle and Tricolor Turf War, while it runs.
    case splatfest
    /// The four continuous Battle Modes.
    case battle
    /// Challenges.
    case events
    /// Salmon Run, and Eggstra Work while one runs.
    case salmonRun
  }
}

// MARK: - SidebarRow

/// One sidebar row: a Mode, Challenges, an event or a form of Splatfest Battle, with its current
/// item and how far it has run, or why none is on.
public enum SidebarRow: Hashable, Sendable {
  /// A Mode of the Mode value, as its summary reads: dimmed while a Splatfest pauses it.
  case mode(ModeSummary)
  /// Challenges: the window on now, else the next one, or `nil` while none is announced.
  case challenge(RunningOrNext<ChallengeWindow>?)
  /// The Eggstra Work running.
  case eggstraWork(Running<Shift>)
  /// The Splatfest running.
  case splatfest(Running<Splatfest>)
  /// A form of Splatfest Battle: the current Rotation of its Splatfest screen, or nothing current.
  case splatfestBattle(SplatfestBattleForm, OnNow<Rotation>)
  /// The Splatfest's Tricolor Turf War: on in the second half, still to come in the first, when it
  /// is dimmed.
  case tricolorTurfWar(RunningOrNext<TricolorTurfWar>)

  /// The row's identity, which the selection holds.
  public var item: SidebarItem {
    switch self {
      case .mode(let summary): .mode(summary.mode)
      case .challenge: .challenge
      case .eggstraWork: .eggstraWork
      case .splatfest: .splatfest
      case .splatfestBattle(let form, _): .splatfestBattle(form)
      case .tricolorTurfWar: .tricolorTurfWar
    }
  }

  /// Whether the row is dimmed because the Splatfest keeps its Mode from play now, as the game's
  /// lobby greys it out: a paused Battle Mode, and Tricolor Turf War before the midterm time.
  public var isDimmed: Bool {
    switch self {
      case .mode(.battle(_, .paused)),
           .tricolorTurfWar(.next): true
      case .mode,
           .challenge,
           .eggstraWork,
           .splatfest,
           .splatfestBattle,
           .tricolorTurfWar: false
    }
  }
}

// MARK: - RunningOrNext

/// An event's window on now with how far it has run, or the next one to come.
public enum RunningOrNext<Item: TimeWindow & Hashable & Sendable>: Hashable, Sendable {
  /// A window is on.
  case running(Running<Item>)
  /// None is on; this one comes next.
  case next(Item)

  /// The window on at `instant`, else `next`, or `nil` when neither is.
  init?(_ current: Item?, next: Item?, at instant: Date) {
    if let current { self = .running(Running(item: current, progress: current.progress(at: instant))) }
    else if let next { self = .next(next) }
    else { return nil }
  }
}

// MARK: - SidebarItem

/// A sidebar row's identity, which the app's selection holds across instants: it outlives the
/// row's content, and outlives the row itself for Eggstra Work and the Splatfest's rows.
public enum SidebarItem: Hashable, Sendable {
  /// A Mode of the Mode value.
  case mode(Mode)
  /// Challenges.
  case challenge
  /// The running Eggstra Work.
  case eggstraWork
  /// The running Splatfest.
  case splatfest
  /// A form of Splatfest Battle.
  case splatfestBattle(SplatfestBattleForm)
  /// Tricolor Turf War.
  case tricolorTurfWar

  /// The row of the iPhone tab `tab`, the Anarchy tab's showing `anarchyMode`: what the sidebar
  /// shows until the player picks a row, so it opens on the default Mode as the tabs do, on the
  /// Splatfest while one runs, and follows a tab picked in another layout.
  public init(_ tab: AppTab, anarchyMode: BattleMode) {
    switch tab {
      case .mode(.regularBattle): self = .mode(.battle(.regular))
      case .mode(.anarchy): self = .mode(.battle(anarchyMode))
      case .mode(.xBattle): self = .mode(.battle(.x))
      case .mode(.challenge): self = .challenge
      case .mode(.salmonRun): self = .mode(.salmonRun)
      case .splatfest: self = .splatfest
    }
  }

  /// The place of the iPhone tab that shows the row's screen, which the tabs select when the
  /// player picks the row: the Splatfest's rows take the Splatfest tab's, Regular Battle's, and
  /// Eggstra Work Salmon Run's. A row that leaves the sidebar falls back to a row in the same
  /// place (`shown(in:)`), so both layouts fall back alike.
  public var place: ModeTab {
    switch self {
      case .mode(.battle(.regular)): .regularBattle
      case .mode(.battle(.anarchySeries)),
           .mode(.battle(.anarchyOpen)): .anarchy
      case .mode(.battle(.x)): .xBattle
      case .mode(.salmonRun),
           .eggstraWork: .salmonRun
      case .challenge: .challenge
      case .splatfest,
           .splatfestBattle,
           .tricolorTurfWar: AppTab.splatfest.place
    }
  }

  /// The row the detail shows for this choice: the choice while `sidebar` lists it, else the row
  /// that takes its place once it leaves, Salmon Run for Eggstra Work and Regular Battle for the
  /// Splatfest's rows, as the iPhone's Splatfest tab gives its place back. Before the schedules
  /// feed's first good response (`nil`), only those two kinds of row are missing.
  public func shown(in sidebar: Sidebar?) -> SidebarItem {
    if sidebar?.lists(self) == true { return self }

    switch self {
      case .eggstraWork: return .mode(.salmonRun)
      case .splatfest,
           .splatfestBattle,
           .tricolorTurfWar: return .mode(.battle(.regular))
      case .mode,
           .challenge: return self
    }
  }
}
