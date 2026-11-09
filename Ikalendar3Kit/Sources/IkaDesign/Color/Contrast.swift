//
//  Contrast.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - ContrastTarget

/// The contrast a colour must reach against what it sits on, by what it draws (WCAG 2, AA).
public enum ContrastTarget: CaseIterable, Sendable {
  /// Body text: 4.5:1.
  case text
  /// Large text (18 pt, or 14 pt bold) and icons: 3:1.
  case largeTextAndIcons

  /// The lowest contrast ratio this target accepts.
  public var minimumRatio: Double {
    switch self {
      case .text: 4.5
      case .largeTextAndIcons: 3
    }
  }
}

// MARK: - Readable tints

extension SRGBColor {
  /// The nearest colour of the same hue and saturation that reaches `target` on `background`:
  /// this colour itself when it already does, else the least lighter (on a background white
  /// contrasts with more) or darker (otherwise) version that does. Text in a colour from the
  /// feed, such as a Splatfest team's, draws in this tint so it stays readable whatever the
  /// colour.
  ///
  /// When even white or black misses the target, which no panel of the app is mid-grey enough
  /// to cause, the result is that white or black.
  public func readableTint(on background: SRGBColor, for target: ContrastTarget) -> SRGBColor {
    let isReadable: (SRGBColor) -> Bool = { $0.contrastRatio(with: background) >= target.minimumRatio }
    guard !isReadable(self) else { return self }

    let hsl: HSLColor = .init(self)
    let goesLighter: Bool = Self.white.contrastRatio(with: background) >= Self.black.contrastRatio(with: background)
    // Lightness only moves the colour towards white or black, so luminance changes in one
    // direction and the first readable lightness is found by bisection. `far` stays readable.
    var near: Double = hsl.lightness
    var far: Double = goesLighter ? 1 : 0
    for _ in 0 ..< 24 {
      let middle: Double = (near + far) / 2
      if isReadable(hsl.color(lightness: middle)) {
        far = middle
      }
      else {
        near = middle
      }
    }
    return hsl.color(lightness: far)
  }
}

extension SRGBColor {
  /// The black or white that text and icons drawn on this colour use: whichever contrasts more.
  /// It always reaches 4.5:1, because the two ratios meet at about 4.58:1.
  public var labelColor: SRGBColor {
    Self.black.contrastRatio(with: self) >= Self.white.contrastRatio(with: self) ? .black : .white
  }
}

// MARK: - HSLColor

/// A colour as hue, saturation and lightness, each from 0 to 1.
private struct HSLColor {
  let hue: Double
  let saturation: Double
  let lightness: Double

  init(_ color: SRGBColor) {
    let red: Double = .init(color.red) / 255
    let green: Double = .init(color.green) / 255
    let blue: Double = .init(color.blue) / 255
    let maximum: Double = max(red, green, blue)
    let minimum: Double = min(red, green, blue)
    let chroma: Double = maximum - minimum

    lightness = (maximum + minimum) / 2
    guard chroma > 0 else {
      hue = 0
      saturation = 0
      return
    }

    saturation = chroma / (1 - abs(2 * lightness - 1))
    let sector: Double =
      switch maximum {
        case red: (green - blue) / chroma
        case green: (blue - red) / chroma + 2
        default: (red - green) / chroma + 4
      }
    hue = (sector / 6).truncatingRemainder(dividingBy: 1) + (sector < 0 ? 1 : 0)
  }

  /// This hue and saturation at `lightness`, rounded to 8-bit channels.
  func color(lightness: Double) -> SRGBColor {
    let chroma: Double = (1 - abs(2 * lightness - 1)) * saturation
    let channel: (Double) -> Double = { offset in
      let sector: Double = (hue * 12 + offset).truncatingRemainder(dividingBy: 12)
      return lightness - chroma / 2 * max(-1, min(sector - 3, 9 - sector, 1))
    }
    return SRGBColor(red: channel(0), green: channel(8), blue: channel(4))
  }
}
