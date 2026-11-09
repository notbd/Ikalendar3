"""Builds ikalendar 3's bundled images from manifest.json.

Run it through scripts/assets.sh, which installs the pinned tools first. Steps, each finished
before the next starts, so a failure leaves every committed file as it was:

  1. Check the manifest: groups, sizes, sources, the id namespaces each group lists, and no two
     ids giving one file name.
  2. Download every source (cached by hash) and check it against the manifest's sha256.
  3. Render each image at its group's three sizes: SVGs drawn at the size, raster images scaled
     down to fit and never up.
  4. Replace the asset catalog and the Swift index of bundled ids.

A second run with the same manifest writes the same bytes.
"""

import argparse
import base64
import binascii
import hashlib
import io
import json
import re
import shutil
import sys
import urllib.request
from dataclasses import dataclass
from pathlib import Path

import resvg_py
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "scripts/assets/manifest.json"
CATALOG = ROOT / "Ikalendar3Kit/Sources/IkaDesign/Resources/Images.xcassets"
INDEX = ROOT / "Ikalendar3Kit/Sources/IkaDesign/Images/BundledImage+Index.swift"
WORK = ROOT / "build/Assets"

SIZES = ("small", "medium", "large")
FORMATS = {"png": "png", "jpeg": "jpg"}
JPEG_QUALITY = 85
# JPEG drops alpha. Some of Nintendo's opaque Stage art has scattered pixels at about 90% alpha,
# which dropping keeps as drawn; anything more transparent is refused.
JPEG_MIN_ALPHA = 224
USER_AGENT = "ikalendar3-assets"
CONTENTS_INFO = {"author": "xcode", "version": 1}


class Failure(Exception):
    """Stops the run with a message for the maintainer."""


@dataclass(frozen=True)
class Picture:
    """One image to render at its group's three sizes."""

    group: str
    folder: str
    format: str
    sizes: dict[str, tuple[int, int]]
    id: str | None  # None for the group's placeholder
    name: str
    note: str
    source: str
    sha256: str | None


# MARK: - Manifest


def load_manifest(path: Path) -> list[Picture]:
    """Reads and checks the manifest; returns every picture, placeholders included."""
    try:
        manifest = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise Failure(f"{path}: {error}")
    expect_keys(manifest, "manifest", {"bases", "groups"})
    bases = manifest["bases"]
    pictures = []
    for group in manifest["groups"]:
        pictures += load_group(group, bases, path.parent)

    # Xcode turns each asset name into a Swift symbol without its hyphens and underscores, so names
    # that differ only there collide as well.
    owners: dict[str, str] = {}
    collisions = []
    for picture in pictures:
        owner = f"{picture.id or 'placeholder'} ({picture.group})"
        symbol = picture.name.replace("-", "")
        if symbol in owners:
            collisions.append(f"{picture.name}: {owners[symbol]} and {owner}")
        owners[symbol] = owner
    if collisions:
        raise Failure("Two ids give one file name:\n  " + "\n  ".join(collisions))
    return pictures


def load_group(group: dict, bases: dict, folder: Path) -> list[Picture]:
    expect_keys(group, "group", {"key", "folder", "format", "sizes", "placeholder", "images"}, {"namespaces"})
    key = group["key"]
    where = f"group {key}"
    if not re.fullmatch(r"[a-z]+(-[a-z]+)*", key):
        raise Failure(f"{where}: keys are lowercase words joined by hyphens")
    if group["format"] not in FORMATS:
        raise Failure(f"{where}: format must be one of {', '.join(FORMATS)}")
    if list(group["sizes"]) != list(SIZES):
        raise Failure(f"{where}: sizes must be {', '.join(SIZES)}, in that order")
    sizes = {size: tuple(box) for size, box in group["sizes"].items()}
    boxes = list(sizes.values())
    if any(len(box) != 2 or not all(isinstance(side, int) and side > 0 for side in box) for box in boxes) or any(
        small[0] > large[0] or small[1] > large[1] for small, large in zip(boxes, boxes[1:])
    ):
        raise Failure(f"{where}: each size is [width, height] in pixels, growing from small to large")

    def picture(image_id: str | None, name: str, note: str, source: str, sha256: str | None) -> Picture:
        return Picture(key, group["folder"], group["format"], sizes, image_id, name, note,
                       resolve(source, bases, folder, where), sha256)

    pictures = [picture(None, f"placeholder-{key}", "Placeholder", group["placeholder"], None)]
    namespaces = group.get("namespaces")
    for image in group["images"]:
        expect_keys(image, where, {"id", "note", "source"}, {"sha256"})
        image_id = image["id"]
        name = feed_name(image_id, namespaces, where) if namespaces else plain_name(image_id, key, where)
        sha256 = image.get("sha256")
        if sha256 is not None and not re.fullmatch(r"[0-9a-f]{64}", sha256):
            raise Failure(f"{where}, {image_id}: sha256 is 64 lowercase hex digits")
        pictures.append(picture(image_id, name, image["note"], image["source"], sha256))
    return pictures


