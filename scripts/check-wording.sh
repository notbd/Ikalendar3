#!/usr/bin/env bash
#
# Fails when a tracked file names how changes are reviewed or written: the review process, or a
# writing tool or model. Code, tests and docs say what the app does and why; the planning files
# keep the rest. The pattern is narrow names and words, case-sensitive, so ordinary English and
# the game's locale files never match it.
#
# Usage: scripts/check-wording.sh
#
# scripts/verify.sh runs it.

set -Eeuo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

readonly PATTERN="\\b(?:[Cc]ouncil|Claude|Anthropic|OpenAI|ChatGPT|Copilot|Gemini|Codex|LLMs?|AI|Opus|Fable|Sol's)\\b"

status=0
matches=$(git grep -I -n -P "$PATTERN" -- . ':!scripts/check-wording.sh') || status=$?
case $status in
  0)
    printf 'Tracked files name how changes are reviewed or written:\n%s\n' "$matches" >&2
    exit 1
    ;;
  1) printf 'No review or writing tool named\n' ;;
  *) exit "$status" ;;
esac
