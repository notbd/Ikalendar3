#!/usr/bin/env bash
#
# Runs every check CI runs, in CI's order, and stops at the first failure:
#
#   1-2  SwiftFormat and SwiftLint, zero violations
#   3    every string catalog key in all 14 localizations (scripts/check-string-catalogs.sh)
#   4    package tests on macOS
#   5-7  unsigned Debug builds: iOS Simulator, macOS, watchOS Simulator
#   8-9  unsigned Release builds: iOS device (with the watch app), macOS
#   10   the iOS Simulator test run
#
# Any compiler or build warning fails the step that shows it. Step 10 also fails when a test
# bundle of the test plan is missing or ran no tests, or when a package test bundle ran fewer
# tests in the simulator than on macOS: xcodebuild can skip a package's tests and still succeed.
#
# Usage: scripts/verify.sh [--derived-data PATH] [--ios-simulator UDID] [--watch-simulator UDID]
#
# Each option falls back to an environment variable (VERIFY_DERIVED_DATA, VERIFY_IOS_SIMULATOR,
# VERIFY_WATCH_SIMULATOR), then to a default this checkout owns: build/DerivedData inside it, and
# an iPhone and an Apple Watch simulator created for it on first use and named after it
# (CONTRIBUTING.md lists them and how to delete them).

set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
readonly ROOT
cd "$ROOT"
# shellcheck source=scripts/versions.env
source scripts/versions.env

readonly PROJECT=Ikalendar3.xcodeproj
readonly TEST_PLAN=Ikalendar3.xctestplan
readonly PACKAGE=Ikalendar3Kit
# The app's test bundle. The test plan must list it beside every package test target.
readonly APP_TEST_TARGET=Ikalendar3Tests
readonly STEP_COUNT=10

# MARK: - Output

step_number=0
step_started=0
step_open=0

# Prints a step's title. `step_done` or `fail` ends the line.
step() {
  step_number=$((step_number + 1))
  step_started=$SECONDS
  step_open=1
  printf '[%d/%d] %-36s' "$step_number" "$STEP_COUNT" "$1"
}

step_done() {
  step_open=0
  printf 'ok %4ss%s\n' $((SECONDS - step_started)) "${1:+   $1}"
}

# Prints the reason (and the log to read) and exits non-zero.
fail() {
  if ((step_open)); then printf 'FAILED\n'; fi
  printf '\n%s\n' "$1" >&2
  if [[ -n ${2:-} ]]; then printf '\nLog: %s\n' "$2" >&2; fi
  printf '\nVERIFY FAILED\n' >&2
  exit 1
}

# Any other failing command is a broken tool or a bug in this script: just as loud. A failure inside
# a command substitution is reported once, by the command that used its output.
on_error() {
  if ((BASH_SUBSHELL == 0)); then fail "Unexpected failure at scripts/verify.sh:$1: $2"; fi
  exit 1
}
trap 'on_error $LINENO "$BASH_COMMAND"' ERR

# Removes colours and terminal hyperlinks, which `swift` writes even into files.
strip_colors() {
  perl -pe 's/\e\[[0-9;]*m//g; s/\e\]8;;.*?\e\\//g'
}

# Prints the lines of a log that explain a failure, or its tail when none match.
diagnostics() {
  local found
  found=$(strip_colors <"$1" \
    | grep -E -A 3 'error:|\*\* (BUILD|TEST) FAILED \*\*|The following build commands failed|recorded an issue|Expectation failed|Fatal error|Test .* failed' \
    | cut -c1-300 | head -n 80 || true)
  if [[ -n $found ]]; then printf '%s\n' "$found"; else tail -n 30 "$1"; fi
}

# Runs a command with its output in $VERIFY_DIR/<name>.log, and fails with the log's
# diagnostics when the command fails.
run_logged() {
  local log=$VERIFY_DIR/$1.log
  shift
  if ! "$@" >"$log" 2>&1; then
    fail "$(diagnostics "$log")" "$log"
  fi
}

