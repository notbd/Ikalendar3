#!/usr/bin/env bash
#
# Fails when a tracked file names how changes are reviewed or written: the review process, or a
# writing tool or model. Code, tests and docs say what the app does and why; the planning files
# keep the rest. The pattern is narrow names and words, case-sensitive, so ordinary English and
# the game's locale files never match it. It is stored in base64 so that this file names none of
# them either and needs no exemption from its own search; `base64 --decode` shows it.
#
# Usage: scripts/check-wording.sh
#
# scripts/verify.sh runs it.

set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

PATTERN=$(base64 --decode <<<"XGIoPzpbQ2Ndb3VuY2lsfENsYXVkZXxBbnRocm9waWN8T3BlbkFJfENoYXRHUFR8Q29waWxvdHxHZW1pbml8Q29kZXh8TExNcz98QUl8T3B1c3xGYWJsZXxTb2wncylcYg==")
readonly PATTERN

status=0
matches=$(git grep -I -n -P "$PATTERN") || status=$?
case $status in
  0)
    printf 'Tracked files name how changes are reviewed or written:\n%s\n' "$matches" >&2
    exit 1
    ;;
  1) printf 'No review or writing tool named\n' ;;
  *) exit "$status" ;;
esac
