"""Builds ikalendar 3's bundled images and SplatNet 3's fonts from manifest.json.

Run it through scripts/assets.sh, which installs the pinned tools first. Steps, each finished
before the next starts, so a failure leaves every output as it was:

  1. Check the manifest: groups, sizes, sources, the id namespaces each group lists, no two ids
     giving one file name, and no two font files with one name.
  2. Download every source (cached by hash) and check it against the manifest's sha256.
  3. Render each image at its group's three sizes: SVGs drawn at the size, raster images scaled
     down to fit and never up.
  4. Unpack each font file's web-font subsets, merge them into one file whose PostScript name is
     the file's name, and check that every character keeps its source outline and advance.
  5. Replace the asset catalog and the Swift index of bundled ids, which are committed, and the
     font folder, which is git-ignored.

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
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

import resvg_py
from fontTools.merge import Merger
from fontTools.misc.psCharStrings import T2WidthExtractor
from fontTools.pens.recordingPen import DecomposingRecordingPen
from fontTools.ttLib import TTFont
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "scripts/assets/manifest.json"
CATALOG = ROOT / "Ikalendar3Kit/Sources/IkaDesign/Resources/Images.xcassets"
INDEX = ROOT / "Ikalendar3Kit/Sources/IkaDesign/Images/BundledImage+Index.swift"
# Git-ignored: the fonts are never committed. App packaging copies them from here.
FONTS = ROOT / "build/Fonts"
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
class Source:
    """One file to download or read, under the name the maintainer sees in messages."""

    label: str
    location: str  # an https URL or a local path
    sha256: str | None  # required before an https source is used; local files have none


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
    source: Source


@dataclass(frozen=True)
class FontFile:
    """One font file to build: SplatNet 3's subsets of one face, merged in order."""

    name: str  # the file name stem and PostScript name, as FontFace.name in IkaDesign
    note: str
    subsets: tuple[Source, ...]


@dataclass(frozen=True)
class Manifest:
    pictures: list[Picture]  # placeholders included
    fonts: list[FontFile]


# MARK: - Manifest


def load_manifest(path: Path) -> Manifest:
    """Reads and checks the manifest."""
    try:
        manifest = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise Failure(f"{path}: {error}")
    expect_keys(manifest, "manifest", {"bases", "groups", "fonts"})
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

    fonts = [load_font(font, bases, path.parent) for font in manifest["fonts"]]
    duplicates = sorted(name for name, count in Counter(font.name for font in fonts).items() if count > 1)
    if duplicates:
        raise Failure(f"Font files listed twice: {', '.join(duplicates)}")
    return Manifest(pictures, fonts)


def load_font(font: dict, bases: dict, folder: Path) -> FontFile:
    expect_keys(font, "font", {"name", "note", "subsets"})
    name = font["name"]
    where = f"font {name}"
    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9]+", name):
        raise Failure(f"{where}: names are letters and digits, the PostScript name of the file")
    if not font["subsets"]:
        raise Failure(f"{where}: lists no subsets")
    subsets = []
    for subset in font["subsets"]:
        expect_keys(subset, where, {"source"}, {"sha256"})
        sha256 = subset.get("sha256")
        if sha256 is not None and not re.fullmatch(r"[0-9a-f]{64}", sha256):
            raise Failure(f"{where}, {subset['source']}: sha256 is 64 lowercase hex digits")
        location = resolve(subset["source"], bases, folder, where)
        subsets.append(Source(location.rsplit("/", 1)[-1], location, sha256))
    return FontFile(name, font["note"], tuple(subsets))


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
                       Source(image_id or name, resolve(source, bases, folder, where), sha256))

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


