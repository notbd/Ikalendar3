#!/usr/bin/env bash
#
# Fails when a string catalog has a key without a non-empty value in each of the 14 app
# localizations, the source language included. Keys marked "Don't Translate" are exempt. Also
# fails when an App Shortcuts phrase (a key of an `AppShortcuts.xcstrings`, or any of its values)
# does not name the app with `${applicationName}`: Siri matches only phrases that do.
#
# Usage: scripts/check-string-catalogs.sh [CATALOG ...]
#
# With no arguments it checks every catalog in the repository that git does not ignore.
# scripts/verify.sh runs it.

set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# The 14 app localizations, as `GameLanguage.localization` in IkaCore names them.
readonly LOCALIZATIONS='["en", "en-GB", "es", "es-419", "fr", "fr-CA", "de", "it", "nl", "ru", "ja", "ko", "zh-Hans", "zh-Hant"]'

catalogs=("$@")
if ((${#catalogs[@]} == 0)); then
  while IFS= read -r -d '' catalog; do
    catalogs+=("$catalog")
  done < <(git ls-files -z --cached --others --exclude-standard -- '*.xcstrings')
fi
if ((${#catalogs[@]} == 0)); then
  printf 'No string catalogs\n'
  exit 0
fi

# One line per incomplete key: "<catalog>: <key> lacks <localizations>". A localization counts
# when it has a value: a string, or a value for every plural or device variation.
problems=$(jq -r --argjson required "$LOCALIZATIONS" '
  input_filename as $file
  | .strings | to_entries[] | select(.value.shouldTranslate != false)
  | .key as $key | (.value.localizations // {}) as $localizations
  | [$required[] | select(
      [$localizations[.] | .. | .stringUnit? | select(. != null) | .value // ""]
      | length == 0 or any(. == ""))]
  | select(length > 0)
  | "\($file): \($key) lacks \(join(", "))"' "${catalogs[@]}")

if [[ -n $problems ]]; then
  printf 'String catalog keys without all 14 localizations:\n%s\n' "$problems" >&2
  exit 1
fi

phrase_catalogs=()
for catalog in "${catalogs[@]}"; do
  [[ $(basename "$catalog") == AppShortcuts.xcstrings ]] && phrase_catalogs+=("$catalog")
done
if ((${#phrase_catalogs[@]} > 0)); then
  # One line per phrase that does not name the app, in its key or in any localization.
  phrases=$(jq -r '
    input_filename as $file
    | .strings | to_entries[]
    | .key as $key
    | [$key, (.value.localizations // {} | .. | .stringUnit? | select(. != null) | .value // "")]
    | map(select(contains("${applicationName}") | not))
    | select(length > 0)
    | "\($file): \($key): \(join(" | "))"' "${phrase_catalogs[@]}")
  if [[ -n $phrases ]]; then
    printf 'App Shortcuts phrases without ${applicationName}:\n%s\n' "$phrases" >&2
    exit 1
  fi
fi

printf '%d catalogs complete, %d with App Shortcuts phrases\n' "${#catalogs[@]}" "${#phrase_catalogs[@]}"
