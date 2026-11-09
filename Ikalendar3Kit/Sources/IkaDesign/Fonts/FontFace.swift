//
//  FontFace.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - FontRole

/// Which of SplatNet 3's two families a text uses.
public enum FontRole: CaseIterable, Hashable, Sendable {
  /// The `splatoon1` family: headings, names and menu labels.
  case heavy
  /// The `splatoon2` family: dates, times, labels and descriptions.
  case light

  /// The family's name, the stem of each of its faces' names.
  var familyName: String {
    switch self {
      case .heavy: "Splatoon1"
      case .light: "Splatoon2"
    }
  }
}

// MARK: - FontScript

/// The characters one face of a family covers. Each script comes from one vendor, so removing a
/// vendor's files drops only its script.
public enum FontScript: CaseIterable, Hashable, Sendable {
  /// Latin, Cyrillic, digits, punctuation and kana: Nintendo's own outlines.
  case base
  /// The 2,350 KS X 1001 Hangul syllables: AsiaSoft.
  case hangul
  /// Kanji of JIS X 0208 levels 1 and 2: Fontworks.
  case japaneseHan
  /// Hanzi of GB2312: DynaComware's GB build.
  case simplifiedHan
  /// Hanzi of Big5: DynaComware's Big5 build.
  case traditionalHan

  /// The suffix after the family name, as in SplatNet 3's subset file names.
  var nameSuffix: String {
    switch self {
      case .base: ""
      case .hangul: "KRko"
      case .japaneseHan: "JP"
      case .simplifiedHan: "CHzh"
      case .traditionalHan: "TWzh"
    }
  }
}

// MARK: - FontFace

/// One font file of SplatNet 3's fonts: one script of one family.
///
/// `name` is the contract with the asset script (ticket 15): it writes each face as one file named
/// `<name>.otf` or `<name>.ttf`, whose PostScript name is `name`. Registration checks both.
public struct FontFace: CaseIterable, Hashable, Sendable {
  /// The family the face belongs to.
  public let role: FontRole
  /// The characters the face covers.
  public let script: FontScript

  /// Every face of both families, ten in all.
  static public let allCases: [FontFace] = FontRole.allCases.flatMap { role in
    FontScript.allCases.map { FontFace(role: role, script: $0) }
  }

  /// The file name stem and PostScript name, such as `Splatoon1CHzh`.
  public var name: String {
    role.familyName + script.nameSuffix
  }

  public init(role: FontRole, script: FontScript) {
    self.role = role
    self.script = script
  }
}
