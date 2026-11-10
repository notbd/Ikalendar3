#!/usr/bin/env bash
#
# Captures the raw App Store screenshots from fixed data: 16 per language (iPhone 6, iPad 4, Mac 3,
# Apple Watch 3) in each of the 14 languages, at App Store sizes, into a git-ignored folder. Frames
# and captions are a later step; nothing is uploaded.
#
# How each Surface is captured:
# - App screens: a Debug fixture launch (CONTRIBUTING.md) on a simulator, captured with
#   `simctl io screenshot`; on the Mac, the app's own window, sized by `--window-size` and captured
#   by its window id. No clicks or keys: every screen is opened by launch options and preferences
#   passed as launch arguments.
# - Widgets, the Live Activity, the menu bar window and the complications: the app's Debug
#   showcase (`--showcase`), which draws them with their own views from the same fixture,
#   captured the same way. A script can neither place a widget nor show the Lock Screen or a watch
#   face editor. These launches are rebased, so the system's countdowns run on the fixture day.
# - Every launch writes times as they read in Tokyo at the fixture's instant
#   (`--fixture-time-zone`), so every language and every run shows the same times.
#
# Before it captures anything, it launches the app once on each device and stops unless the font
# log of SplatNet 3's faces says every face registered (build them with
# `scripts/assets.sh --only fonts`). It checks each image's pixel size against the App Store size
# it targets.
#
# It creates its own simulators of App Store sizes and deletes them when it ends; each one passed
# by UDID is used instead and kept. The Mac app keeps its data in the output folder and a defaults
# suite of its own, both removed at the end.
#
# Usage: scripts/screenshots.sh [--languages "en ja ..."] [--output PATH] [--derived-data PATH]
#                               [--iphone UDID] [--ipad UDID] [--watch UDID] [--skip-build]

set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
readonly ROOT
cd "$ROOT"

readonly ALL_LANGUAGES="en en-GB es es-419 fr fr-CA de it nl ru ja ko zh-Hans zh-Hant"
readonly BUNDLE_ID=io.tianwei.ikalendar3
readonly WATCH_BUNDLE_ID=io.tianwei.ikalendar3.watchkitapp
readonly FIXTURES="$ROOT/Ikalendar3Kit/Fixtures"
readonly TIME_ZONE=Asia/Tokyo

# The fixed data: a normal day, the 2026-08-23 Splatfest in its second half, and the 2026-09-07
# Big Run day while its Challenge runs. Each instant sits inside a Rotation, at least half an hour
# from its ends, so a rebased launch stays in it (FixtureLaunch.prepare).
readonly NORMAL_DAY="normalDay 2026-10-21T03:10:00Z"
readonly SPLATFEST="splatfestEnd 2026-08-23T21:10:00Z"
readonly BIG_RUN_DAY="bigRun 2026-09-08T02:50:00Z"

# App Store sizes in pixels: iPhone 6.9-inch, iPad 13-inch, Mac, Apple Watch Series 46mm.
readonly IPHONE_SIZE=1320x2868
readonly IPAD_PORTRAIT=2064x2752
readonly IPAD_LANDSCAPE=2752x2064
readonly MAC_SIZE=2880x1800
readonly WATCH_SIZE=416x496
readonly MAC_WINDOW=1440x900

readonly IPHONE_TYPE="iPhone 18 Pro Max"
readonly IPAD_TYPE="iPad Pro 13-inch (M5)"
readonly WATCH_TYPE="Apple Watch Series 12 (46mm)"

languages=$ALL_LANGUAGES
output="$ROOT/build/Screenshots/AppStore"
derived_data="$ROOT/build/Dev"
iphone=""
ipad=""
watch=""
skip_build=false

usage() {
  sed -n '/^# Usage:/,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while (($#)); do
  case $1 in
    --languages) languages=$2; shift 2 ;;
    --output) output=$2; shift 2 ;;
    --derived-data) derived_data=$2; shift 2 ;;
    --iphone) iphone=$2; shift 2 ;;
    --ipad) ipad=$2; shift 2 ;;
    --watch) watch=$2; shift 2 ;;
    --skip-build) skip_build=true; shift ;;
    -h | --help) usage; exit 0 ;;
    *) printf 'error: unknown option %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

for language in $languages; do
  [[ " $ALL_LANGUAGES " == *" $language "* ]] || fail "unknown language $language; the 14 are: $ALL_LANGUAGES"
done

# MARK: Cleanup

