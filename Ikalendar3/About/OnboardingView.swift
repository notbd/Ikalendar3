//
//  OnboardingView.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import IkaCore
import IkaDesign
import SwiftUI

// MARK: - OnboardingView

/// ikalendar 2's welcome screen with the new name, and no other page: the icon and title float in,
/// the icon bounces now and then, and Get Started closes it for good. It shows instead of the
/// schedules on first launch while the first load runs (`AppRootView`).
///
/// Under Reduce Motion the entrance only fades in, and the bounce and the button's pulse stop.
struct OnboardingView: View {
  @Environment(PreferenceStore.self) private var preferences
  @Environment(\.gameLanguage) private var language
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  /// Choreography timing, relative to the screen's appearance unless noted.
  private enum Timing {
    /// The beat of stillness before the entrance.
    static let entranceDelay: TimeInterval = 1
    /// The entrance, until the icon lands.
    static let entranceDuration: TimeInterval = Phase.show.duration + Phase.float.duration
    /// The first automatic bounce, after the landing.
    static let firstAutoBounceDelay: TimeInterval = 3
    /// The pause between automatic bounces; a tap restarts it.
    static let autoBounceInterval: TimeInterval = 9
    /// How often the button pulses.
    static let buttonPulseInterval: TimeInterval = 9
  }

  @State private var hasEntered = false
  @State private var hasLanded = false
  @State private var buttonPulses = 0
  @State private var iconBounces = 0

  var body: some View {
    ZStack {
      Rectangle()
        .fill(.background)
        .ignoresSafeArea()
        .onTapGesture { iconBounces += 1 }

      VStack(alignment: .leading) {
        Spacer()
        icon
          .onTapGesture { iconBounces += 1 }
        title
          .onTapGesture { iconBounces += 1 }
        Spacer()
        button
      }
      .containerRelativeFrame(.horizontal) { width, _ in columnWidth(in: width) }
      .padding(Self.margin)
    }
    .sensoryFeedback(Haptic.onboardingLanded, trigger: hasLanded)
    // The entrance, then the first bounce unless a tap has bounced the icon already.
    .task {
      try? await Task.sleep(for: .seconds(Timing.entranceDelay))
      hasEntered = true

      try? await Task.sleep(for: .seconds(Timing.entranceDuration))
      guard !Task.isCancelled else { return }

      hasLanded = true

      try? await Task.sleep(for: .seconds(Timing.firstAutoBounceDelay))
      guard !Task.isCancelled, iconBounces == 0 else { return }

      iconBounces += 1
    }
    // The button's pulse, from the landing on.
    .task {
      try? await Task.sleep(for: .seconds(Timing.entranceDelay + Timing.entranceDuration))
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(Timing.buttonPulseInterval), tolerance: .seconds(Motion.timerTolerance))
        guard !Task.isCancelled else { return }

        buttonPulses += 1
      }
    }
    // Each bounce, by tap or automatic, schedules the next.
    .task(id: iconBounces) {
      guard iconBounces > 0 else { return }

      try? await Task.sleep(for: .seconds(Timing.autoBounceInterval), tolerance: .seconds(Motion.timerTolerance))
      guard !Task.isCancelled else { return }

      iconBounces += 1
    }
  }

  // MARK: Parts

  private var icon: some View {
    AppIconMark(size: 90)
      .sensoryFeedback(Haptic.iconBounce, trigger: iconBounces)
      .modifier(Entrance(part: .icon, hasStarted: hasEntered))
      .squashBounce(trigger: iconBounces, amplitude: .onboarding)
  }

  /// "Welcome to ikalendar3", the name in the app's accent.
  private var title: some View {
    var title: AttributedString = .init(AboutText.welcome.text(in: language, Ikalendar3App.name))
    if let name = title.range(of: Ikalendar3App.name) {
      title[name].foregroundColor = Color(.appAccent)
    }

    return Text(title)
      .ikaFont(.heavy, size: 42, relativeTo: .largeTitle)
      // The face's own line gap spaces its lines twice as far apart as the system font's.
      .lineHeight(.multiple(factor: 1.1))
      // Past the second accessibility size the name alone outgrows a 6.1-inch screen and would
      // break inside the word, so the 42-point title grows no further; it shrinks rather than being
      // cut off when the screen is short.
      .dynamicTypeSize(...DynamicTypeSize.accessibility2)
      .minimumScaleFactor(0.5)
      .foregroundStyle(.primary)
      .modifier(Entrance(part: .title, hasStarted: hasEntered))
  }

  private var button: some View {
    Button {
      preferences.shouldShowOnboarding = false
    } label: {
      Text(AboutText.getStarted.text(in: language))
        .ikaFont(.heavy, size: 18, relativeTo: .headline)
        .lineHeight(.multiple(factor: 1.1))
        .padding(.vertical, 10)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        // On the accent fill (`accentFill`): 9.6:1 in light, 10.2:1 in dark.
        .foregroundStyle(.black)
    }
    .buttonStyle(.glassProminent)
    .tint(.accentFill)
    .sensoryFeedback(Haptic.done, trigger: preferences.shouldShowOnboarding) { _, isShown in !isShown }
    .modifier(Entrance(part: .button, hasStarted: hasEntered))
    .phaseAnimator([1, 0.95], trigger: buttonPulses) { content, scale in
      content.scaleEffect(isPulsing ? scale : 1)
    } animation: { scale in
      scale == 1 ? Motion.buttonPulseOut : Motion.buttonPulseIn
    }
  }

  // MARK: Helpers

  private var isCompact: Bool {
    horizontalSizeClass == .compact
  }

  /// The column's width in a container `width` wide: four fifths of a compact width, half of a
  /// regular one, and from the first accessibility text size the whole compact width inside the
  /// margins, for the larger title.
  private func columnWidth(in width: CGFloat) -> CGFloat {
    guard isCompact else { return width / 2 }

    return dynamicTypeSize.isAccessibilitySize ? width - 2 * Self.margin : width * 4 / 5
  }

  /// The space around the column.
  static private let margin: CGFloat = 16

  private var isPulsing: Bool {
    DecorativeMotion.buttonPulse.form(reduceMotion: reduceMotion) == .full
  }
}

