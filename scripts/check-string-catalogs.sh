#!/usr/bin/env bash
#
# Fails when a string catalog has a key without a non-empty value in each of the 14 app
# localizations, the source language included. Keys marked "Don't Translate" are exempt. Also
# fails when an App Shortcuts phrase (a key of an `AppShortcuts.xcstrings`, or any of its values)
# does not name the app with `${applicationName}`: Siri matches only phrases that do. And fails
# when two phrases read the same in a language once each parameter is filled in with every value
# it can take: which of their shortcuts Siri runs is then left to the system.
#
# Usage: scripts/check-string-catalogs.sh [CATALOG ...]
#
# With no arguments it checks every catalog in the repository that git does not ignore.
# scripts/verify.sh runs it.

set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# The 14 app localizations, as `GameLanguage.localization` in IkaCore names them.
readonly LOCALIZATIONS='["en", "en-GB", "es", "es-419", "fr", "fr-CA", "de", "it", "nl", "ru", "ja", "ko", "zh-Hans", "zh-Hant"]'
# The intents the App Shortcuts run, and the catalog that names their parameters' values.
readonly INTENTS=Ikalendar3Kit/Sources/IkaIntents
readonly INTENTS_CATALOG=$INTENTS/Resources/Localizable.xcstrings

# The values each phrase parameter can take, read from the Swift sources the build reads, as
# {"<name>": ["<key>", ...]}: for each intent parameter `public var <name>: <Type>Parameter` in
# IkaIntents, the keys of its type's case titles (`DisplayRepresentation(title:
# LocalizedStringResource("<key>"` in `Parameters/<Type>Parameter.swift`) in its catalog.
parameter_values() {
  local name type
  git ls-files -z -- "$INTENTS/*.swift" \
    | xargs -0 perl -ne 'print "$1 $2\n" if /^\s*public var (\w+): (\w+Parameter)\b/' \
    | sort -u \
    | while read -r name type; do
      perl -ne 'print "$1\n" while /DisplayRepresentation\(title: LocalizedStringResource\("([^"]+)"/g' \
        "$INTENTS/Parameters/$type.swift" \
        | jq -R --arg name "$name" '{name: $name, key: .}'
    done \
    | jq -s 'group_by(.name) | map({key: .[0].name, value: (map(.key) | unique)}) | from_entries'
}

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

  # Each phrase in each language, with each parameter filled in with each of its values' names
  # in that language, compared as spoken: in lower case, without punctuation. One line per
  # parameter no intent has, then one per spoken phrase that two phrases share.
  values=$(parameter_values)
  duplicates=$(jq -n -r --argjson required "$LOCALIZATIONS" --argjson values "$values" \
    --slurpfile names "$INTENTS_CATALOG" '
    def name($key; $language): $names[0].strings[$key].localizations[$language].stringUnit.value // $key;
    def spoken: ascii_downcase | gsub("[[:punct:]]"; "") | gsub("\\s+"; " ");
    [inputs
      | input_filename as $file
      | .strings | to_entries[]
      | .key as $key | (.value.localizations // {}) as $localizations
      | $required[] as $language
      | ($localizations[$language].stringUnit.value // $key) as $phrase
      | ([$phrase | scan("\\$\\{(\\w+)\\}") | .[0] | select(. != "applicationName")] | unique) as $parameters
      | if any($parameters[]; $values[.] == null) then
          {problem: "\($file): \($key) names a parameter no intent has: \($parameters | join(", "))"}
        else
          reduce $parameters[] as $parameter ([$phrase];
            [.[] as $text | $values[$parameter][] as $value
              | $text | gsub("\\$\\{" + $parameter + "\\}"; name($value; $language))])
          | .[] | {language: $language, text: ., spoken: spoken, key: $key}
        end]
    | (map(select(.problem) | .problem) | unique[]),
      (map(select(.spoken)) | group_by([.language, .spoken])[]
        | select(map(.key) | unique | length > 1)
        | "\(.[0].language): \"\(.[0].text)\" from \(map(.key) | unique | map("\"\(.)\"") | join(" and "))")
  ' "${phrase_catalogs[@]}")
  if [[ -n $duplicates ]]; then
    printf 'App Shortcuts phrases with a parameter no intent has, or that read the same:\n%s\n' "$duplicates" >&2
    exit 1
  fi
fi

printf '%d catalogs complete, %d with App Shortcuts phrases\n' "${#catalogs[@]}" "${#phrase_catalogs[@]}"