created_simulators=()
mac_pid=""
readonly MAC_SUITE="ikalendar3-screenshots-$(basename "$ROOT")"
readonly MAC_DATA="$output/.mac-data"

cleanup() {
  [[ -z $mac_pid ]] || kill "$mac_pid" 2>/dev/null || true
  for udid in "${created_simulators[@]+"${created_simulators[@]}"}"; do
    xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
    xcrun simctl delete "$udid" >/dev/null 2>&1 || true
  done
  command rm -rf "$MAC_DATA"
  defaults delete "$MAC_SUITE" >/dev/null 2>&1 || true
}
trap cleanup EXIT

# MARK: Languages

# The locale each text set's screenshots run in, which sets the date formats and the hour cycle.
locale_of() {
  case $1 in
    en) echo en_US ;;
    en-GB) echo en_GB ;;
    es) echo es_ES ;;
    es-419) echo es_MX ;;
    fr) echo fr_FR ;;
    fr-CA) echo fr_CA ;;
    de) echo de_DE ;;
    it) echo it_IT ;;
    nl) echo nl_NL ;;
    ru) echo ru_RU ;;
    ja) echo ja_JP ;;
    ko) echo ko_KR ;;
    zh-Hans) echo zh_CN ;;
    zh-Hant) echo zh_TW ;;
  esac
}

# Sets `base` to the arguments every launch in a language takes: the language and locale, and the
# preferences (the argument domain wins over every defaults suite): Ink in dark appearance, past
# the welcome screen.
set_language() {
  base=(-AppleLanguages "($1)" -AppleLocale "$(locale_of "$1")"
    -pref.style ink -pref.color_scheme dark -state.should_show_onboarding '<false/>')
}

# Sets `fixture` to the fixture options of a day, "<fixture> <instant>".
set_day() {
  fixture=(--fixture "${1% *}" --fixture-folder "$FIXTURES" --fixture-instant "${1#* }"
    --fixture-time-zone "$TIME_ZONE")
}

# MARK: Checks

# Fails unless the image is `size` pixels ("<width>x<height>").
check_size() {
  local file=$1 size=$2 width height
  width=$(sips -g pixelWidth "$file" | awk '/pixelWidth/ { print $2 }')
  height=$(sips -g pixelHeight "$file" | awk '/pixelHeight/ { print $2 }')
  [[ "${width}x$height" == "$size" ]] || fail "$file is ${width}x$height pixels, not the App Store size $size"
  printf '%s\n' "${file#"$ROOT/"}"
}

# Fails unless the font log (`log show` output on stdin) says every face registered: the line
# `BundledResources.load(from:)` writes, "Registered <n> of <m> font faces".
check_fonts() {
  local device=$1 line
  line=$(grep -o 'Registered [0-9]* of [0-9]* font faces' | tail -1) || true
  [[ -n $line ]] || fail "$device: no font face registered (scripts/assets.sh --only fonts builds them); nothing captured"
  read -r _ registered _ expected _ <<<"$line"
  ((registered == expected)) ||
    fail "$device: $line; scripts/assets.sh --only fonts builds the missing ones; nothing captured"
  printf '%s: %s\n' "$device" "$line"
}

# MARK: Build

if [[ $skip_build == false ]]; then
  printf 'Building the iOS and watchOS apps and the Mac app (Debug) into %s\n' "$derived_data"
  mkdir -p "$output"
  # Simulator builds keep the default signing, which gives the app its App Group container.
  xcodebuild build -project Ikalendar3.xcodeproj -scheme Ikalendar3 -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$derived_data" -quiet >"$output/build-ios.log" 2>&1 ||
    fail "the iOS build failed; see $output/build-ios.log"
  xcodebuild build -project Ikalendar3.xcodeproj -scheme Ikalendar3 -destination "platform=macOS,arch=$(uname -m)" \
    -derivedDataPath "$derived_data" -quiet CODE_SIGNING_ALLOWED=NO >"$output/build-macos.log" 2>&1 ||
    fail "the macOS build failed; see $output/build-macos.log"
fi

readonly IOS_APP="$derived_data/Build/Products/Debug-iphonesimulator/Ikalendar3.app"
readonly WATCH_APP="$derived_data/Build/Products/Debug-watchsimulator/Ikalendar3Watch.app"
readonly MAC_APP="$derived_data/Build/Products/Debug/Ikalendar3.app"
for app in "$IOS_APP" "$WATCH_APP" "$MAC_APP"; do
  [[ -d $app ]] || fail "$app is missing; run without --skip-build"
