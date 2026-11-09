//
//  ScheduleFeed+Decoding.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import OSLog

extension ScheduleFeed {
  /// Decodes a `schedules.json` response body. Runs off the main actor.
  ///
  /// - Throws: `DecodingError` when the body is not the schedules feed at all. A part that
  ///   fails on its own is reported in `failedSections` instead.
  @concurrent
  static public func decode(from body: Data) async throws -> ScheduleFeed {
    try ScheduleFeed(FeedJSON.decoder().decode(ScheduleFeedDTO.self, from: body).data)
  }

  private init(_ dto: SectionsDTO) {
    var failedSections: Set<Section> = []

    // Builds one part of the feed on its own: a failure leaves its sections empty and reports
    // them.
    func isolate<Value>(_ sections: [Section], _ build: () throws -> Value) -> Value? {
      do {
        return try build()
      }
      catch {
        Logger.decode.error("schedules: \(sections, privacy: .public) failed: \(error, privacy: .public)")
        failedSections.formUnion(sections)
        return nil
      }
    }

    var rotationsByMode: [RotationMode: [Rotation]] = [:]
    func addRotations<Node: BattleNodeDTO>(of list: Isolated<NodesDTO<Node>>?) {
      let rotations = isolate(Node.modes.map(Section.rotations)) {
        try Self.rotations(of: value(of: list).nodes)
      }
      rotationsByMode.merge(rotations ?? [:]) { $1 }
    }
    addRotations(of: dto.regularSchedules)
    addRotations(of: dto.bankaraSchedules)
    addRotations(of: dto.xSchedules)
    addRotations(of: dto.festSchedules)
    self.rotationsByMode = rotationsByMode

    challenges = isolate([.challenges]) {
      try Self.challenges(of: value(of: dto.eventSchedules).nodes)
    } ?? []

    salmonRun = isolate([.salmonRun]) {
      let coop = try value(of: dto.coopGroupingSchedule)
      let regular = try value(of: coop.regularSchedules).nodes
      guard !regular.isEmpty else { throw FeedDecodingError.emptyList }

      let bigRun = try value(of: coop.bigRunSchedules).nodes
      return (Self.shifts(of: regular, kind: .regular) + Self.shifts(of: bigRun, kind: .bigRun))
        .sorted { $0.startTime < $1.startTime }
    } ?? []

    eggstraWork = isolate([.eggstraWork]) {
      let coop = try value(of: dto.coopGroupingSchedule)
      return try Self.shifts(of: value(of: coop.teamContestSchedules).nodes, kind: .eggstraWork)
        .sorted { $0.startTime < $1.startTime }
    } ?? []

    // `null` while no Splatfest is announced or running.
    currentSplatfest = dto.currentFest.flatMap { currentFest in
      isolate([.splatfest]) { try Self.currentSplatfest(of: currentFest.result.get()) }
    }

    terms = TermTable(feed: dto)
    self.failedSections = failedSections
  }

  /// The Rotations of each Battle Mode a battle list holds, in time order.
  ///
  /// A window with no settings pauses a continuous Battle Mode (a Splatfest replaces it) and
  /// holds no Splatfest Battle (no Splatfest runs). A window with settings must hold one for
  /// every Battle Mode of the list.
  static private func rotations<Node: BattleNodeDTO>(of nodes: [Node]) throws -> [RotationMode: [Rotation]] {
    guard !nodes.isEmpty else { throw FeedDecodingError.emptyList }

    var rotationsByMode: [RotationMode: [Rotation]] = .init(uniqueKeysWithValues: Node.modes.map { ($0, []) })
    for node in nodes.sorted(by: { $0.startTime < $1.startTime }) {
      let settings = node.settings.map { settings in
        [RotationMode: VsSettingDTO](
          settings.compactMap { setting in Node.mode(of: setting).map { ($0, setting) } },
          uniquingKeysWith: { first, _ in first })
      }
      for mode in Node.modes {
        let setting: Rotation.Setting?
        switch (settings, mode) {
          case (let settings?, _):
            guard let vsSetting = settings[mode] else { throw FeedDecodingError.missingSetting(mode) }

            setting = Rotation.Setting(
              rule: RuleID(vsSetting.vsRule.id),
              stages: vsSetting.vsStages.map { StageID($0.id) })

          case (nil, .battle):
            setting = nil

          case (nil, .splatfestBattle):
            continue
        }

        rotationsByMode[mode, default: []].append(Rotation(
          mode: mode,
          startTime: node.startTime,
          endTime: node.endTime,
          setting: setting))
      }
    }
    return rotationsByMode
  }

