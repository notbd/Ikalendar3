#!/usr/bin/env bash
#
# Builds the bundled images from scripts/assets/manifest.json: downloads every source, checks its
# hash, renders three pixel sizes and replaces the asset catalog in IkaDesign and the Swift index
# of bundled ids. The built images are committed; CI never runs this.
#
# The tools are pinned so a second run writes the same bytes: Python from scripts/versions.env,
# its packages with hashes from scripts/assets/requirements.txt, installed into a virtual
# environment in build/Assets/Tools that is rebuilt whenever the pins change.
#
# Usage: scripts/assets.sh [--manifest PATH]

set -Eeuo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
readonly ROOT
cd "$ROOT"
# shellcheck source=scripts/versions.env
source scripts/versions.env

readonly TOOLS=build/Assets/Tools
readonly REQUIREMENTS=scripts/assets/requirements.txt
readonly PINS="Python $ASSET_PYTHON_VERSION"$'\n'"$(cat "$REQUIREMENTS")"

if [[ ! -x $TOOLS/bin/python || $(cat "$TOOLS/pins" 2>/dev/null) != "$PINS" ]]; then
  python="python$ASSET_PYTHON_VERSION"
  command -v "$python" >/dev/null || {
    printf 'error: %s not found; scripts/versions.env pins Python %s\n' "$python" "$ASSET_PYTHON_VERSION" >&2
    exit 1
  }
  command rm -rf "$TOOLS"
  "$python" -m venv "$TOOLS"
  "$TOOLS/bin/python" -m pip install --quiet --disable-pip-version-check --require-hashes --only-binary=:all: \
    -r "$REQUIREMENTS"
  printf '%s' "$PINS" >"$TOOLS/pins"
fi

exec "$TOOLS/bin/python" -I scripts/assets/build.py "$@"
