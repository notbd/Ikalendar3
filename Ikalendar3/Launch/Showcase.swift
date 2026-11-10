//
//  Showcase.swift
//  Ikalendar3
//
//  Copyright (c) TIANWEI ZHANG. All rights reserved.
//

#if DEBUG
import IkaCore
import IkaDesign
import IkaFixtures
import IkaIntents
import SwiftUI
import WidgetKit

// MARK: - Showcase

/// The Debug launch's pictures of the Surfaces the system draws (`--showcase <name>`): the
/// widgets, the Live Activity and the menu bar window, drawn by their own views from the snapshot
/// at the app clock's instant, on a backdrop standing in for the Lock Screen, the Home Screen or
/// the desktop. The simulator cannot place a widget or show the Lock Screen from a script, so the
/// screenshot script captures these instead. A rebased fixture launch keeps the system's
/// countdowns on the fixture day.
enum Showcase: String, CaseIterable {
  /// iPhone: the Lock Screen widgets over Home Screen widgets. iPad: Home Screen widgets.
  case widgets
  /// iPhone: the Live Activity in the expanded Dynamic Island and on the Lock Screen.
  case liveActivity = "live-activity"
  /// Mac: the menu bar window beside desktop widgets.
  case menuBar = "menu-bar"

  /// The showcase a launch asks for, or `nil` when it names none.
  static func requested(_ arguments: [String] = ProcessInfo.processInfo.arguments) -> Showcase? {
    let option = "--showcase"
    let arguments: LaunchArguments = .init(arguments)
    guard arguments.contains(option) else { return nil }
    guard let name = arguments.value(of: option), let showcase = Showcase(rawValue: name) else {
      fatalError("\(option) takes one of \(allCases.map(\.rawValue).joined(separator: ", "))")
    }

    return showcase
  }
}

// MARK: - ShowcaseView

/// The showcase on a full-window backdrop, in dark appearance as the screenshots are.
struct ShowcaseView: View {
  @Environment(RefreshEngine.self) private var engine
  @Environment(AppClock.self) private var clock

  let showcase: Showcase

  var body: some View {
    let samples: ShowcaseSamples = .init(snapshot: engine.snapshot, now: clock.now, language: AppServices.language)
    ZStack {
      ShowcaseWallpaper()
      switch showcase {
        case .widgets: widgets(samples)
        case .liveActivity: liveActivity(samples)
        case .menuBar: menuBar(samples)
      }
    }
    .environment(\.colorScheme, .dark)
    #if os(macOS)
    // The desktop it stands in for has no title bar.
    .toolbar(removing: .title)
    .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
    #endif
  }
}

extension ShowcaseView {
  /// The widgets of this device: the iPhone's Lock and Home Screens, the iPad's Home Screen, or
  /// the Mac desktop.
  @ViewBuilder
  private func widgets(_ samples: ShowcaseSamples) -> some View {
    #if os(iOS)
    if UIDevice.current.userInterfaceIdiom == .pad {
      PadHomeScreenShowcase(samples: samples)
    }
    else {
      PhoneWidgetsShowcase(samples: samples)
    }
    #else
    DesktopWidgets(samples: samples)
    #endif
  }

  /// The Live Activity, which only iOS shows.
  @ViewBuilder
  private func liveActivity(_ samples: ShowcaseSamples) -> some View {
    #if os(iOS)
    LiveActivityShowcase(samples: samples)
    #endif
  }

  /// The menu bar window, which only the Mac shows.
  @ViewBuilder
  private func menuBar(_ samples: ShowcaseSamples) -> some View {
    #if os(macOS)
    MenuBarShowcase(samples: samples)
    #endif
  }
}

// MARK: - ShowcaseSamples

/// The widget entries and the Live Activity render a showcase draws: what each would show at
/// `now`, built as their timeline providers build them.
struct ShowcaseSamples {
  let snapshot: Snapshot
  let now: Date
  let terms: GameTerms

  init(snapshot: Snapshot, now: Date, language: GameLanguage) {
    self.snapshot = snapshot
    self.now = now
    terms = snapshot.terms(in: language)
  }

  /// The battle widget set to `mode` at `family`.
  func battle(_ mode: BattleMode, _ family: BattleWidgetFamily) -> ScheduleWidgetEntry<BattleWidgetContent> {
    entry(snapshot.battleWidgetTimeline(of: mode, family: family, from: now))
  }

  /// The extra large widget with every Battle Mode.
  var overview: ScheduleWidgetEntry<[BattleWidgetContent]> {
    entry(snapshot.extraLargeBattleWidgetTimeline(from: now))
  }

  /// The Salmon Run widget.
  var salmonRun: ScheduleWidgetEntry<SalmonRunWidgetContent> {
    entry(snapshot.salmonRunWidgetTimeline(from: now))
  }