  /// The published Challenges, in the order their first windows open.
  static private func challenges(of nodes: [EventNodeDTO]) throws -> [Challenge] {
    guard !nodes.isEmpty else { throw FeedDecodingError.emptyList }

    return nodes
      .map { node in
        let setting = node.leagueMatchSetting
        return Challenge(
          id: ChallengeID(setting.leagueMatchEvent.id),
          rule: RuleID(setting.vsRule.id),
          stages: setting.vsStages.map { StageID($0.id) },
          windows: node.timePeriods
            .map { Challenge.Window(startTime: $0.startTime, endTime: $0.endTime) }
            .sorted { $0.startTime < $1.startTime })
      }
      .sorted { ($0.windows.first?.startTime ?? .distantFuture) < ($1.windows.first?.startTime ?? .distantFuture) }
  }

  static private func shifts(of nodes: [CoopNodeDTO], kind: Shift.Kind) -> [Shift] {
    nodes.map { node in
      Shift(
        kind: kind,
        startTime: node.startTime,
        endTime: node.endTime,
        stage: StageID(node.setting.coopStage.id),
        weapons: node.setting.weapons.map { WeaponID($0.id) },
        kingSalmonid: node.setting.boss.map { KingSalmonidID($0.id) })
    }
  }

  static private func currentSplatfest(of dto: CurrentFestDTO) throws -> CurrentSplatfest {
    try CurrentSplatfest(
      feedID: dto.id,
      splatfest: Splatfest(
        id: splatfestID(ofFeedID: dto.id),
        startTime: dto.startTime,
        midtermTime: dto.midtermTime,
        endTime: dto.endTime,
        teamColors: dto.teams
          .map { RGBAColor(red: $0.color.r, green: $0.color.g, blue: $0.color.b, alpha: $0.color.a) },
        tricolorStages: (dto.tricolorStages ?? []).map { StageID($0.id) }))
  }

  /// The Splatfest code in Nintendo's id: `Fest-US:JUEA-00108`, base64-encoded, holds
  /// `JUEA-00108`.
  static fileprivate func splatfestID(ofFeedID feedID: String) throws -> SplatfestID {
    guard
      let data = Data(base64Encoded: feedID),
      let decoded = String(data: data, encoding: .utf8),
      let separator = decoded.firstIndex(of: ":")
    else { throw FeedDecodingError.malformedSplatfestID(feedID) }

    return SplatfestID(String(decoded[decoded.index(after: separator)...]))
  }
}

// MARK: - Feed terms

extension TermTable {
  /// The English names the feed writes beside its ids, read from every list that decodes,
  /// whether or not its Schedule could be built.
  fileprivate init(feed dto: SectionsDTO) {
    self.init()

    func settings(of list: Isolated<NodesDTO<some BattleNodeDTO>>?) -> [VsSettingDTO] {
      decodedNodes(list).flatMap { $0.settings ?? [] }
    }
    let battleSettings = settings(of: dto.regularSchedules) + settings(of: dto.bankaraSchedules)
      + settings(of: dto.xSchedules) + settings(of: dto.festSchedules)
    let challengeSettings = decodedNodes(dto.eventSchedules).map(\.leagueMatchSetting)
    add(battleSettings.map(\.vsRule) + challengeSettings.map(\.vsRule), to: \.rules)
    add(battleSettings.flatMap(\.vsStages) + challengeSettings.flatMap(\.vsStages), to: \.stages)
    for challenge in challengeSettings.map(\.leagueMatchEvent) {
      if
        let name = challenge.name, !name.isEmpty, let description = challenge.desc,
        let rulesText = challenge.regulation
      {
        challenges[ChallengeID(challenge.id)] = ChallengeTerms(
          name: name,
          description: description,
          rulesText: rulesText)
      }
    }

    let coop = try? value(of: dto.coopGroupingSchedule)
    let shiftSettings = [coop?.regularSchedules, coop?.bigRunSchedules, coop?.teamContestSchedules]
      .flatMap(decodedNodes)
      .map(\.setting)
    add(shiftSettings.map(\.coopStage), to: \.stages)
    add(shiftSettings.flatMap(\.weapons), to: \.weapons)
    add(shiftSettings.compactMap(\.boss), to: \.kingSalmonids)

    if
      let splatfest = try? value(of: dto.currentFest),
      let id = try? ScheduleFeed.splatfestID(ofFeedID: splatfest.id),
      let title = splatfest.title, !title.isEmpty
    {
      add(splatfest.tricolorStages ?? [], to: \.stages)
      splatfests[id] = SplatfestTerms(title: title, teamNames: [])
    }
  }

