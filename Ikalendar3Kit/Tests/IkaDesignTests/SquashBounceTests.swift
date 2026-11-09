//
//  SquashBounceTests.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI
import Testing
@testable import IkaDesign

// MARK: - SquashBounceTests

/// The shared squash-and-stretch bounce must replay the two hand-written curves it replaced,
/// value for value. Both are kept below as a fixture, copied from the deleted code.
/// Carried over from ikalendar 2's `SquashBounceTests`.
struct SquashBounceTests {
  /// One sample per frame of a 240 Hz display.
  static private let samplesPerSecond: Double = 240

  private struct Sample: Equatable {
    let scale: Double
    let vStretch: Double
    let vTranslation: Double
  }

  /// Samples a timeline every 1/240 s from 0 through its duration.
  private func samples<Value>(
    of timeline: KeyframeTimeline<Value>,
    _ sample: (Value) -> Sample)
    -> [Sample]
  {
    let count = Int((timeline.duration * Self.samplesPerSecond).rounded(.up)) + 1
    return (0 ..< count).map { sample(timeline.value(time: Double($0) / Self.samplesPerSecond)) }
  }

  private func sharedTimeline(_ amplitude: SquashBounceValues.Amplitude) -> KeyframeTimeline<SquashBounceValues> {
    .init(initialValue: SquashBounceValues()) {
      SquashBounceValues.keyframes(amplitude)
    }
  }

  @Test
  func `About icon bounce matches the old About keyframes`() {
    let sharedTimeline: KeyframeTimeline<SquashBounceValues> = sharedTimeline(.aboutIcon)
    let oldTimeline: KeyframeTimeline<OldAboutIconValues> = .init(initialValue: OldAboutIconValues()) {
      OldAboutIconValues.appIconKeyframes()
    }
    let sharedSamples: [Sample] = samples(of: sharedTimeline) {
      .init(scale: $0.scale, vStretch: $0.vStretch, vTranslation: $0.vTranslation)
    }
    let oldSamples: [Sample] = samples(of: oldTimeline) {
      .init(scale: $0.scale, vStretch: $0.vStretch, vTranslation: $0.vTranslation)
    }

    #expect(sharedTimeline.duration == oldTimeline.duration)
    #expect(oldSamples.count > Int(Self.samplesPerSecond))
    #expect(sharedSamples == oldSamples)
    #expect(sharedSamples.contains { $0.vTranslation < -30 })
  }

  @Test
  func `Onboarding bounce matches the old onboarding keyframes`() {
    let sharedTimeline: KeyframeTimeline<SquashBounceValues> = sharedTimeline(.onboarding)
    let oldTimeline: KeyframeTimeline<OldOnboardingValues> = .init(initialValue: .iconEnd) {
      OldOnboardingValues.iconExtraKeyframes(start: .iconEnd)
    }
    let sharedSamples: [Sample] = samples(of: sharedTimeline) {
      .init(scale: $0.scale, vStretch: $0.vStretch, vTranslation: $0.vTranslation)
    }
    let oldSamples: [Sample] = samples(of: oldTimeline) {
      .init(scale: $0.scale, vStretch: $0.vStretch, vTranslation: $0.vTranslation)
    }

    #expect(sharedTimeline.duration == oldTimeline.duration)
    #expect(oldSamples.count > Int(Self.samplesPerSecond))
    #expect(sharedSamples == oldSamples)
    #expect(sharedSamples.contains { $0.vTranslation < -10 })
  }
}

// MARK: - OldAboutIconValues

/// Fixture: `SettingsAboutAppIconAnimationValues` before the shared bounce.
private struct OldAboutIconValues {
  var scale: Double = 1
  var vStretch: Double = 1
  var vTranslation: Double = 0

  @KeyframesBuilder<OldAboutIconValues>
  static func appIconKeyframes()
    -> some Keyframes<OldAboutIconValues>
  {
    KeyframeTrack(\.vStretch) {
      CubicKeyframe(1.0, duration: 0.01)
      CubicKeyframe(0.8, duration: 0.06)
      CubicKeyframe(1.12, duration: 0.1)
      CubicKeyframe(1.04, duration: 0.3)
      CubicKeyframe(1.0, duration: 0.3)
      CubicKeyframe(0.9, duration: 0.22)
      CubicKeyframe(1.02, duration: 0.23)
      CubicKeyframe(1.0, duration: 0.20)
    }

    KeyframeTrack(\.scale) {
      LinearKeyframe(1.0, duration: 0.16)
      SpringKeyframe(1.03, duration: 0.38, spring: .bouncy)
      SpringKeyframe(1.03, duration: 0.27, spring: .smooth)
      SpringKeyframe(1.0, spring: .bouncy(duration: 0.65, extraBounce: 0.1))
    }

    KeyframeTrack(\.vTranslation) {
      SpringKeyframe(40.0, duration: 0.11, spring: .bouncy)
      SpringKeyframe(-30.0, duration: 0.43, spring: .bouncy)
      SpringKeyframe(-34.0, duration: 0.27, spring: .smooth)
      SpringKeyframe(0.0, spring: .bouncy(duration: 0.65, extraBounce: 0.3))
    }
  }
}

// MARK: - OldOnboardingValues

/// Fixture: `OnboardingObject.OnboardingAnimationValues` and `iconExtraKeyframes` before the
/// shared bounce.
private struct OldOnboardingValues {
  var opacity: Double
  var scale: Double
  var vStretch: Double
  var vTranslation: Double

  /// `OnboardingObject.iconEnd.animationValues`, the old animator's initial value.
  static let iconEnd: OldOnboardingValues = .init(opacity: 1, scale: 1, vStretch: 1, vTranslation: 0)

  @KeyframesBuilder<OldOnboardingValues>
  static func iconExtraKeyframes(start _: OldOnboardingValues)
    -> some Keyframes<OldOnboardingValues>
  {
    KeyframeTrack(\.vStretch) {
      CubicKeyframe(1.0, duration: 0.01)
      CubicKeyframe(0.8, duration: 0.06)
      CubicKeyframe(1.12, duration: 0.1)
      CubicKeyframe(1.04, duration: 0.3)
      CubicKeyframe(1.0, duration: 0.3)
      CubicKeyframe(0.9, duration: 0.22)
      CubicKeyframe(1.02, duration: 0.23)
      CubicKeyframe(1.0, duration: 0.20)
    }

    KeyframeTrack(\.scale) {
      LinearKeyframe(1.0, duration: 0.16)
      SpringKeyframe(1.05, duration: 0.38, spring: .bouncy)
      SpringKeyframe(1.05, duration: 0.27, spring: .smooth)
      SpringKeyframe(1.0, spring: .bouncy(duration: 0.65, extraBounce: 0.1))
    }

    KeyframeTrack(\.vTranslation) {
      SpringKeyframe(10.0, duration: 0.11, spring: .bouncy)
      SpringKeyframe(-10.0, duration: 0.43, spring: .bouncy)
      SpringKeyframe(-12.0, duration: 0.27, spring: .smooth)
      SpringKeyframe(0.0, spring: .bouncy(duration: 0.65, extraBounce: 0.3))
    }
  }
}
