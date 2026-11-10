//
//  SquashBounce.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

// MARK: - SquashBounceValues

/// Animatable values for a squash-and-stretch bounce: dip, hop with overshoot, settle.
public struct SquashBounceValues: Sendable {
  /// The overall scale.
  public var scale: Double = 1
  /// The vertical stretch on top of `scale`.
  public var vStretch: Double = 1
  /// The vertical offset in points.
  public var vTranslation: Double = 0

  /// Values at rest.
  public init() { }

  /// How far the icon hops. The stretch track is shared; only scale and travel differ per site.
  public struct Amplitude: Sendable {
    /// The scale at the top of the hop.
    public let scalePeak: Double
    /// How far the icon dips before the hop (positive is down).
    public let dip: Double
    /// The top of the hop (negative is up).
    public let hop: Double
    /// Where the hop holds before it settles.
    public let hopHold: Double

    /// Onboarding icon (mid size): a small hop.
    static public let onboarding: Amplitude = .init(scalePeak: 1.05, dip: 10, hop: -10, hopHold: -12)
    /// About page icon (large size): a big hop.
    static public let aboutIcon: Amplitude = .init(scalePeak: 1.03, dip: 40, hop: -30, hopHold: -34)
  }

  /// The bounce's keyframes at `amplitude`.
  @KeyframesBuilder<SquashBounceValues>
  static public func keyframes(_ amplitude: Amplitude)
    -> some Keyframes<SquashBounceValues>
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
      SpringKeyframe(amplitude.scalePeak, duration: 0.38, spring: .bouncy)
      SpringKeyframe(amplitude.scalePeak, duration: 0.27, spring: .smooth)
      SpringKeyframe(1.0, spring: .bouncy(duration: 0.65, extraBounce: 0.1))
    }

    KeyframeTrack(\.vTranslation) {
      SpringKeyframe(amplitude.dip, duration: 0.11, spring: .bouncy)
      SpringKeyframe(amplitude.hop, duration: 0.43, spring: .bouncy)
      SpringKeyframe(amplitude.hopHold, duration: 0.27, spring: .smooth)
      SpringKeyframe(0.0, spring: .bouncy(duration: 0.65, extraBounce: 0.3))
    }
  }
}

// MARK: - SquashBounce

/// Bounces the content on every change of `trigger`; still under Reduce Motion.
///
/// A modifier on purpose: in a `(some View) -> some View` helper, the animator's content
/// closure captures an opaque metatype and trips a non-Sendable warning (ikalendar 2's a58eaf9).
struct SquashBounce: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let trigger: Int
  let amplitude: SquashBounceValues.Amplitude

  func body(content: Content) -> some View {
    let input: AnimatorInput = .init(trigger: trigger, reduceMotion: reduceMotion)

    content
      .keyframeAnimator(
        initialValue: SquashBounceValues(),
        trigger: input.trigger)
      { content, values in
        let values: SquashBounceValues = input.drawn(values)
        content
          .scaleEffect(values.scale)
          .scaleEffect(y: values.vStretch)
          .offset(y: values.vTranslation)
      } keyframes: { _ in
        SquashBounceValues.keyframes(amplitude)
      }
  }
}

// MARK: SquashBounce.AnimatorInput

extension SquashBounce {
  /// What the keyframe animator gets for one render.
  struct AnimatorInput {
    /// The caller's trigger. It never depends on Reduce Motion: a trigger that changed with the
    /// setting would start the keyframes the moment Reduce Motion turns on or off.
    let trigger: Int
    let isPlaying: Bool

    init(trigger: Int, reduceMotion: Bool) {
      self.trigger = trigger
      isPlaying = DecorativeMotion.squashBounce.form(reduceMotion: reduceMotion) == .full
    }

    /// The values the content draws: the keyframes' while the bounce plays, rest otherwise.
    func drawn(_ values: SquashBounceValues) -> SquashBounceValues {
      isPlaying ? values : SquashBounceValues()
    }
  }
}

extension View {
  /// Plays the squash-and-stretch bounce on every change of `trigger`, which the calling view owns.
  public func squashBounce(trigger: Int, amplitude: SquashBounceValues.Amplitude) -> some View {
    modifier(SquashBounce(trigger: trigger, amplitude: amplitude))
  }
}
