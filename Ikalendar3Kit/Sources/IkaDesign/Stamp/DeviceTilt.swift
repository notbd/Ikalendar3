//
//  DeviceTilt.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if os(iOS)
import CoreMotion
import UIKit

// MARK: - DeviceTilt

/// The device-motion monitor behind the Mode stamp's tilt, as ikalendar 2's: it samples gravity at
/// `GravityDeltaWindow.updateInterval`, keeps one rolling window per axis, and reports how far
/// gravity has moved from the windows' means, in the interface's axes.
///
/// One motion manager serves every stamp, as Core Motion asks. It samples only while some view
/// iterates `updates()`, so a stamp that is off screen, docked, under Reduce Motion or in an
/// inactive scene costs nothing. The simulator has no motion sensors and reports nothing.
@MainActor
enum DeviceTilt {
  static private let manager: CMMotionManager = .init()
  static private var subscribers: [UUID: AsyncStream<ModeStampMath.Tilt>.Continuation] = [:]
  static private var xWindow: GravityDeltaWindow = .init()
  static private var yWindow: GravityDeltaWindow = .init()

  /// The tilt at each sample until the caller stops iterating.
  static func updates() -> AsyncStream<ModeStampMath.Tilt> {
    let (stream, continuation) = AsyncStream.makeStream(
      of: ModeStampMath.Tilt.self,
      bufferingPolicy: .bufferingNewest(1))
    let id: UUID = .init()
    continuation.onTermination = { _ in
      Task { @MainActor in unsubscribe(id) }
    }
    subscribers[id] = continuation
    if subscribers.count == 1 { start() }
    return stream
  }

  static private func unsubscribe(_ id: UUID) {
    subscribers[id] = nil
    if subscribers.isEmpty { manager.stopDeviceMotionUpdates() }
  }

  /// Starts sampling with fresh windows, where the device has motion sensors.
  static private func start() {
    guard manager.isDeviceMotionAvailable else { return }

    xWindow = .init()
    yWindow = .init()
    manager.deviceMotionUpdateInterval = GravityDeltaWindow.updateInterval
    manager.startDeviceMotionUpdates(to: .main) { data, _ in
      // Delivered on the main queue, so on the main actor.
      MainActor.assumeIsolated {
        guard let gravity = data?.gravity else { return }

        publish(gravity)
      }
    }
  }

  /// Folds a gravity sample into the windows and sends the tilt to every subscriber.
  static private func publish(_ gravity: CMAcceleration) {
    let tilt: ModeStampMath.Tilt = ModeStampMath.screenTilt(
      dx: xWindow.push(CGFloat(gravity.x)),
      dy: yWindow.push(CGFloat(gravity.y)),
      orientation: interfaceOrientation)
    for continuation in subscribers.values {
      continuation.yield(tilt)
    }
  }

  /// The orientation of the first window scene, read at each sample, so a rotation applies at
  /// the next sample with no observer to keep in step.
  static private var interfaceOrientation: InterfaceOrientation {
    let scene: UIWindowScene? = UIApplication.shared.connectedScenes.lazy.compactMap { $0 as? UIWindowScene }.first
    return scene.map { InterfaceOrientation($0.effectiveGeometry.interfaceOrientation) } ?? .unknown
  }
}
#endif
