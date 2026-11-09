//
//  FontCascade.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreText
import IkaCore
import SwiftUI

// MARK: - FontCascade

/// The order in which text of one role and language looks for each character's glyph, as SplatNet 3
/// stacks its families: the role's base family (Latin and kana, then Hangul), then the Han face of
/// the language, then the system font. Faces that are not registered are skipped.
///
/// The Han face follows the language alone, so one screen in one language never mixes two Han
/// faces, and a Chinese stack never falls through to the Japanese kanji.
public struct FontCascade: Hashable, Sendable {
  /// The faces in order. The system font follows the last one; with none, it sets every character.
  public let faces: [FontFace]

  /// The cascade for `role` and `language` over the faces in `registered`.
  public init(role: FontRole, language: GameLanguage, registered: Set<FontFace>) {
    let scripts: [FontScript] = [.base, .hangul, .han(for: language)]
    faces = scripts
      .map { FontFace(role: role, script: $0) }
      .filter(registered.contains)
  }

  /// The Core Text descriptor that sets text in the first face and cascades to the others, or `nil`
  /// when the system font sets everything.
  var descriptor: CTFontDescriptor? {
    guard let first = faces.first else { return nil }

    let fallbacks: [CTFontDescriptor] = faces.dropFirst().map {
      CTFontDescriptorCreateWithNameAndSize($0.name as CFString, 0)
    }
    let attributes: [CFString: Any] = [
      kCTFontNameAttribute: first.name,
      kCTFontCascadeListAttribute: fallbacks,
    ]
    return CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
  }

  /// This cascade at `size` points.
  func font(size: CGFloat) -> Font {
    guard let descriptor else { return .system(size: size) }

    return Font(CTFontCreateWithFontDescriptor(descriptor, size, nil))
  }
}

extension FontScript {
  /// The Han face the game uses for `language`: the GB build for Simplified Chinese, the Big5
  /// build for Traditional Chinese, and Fontworks' kanji for every other language.
  static func han(for language: GameLanguage) -> FontScript {
    switch language {
      case .zhCN: .simplifiedHan
      case .zhTW: .traditionalHan
      case .enUS,
           .enGB,
           .esES,
           .esMX,
           .frFR,
           .frCA,
           .deDE,
           .itIT,
           .nlNL,
           .ruRU,
           .jaJP,
           .koKR: .japaneseHan
    }
  }
}