// MARK: - Phase

/// The entrance's phases.
private enum Phase {
  case show
  case float
  case bounceDown
  case bounceUp

  var duration: Double {
    switch self {
      case .show: 1.5
      case .float: 0.5
      case .bounceDown: 0.15
      case .bounceUp: 1.0
    }
  }
}

// MARK: - Entrance

/// Plays a part's entrance once `hasStarted` turns true: in full, or under Reduce Motion only its
/// fade, at the place the entrance ends.
///
/// A modifier, as `SquashBounce` is: in a `(some View) -> some View` helper, the animator's content
/// closure trips a non-Sendable warning.
private struct Entrance: ViewModifier {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let part: Part
  let hasStarted: Bool

  func body(content: Content) -> some View {
    let isReduced = reduceMotion
    switch part {
      case .icon:
        content.keyframeAnimator(initialValue: part.start, trigger: hasStarted) { content, values in
          let values = values.drawn(isReduced: isReduced)
          content.opacity(values.opacity).scaleEffect(values.scale).offset(y: values.offset)
        } keyframes: { _ in
          Part.iconKeyframes()
        }

      case .title:
        content.keyframeAnimator(initialValue: part.start, trigger: hasStarted) { content, values in
          let values = values.drawn(isReduced: isReduced)
          content.opacity(values.opacity).scaleEffect(values.scale).offset(y: values.offset)
        } keyframes: { _ in
          Part.titleKeyframes()
        }

      case .button:
        content.keyframeAnimator(initialValue: part.start, trigger: hasStarted) { content, values in
          let values = values.drawn(isReduced: isReduced)
          content.opacity(values.opacity).scaleEffect(values.scale).offset(y: values.offset)
        } keyframes: { start in
          Part.buttonKeyframes(start)
        }
    }
  }
}

