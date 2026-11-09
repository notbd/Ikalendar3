#!/usr/bin/env bash
#
# The release fonts check: fails unless every product that draws text ships or loads every
# SplatNet 3 face. A Release build without the fonts passes every other check and falls back to
# the system font, so a release runs this before archiving. It needs network; CI and the verify
# script never run it and stay font-free.
#
#   1  builds the fonts with the asset script (scripts/assets.sh --only fonts)
#   2  removes the build folder, so no file of an earlier build counts, then builds the unsigned
#      Release products: iOS device (with the watch app) and macOS
#   3  the app and the watch app: their resource framework holds a file for each face in
#      scripts/assets/manifest.json, named as `FontRegistry` looks it up
#   4  each widget extension: it links the resource framework, and one of its run paths resolves
#      to its host app's copy, which step 3 checked
#
# Usage: scripts/check-release-fonts.sh [--derived-data PATH] [--skip-font-build]
#
# --derived-data defaults to build/ReleaseCheck in this checkout; its Build folder is removed on
# each run. --skip-font-build checks the fonts already in IkaResources/Fonts, as when a run shows
# that a missing face fails the check.

set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
readonly ROOT
cd "$ROOT"

readonly PROJECT=Ikalendar3.xcodeproj
readonly FRAMEWORK=IkaResources.framework

derived_data=$ROOT/build/ReleaseCheck
build_fonts=1
while (($# > 0)); do
  case $1 in
    --derived-data) derived_data=${2:?--derived-data needs a path}; shift 2 ;;
    --skip-font-build) build_fonts=0; shift ;;
    -h | --help) sed -n '3,/^$/s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) sed -n '3,/^$/s/^# \{0,1\}//p' "${BASH_SOURCE[0]}" >&2; exit 64 ;;
  esac
done
mkdir -p "$derived_data"
derived_data=$(cd "$derived_data" && pwd)
readonly derived_data
readonly LOGS=$derived_data/ReleaseCheck
mkdir -p "$LOGS"

problems=()

# Runs a command with its output in $LOGS/<name>.log and stops with the log's tail if it fails.
run_logged() {
  local log=$LOGS/$1.log
  shift
  if ! "$@" >"$log" 2>&1; then
    tail -n 30 "$log" >&2
    printf '\nFailed: %s\nLog: %s\n' "$*" "$log" >&2
    exit 1
  fi
}

# Records each face in `faces` with no `<name>.otf` or `<name>.ttf` in the resources of the
# framework at $2, for the product $1.
expect_faces() {
  local product=$1 resources=$2 face missing=()
  [[ -d $resources/Versions/A/Resources ]] && resources=$resources/Versions/A/Resources
  for face in "${faces[@]}"; do
    [[ -f $resources/$face.otf || -f $resources/$face.ttf ]] || missing+=("$face")
  done
  if ((${#missing[@]} > 0)); then
    problems+=("$product lacks ${missing[*]} in ${resources#"$derived_data"/}")
  else
    printf '  %-28s %d of %d faces in its %s\n' "$product" "${#faces[@]}" "${#faces[@]}" "$FRAMEWORK"
  fi
}

# Records a problem unless the extension binary $2 links the resource framework and one of its run
# paths resolves to the host's copy at $3.
expect_host_copy() {
  local product=$1 binary=$2 host_copy rpath resolved found=""
  host_copy=$(cd "$3" && pwd -P)
  if ! otool -L "$binary" | grep -q "@rpath/$FRAMEWORK/"; then
    problems+=("$product does not link $FRAMEWORK")
    return
  fi
  while IFS= read -r rpath; do
    resolved=${rpath/#@executable_path/$(dirname "$binary")}
    resolved=${resolved/#@loader_path/$(dirname "$binary")}
    if [[ -d $resolved/$FRAMEWORK && $(cd "$resolved/$FRAMEWORK" && pwd -P) == "$host_copy" ]]; then
      found=$rpath
      break
    fi
  done < <(otool -l "$binary" | awk '$1 == "cmd" { rpath = ($2 == "LC_RPATH") } rpath && $1 == "path" { print $2 }')
  if [[ -z $found ]]; then
    problems+=("$product: no run path resolves to its host's $FRAMEWORK")
  else
    printf '  %-28s loads the host'\''s copy through %s\n' "$product" "$found"
  fi
}

if ((build_fonts)); then
  printf 'Building the fonts\n'
  run_logged fonts scripts/assets.sh --only fonts
fi
faces=()
while IFS= read -r face; do faces+=("$face"); done < <(jq -r '.fonts[].name' scripts/assets/manifest.json)

printf 'Building the Release products in %s\n' "$derived_data"
command rm -rf "$derived_data/Build"
for platform in iOS macOS; do
  destination='generic/platform=iOS'
  [[ $platform == macOS ]] && destination="platform=macOS,arch=$(uname -m)"
  run_logged "build-$platform" xcodebuild build -project "$PROJECT" -scheme Ikalendar3 -configuration Release \
    -destination "$destination" -derivedDataPath "$derived_data" CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO
done

ios=$derived_data/Build/Products/Release-iphoneos/Ikalendar3.app
watch=$ios/Watch/Ikalendar3Watch.app
mac=$derived_data/Build/Products/Release/Ikalendar3.app

printf 'Checking %d faces: %s\n' "${#faces[@]}" "${faces[*]}"
expect_faces 'iOS app' "$ios/Frameworks/$FRAMEWORK"
expect_host_copy 'iOS widget extension' "$ios/PlugIns/Ikalendar3Widgets.appex/Ikalendar3Widgets" \
  "$ios/Frameworks/$FRAMEWORK"
expect_faces 'watch app' "$watch/Frameworks/$FRAMEWORK"
expect_host_copy 'watch widget extension' "$watch/PlugIns/Ikalendar3WatchWidgets.appex/Ikalendar3WatchWidgets" \
  "$watch/Frameworks/$FRAMEWORK"
expect_faces 'macOS app' "$mac/Contents/Frameworks/$FRAMEWORK"
expect_host_copy 'macOS widget extension' \
  "$mac/Contents/PlugIns/Ikalendar3Widgets.appex/Contents/MacOS/Ikalendar3Widgets" "$mac/Contents/Frameworks/$FRAMEWORK"

if ((${#problems[@]} > 0)); then
  printf '\nRELEASE FONTS CHECK FAILED\n' >&2
  printf '  %s\n' "${problems[@]}" >&2
  exit 1
fi
printf '\nRELEASE FONTS CHECK PASSED\n'
