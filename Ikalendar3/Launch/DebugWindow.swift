//
//  DebugWindow.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if DEBUG
import IkaFixtures
import SwiftUI
#if os(macOS)
import AppKit
#endif

// MARK: - DebugWindow

/// The Debug launch options that shape the window, so a script can capture it at an App Store
/// screenshot size with no clicks or keys:
///
/// - `--window-size <width>x<height>` (Mac): the window's frame in points, title bar included.
///   With a showcase the title bar turns clear, as the desktop it stands in for has none.
/// - `--landscape` (iPad): lays the window out as in landscape, turned a quarter clockwise to fill
///   the portrait screen, with no status bar; the script turns the screenshot back. The simulator
///   takes no rotation from the command line, and an iPad app cannot turn the device.
enum DebugWindow {
  #if os(macOS)
  /// The window frame's size the launch asks for, or `nil` when it names none.
  static func size(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> CGSize? {
    let option = "--window-size"
    let arguments: LaunchArguments = .init(arguments)
    guard arguments.contains(option) else { return nil }

    let parts = arguments.value(of: option)?.split(separator: "x").compactMap { Double($0) } ?? []
    guard parts.count == 2 else { fatalError("\(option) takes <width>x<height> in points, such as 1440x900") }

    return CGSize(width: parts[0], height: parts[1])
  }
  #endif

  #if os(iOS)
  /// Whether the launch asks for the landscape layout turned to fit the portrait screen.
  static func isLandscape(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
    LaunchArguments(arguments).contains("--landscape")
  }
  #endif
}

extension View {
  /// Applies the window options the launch asks for (`DebugWindow`).
  @ViewBuilder
  func debugWindow() -> some View {
    #if os(macOS)
    background { DebugWindowReader() }
    #else
    if DebugWindow.isLandscape() { LandscapeCanvas { self } } else { self }
    #endif
  }
}

#if os(macOS)
extension View {
  /// Opens the main window once this view appears, when the launch sizes it (`--window-size`), for
  /// the screenshot script. A launch whose arguments leave a word over opens no main window, only
  /// the menu bar entry, whose label this modifies. The arguments are read as option and value
  /// pairs, so an option that takes no value, followed by one that takes a value, leaves the
  /// second one's value over: `--fixture-rebase --showcase menu-bar` leaves `menu-bar`. Opening a
  /// window that is open brings it forward.
  func debugOpeningMainWindow() -> some View {
    modifier(MainWindowOpener())
  }
}

/// Opens the main window when the launch sizes it.
private struct MainWindowOpener: ViewModifier {
  @Environment(\.openWindow) private var openWindow

  func body(content: Content) -> some View {
    content.task {
      guard DebugWindow.size() != nil else { return }

      openWindow(id: Ikalendar3App.mainWindowID)
    }
  }
}

// MARK: - DebugWindowReader

/// Finds the view's window and sets the frame the launch asks for, centred on its screen.
private struct DebugWindowReader: NSViewRepresentable {
  func makeNSView(context _: Context) -> WindowFinder {
    WindowFinder()
  }

  func updateNSView(_: WindowFinder, context _: Context) { }

  final class WindowFinder: NSView {
    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      guard let window, let size = DebugWindow.size() else { return }

      if Showcase.requested() != nil {
        // A borderless window leaves the window list, so the title bar turns clear instead.
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
          window.standardWindowButton(button)?.isHidden = true
        }
      }
      let visible = window.screen?.visibleFrame ?? .zero
      window.setFrame(
        NSRect(
          x: visible.midX - size.width / 2,
          y: visible.midY - size.height / 2,
          width: size.width,
          height: size.height),
        display: true)
    }
  }
}
#else

// MARK: - LandscapeCanvas

/// The window's content laid out in the screen's landscape size, with a status bar's room at its
/// top, turned a quarter clockwise to fill the portrait screen.
private struct LandscapeCanvas<Content: View>: View {
  @ViewBuilder let content: Content

  var body: some View {
    GeometryReader { proxy in
      content
        // The system draws the edge effects along the portrait screen's edges, across the content.
        .scrollEdgeEffectHidden(true, for: .all)
        .safeAreaPadding(.top, 24)
        .safeAreaPadding(.bottom, 20)
        .frame(width: proxy.size.height, height: proxy.size.width)
        .rotationEffect(.degrees(90))
        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
    }
    .ignoresSafeArea()
    .statusBarHidden()
    .persistentSystemOverlays(.hidden)
  }
}
#endif
#endif