  /// Adds each term's name to a table, skipping those with no name.
  private mutating func add(_ terms: [some NamedDTO], to table: WritableKeyPath<
    TermTable,
    [FeedID<some Any>: String],
  >) {
    for term in terms {
      if let name = term.name, !name.isEmpty {
        self[keyPath: table][FeedID(term.id)] = name
      }
    }
  }
}

// MARK: - ScheduleFeedDTO

/// The feed's top level.
private struct ScheduleFeedDTO: Decodable {
  let data: SectionsDTO
}

// MARK: - SectionsDTO

/// The feed's lists, each decoded on its own.
private struct SectionsDTO: Decodable {
  let regularSchedules: Isolated<NodesDTO<RegularNodeDTO>>?
  let bankaraSchedules: Isolated<NodesDTO<BankaraNodeDTO>>?
  let xSchedules: Isolated<NodesDTO<XNodeDTO>>?
  let festSchedules: Isolated<NodesDTO<FestNodeDTO>>?
  let eventSchedules: Isolated<NodesDTO<EventNodeDTO>>?
  let coopGroupingSchedule: Isolated<CoopDTO>?
  /// The current Splatfest, `null` while none is announced or running.
  let currentFest: Isolated<CurrentFestDTO>?
}

// MARK: - NodesDTO

/// A GraphQL connection: the feed wraps every list in `nodes`.
private struct NodesDTO<Node: Decodable>: Decodable {
  let nodes: [Node]
}

/// The value of a part that decoded, or the reason it cannot be used.
private func value<Value>(of part: Isolated<Value>?) throws -> Value {
  guard let part else { throw FeedDecodingError.missing }

  return try part.result.get()
}

/// The nodes of a list that decoded, or none.
private func decodedNodes<Node>(_ list: Isolated<NodesDTO<Node>>?) -> [Node] {
  (try? value(of: list).nodes) ?? []
}

// MARK: - NamedDTO

/// An id with the feed's English name, which is kept only as the fallback name.
private protocol NamedDTO {
  var id: String { get }
  var name: String? { get }
}

// MARK: - TermDTO

/// A Stage, Rule or King Salmonid by Nintendo's id.
private struct TermDTO: NamedDTO, Decodable {
  let id: String
  let name: String?
}

// MARK: - VsSettingDTO

/// What one Battle Mode plays in a window.
private struct VsSettingDTO: Decodable {
  let vsRule: TermDTO
  let vsStages: [TermDTO]
  /// Anarchy Battle's form: `CHALLENGE` is Anarchy Series, `OPEN` Anarchy Open.
  let bankaraMode: String?
  /// Splatfest Battle's form: `REGULAR` is Open, `CHALLENGE` Pro.
  let festMode: String?
}

// MARK: - BattleNodeDTO

/// One window of a battle list.
private protocol BattleNodeDTO: Decodable {
  /// The Battle Modes the list holds.
  static var modes: [RotationMode] { get }
  /// The Battle Mode a setting of the list belongs to, or `nil` for one the app does not know.
  static func mode(of setting: VsSettingDTO) -> RotationMode?

  var startTime: Date { get }
  var endTime: Date { get }
  /// The window's settings, or `nil` when it lists none.
  var settings: [VsSettingDTO]? { get }
}

// MARK: - RegularNodeDTO

private struct RegularNodeDTO: BattleNodeDTO {
  static let modes: [RotationMode] = [.battle(.regular)]

  let startTime: Date
  let endTime: Date
  let regularMatchSetting: VsSettingDTO?

  var settings: [VsSettingDTO]? { regularMatchSetting.map { [$0] } }