def fetch_all(sources: list[Source]) -> dict[str, bytes]:
    """Every source's bytes by location. Stops before anything is written if a hash is off."""
    contents, problems = {}, []
    for source in sources:
        if source.location in contents:
            continue
        if source.location.startswith("https://"):
            data = download(source.location, source.sha256)
            actual = hashlib.sha256(data).hexdigest()
            if source.sha256 is None:
                problems.append(f"{source.label}: add \"sha256\": \"{actual}\"")
            elif actual != source.sha256:
                problems.append(f"{source.label}: sha256 is {actual}, the manifest says {source.sha256}")
        else:
            data = Path(source.location).read_bytes()
        contents[source.location] = data
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
    if picture.source.location.endswith(".svg"):
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


# MARK: - Fonts


def merge_font(font: FontFile, contents: dict[str, bytes]) -> TTFont:
    """The font file's subsets as one font whose PostScript name is `font.name`."""
    subsets = [unpack(contents[subset.location]) for subset in font.subsets]
    for subset in subsets:
        make_name_keyed(subset)
    if len(subsets) == 1:
        merged = subsets[0]
    else:
        merged = Merger().merge([sfnt(subset) for subset in subsets])
        # The merger stamps the current time; the subsets' own dates keep a second run's bytes equal.
        merged["head"].created = min(subset["head"].created for subset in subsets)
        merged["head"].modified = max(subset["head"].modified for subset in subsets)
    rename(merged, font.name)
    check_outlines(font, merged, contents)
    return merged


def unpack(web_font: bytes) -> TTFont:
    """A woff file as plain TrueType or OpenType: the same tables, uncompressed."""
    font = TTFont(io.BytesIO(web_font), recalcTimestamp=False)
    font.flavor = None
    return font


def sfnt(font: TTFont) -> io.BytesIO:
    data = io.BytesIO()
    font.save(data)
    data.seek(0)
    return data


def make_name_keyed(font: TTFont) -> None:
    """Turns a CID-keyed CFF font into a name-keyed one, the only kind fontTools merges (Fontworks'
    Rowdy subsets are CID-keyed). Every glyph moves to the private dict most glyphs use; that
    changes hint zones of the others (only .notdef in Rowdy), never an outline, and each moved
    glyph's width is restated against its new private dict."""
    if "CFF " not in font or not hasattr(font["CFF "].cff[0], "FDSelect"):
        return
    cff = font["CFF "].cff
    cff.desubroutinize()
    top = cff[0]
    font_dicts = list(top.FDSelect)
    kept = Counter(font_dicts).most_common(1)[0][0]
    private = top.FDArray[kept].Private
    for name, font_dict in zip(top.charset, font_dicts):
        charstring = top.CharStrings[name]
        if font_dict != kept:
            restate_width(charstring, private)
        charstring.private = private
    top.Private = private
    for key in ("ROS", "CIDFontVersion", "CIDFontRevision", "CIDFontType", "CIDCount", "UIDBase", "FDArray",
                "FDSelect"):
        top.rawDict.pop(key, None)
        if hasattr(top, key):
            delattr(top, key)
    for holder in (top.CharStrings, top.CharStrings.charStringsIndex):
        for key in ("fdSelect", "fdArray"):
            if hasattr(holder, key):
                delattr(holder, key)
    top.CharStrings.charStringsIndex.private = private


def restate_width(charstring, private) -> None:
    """Rewrites a desubroutinized charstring's width, stated against its own private dict, against
    `private` instead: the same advance in other numbers, as fontTools' merger does."""
    unset = object()
    extractor = T2WidthExtractor([], [], charstring.private.nominalWidthX, unset)
    extractor.execute(charstring)
    width = charstring.private.defaultWidthX if extractor.width is unset else extractor.width
    if extractor.width is not unset:
        charstring.program.pop(0)
    if width != private.defaultWidthX:
        charstring.program.insert(0, width - private.nominalWidthX)