# MARK: - Options

usage() {
  sed -n '3,/^$/s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"
}

derived_data=${VERIFY_DERIVED_DATA:-$ROOT/build/DerivedData}
ios_udid=${VERIFY_IOS_SIMULATOR:-}
watch_udid=${VERIFY_WATCH_SIMULATOR:-}

while (($# > 0)); do
  case $1 in
    --derived-data) derived_data=${2:?--derived-data needs a path}; shift 2 ;;
    --ios-simulator) ios_udid=${2:?--ios-simulator needs a UDID}; shift 2 ;;
    --watch-simulator) watch_udid=${2:?--watch-simulator needs a UDID}; shift 2 ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; exit 64 ;;
  esac
done

mkdir -p "$derived_data"
derived_data=$(cd "$derived_data" && pwd)
readonly derived_data
# Logs, reports and result bundles of this run; replaced by the next run.
readonly VERIFY_DIR=$derived_data/Verify
rm -rf "$VERIFY_DIR"
mkdir -p "$VERIFY_DIR"

# MARK: - Tools

swiftformat_version=$(swiftformat --version 2>/dev/null || echo none)
swiftlint_version=$(swiftlint version 2>/dev/null || echo none)
[[ $swiftformat_version == "$SWIFTFORMAT_VERSION" ]] \
  || fail "SwiftFormat $swiftformat_version found; scripts/versions.env pins $SWIFTFORMAT_VERSION (CONTRIBUTING.md)."
[[ $swiftlint_version == "$SWIFTLINT_VERSION" ]] \
  || fail "SwiftLint $swiftlint_version found; scripts/versions.env pins $SWIFTLINT_VERSION (CONTRIBUTING.md)."
xcode_version=$(xcodebuild -version | awk 'NR == 1 { print $2 } NR == 2 { print "(" $3 ")" }' | paste -sd ' ' -)

# MARK: - Simulators

# Simulators this checkout creates and owns are named "<OWNER> iPhone" and "<OWNER> Apple Watch".
OWNER="ikalendar3 $(basename "$ROOT") $(printf '%s' "$ROOT" | shasum | cut -c1-6)"
readonly OWNER

# Prints "<udid>|<name>|<OS version>|<device type>|<runtime>" of the first available simulator
# of the platform that matches, newest runtime first. `by` is udid, name or family (a name prefix,
# on a plain OS runtime). Prints nothing when none matches.
find_simulator() {
  xcrun simctl list devices available --json | jq -r --arg platform "$1" --arg by "$2" --arg value "$3" '
    ("com.apple.CoreSimulator.SimRuntime." + $platform + "-") as $prefix
    | [.devices | to_entries[] | select(.key | startswith($prefix))
      | (.key | ltrimstr($prefix)) as $suffix
      | ($suffix | capture("^(?<v>[0-9]+(-[0-9]+)*)").v | split("-") | map(tonumber)) as $version
      | .key as $runtime | ($suffix | test("^[0-9-]+$")) as $plain
      | .value[] | . + {version: $version, runtime: $runtime, plain: $plain}]
    | sort_by((.version | map(-.)), .name)
    | map(select(if $by == "udid" then .udid == $value elif $by == "name" then .name == $value
        else .plain and (.name | startswith($value)) end))
    | first // empty
    | [.udid, .name, (.version | map(tostring) | join(".")), .deviceTypeIdentifier, .runtime] | join("|")'
}