// MARK: - EntranceValues

/// What an entrance animates for one part.
nonisolated private struct EntranceValues {
  var opacity: Double
  var scale: Double
  var offset: Double
  /// Where the part rests once the entrance ends.
  let restingOffset: Double

  /// The values a part draws: these in full, or under Reduce Motion only the opacity, at rest.
  func drawn(isReduced: Bool) -> EntranceValues {
    isReduced ? EntranceValues(opacity: opacity, scale: 1, offset: restingOffset, restingOffset: restingOffset) : self
  }
}

// MARK: - Part

/// The welcome screen's three animated parts, with ikalendar 2's entrance keyframes.
private enum Part {
  case icon
  case title
  case button

  /// The values before the entrance.
  var start: EntranceValues {
    switch self {
      case .icon: EntranceValues(opacity: 0, scale: 0.5, offset: -5, restingOffset: Self.liftedOffset)
      case .title: EntranceValues(opacity: 0, scale: 0.5, offset: 10, restingOffset: Self.liftedOffset)
      case .button: EntranceValues(opacity: 0, scale: 0.8, offset: 10, restingOffset: 0)
    }
  }

  /// How far the icon and the title rise as they land.
  static private let liftedOffset: Double = -80

  /// The icon fades and grows in during the show, holds through the float, then springs up to rest.
  @KeyframesBuilder<EntranceValues>
  static func iconKeyframes() -> some Keyframes<EntranceValues> {
    KeyframeTrack(\.opacity) {
      LinearKeyframe(1.0, duration: Phase.show.duration)
    }
    KeyframeTrack(\.scale) {
      SpringKeyframe(1.0, duration: Phase.show.duration)
    }
    KeyframeTrack(\.offset) {
      LinearKeyframe(0.0, duration: Phase.show.duration)
      LinearKeyframe(0.0, duration: Phase.float.duration + 0.1)
      SpringKeyframe(5.0, duration: Phase.bounceDown.duration, spring: .bouncy)
      SpringKeyframe(liftedOffset, duration: Phase.bounceUp.duration, spring: .bouncy)
    }
  }

  /// The title mirrors the icon, a beat earlier, so it trails the icon upward.
  @KeyframesBuilder<EntranceValues>
  static func titleKeyframes() -> some Keyframes<EntranceValues> {
    KeyframeTrack(\.opacity) {
      LinearKeyframe(1.0, duration: Phase.show.duration)
    }
    KeyframeTrack(\.scale) {
      SpringKeyframe(1.0, duration: Phase.show.duration)
    }
    KeyframeTrack(\.offset) {
      LinearKeyframe(0.0, duration: Phase.show.duration + Phase.float.duration)
      SpringKeyframe(5.0, duration: Phase.bounceDown.duration, spring: .bouncy)
      SpringKeyframe(liftedOffset, duration: Phase.bounceUp.duration, spring: .bouncy)
    }
  }

  /// The button stays hidden through the show and the float, then springs in as the icon lands.
  @KeyframesBuilder<EntranceValues>
  static func buttonKeyframes(_ start: EntranceValues) -> some Keyframes<EntranceValues> {
    KeyframeTrack(\.opacity) {
      LinearKeyframe(start.opacity, duration: Phase.show.duration + Phase.float.duration)
      SpringKeyframe(1.0, duration: Phase.bounceDown.duration + Phase.bounceUp.duration)
    }
    KeyframeTrack(\.scale) {
      LinearKeyframe(start.scale, duration: Phase.show.duration + Phase.float.duration)
      SpringKeyframe(1.0, duration: Phase.bounceDown.duration + Phase.bounceUp.duration)
    }
    KeyframeTrack(\.offset) {
      LinearKeyframe(start.offset, duration: Phase.show.duration + Phase.float.duration)
      SpringKeyframe(0.0, duration: Phase.bounceUp.duration, spring: .bouncy)
    }
  }
}
