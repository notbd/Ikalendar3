//
//  DecorativeMotion.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

// MARK: - DecorativeMotion

/// Every motion the app plays for decoration rather than in answer to the user's own gesture.
/// Motion the user drives (scrolling, paging, sheets) is not listed and always stays.
///
/// Each view that plays one of these asks `form(reduceMotion:)` how to play it, so the Reduce
/// Motion rule lives here once.
public enum DecorativeMotion: CaseIterable, Sendable {
  /// The Mode stamp tilting with the device.
  case stampTilt
  /// The Mode stamp shrinking into the navigation bar badge as the list scrolls.
  case stampDock
  /// The squash-and-stretch hop of the onboarding and About icons.
  case squashBounce
  /// The periodic wiggle on an undiscovered row's symbol.
  case iconNudge
  /// The onboarding button growing and settling to draw the eye.
  case buttonPulse
  /// A text pulsing to a colour and back.
  case periodicPulse
  /// Rows moving into place when a Rotation rolls off a list.
  case listReflow
  /// The time-left digits rolling as they count down.
  case countdownRoll
  /// A Shift's kind icon growing as the Shift becomes current.
  case currentIconGrow

  /// How the motion plays: in full, or in its still or cross-fade form under Reduce Motion.
  public func form(reduceMotion: Bool) -> MotionForm {
    reduceMotion ? reducedForm : .full
  }

  /// The form under Reduce Motion. Spatial motion stops; a change of state the user must still
  /// notice (the dock handover, a colour pulse, the countdown's new digits) cross-fades.
  private var reducedForm: MotionForm {
    switch self {
      case .stampTilt,
           .squashBounce,
           .iconNudge,
           .buttonPulse,
           .listReflow,
           .currentIconGrow:
        .still
      case .stampDock,
           .periodicPulse,
           .countdownRoll:
        .crossFade
    }
  }
}

// MARK: - MotionForm

/// How a decorative motion plays.
public enum MotionForm: Sendable {
  /// As designed.
  case full
  /// As an opacity change only: nothing moves, scales or rotates.
  case crossFade
  /// Not at all: the change, if any, happens at once.
  case still
}