# Prints the simulator to use: the given UDID, else the one this checkout owns, created on first
# use like the first device of the family on the newest runtime. Never a shared device, because two
# runs on one simulator kill each other's test host.
resolve_simulator() {
  local platform=$1 family=$2 udid=$3 owned found template device_type runtime
  if [[ -n $udid ]]; then
    find_simulator "$platform" udid "$udid"
    return
  fi
  owned="$OWNER $family"
  found=$(find_simulator "$platform" name "$owned")
  if [[ -z $found ]]; then
    template=$(find_simulator "$platform" family "$family")
    [[ -n $template ]] || return 0
    IFS='|' read -r _ _ _ device_type runtime <<<"$template"
    xcrun simctl create "$owned" "$device_type" "$runtime" >/dev/null || return 0
    found=$(find_simulator "$platform" name "$owned")
  fi
  printf '%s\n' "$found"
}

ios_simulator=$(resolve_simulator iOS iPhone "$ios_udid") || true
[[ -n $ios_simulator ]] \
  || fail "No available iOS simulator${ios_udid:+ with UDID $ios_udid}. List them with: xcrun simctl list devices available"
watch_simulator=$(resolve_simulator watchOS "Apple Watch" "$watch_udid") || true
[[ -n $watch_simulator ]] \
  || fail "No available watchOS simulator${watch_udid:+ with UDID $watch_udid}. List them with: xcrun simctl list devices available"
ios_udid=${ios_simulator%%|*}
watch_udid=${watch_simulator%%|*}

# Boots the iPhone while the earlier steps run; step 10 waits for it. It stays booted afterwards,
# which makes the next run faster.
xcrun simctl bootstatus "$ios_udid" -b >"$VERIFY_DIR/boot-ios-simulator.log" 2>&1 &
boot_pid=$!

# MARK: - Checks

# Prints each package test target, sorted.
package_test_targets() {
  swift package --package-path "$PACKAGE" --scratch-path "$derived_data/SwiftPM" describe --type json \
    | jq -r '.targets[] | select(.type == "test") | .name' | sort
}

# Prints "<target> <executed tests>" per given test target, from the xUnit reports of `swift test`
# (Swift Testing writes its own next to XCTest's). Skipped tests do not count.
package_test_counts() {
  local target report count
  for target in "$@"; do
    count=0
    for report in "$VERIFY_DIR/package-tests.xml" "$VERIFY_DIR/package-tests-swift-testing.xml"; do
      [[ -f $report ]] || continue
      count=$((count + $(xmllint --xpath "count(//testcase[not(skipped)][@classname='$target' or starts-with(@classname, '$target.')])" "$report")))
    done
    printf '%s %d\n' "$target" "$count"
  done
}

# Prints "<test bundle> <executed tests>" for every test bundle in a test result bundle.
# Skipped tests do not count; a parameterized test counts once.
simulator_test_counts() {
  xcrun xcresulttool get test-results tests --path "$1" | jq -r '
    .testNodes[] | .. | objects | select(.nodeType == "Unit test bundle")
    | "\(.name) \([.. | objects | select(.nodeType == "Test Case" and .result != "Skipped")] | length)"'
}

# Prints each warning a result bundle's build recorded, one per line.
bundle_warnings() {
  xcrun xcresulttool get build-results --path "$1" \
    | jq -r '.warnings[]? | (.sourceURL // "" | sub("^file://"; "") | sub("#.*$"; "")) as $file
      | if $file == "" then .message else "\($file): \(.message)" end' | sort -u
}

# Runs xcodebuild with the shared options and a result bundle named after the step, and fails on
# any warning. A task that is up to date never shows its warning again, so Swift warnings are
# errors (a failed compile always runs again), and any other warning removes the build folder
# (the next run builds from scratch and shows it again until it is fixed).
xcodebuild_step() {
  local name=$1
  shift
  run_logged "$name" xcodebuild "$@" -project "$PROJECT" -derivedDataPath "$derived_data" \
    -resultBundlePath "$VERIFY_DIR/$name.xcresult" -hideShellScriptEnvironment \
    SWIFT_TREAT_WARNINGS_AS_ERRORS=YES COMPILER_INDEX_STORE_ENABLE=NO
  local warnings
  warnings=$(bundle_warnings "$VERIFY_DIR/$name.xcresult")
  if [[ -n $warnings ]]; then
    if [[ -d $derived_data/Build/Intermediates.noindex ]]; then rm -rf "$derived_data/Build"; fi
    fail "Build warnings (there must be none):"$'\n'"$warnings" "$VERIFY_DIR/$name.log"
  fi
}

