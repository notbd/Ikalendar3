//
//  TabReselection.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

import SwiftUI

#if os(iOS)
import ObjectiveC
import UIKit

// MARK: - Tab reselection

extension View {
  /// While `isEnabled`, a second tap on the selected tab runs `handle` and is the app's alone: the
  /// system neither scrolls the tab's list to the top nor pops its navigation stack. Tapping the
  /// status bar still scrolls. Apply it to the `TabView`.
  ///
  /// SwiftUI scrolls to the top on such a tap whatever the selection binding does, and offers no
  /// way to stop it, so this answers UIKit's `tabBarController(_:shouldSelectTab:)` in front of
  /// SwiftUI's own delegate. It stands in front only while enabled: SwiftUI's scroll to the top on
  /// the other tabs needs its delegate in place.
  func interceptingTabReselection(isEnabled: Bool, perform handle: @escaping () -> Void) -> some View {
    background(TabReselectionInterceptor(isEnabled: isEnabled, handle: handle).accessibilityHidden(true))
  }
}

// MARK: - TabReselectionInterceptor

/// Puts a `TabReselectionDelegate` in front of the window's tab bar controller delegate while
/// enabled, and takes it away when not.
private struct TabReselectionInterceptor: UIViewControllerRepresentable {
  let isEnabled: Bool
  let handle: () -> Void

  func makeUIViewController(context _: Context) -> Controller {
    Controller()
  }

  /// Runs on every tick of the app clock, since `handle` is a new closure each time the tabs
  /// render. That is harmless: `apply()` is a window lookup and a check of the delegate in place.
  /// It installs or removes the interceptor only when `isEnabled` changes or SwiftUI replaced the
  /// delegate; otherwise it hands the interceptor the new closure.
  func updateUIViewController(_ controller: Controller, context _: Context) {
    controller.isEnabled = isEnabled
    controller.handle = handle
    controller.apply()
  }

  /// An empty controller that finds the tab bar controller once it is in a window. The tab bar
  /// controller is not its ancestor: the `TabView` it sits behind hosts it.
  final class Controller: UIViewController {
    var isEnabled = false
    var handle: () -> Void = { }

    override func viewIsAppearing(_ animated: Bool) {
      super.viewIsAppearing(animated)
      apply()
    }

    func apply() {
      guard let tabBarController = view.window?.rootViewController?.firstTabBarController else { return }

      if isEnabled {
        TabReselectionDelegate.install(on: tabBarController, handle: handle)
      }
      else {
        TabReselectionDelegate.uninstall(from: tabBarController)
      }
    }
  }
}

extension UIViewController {
  /// This controller or the first tab bar controller among its children, depth first.
  fileprivate var firstTabBarController: UITabBarController? {
    (self as? UITabBarController) ?? children.lazy.compactMap(\.firstTabBarController).first
  }
}

// MARK: - TabReselectionDelegate

/// A tab bar controller delegate that answers a second tap on the selected tab and forwards
/// everything else to the delegate SwiftUI set.
final private class TabReselectionDelegate: NSObject, UITabBarControllerDelegate {
  /// The delegate SwiftUI set. Unchecked because UIKit asks the two Objective-C forwarding
  /// methods below without isolation, though always on the main thread.
  nonisolated(unsafe) weak private var forwardee: UITabBarControllerDelegate?
  /// Handles a second tap on the selected tab.
  private var handle: () -> Void

  private init(forwardee: UITabBarControllerDelegate?, handle: @escaping () -> Void) {
    self.forwardee = forwardee
    self.handle = handle
  }

  /// Puts an interceptor in front of `controller`'s delegate, or updates the one there. The
  /// controller keeps it alive: its `delegate` is weak.
  static func install(on controller: UITabBarController, handle: @escaping () -> Void) {
    if let installed = controller.delegate as? TabReselectionDelegate {
      installed.handle = handle
      return
    }

    let interceptor: TabReselectionDelegate = .init(forwardee: controller.delegate, handle: handle)
    objc_setAssociatedObject(controller, &associationKey, interceptor, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    controller.delegate = interceptor
  }

  /// Gives `controller` back the delegate SwiftUI set.
  static func uninstall(from controller: UITabBarController) {
    guard let installed = controller.delegate as? TabReselectionDelegate else { return }

    controller.delegate = installed.forwardee
    objc_setAssociatedObject(controller, &associationKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }

  func tabBarController(_ controller: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
    guard tab != controller.selectedTab else {
      handle()
      return false
    }

    return forwardee?.tabBarController?(controller, shouldSelectTab: tab) ?? true
  }

  override nonisolated func responds(to selector: Selector!) -> Bool {
    super.responds(to: selector) || forwardee?.responds(to: selector) == true
  }

  override nonisolated func forwardingTarget(for _: Selector!) -> Any? {
    forwardee
  }
}

/// The key under which a tab bar controller keeps its interceptor.
nonisolated(unsafe) private var associationKey: UInt8 = 0
#endif