done

# MARK: Simulators

# Unless the variable named `name` holds a UDID, creates a simulator of `type` into it, which
# cleanup deletes.
create_simulator() {
  local name=$1 type=$2 udid
  [[ -z ${!name} ]] || return 0
  udid=$(xcrun simctl create "ikalendar3 screenshots $type" "$type")
  created_simulators+=("$udid")
  printf -v "$name" '%s' "$udid"
}

create_simulator iphone "$IPHONE_TYPE"
create_simulator ipad "$IPAD_TYPE"
create_simulator watch "$WATCH_TYPE"

for udid in "$iphone" "$ipad" "$watch"; do
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
done
# The iPad shows apps full screen, not as windows; SpringBoard reads it at boot.
if [[ $(xcrun simctl spawn "$ipad" defaults read com.apple.springboard SBMedusaMultitaskingEnabled 2>/dev/null) != 0 ]]
then
  xcrun simctl spawn "$ipad" defaults write com.apple.springboard SBMedusaMultitaskingEnabled -bool false
  xcrun simctl shutdown "$ipad"
  xcrun simctl boot "$ipad"
  xcrun simctl bootstatus "$ipad" -b >/dev/null
fi
# The watch has no light appearance to leave.
for udid in "$iphone" "$ipad"; do
  xcrun simctl ui "$udid" appearance dark
  xcrun simctl status_bar "$udid" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
  xcrun simctl install "$udid" "$IOS_APP"
done
xcrun simctl install "$watch" "$WATCH_APP"

# MARK: Launches

# Launches the app on simulator `udid` with `bundle` and the arguments that follow, starting over.
launch() {
  local udid=$1 bundle=$2
  shift 2
  xcrun simctl launch --terminate-running-process "$udid" "$bundle" "$@" >/dev/null
}

# Launches the Mac app with the arguments that follow, its window `MAC_WINDOW` points, and waits
# for that window. Sets `mac_pid` and `mac_window`.
launch_mac() {
  [[ -z $mac_pid ]] || { kill "$mac_pid" 2>/dev/null || true; sleep 1; }
  mkdir -p "$MAC_DATA"
  open -n -g "$MAC_APP" --args "$@" --data-folder "$MAC_DATA" --defaults-suite "$MAC_SUITE" \
    --window-size "$MAC_WINDOW" -ApplePersistenceIgnoreState YES
  mac_pid=""
  mac_window=""
  for _ in $(seq 40); do
    sleep 0.5
    mac_pid=${mac_pid:-$(pgrep -n -f "$MAC_APP/Contents/MacOS/Ikalendar3" || true)}
    [[ -n $mac_pid ]] && mac_window=$(mac_window_of "$mac_pid")
    [[ -n $mac_window ]] && return
  done
  fail "the Mac app opened no window"
}

# The id of the largest normal window of process `pid`, from the window server's list.
mac_window_of() {
  osascript -l JavaScript - "$1" <<'EOF'
ObjC.import('CoreGraphics')
function run(argv) {
  const list = ObjC.deepUnwrap(ObjC.castRefToObject(
    $.CGWindowListCopyWindowInfo($.kCGWindowListOptionOnScreenOnly, $.kCGNullWindowID))) || []
  const windows = list
    .filter(w => w.kCGWindowOwnerPID == Number(argv[0]) && w.kCGWindowLayer == 0)
    .sort((a, b) => b.kCGWindowBounds.Width * b.kCGWindowBounds.Height - a.kCGWindowBounds.Width * a.kCGWindowBounds.Height)
  return windows.length ? String(windows[0].kCGWindowNumber) : ''
}
EOF
}

# Waits for a launch to draw and its opening animation to end, then saves simulator `udid`'s
# screen to `file`.
capture() {
  local udid=$1 file=$2
  sleep 8
  xcrun simctl io "$udid" screenshot "$file" >/dev/null 2>&1
}

# MARK: Fonts