# Fails unless every given path exists.
expect_paths() {
  local path
  for path in "$@"; do
    [[ -e $path ]] || fail "Missing from the build: $path"
  done
}

# Fails unless the app bundle $1 holds the resource framework exactly $2 times and no font file
# outside it: a second copy, such as one in a widget extension, would ship silently.
expect_resource_copies() {
  local copies strays
  copies=$(find "$1" -name IkaResources.framework | wc -l | tr -d ' ')
  [[ $copies == "$2" ]] || fail "The resource framework is in $1 $copies times, not $2."
  strays=$(find "$1" \( -name '*.otf' -o -name '*.ttf' \) -not -path '*/IkaResources.framework/*')
  [[ -z $strays ]] || fail "Font files outside the resource framework:"$'\n'"$strays"
}

# MARK: - Run

printf 'Xcode %s%s, SwiftFormat %s, SwiftLint %s\n' "$xcode_version" \
  "$([[ ${xcode_version%% *} == "$XCODE_VERSION" ]] || printf ' (CI uses %s)' "$XCODE_VERSION")" \
  "$swiftformat_version" "$swiftlint_version"
printf 'Derived data: %s\n' "$derived_data"
IFS='|' read -r _ name os _ <<<"$ios_simulator"
printf 'iOS simulator: %s, iOS %s (%s)\n' "$name" "$os" "$ios_udid"
IFS='|' read -r _ name os _ <<<"$watch_simulator"
printf 'watchOS simulator: %s, watchOS %s (%s)\n\n' "$name" "$os" "$watch_udid"

started=$SECONDS

step "SwiftFormat"
run_logged swiftformat swiftformat --lint .
step_done

step "SwiftLint"
run_logged swiftlint swiftlint lint --strict --quiet
step_done

step "String catalogs"
run_logged string-catalogs scripts/check-string-catalogs.sh
step_done "$(<"$VERIFY_DIR/string-catalogs.log")"

step "Package tests, macOS"
# The app's and every package test target must be in the test plan, or the simulator run never
# builds them.
test_plan_targets=$(jq -r '.testTargets[].target.name' "$TEST_PLAN" | sort)
package_targets=$(package_test_targets)
unplanned=$(comm -23 <(printf '%s\n' "$package_targets" "$APP_TEST_TARGET" | sort) <(printf '%s\n' "$test_plan_targets"))
[[ -z $unplanned ]] || fail "Test targets missing from $TEST_PLAN, so xcodebuild never runs them:"$'\n'"$unplanned"
run_logged package-tests swift test --package-path "$PACKAGE" --scratch-path "$derived_data/SwiftPM" \
  -Xswiftc -warnings-as-errors --xunit-output "$VERIFY_DIR/package-tests.xml"
# Swift warnings are errors already; anything else (a manifest warning) also clears the build.
warnings=$(strip_colors <"$VERIFY_DIR/package-tests.log" | grep -E '(^|: )warning: ' | sort -u || true)
if [[ -n $warnings ]]; then
  rm -rf "$derived_data/SwiftPM"
  fail "Package warnings (there must be none):"$'\n'"$warnings" "$VERIFY_DIR/package-tests.log"
fi
# shellcheck disable=SC2086 # one word per target
macos_counts=$(package_test_counts $package_targets)
silent=$(awk '$2 == 0 { print $1 }' <<<"$macos_counts")
[[ -z $silent ]] || fail "Package test targets that ran no tests on macOS:"$'\n'"$silent" "$VERIFY_DIR/package-tests.log"
step_done "$(awk '{ printf "%s%s %s", sep, $1, $2; sep = ", " }' <<<"$macos_counts")"