  #if os(iOS)
  /// The Live Activity of Tracking `mode`, as the system renders it now, or `nil` when the
  /// snapshot has nothing to Track.
  func tracking(_ mode: Mode) -> TrackingRender? {
    snapshot.trackingState(of: mode, at: now).map {
      TrackingRender(mode: mode, state: $0, isStale: false, renderTime: now, terms: terms)
    }
  }
  #endif

  private func entry<Content>(_ timeline: WidgetTimeline<Content>?) -> ScheduleWidgetEntry<Content> {
    ScheduleWidgetEntry(date: now, schedule: timeline?.entries.first, terms: terms)
  }
}

// MARK: - Widget frames

/// A Home Screen or desktop widget's frame: the system's content margins and rounded corners on
/// Ink's dotted background, which the widget's container background asks for.
private struct WidgetFrame<Content: View>: View {
  let size: CGSize
  @ViewBuilder let content: Content

  var body: some View {
    content
      .padding(16)
      .frame(width: size.width, height: size.height)
      .background { InkBackground() }
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
  }
}

/// Widget sizes in points, as the system lays out its families on an iPhone 6.9-inch display, an
/// iPad 13-inch display and a Mac desktop.
private enum WidgetSize {
  static let small: CGSize = .init(width: 170, height: 170)
  static let medium: CGSize = .init(width: 364, height: 170)
  static let large: CGSize = .init(width: 364, height: 382)
  static let padMedium: CGSize = .init(width: 379, height: 170)
  static let padLarge: CGSize = .init(width: 379, height: 379)
  static let padExtraLarge: CGSize = .init(width: 795, height: 379)
  static let circular: CGSize = .init(width: 76, height: 76)
  static let rectangular: CGSize = .init(width: 172, height: 76)
}

// MARK: - ShowcaseWallpaper

/// A dark wallpaper in Splatfest-like Mode colours, standing in for the player's.
private struct ShowcaseWallpaper: View {
  var body: some View {
    LinearGradient(
      colors: [
        Color(ModeColor(Mode.battle(.regular)).base).opacity(0.55),
        .black,
        Color(ModeColor(Mode.salmonRun).base).opacity(0.5),
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing)
      .background(.black)
      .ignoresSafeArea()
  }
}

#if os(iOS)

// MARK: - Lock Screen parts

/// The Lock Screen's date and time over what it holds: the time is the screenshots' 9:41, the date
/// the app clock's day in the app language.
private struct LockScreenClock<Accessory: View>: View {
  let samples: ShowcaseSamples
  @ViewBuilder let accessory: Accessory

  var body: some View {
    VStack(spacing: 2) {
      HStack(spacing: 6) {
        Text(samples.now, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
        accessory
      }
      .font(.system(size: 20, weight: .semibold))
      Text(verbatim: "9:41")
        .font(.system(size: 104, weight: .bold, design: .rounded))
    }
    .foregroundStyle(.white)
    .environment(\.locale, Locale(identifier: samples.terms.language.rawValue))
  }
}

/// A Lock Screen widget at `family` in the vibrant rendering mode, in white on the wallpaper.
private struct LockScreenWidget: View {
  let entry: ScheduleWidgetEntry<BattleWidgetContent>
  let family: WidgetFamily

  var body: some View {
    LockScreenBattleView(entry: entry, family: family)
      .environment(\.widgetRenderingMode, .vibrant)
      .foregroundStyle(.white)
      .frame(width: size?.width, height: size?.height)
      .background {
        if family == .accessoryCircular {
          Circle().fill(.white.opacity(0.18))
        }
      }
  }

  private var size: CGSize? {
    switch family {
      case .accessoryCircular: WidgetSize.circular
      case .accessoryRectangular: WidgetSize.rectangular
      default: nil
    }
  }
}

// MARK: - PhoneWidgetsShowcase

/// The iPhone's widgets: the Lock Screen with its inline, circular and rectangular widgets, then
/// Home Screen widgets in every size the Salmon Run and battle widgets come in.
private struct PhoneWidgetsShowcase: View {
  let samples: ShowcaseSamples

  var body: some View {
    VStack(spacing: 18) {
      LockScreenClock(samples: samples) {
        LockScreenWidget(entry: samples.battle(.regular, .inline), family: .accessoryInline)
          .lineLimit(1)
      }
      HStack(spacing: 12) {
        LockScreenWidget(entry: samples.battle(.x, .circular), family: .accessoryCircular)
        LockScreenWidget(entry: samples.battle(.anarchySeries, .rectangular), family: .accessoryRectangular)
        LockScreenWidget(entry: samples.battle(.anarchyOpen, .circular), family: .accessoryCircular)
      }
      Spacer(minLength: 12)
      WidgetFrame(size: WidgetSize.medium) {
        BattleWidgetLayout(entry: samples.battle(.anarchySeries, .medium), family: .systemMedium)
      }
      HStack(spacing: 24) {
        WidgetFrame(size: WidgetSize.small) {
          SalmonRunWidgetLayout(entry: samples.salmonRun, family: .systemSmall)
        }
        WidgetFrame(size: WidgetSize.small) {
          BattleWidgetLayout(entry: samples.battle(.x, .small), family: .systemSmall)
        }
      }
    }
    .padding(.top, 60)
    .padding(.bottom, 40)
  }
}

// MARK: - PadHomeScreenShowcase

/// The iPad's Home Screen widgets: the extra large one with every Battle Mode, then a large battle
/// widget beside the Salmon Run widget and two small battle widgets.
private struct PadHomeScreenShowcase: View {
  let samples: ShowcaseSamples