  static func mode(of _: VsSettingDTO) -> RotationMode? { .battle(.regular) }
}

// MARK: - BankaraNodeDTO

private struct BankaraNodeDTO: BattleNodeDTO {
  static let modes: [RotationMode] = [.battle(.anarchySeries), .battle(.anarchyOpen)]

  let startTime: Date
  let endTime: Date
  let bankaraMatchSettings: [VsSettingDTO]?

  var settings: [VsSettingDTO]? { bankaraMatchSettings }

  static func mode(of setting: VsSettingDTO) -> RotationMode? {
    switch setting.bankaraMode {
      case "CHALLENGE": .battle(.anarchySeries)
      case "OPEN": .battle(.anarchyOpen)
      default: nil
    }
  }
}

// MARK: - XNodeDTO

private struct XNodeDTO: BattleNodeDTO {
  static let modes: [RotationMode] = [.battle(.x)]

  let startTime: Date
  let endTime: Date
  let xMatchSetting: VsSettingDTO?

  var settings: [VsSettingDTO]? { xMatchSetting.map { [$0] } }

  static func mode(of _: VsSettingDTO) -> RotationMode? { .battle(.x) }
}

// MARK: - FestNodeDTO

private struct FestNodeDTO: BattleNodeDTO {
  static let modes: [RotationMode] = SplatfestBattleForm.allCases.map(RotationMode.splatfestBattle)

  let startTime: Date
  let endTime: Date
  let festMatchSettings: [VsSettingDTO]?

  var settings: [VsSettingDTO]? { festMatchSettings }

  static func mode(of setting: VsSettingDTO) -> RotationMode? {
    switch setting.festMode {
      case "REGULAR": .splatfestBattle(.open)
      case "CHALLENGE": .splatfestBattle(.pro)
      default: nil
    }
  }
}

// MARK: - EventNodeDTO

/// One Challenge and its windows.
private struct EventNodeDTO: Decodable {
  struct SettingDTO: Decodable {
    let leagueMatchEvent: EventDTO
    let vsRule: TermDTO
    let vsStages: [TermDTO]
  }

  /// A Challenge with the feed's English texts, which are kept only as the fallback texts.
  struct EventDTO: Decodable {
    let id: String
    let name: String?
    let desc: String?
    let regulation: String?
  }

  struct PeriodDTO: Decodable {
    let startTime: Date
    let endTime: Date
  }

  let leagueMatchSetting: SettingDTO
  let timePeriods: [PeriodDTO]
}

// MARK: - CoopDTO

/// Salmon Run's three lists.
private struct CoopDTO: Decodable {
  let regularSchedules: Isolated<NodesDTO<CoopNodeDTO>>?
  let bigRunSchedules: Isolated<NodesDTO<CoopNodeDTO>>?
  /// Eggstra Work.
  let teamContestSchedules: Isolated<NodesDTO<CoopNodeDTO>>?
}

// MARK: - CoopNodeDTO

/// One Shift.
private struct CoopNodeDTO: Decodable {
  struct SettingDTO: Decodable {
    let coopStage: TermDTO
    let weapons: [WeaponDTO]
    /// The King Salmonid, `null` on an Eggstra Work.
    let boss: TermDTO?
  }

  /// A weapon by splatoon3.ink's derived id.
  struct WeaponDTO: NamedDTO, Decodable {
    let id: String
    let name: String?

    enum CodingKeys: String, CodingKey {
      case id = "__splatoon3ink_id"
      case name
    }
  }

  let startTime: Date
  let endTime: Date
  let setting: SettingDTO
}

// MARK: - CurrentFestDTO

/// The current Splatfest as splatoon3.ink's US account sees it.
private struct CurrentFestDTO: Decodable {
  struct TeamDTO: Decodable {
    let color: ColorDTO
  }

  struct ColorDTO: Decodable {
    let r: Double
    let g: Double
    let b: Double
    let a: Double
  }

  /// Nintendo's id, which names the region (`Fest-US:JUEA-00108`, base64-encoded).
  let id: String
  /// The English title, kept only as the fallback title.
  let title: String?
  let startTime: Date
  let midtermTime: Date
  let endTime: Date
  let teams: [TeamDTO]
  let tricolorStages: [TermDTO]?
}
