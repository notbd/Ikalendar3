//
//  FontCascadeTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import CoreText
import IkaCore
import Testing
@testable import IkaDesign

/// Pins the per-character fallback order: the role's base family (Nintendo's Latin and kana face,
/// then AsiaSoft's Hangul), then the Han face of the text's language, then the system font. The
/// faces are passed in, so these tests run the same with or without font files (CI has none).
struct FontCascadeTests {
  static private let chineseLanguages: [GameLanguage] = [.zhCN, .zhTW]

  /// Face names in cascade order; the system font follows the last one.
  private func stack(
    _ role: FontRole,
    _ language: GameLanguage,
    registered: Set<FontFace> = Set(FontFace.allCases))
    -> [String]
  {
    FontCascade(role: role, language: language, registered: registered).faces.map(\.name)
  }

  @Test(arguments: GameLanguage.allCases.filter { !chineseLanguages.contains($0) })
  func `Every non-Chinese language takes the Fontworks kanji after the base family`(language: GameLanguage) {
    #expect(stack(.heavy, language) == ["Splatoon1", "Splatoon1KRko", "Splatoon1JP"])
    #expect(stack(.light, language) == ["Splatoon2", "Splatoon2KRko", "Splatoon2JP"])
  }

  @Test
  func `Simplified Chinese takes the GB build after the base family`() {
    #expect(stack(.heavy, .zhCN) == ["Splatoon1", "Splatoon1KRko", "Splatoon1CHzh"])
    #expect(stack(.light, .zhCN) == ["Splatoon2", "Splatoon2KRko", "Splatoon2CHzh"])
  }

  @Test
  func `Traditional Chinese takes the Big5 build after the base family`() {
    #expect(stack(.heavy, .zhTW) == ["Splatoon1", "Splatoon1KRko", "Splatoon1TWzh"])
    #expect(stack(.light, .zhTW) == ["Splatoon2", "Splatoon2KRko", "Splatoon2TWzh"])
  }

  @Test(arguments: chineseLanguages, FontRole.allCases)
  func `Chinese stacks never reach the Japanese kanji`(language: GameLanguage, role: FontRole) {
    #expect(!stack(role, language).contains { $0.hasSuffix("JP") })
  }

  @Test(arguments: GameLanguage.allCases, FontRole.allCases)
  func `Every role falls back to the system font with no faces registered`(
    language: GameLanguage,
    role: FontRole)
  {
    #expect(stack(role, language, registered: []) == [])
  }

  @Test
  func `Removing AsiaSoft's faces drops only Hangul to the system font`() {
    let registered: Set<FontFace> = Set(FontFace.allCases.filter { !$0.name.hasSuffix("KRko") })

    #expect(stack(.heavy, .koKR, registered: registered) == ["Splatoon1", "Splatoon1JP"])
    #expect(stack(.light, .zhCN, registered: registered) == ["Splatoon2", "Splatoon2CHzh"])
  }

  @Test
  func `Removing Fontworks' faces drops only the Japanese kanji to the system font`() {
    let registered: Set<FontFace> = Set(FontFace.allCases.filter { !$0.name.hasSuffix("JP") })

    #expect(stack(.heavy, .jaJP, registered: registered) == ["Splatoon1", "Splatoon1KRko"])
    #expect(stack(.light, .zhTW, registered: registered) == ["Splatoon2", "Splatoon2KRko", "Splatoon2TWzh"])
  }

  @Test
  func `Removing DynaComware's faces drops only Chinese Han to the system font`() {
    let registered: Set<FontFace> = Set(FontFace.allCases.filter { !$0.name.hasSuffix("zh") })

    #expect(stack(.heavy, .zhCN, registered: registered) == ["Splatoon1", "Splatoon1KRko"])
    #expect(stack(.light, .zhTW, registered: registered) == ["Splatoon2", "Splatoon2KRko"])
    #expect(stack(.heavy, .jaJP, registered: registered) == ["Splatoon1", "Splatoon1KRko", "Splatoon1JP"])
  }

  @Test
  func `Removing Nintendo's faces keeps every vendor's Han and Hangul`() {
    let registered: Set<FontFace> = Set(FontFace.allCases.filter { !["Splatoon1", "Splatoon2"].contains($0.name) })

    #expect(stack(.heavy, .enUS, registered: registered) == ["Splatoon1KRko", "Splatoon1JP"])
    #expect(stack(.light, .zhCN, registered: registered) == ["Splatoon2KRko", "Splatoon2CHzh"])
  }

  @Test
  func `Core Text sets text in the first face and cascades to the others in order`() throws {
    let cascade: FontCascade = .init(role: .light, language: .zhTW, registered: Set(FontFace.allCases))

    let descriptor: CTFontDescriptor = try #require(cascade.descriptor)
    let fallbacks = try #require(
      CTFontDescriptorCopyAttribute(descriptor, kCTFontCascadeListAttribute) as? [CTFontDescriptor])

    #expect(CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String == "Splatoon2")
    #expect(fallbacks.map { CTFontDescriptorCopyAttribute($0, kCTFontNameAttribute) as? String } == [
      "Splatoon2KRko", "Splatoon2TWzh",
    ])
  }

  @Test
  func `Core Text uses the system font alone with no faces registered`() {
    #expect(FontCascade(role: .heavy, language: .jaJP, registered: []).descriptor == nil)
  }

  @Test
  func `The ten faces carry the names the asset script writes`() {
    #expect(Set(FontFace.allCases.map(\.name)) == [
      "Splatoon1", "Splatoon1KRko", "Splatoon1JP", "Splatoon1CHzh", "Splatoon1TWzh",
      "Splatoon2", "Splatoon2KRko", "Splatoon2JP", "Splatoon2CHzh", "Splatoon2TWzh",
    ])
  }
}
