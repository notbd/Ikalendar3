#!/usr/bin/env bash
#
# Fails when a string catalog has a key without a non-empty value in each of the 14 app
# localizations, the source language included. Keys marked "Don't Translate" are exempt.
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
printf '%d catalogs complete\n' "${#catalogs[@]}"
