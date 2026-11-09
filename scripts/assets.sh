#!/usr/bin/env bash
#
# Builds the bundled images and SplatNet 3's fonts from scripts/assets/manifest.json: downloads
# every source and checks its hash, then renders three pixel sizes of each image into IkaDesign's
# asset catalog and the Swift index of bundled ids (committed), and merges each font's web-font
# subsets into one file in build/Fonts (git-ignored). CI never runs this; a release build runs it
# first.
#
# The tools are pinned so a second run writes the same bytes: Python from scripts/versions.env,
# its packages with hashes from scripts/assets/requirements.txt, installed into a virtual
# environment in build/Assets/Tools that is rebuilt whenever the pins change.
#
# Usage: scripts/assets.sh [--only images|fonts] [--manifest PATH]

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
