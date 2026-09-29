"""Render the app's launcher icons and launch images from docs/design/logo/.

Re-run it (`make icons`) whenever docs/design/logo/ changes, and commit the
PNGs it writes. It is a one-off, not part of the build: the Android adaptive,
themed and launch-screen marks are hand-written VectorDrawables
(android/app/src/main/res/drawable/ic_launcher_*.xml) and have to be edited by
hand to match. See D130.

No package does this (CLAUDE.md rule 8): each SVG is rasterised at 1024 px by
headless Google Chrome, then PIL downsamples it to each size.

  - Android legacy (API 24-25) mipmap-*/ic_launcher.png, from mark-master.svg:
    a rounded square (corner radius 24/108 of the side), transparent corners.
  - iOS AppIcon.appiconset, from ios-appicon-1024.svg: every file its
    Contents.json lists, opaque RGB (the App Store rejects alpha), square.
  - iOS LaunchImage.imageset, from android-adaptive-foreground.svg: the mark
    alone, cropped to its content, transparent, at 96/192/288 px.
"""

import json
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
LOGO = ROOT / "docs/design/logo"
ANDROID_RES = ROOT / "android/app/src/main/res"
IOS_ASSETS = ROOT / "ios/Runner/Assets.xcassets"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
RENDER = 1024


def render(svg: Path, tmp: Path) -> Image.Image:
    """Rasterise [svg] to a RENDER x RENDER RGBA image via headless Chrome."""
    wrapper = tmp / f"{svg.stem}.html"
    wrapper.write_text(
        "<!doctype html><style>html,body{margin:0}</style>"
        f'<img src="{svg.as_uri()}" width="{RENDER}" height="{RENDER}">'
    )
    out = tmp / f"{svg.stem}.png"
    subprocess.run(
        [
            CHROME,
            "--headless",
            f"--screenshot={out}",
            f"--window-size={RENDER},{RENDER}",
            "--default-background-color=00000000",  # transparent RGBA
            "--hide-scrollbars",
            wrapper.as_uri(),
        ],
        check=True,
        capture_output=True,
    )
    image = Image.open(out).convert("RGBA")
    if image.size != (RENDER, RENDER):
        raise SystemExit(f"{svg.name}: Chrome rendered {image.size}, not {RENDER}px")
    return image


def android_legacy(master: Image.Image) -> None:
    # Draw the mask at the render size and scale it with the image, so the
    # rounded corners are antialiased the same way at every density.
    mask = Image.new("L", master.size, 0)
    radius = round(RENDER * 24 / 108)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, RENDER - 1, RENDER - 1), radius=radius, fill=255
    )
    tile = master.copy()
    tile.putalpha(mask)
    for density, px in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                        ("xxhdpi", 144), ("xxxhdpi", 192)]:
        out = ANDROID_RES / f"mipmap-{density}/ic_launcher.png"
        tile.resize((px, px), Image.LANCZOS).save(out)
        print(f"wrote {out.relative_to(ROOT)} ({px}px)")


def ios_app_icon(icon: Image.Image) -> None:
    opaque = icon.convert("RGB")
    folder = IOS_ASSETS / "AppIcon.appiconset"
    contents = json.loads((folder / "Contents.json").read_text())
    done = set()
    for entry in contents["images"]:
        name = entry["filename"]
        if name in done:
            continue
        done.add(name)
        points = float(entry["size"].split("x")[0])
        px = round(points * int(entry["scale"].rstrip("x")))
        out = folder / name
        opaque.resize((px, px), Image.LANCZOS).save(out)
        print(f"wrote {out.relative_to(ROOT)} ({px}px)")


def ios_launch_image(foreground: Image.Image) -> None:
    # Crop to the mark's content, centred in a square with no margin: the
    # storyboard centres the image, and the view's green is the ground.
    left, top, right, bottom = foreground.getbbox()
    side = max(right - left, bottom - top)
    cx, cy = (left + right) / 2, (top + bottom) / 2
    box = tuple(round(v) for v in
                (cx - side / 2, cy - side / 2, cx + side / 2, cy + side / 2))
    mark = foreground.crop(box)
    folder = IOS_ASSETS / "LaunchImage.imageset"
    for suffix, px in [("", 96), ("@2x", 192), ("@3x", 288)]:
        out = folder / f"LaunchImage{suffix}.png"
        mark.resize((px, px), Image.LANCZOS).save(out)
        print(f"wrote {out.relative_to(ROOT)} ({px}px)")


def main() -> None:
    with tempfile.TemporaryDirectory() as name:
        tmp = Path(name)
        android_legacy(render(LOGO / "mark-master.svg", tmp))
        ios_app_icon(render(LOGO / "ios-appicon-1024.svg", tmp))
        ios_launch_image(render(LOGO / "android-adaptive-foreground.svg", tmp))


if __name__ == "__main__":
    main()