printf 'Checking the font faces on each device\n'
set_language en
set_day "$NORMAL_DAY"
launch "$iphone" "$BUNDLE_ID" "${base[@]}" "${fixture[@]}"
launch "$ipad" "$BUNDLE_ID" "${base[@]}" "${fixture[@]}"
launch "$watch" "$WATCH_BUNDLE_ID" "${base[@]}" "${fixture[@]}"
launch_mac "${base[@]}" "${fixture[@]}"
sleep 3
for device in "iPhone $iphone $BUNDLE_ID" "iPad $ipad $BUNDLE_ID" "watch $watch $WATCH_BUNDLE_ID"; do
  read -r name udid bundle <<<"$device"
  xcrun simctl spawn "$udid" log show --last 2m --style compact 2>/dev/null \
    --predicate "subsystem == \"$bundle\" AND category == \"fonts\"" | check_fonts "$name"
done
log show --last 2m --style compact \
  --predicate "subsystem == \"$BUNDLE_ID\" AND category == \"fonts\" AND processID == $mac_pid" | check_fonts Mac

# MARK: Capture

for language in $languages; do
  folder="$output/$language"
  command rm -rf "$folder"
  mkdir -p "$folder"
  printf 'Capturing %s\n' "$language"
  set_language "$language"

  # iPhone: a Battle Mode's list, Salmon Run, a running Splatfest, a Challenge on the Big Run day,
  # the widgets, the Live Activity.
  shot() {
    local file="$folder/$1.png" place=$2 day=$3
    set_day "$day"
    launch "$iphone" "$BUNDLE_ID" "${base[@]}" -pref.default_mode "$place" "${fixture[@]}" "${@:4}"
    capture "$iphone" "$file"
    check_size "$file" "$IPHONE_SIZE"
  }
  shot 01-iphone-battle anarchy "$NORMAL_DAY"
  shot 02-iphone-salmon-run salmon_run "$NORMAL_DAY"
  shot 03-iphone-splatfest regular_battle "$SPLATFEST"
  shot 04-iphone-challenge challenge "$BIG_RUN_DAY"
  shot 05-iphone-widgets regular_battle "$NORMAL_DAY" --fixture-rebase --showcase widgets
  shot 06-iphone-live-activity regular_battle "$NORMAL_DAY" --fixture-rebase --showcase live-activity

  # iPad: columns in landscape, the sidebar with a detail in portrait, a running Splatfest, the
  # Home Screen widgets.
  pad_shot() {
    local file="$folder/$1.png" place=$2 day=$3
    set_day "$day"
    launch "$ipad" "$BUNDLE_ID" "${base[@]}" -pref.default_mode "$place" "${fixture[@]}" "${@:4}"
    capture "$ipad" "$file"
    # The landscape layout is drawn turned a quarter clockwise (`--landscape`); turn it back.
    if [[ " ${*:4} " == *" --landscape "* ]]; then
      sips --rotate 270 "$file" >/dev/null
      check_size "$file" "$IPAD_LANDSCAPE"
    else
      check_size "$file" "$IPAD_PORTRAIT"
    fi
  }
  pad_shot 07-ipad-columns regular_battle "$NORMAL_DAY" --landscape
  pad_shot 08-ipad-sidebar salmon_run "$NORMAL_DAY"
  pad_shot 09-ipad-splatfest regular_battle "$SPLATFEST"
  pad_shot 10-ipad-widgets regular_battle "$NORMAL_DAY" --fixture-rebase --showcase widgets

  # Mac: Columns, Overview, the menu bar window with desktop widgets.
  mac_shot() {
    local file="$folder/$1.png" day=$2
    set_day "$day"
    launch_mac "${base[@]}" "${fixture[@]}" "${@:3}"
    sleep 4
    screencapture -l "$mac_window" -o -x "$file"
    check_size "$file" "$MAC_SIZE"
  }
  mac_shot 11-mac-columns "$NORMAL_DAY" -pref.mac_layout columns
  mac_shot 12-mac-overview "$BIG_RUN_DAY" -pref.mac_layout overview
  mac_shot 13-mac-menu-bar "$NORMAL_DAY" --fixture-rebase --showcase menu-bar

  # Apple Watch: the Now page, a Mode page, the complications.
  watch_shot() {
    local file="$folder/$1.png"
    set_day "$NORMAL_DAY"
    launch "$watch" "$WATCH_BUNDLE_ID" "${base[@]}" "${fixture[@]}" "${@:2}"
    capture "$watch" "$file"
    check_size "$file" "$WATCH_SIZE"
  }
  watch_shot 14-watch-now
  watch_shot 15-watch-mode-page --mode-page salmonRun
  watch_shot 16-watch-complications --fixture-rebase --showcase complications
done

printf 'Saved 16 screenshots for each of: %s\nin %s\n' "$languages" "$output"
