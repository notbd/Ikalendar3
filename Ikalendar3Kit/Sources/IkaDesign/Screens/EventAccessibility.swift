//
//  EventAccessibility.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import Foundation
import IkaCore
import SwiftUI

extension View {
  /// Makes the view one VoiceOver element reading `event` as every Style and the watch read it:
  /// its sentence as the label and, for a Splatfest, which its sentence leaves out, the team
  /// names as the value.
  public func eventAccessibility(_ event: EventItem, writer: SentenceWriter, at instant: Date) -> some View {
    let teamNames: String =
      switch event {
        case .splatfest(let card): writer.teamNames(of: card.splatfest)
        case .challenge,
             .bigRun,
             .eggstraWork: ""
      }
    return accessibilityElement(children: .ignore)
      .accessibilityLabel(Text(verbatim: writer.sentence(for: event, at: instant)))
      .accessibilityValue(Text(verbatim: teamNames))
  }

  /// Makes the view one VoiceOver element reading `splatfest`: its sentence as the label and the
  /// team names as the value, as `eventAccessibility(_:writer:at:)` reads a Splatfest's card.
  public func splatfestAccessibility(_ splatfest: Splatfest, writer: SentenceWriter, at instant: Date) -> some View {
    accessibilityElement(children: .ignore)
      .accessibilityLabel(Text(verbatim: writer.sentence(for: splatfest, at: instant)))
      .accessibilityValue(Text(verbatim: writer.teamNames(of: splatfest)))
  }
}
