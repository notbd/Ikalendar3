//
//  SplatfestCardView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS) || os(macOS)
import IkaCore
import SwiftUI

// MARK: - SplatfestCardView

/// The plain Splatfest card Timeline's stand-in screens show until ticket 31 draws its own: the
/// art once downloaded, the title, the three teams in their colours with their names, and the
/// times. It receives `IkaCore` values only and reads no store.
public struct SplatfestCardView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.timeZone) private var timeZone

  private let splatfest: Splatfest
  private let art: URL?
  private let terms: GameTerms
  private let style: Style
  private let now: Date

  /// The decoded art, or `nil` while there is none.
  @State private var artImage: Image?

  /// - Parameters:
  ///   - splatfest: The Splatfest.
  ///   - art: Its stored art file from the screen value, or `nil` while none is downloaded:
  ///     the team colours stand alone then.
  ///   - terms: The game's names in the app language.
  ///   - style: The Style whose panel the team names must read on.
  ///   - now: The app clock's instant.
  public init(splatfest: Splatfest, art: URL?, terms: GameTerms, style: Style, now: Date) {
    self.splatfest = splatfest
    self.art = art
    self.terms = terms
    self.style = style
    self.now = now
  }

  public var body: some View {
    let texts = terms.splatfest(splatfest.id)
    // Looked up one by one: the source may lack them.
    let teamNames = texts.teamNames ?? []
    VStack(alignment: .leading, spacing: 8) {
      if let artImage {
        artImage
          .resizable()
          .scaledToFit()
          .clipShape(.rect(cornerRadius: 8))
      }
      Text(verbatim: texts.title)
        .font(.headline)
      ForEach(splatfest.teamColors.indices, id: \.self) { index in
        let color: SRGBColor = .init(splatfest.teamColors[index])
        Label {
          if teamNames.indices.contains(index) {
            Text(verbatim: teamNames[index])
              .foregroundStyle(Color(color.readableTint(on: style.panel(in: colorScheme), for: .text)))
          }
        } icon: {
          Circle()
            .fill(Color(color))
            .frame(width: 14, height: 14)
        }
        .font(.subheadline.weight(.semibold))
      }
      Text(verbatim: ScheduleFormat(language: terms.language, timeZone: timeZone).dateRange(of: splatfest))
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .task(id: art) {
      artImage = art.flatMap(Image.init(contentsOf:))
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(SentenceWriter(terms: terms, timeZone: timeZone, hourCycle: Locale.current.hourCycle)
      .sentence(for: splatfest, at: now))
    .accessibilityValue(teamNames.formatted(.list(type: .and).locale(Locale(identifier: terms.language.rawValue))))
  }
}
#endif
