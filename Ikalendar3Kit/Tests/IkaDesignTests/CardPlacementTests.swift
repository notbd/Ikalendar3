//
//  CardPlacementTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI
import Testing
@testable import IkaDesign

// MARK: - CardPlacementTests

/// Pins where the two-card layouts put a card that comes back narrower than its slot (an
/// aspect-fit picture): at the slot's centre, as ikalendar 2 does, not against an outer edge.
@MainActor
struct CardPlacementTests {
  @Test
  func `A narrower Stage B card sits at the centre of its slot`() throws {
    // Offered 100 pt of height, the square Stage B card is 100 wide, so both slots are 100 by 40
    // (Stage A's height). Proposed 100 by 40, Stage B comes back 40 by 40.
    let image = try Rendered(BattleSecondaryStagesLayout {
      Rendered.red.frame(width: 100, height: 40)
      Rendered.blue.aspectRatio(1, contentMode: .fit)
    }
    .frame(height: 100))

    #expect(image.centerX(of: .red) == 50)
    #expect(image.centerX(of: .blue) == Rendered.width - 50)
  }

  @Test
  func `A narrower Stage card sits at the centre of its slot`() throws {
    // The weapons card fills its square slot; the square Stage card is narrower than its 16:9 slot.
    let image = try Rendered(SalmonStageAndWeaponsLayout {
      Rendered.red.aspectRatio(1, contentMode: .fit)
      Rendered.blue
    })
    let height: CGFloat = image.size.height
    let stageCenterX = try #require(image.centerX(of: .red))

    #expect(image.centerX(of: .blue) == Rendered.width - height / 2)
    #expect(abs(stageCenterX - height * 16 / 9 / 2) <= 0.5)
  }
}

// MARK: - Rendered

/// A view rendered 258 pt wide at one pixel per point, read back as sRGB pixels.
@MainActor
private struct Rendered: CustomTestStringConvertible {
  enum Ink {
    case red
    case blue
  }

  static let width: CGFloat = 258

  /// Pure sRGB inks, which the system colours are not.
  static let red: Color = .init(.sRGB, red: 1, green: 0, blue: 0)
  static let blue: Color = .init(.sRGB, red: 0, green: 0, blue: 1)

  let size: CGSize
  private let pixels: [UInt8]

  init(_ view: some View) throws {
    let renderer: ImageRenderer = .init(content: view)
    renderer.proposedSize = ProposedViewSize(width: Self.width, height: nil)
    renderer.scale = 1
    let image = try #require(renderer.cgImage)

    var pixels: [UInt8] = .init(repeating: 0, count: image.width * image.height * 4)
    let context = try #require(CGContext(
      data: &pixels,
      width: image.width,
      height: image.height,
      bitsPerComponent: 8,
      bytesPerRow: image.width * 4,
      space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    self.pixels = pixels
    size = CGSize(width: image.width, height: image.height)
  }

  var testDescription: String { "\(Int(size.width)) by \(Int(size.height)) pixels" }

  /// The horizontal centre of the columns that hold `ink`, or `nil` when none does.
  func centerX(of ink: Ink) -> CGFloat? {
    let width: Int = .init(size.width)
    let columns = (0 ..< width).filter { x in
      (0 ..< Int(size.height)).contains { y in
        let pixel = (y * width + x) * 4
        let (red, blue) = (pixels[pixel], pixels[pixel + 2])
        return switch ink {
          case .red: red > 200 && blue < 60
          case .blue: blue > 200 && red < 60
        }
      }
    }
    guard let first = columns.first, let last = columns.last else { return nil }

    return CGFloat(first + last + 1) / 2
  }
}