def feed_name(image_id: str, namespaces: list[str], where: str) -> str:
    """A Nintendo base64 image_id (`VsStage-1`), decoded first because base64 is case-sensitive, then
    lowercased: `vsstage-1`. A negative number's sign becomes a word (`CoopStage--1` gives
    `coopstage-minus1`), so it stays apart from the positive number in Xcode's asset symbols."""
    try:
        decoded = base64.b64decode(image_id, validate=True).decode("ascii")
    except (binascii.Error, UnicodeDecodeError):
        raise Failure(f"{where}, {image_id}: not a base64 feed image_id")
    namespace, _, number = decoded.partition("-")
    if namespace not in namespaces:
        raise Failure(f"{where}, {image_id}: namespace {namespace!r} ({decoded}) is not listed in {namespaces}")
    if not re.fullmatch(r"[A-Za-z]+", namespace) or not re.fullmatch(r"-?\d+", number):
        raise Failure(f"{where}, {image_id}: {decoded} is not <namespace>-<number>")
    return f"{namespace.lower()}-{number.replace('-', 'minus')}"


def plain_name(image_id: str, key: str, where: str) -> str:
    """An image_id already lowercase and plain (weapon hashes, Mode icons), prefixed with its group."""
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", image_id):
        raise Failure(f"{where}, {image_id}: ids of a group without namespaces are lowercase words and digits")
    return f"{key}-{image_id}"


def resolve(source: str, bases: dict, folder: Path, where: str) -> str:
    """`https://…`, `<base>:<path>` under a manifest base, or `file:<path>` next to the manifest."""
    if source.startswith("https://"):
        return source
    prefix, _, path = source.partition(":")
    if prefix == "file" and path:
        return str(folder / path)
    if prefix in bases and path:
        return bases[prefix] + path
    raise Failure(f"{where}: source {source!r} is not https://, file: or one of {sorted(bases)}")


def expect_keys(value: dict, where: str, required: set[str], optional: set[str] = frozenset()) -> None:
    if not isinstance(value, dict):
        raise Failure(f"{where}: expected an object")
    missing, unknown = required - value.keys(), value.keys() - required - optional
    if missing or unknown:
        raise Failure(f"{where}: missing {sorted(missing)}, unknown {sorted(unknown)}")


# MARK: - Sources


def fetch_all(pictures: list[Picture]) -> dict[str, bytes]:
    """Every source's bytes by source. Stops before anything is written if a hash is off."""
    contents, problems = {}, []
    for picture in pictures:
        if picture.source in contents:
            continue
        if picture.source.startswith("https://"):
            data = download(picture.source, picture.sha256)
            actual = hashlib.sha256(data).hexdigest()
            if picture.sha256 is None:
                problems.append(f"{picture.id}: add \"sha256\": \"{actual}\"")
            elif actual != picture.sha256:
                problems.append(f"{picture.id}: sha256 is {actual}, the manifest says {picture.sha256}")
        else:
            data = Path(picture.source).read_bytes()
        contents[picture.source] = data
    if problems:
        raise Failure("Downloads that do not match the manifest:\n  " + "\n  ".join(problems))
    return contents


def download(url: str, sha256: str | None) -> bytes:
    cached = WORK / "Downloads" / sha256 if sha256 else None
    if cached and cached.exists() and hashlib.sha256(cached.read_bytes()).hexdigest() == sha256:
        return cached.read_bytes()
    print(f"Downloading {url}")
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            data = response.read()
    except OSError as error:
        raise Failure(f"{url}: {error}")
    if cached and hashlib.sha256(data).hexdigest() == sha256:
        cached.parent.mkdir(parents=True, exist_ok=True)
        cached.write_bytes(data)
    return data


# MARK: - Rendering


def render(picture: Picture, data: bytes, box: tuple[int, int]) -> bytes:
    """The picture fitted into `box`, encoded in its group's format."""
    if picture.source.endswith(".svg"):
        image = render_svg(data, box)
    else:
        image = scale_down(Image.open(io.BytesIO(data)), box)
    output = io.BytesIO()
    if picture.format == "jpeg":
        if image.mode == "RGBA" and image.getextrema()[3][0] < JPEG_MIN_ALPHA:
            raise Failure(f"{picture.name}: has transparency, which JPEG drops; use a png group")
        image.convert("RGB").save(output, "JPEG", quality=JPEG_QUALITY, subsampling=0, optimize=True)
    else:
        image.convert("RGBA").save(output, "PNG", optimize=True)
    return output.getvalue()