def rename(font: TTFont, name: str) -> None:
    """Sets the PostScript name, which Core Text registers and finds a face by. The subsets of one
    region share their source font's name, so every face needs its own."""
    table = font["name"]
    table.removeNames(nameID=6)
    table.setName(name, 6, 3, 1, 0x409)
    table.setName(name, 6, 1, 0, 0)
    if "CFF " in font:
        font["CFF "].cff.fontNames = [name]


def check_outlines(font: FontFile, merged: TTFont, contents: dict[str, bytes]) -> None:
    """Stops unless `merged` maps exactly the characters of the subsets and draws each one with its
    subset's outline and advance (the first subset's, where two map one character). Hints may
    differ; outlines may not."""
    glyphs, cmap = merged.getGlyphSet(), merged.getBestCmap()
    checked, problems = set(), []
    for subset in font.subsets:
        source = unpack(contents[subset.location])
        source_glyphs = source.getGlyphSet()
        for code_point, name in source.getBestCmap().items():
            if code_point in checked:
                continue
            checked.add(code_point)
            if code_point not in cmap or drawing(source_glyphs, name) != drawing(glyphs, cmap[code_point]):
                problems.append(f"U+{code_point:04X} ({subset.label})")
    problems += [f"U+{code_point:04X} is in no subset" for code_point in sorted(cmap.keys() - checked)]
    if problems:
        raise Failure(f"{font.name}: merging changed {len(problems)} characters, such as " + ", ".join(problems[:5]))


def drawing(glyphs, name: str) -> tuple:
    """A glyph's advance and outline, components drawn in place, so renamed glyphs compare equal."""
    pen = DecomposingRecordingPen(glyphs)
    glyphs[name].draw(pen)
    return glyphs[name].width, pen.value


def write_fonts(fonts: list[FontFile], contents: dict[str, bytes], folder: Path) -> None:
    """Writes each font file as `<name>.otf` (CFF outlines) or `<name>.ttf` (TrueType outlines)."""
    folder.mkdir(parents=True)
    for font in fonts:
        merged = merge_font(font, contents)
        merged.recalcTimestamp = False
        extension = "otf" if merged.sfntVersion == "OTTO" else "ttf"
        merged.save(folder / f"{font.name}.{extension}")
        print(f"Built {font.name}.{extension} from {', '.join(subset.label for subset in font.subsets)}")


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
            (image_set / file).write_bytes(render(picture, contents[picture.source.location], picture.sizes[size]))
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


def build(path: Path, only: str | None) -> None:
    manifest = load_manifest(path)
    pictures = [] if only == "fonts" else manifest.pictures
    fonts = [] if only == "images" else manifest.fonts
    sources = [picture.source for picture in pictures] + [source for font in fonts for source in font.subsets]
    contents = fetch_all(sources)

    staging = WORK / "Staging"
    shutil.rmtree(staging, ignore_errors=True)
    if pictures:
        write_catalog(pictures, contents, staging / CATALOG.name)
        (staging / INDEX.name).write_text(index_source(pictures))
    if fonts:
        write_fonts(fonts, contents, staging / FONTS.name)

    if pictures:
        replace(staging / CATALOG.name, CATALOG)
        shutil.move(staging / INDEX.name, INDEX)
        print(f"Wrote {len(pictures) * len(SIZES)} images to {CATALOG.relative_to(ROOT)}")
    if fonts:
        replace(staging / FONTS.name, FONTS)
        print(f"Wrote {len(fonts)} fonts to {FONTS.relative_to(ROOT)}")


def replace(staged: Path, destination: Path) -> None:
    shutil.rmtree(destination, ignore_errors=True)
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(staged, destination)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--manifest", type=Path, default=MANIFEST, help="the manifest to build (default: %(default)s)")
    parser.add_argument("--only", choices=["images", "fonts"], help="build only the images or only the fonts")
    arguments = parser.parse_args()
    try:
        build(arguments.manifest, arguments.only)
    except Failure as failure:
        sys.exit(f"error: {failure}")


if __name__ == "__main__":
    main()
