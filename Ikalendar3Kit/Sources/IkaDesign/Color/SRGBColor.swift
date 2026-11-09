//
//  SRGBColor.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import SwiftUI

// MARK: - SRGBColor

/// An opaque sRGB colour with 8-bit channels: the unit the palette and its contrast checks work
/// in, so every colour they compute is one a screen draws exactly.
public struct SRGBColor: Hashable, Sendable {
  static public let black: SRGBColor = .init(hex: 0x000000)
  static public let white: SRGBColor = .init(hex: 0xFFFFFF)

  /// The red channel.
  public let red: UInt8
  /// The green channel.
  public let green: UInt8
  /// The blue channel.
  public let blue: UInt8

  /// The colour with these channels.
  public init(red: UInt8, green: UInt8, blue: UInt8) {
    self.red = red
    self.green = green
    self.blue = blue
  }

  /// The colour written as `0xRRGGBB`, as in CSS.
  public init(hex: UInt32) {
    self.init(red: UInt8(hex >> 16 & 0xFF), green: UInt8(hex >> 8 & 0xFF), blue: UInt8(hex & 0xFF))
  }

  /// The colour with these channels, each from 0 to 1 and rounded to the nearest 8-bit step.
  public init(red: Double, green: Double, blue: Double) {
    self.init(red: Self.channel(red), green: Self.channel(green), blue: Self.channel(blue))
  }

  /// A feed colour, such as a Splatfest team's. Its opacity is dropped: the feed's team colours
  /// are all opaque.
  public init(_ feedColor: RGBAColor) {
    self.init(red: feedColor.red, green: feedColor.green, blue: feedColor.blue)
  }

  /// WCAG 2's relative luminance: 0 for black, 1 for white.
  public var relativeLuminance: Double {
    0.2126 * Self.linear(red) + 0.7152 * Self.linear(green) + 0.0722 * Self.linear(blue)
  }

  /// WCAG 2's contrast ratio with `other`, from 1 (none) to 21 (black on white). Order does not
  /// matter.
  public func contrastRatio(with other: SRGBColor) -> Double {
    let lighter: Double = max(relativeLuminance, other.relativeLuminance)
    let darker: Double = min(relativeLuminance, other.relativeLuminance)
    return (lighter + 0.05) / (darker + 0.05)
  }

  static private func channel(_ value: Double) -> UInt8 {
    UInt8((min(max(value, 0), 1) * 255).rounded())
  }

  /// An 8-bit sRGB channel in linear light.
  static private func linear(_ channel: UInt8) -> Double {
    let value: Double = .init(channel) / 255
    return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
  }
}

// MARK: CustomStringConvertible

extension SRGBColor: CustomStringConvertible {
  /// The colour as `#rrggbb`.
  public var description: String {
    "#" + [red, green, blue].map { String(format: "%02x", $0) }.joined()
  }
}

extension Color {
  /// The SwiftUI colour for `color`.
  public init(_ color: SRGBColor) {
    self.init(
      .sRGB,
      red: Double(color.red) / 255,
      green: Double(color.green) / 255,
      blue: Double(color.blue) / 255)
  }
}