def render_svg(data: bytes, box: tuple[int, int]) -> Image.Image:
    """Draws an SVG at the largest size that fits `box`: vectors scale up without loss."""
    svg = data.decode("utf-8")
    natural = Image.open(io.BytesIO(bytes(resvg_py.svg_to_bytes(svg_string=svg, skip_system_fonts=True))))
    width, height = fit(natural.size, box, allow_upscale=True)
    drawn = resvg_py.svg_to_bytes(svg_string=svg, width=width, height=height, skip_system_fonts=True)
    return Image.open(io.BytesIO(bytes(drawn)))


def scale_down(image: Image.Image, box: tuple[int, int]) -> Image.Image:
    """Scales a raster image down to fit `box`. Smaller images keep their pixels: scaling up
    adds bytes, not detail. Alpha is premultiplied while scaling, so edges keep their colour."""
    size = fit(image.size, box, allow_upscale=False)
    if image.mode != "RGB":
        image = image.convert("RGBA")
    if size == image.size:
        return image
    if image.mode == "RGBA":
        return image.convert("RGBa").resize(size, Image.Resampling.LANCZOS).convert("RGBA")
    return image.resize(size, Image.Resampling.LANCZOS)


def fit(size: tuple[int, int], box: tuple[int, int], allow_upscale: bool) -> tuple[int, int]:
    scale = min(box[0] / size[0], box[1] / size[1])
    if not allow_upscale:
        scale = min(scale, 1)
    return max(1, round(size[0] * scale)), max(1, round(size[1] * scale))


# MARK: - Output


def write_catalog(pictures: list[Picture], contents: dict[str, bytes], catalog: Path) -> None:
    write_json(catalog / "Contents.json", {"info": CONTENTS_INFO})
    for picture in pictures:
        folder = catalog / picture.folder
        write_json(folder / "Contents.json", {"info": CONTENTS_INFO})
        for size in SIZES:
            name = f"{picture.name}_{size}"
            file = f"{name}.{FORMATS[picture.format]}"
            image_set = folder / f"{name}.imageset"
            image_set.mkdir()
            (image_set / file).write_bytes(render(picture, contents[picture.source], picture.sizes[size]))
            write_json(image_set / "Contents.json",
                       {"images": [{"filename": file, "idiom": "universal"}], "info": CONTENTS_INFO})


def write_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")


def index_source(pictures: list[Picture]) -> str:
    """The Swift index of bundled ids, formatted as SwiftFormat leaves it."""
    lines = [
        "//",
        "//  BundledImage+Index.swift",
        "//  Ikalendar3",
        "//",
        "//  Copyright (c) TIANWEI ZHANG. All rights reserved.",
        "//",
        "",
        "// Written by scripts/assets.sh from scripts/assets/manifest.json. Do not edit.",
        "",
        "extension BundledImage {",
        "  /// Each bundled image's base name by manifest id, per group.",
        "  static let baseNames: [Group: [String: String]] = [",
    ]
    groups = dict.fromkeys(picture.group for picture in pictures)
    for group in groups:
        member = re.sub(r"-([a-z])", lambda match: match[1].upper(), group)
        lines.append(f"    .{member}: [")
        for picture in (p for p in pictures if p.group == group and p.id):
            lines.append(f'      "{picture.id}": "{picture.name}", // {picture.note}')
        lines.append("    ],")
    lines += ["  ]", "}", ""]
    return "\n".join(lines)


def build(manifest: Path) -> None:
    pictures = load_manifest(manifest)
    contents = fetch_all(pictures)

    staging = WORK / "Staging"
    shutil.rmtree(staging, ignore_errors=True)
    write_catalog(pictures, contents, staging / CATALOG.name)
    (staging / INDEX.name).write_text(index_source(pictures))

    shutil.rmtree(CATALOG, ignore_errors=True)
    CATALOG.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(staging / CATALOG.name, CATALOG)
    shutil.move(staging / INDEX.name, INDEX)
    print(f"Wrote {len(pictures) * len(SIZES)} images to {CATALOG.relative_to(ROOT)}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--manifest", type=Path, default=MANIFEST, help="the manifest to build (default: %(default)s)")
    try:
        build(parser.parse_args().manifest)
    except Failure as failure:
        sys.exit(f"error: {failure}")


if __name__ == "__main__":
    main()