  var body: some View {
    VStack(spacing: 37) {
      WidgetFrame(size: WidgetSize.padExtraLarge) {
        BattleOverviewView(entry: samples.overview)
      }
      HStack(alignment: .top, spacing: 37) {
        WidgetFrame(size: WidgetSize.padLarge) {
          BattleWidgetLayout(entry: samples.battle(.regular, .large), family: .systemLarge)
        }
        VStack(spacing: 37) {
          WidgetFrame(size: WidgetSize.padMedium) {
            SalmonRunWidgetLayout(entry: samples.salmonRun, family: .systemMedium)
          }
          HStack(spacing: 39) {
            WidgetFrame(size: WidgetSize.small) {
              BattleWidgetLayout(entry: samples.battle(.anarchySeries, .small), family: .systemSmall)
            }
            WidgetFrame(size: WidgetSize.small) {
              BattleWidgetLayout(entry: samples.battle(.x, .small), family: .systemSmall)
            }
          }
        }
      }
    }
  }
}

// MARK: - LiveActivityShowcase

/// The Live Activity of Tracking Anarchy Battle (Series): the expanded Dynamic Island at the top,
/// then the Lock Screen with the activity under the clock, each with its own views.
private struct LiveActivityShowcase: View {
  let samples: ShowcaseSamples

  private let mode: Mode = .battle(.anarchySeries)

  var body: some View {
    if let render = samples.tracking(mode) {
      VStack(spacing: 28) {
        island(render)
        LockScreenClock(samples: samples) { EmptyView() }
          .padding(.top, 24)
        Spacer(minLength: 0)
        TrackingLockScreenView(render: render) { refresh(render) }
          .background(.black)
          .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
          .padding(.horizontal, 14)
          .padding(.bottom, 48)
      }
    }
  }

  /// The expanded Dynamic Island: the system's black shape with the activity's leading, trailing
  /// and bottom regions.
  private func island(_ render: TrackingRender) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        TrackingIsland.leading(render)
        Spacer(minLength: 8)
        TrackingIsland.trailing(render)
      }
      TrackingIsland.bottom(render) { refresh(render) }
    }
    .padding(.horizontal, 22)
    .padding(.vertical, 18)
    .background(.black, in: RoundedRectangle(cornerRadius: 44, style: .continuous))
    .padding(.horizontal, 10)
    .padding(.top, 10)
  }

  /// The Refresh button as the activity draws it; here it does nothing.
  private func refresh(_ render: TrackingRender) -> some View {
    Button { } label: {
      TrackingRefreshLabel(
        title: TrackingText.refresh.text(in: render.terms.language),
        systemImage: TrackingText.refresh.systemImage)
    }
    .trackingRefreshButtonStyle()
  }
}
#endif

#if os(macOS)

// MARK: - DesktopWidgets

/// Desktop widgets: a large battle widget, the Salmon Run widget and a small battle widget.
private struct DesktopWidgets: View {
  let samples: ShowcaseSamples

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      WidgetFrame(size: WidgetSize.large) {
        BattleWidgetLayout(entry: samples.battle(.anarchySeries, .large), family: .systemLarge)
      }
      WidgetFrame(size: WidgetSize.medium) {
        SalmonRunWidgetLayout(entry: samples.salmonRun, family: .systemMedium)
      }
      HStack(spacing: 24) {
        WidgetFrame(size: WidgetSize.small) {
          BattleWidgetLayout(entry: samples.battle(.regular, .small), family: .systemSmall)
        }
        WidgetFrame(size: WidgetSize.small) {
          BattleWidgetLayout(entry: samples.battle(.x, .small), family: .systemSmall)
        }
      }
    }
  }
}

// MARK: - MenuBarShowcase

/// The desktop: widgets on the left, and the menu bar window open below the right end of the menu
/// bar, drawn by its own view.
private struct MenuBarShowcase: View {
  let samples: ShowcaseSamples

  var body: some View {
    HStack(alignment: .top) {
      DesktopWidgets(samples: samples)
      Spacer(minLength: 24)
      MenuBarWindow()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
    }
    .padding(40)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
#endif
#endif