step "Build, iOS Simulator"
xcodebuild_step build-ios-simulator build -scheme Ikalendar3 -destination "id=$ios_udid" CODE_SIGNING_ALLOWED=NO
step_done

step "Build, macOS"
xcodebuild_step build-macos build -scheme Ikalendar3 -destination "platform=macOS,arch=$(uname -m)" \
  CODE_SIGNING_ALLOWED=NO
step_done

step "Build, watchOS Simulator"
xcodebuild_step build-watchos-simulator build -scheme Ikalendar3Watch -destination "id=$watch_udid" \
  CODE_SIGNING_ALLOWED=NO
step_done

step "Build, iOS device, Release"
xcodebuild_step build-ios-release build -scheme Ikalendar3 -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
ios_app=$derived_data/Build/Products/Release-iphoneos/Ikalendar3.app
expect_paths "$ios_app/PlugIns/Ikalendar3Widgets.appex" "$ios_app/Watch/Ikalendar3Watch.app" \
  "$ios_app/Watch/Ikalendar3Watch.app/PlugIns/Ikalendar3WatchWidgets.appex" \
  "$ios_app/Frameworks/IkaResources.framework" "$ios_app/Watch/Ikalendar3Watch.app/Frameworks/IkaResources.framework"
expect_resource_copies "$ios_app" 2
step_done "widget extension and watch app embedded, the resource framework once in each app"

step "Build, macOS, Release"
xcodebuild_step build-macos-release build -scheme Ikalendar3 -configuration Release \
  -destination "platform=macOS,arch=$(uname -m)" CODE_SIGNING_ALLOWED=NO
mac_app=$derived_data/Build/Products/Release/Ikalendar3.app
expect_paths "$mac_app/Contents/PlugIns/Ikalendar3Widgets.appex" "$mac_app/Contents/Frameworks/IkaResources.framework"
expect_resource_copies "$mac_app" 1
[[ -z $(find "$mac_app" -name 'Ikalendar3Watch*') ]] || fail "The macOS app embeds the watch app: $mac_app"
step_done "widget extension and resource framework embedded, no watch app"

step "Test, iOS Simulator"
wait "$boot_pid" || fail "The iOS simulator did not boot." "$VERIFY_DIR/boot-ios-simulator.log"
# Keeps automatic signing, which signs to run locally with no team: the App Group needs the
# entitlement, and an unsigned build has none.
xcodebuild_step test-ios-simulator test -scheme Ikalendar3 -destination "id=$ios_udid"
ios_counts=$(simulator_test_counts "$VERIFY_DIR/test-ios-simulator.xcresult")
problems=$(MACOS="$macos_counts" PLAN="$test_plan_targets" awk '
  BEGIN {
    n = split(ENVIRON["MACOS"], lines, "\n")
    for (i = 1; i <= n; i++) { split(lines[i], f, " "); minimum[f[1]] = f[2] }
    n = split(ENVIRON["PLAN"], lines, "\n")
    for (i = 1; i <= n; i++) planned[lines[i]] = 1
  }
  { ran[$1] = $2 }
  END {
    for (t in planned) {
      if (!(t in ran)) print t ": missing from the run"
      else if (ran[t] == 0) print t ": ran no tests"
      else if ((t in minimum) && ran[t] < minimum[t]) print t ": ran " ran[t] " tests, " minimum[t] " on macOS"
    }
  }' <<<"$ios_counts" | sort)
[[ -z $problems ]] || fail "Test bundles that did not run in full (xcodebuild still reported success):"$'\n'"$problems" \
  "$VERIFY_DIR/test-ios-simulator.log"
step_done "$(sort <<<"$ios_counts" | awk '{ printf "%s%s %s", sep, $1, $2; sep = ", " }')"

printf '\nVERIFY PASSED in %ss. Logs: %s\n' $((SECONDS - started)) "$VERIFY_DIR"
