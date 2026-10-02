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

And the in-app brand images under assets/brand/ (D137), each as Flutter
resolution variants (<name>.png, 2.0x/<name>.png, 3.0x/<name>.png):

  - mark.png, from mark-master.svg: the same rounded tile as Android legacy,
    at 56/112/168 px -- the create/join households screens' mark.
  - lockup_light.png, lockup_dark.png, from lockup-en-light/-dark.svg: the
    sign-in screen's lockup, background removed, cropped to its content
    left/right, at 48/96/144 px tall. Needs network access: its text is
    Literata, which is not installed here, and an SVG inside <img> cannot load
    web fonts -- so it is inlined into a page that links Google Fonts.
  - google_g.png, from docs/design/google/: the official Google "G", tile
    removed and cropped to the G, not recoloured, at 20/40/60 px. Inlined
    too: its gradient is a <foreignObject>, which <img> does not render.
"""

from __future__ import annotations

import json
import re
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
LOGO = ROOT / "docs/design/logo"
ANDROID_RES = ROOT / "android/app/src/main/res"
IOS_ASSETS = ROOT / "ios/Runner/Assets.xcassets"
BRAND = ROOT / "assets/brand"
GOOGLE_G = (ROOT / "docs/design/google/"
            "Theme=Neutral, Show text=No, Shape=Square, Platform=Android+Web.svg")
LITERATA = ("https://fonts.googleapis.com/css2"
            "?family=Literata:wght@600&display=block")
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


def rounded_tile(master: Image.Image) -> Image.Image:
    """[master] with its corners cut to radius 24/108 of the side."""
    # Draw the mask at the render size and scale it with the image, so the
    # rounded corners are antialiased the same way at every density.
    mask = Image.new("L", master.size, 0)
    radius = round(RENDER * 24 / 108)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, RENDER - 1, RENDER - 1), radius=radius, fill=255
    )
    tile = master.copy()
    tile.putalpha(mask)
    return tile


def render_inline(svg: str, name: str, width: int, height: int,
                  tmp: Path, font_css: str | None = None) -> Image.Image:
    """Rasterise SVG source [svg] at [width] x [height], inlined in a page.

    Unlike [render], the SVG is part of the page's DOM, so it can use a web
    font ([font_css], a stylesheet URL) and a <foreignObject>.
    """
    svg = re.sub(r"<\?xml[^>]*\?>\s*", "", svg)
    svg = re.sub(r'(<svg\b[^>]*?)\swidth="[^"]*"', rf'\1 width="{width}"', svg,
                 count=1)
    svg = re.sub(r'(<svg\b[^>]*?)\sheight="[^"]*"', rf'\1 height="{height}"',
                 svg, count=1)
    link = f'<link rel="stylesheet" href="{font_css}">' if font_css else ""
    wrapper = tmp / f"{name}.html"
    wrapper.write_text(
        f"<!doctype html>{link}<style>html,body{{margin:0}}"
        f"svg{{display:block}}</style>{svg}"
    )
    out = tmp / f"{name}.png"
    subprocess.run(
        [
            CHROME,
            "--headless=new",
            f"--screenshot={out}",
            f"--window-size={width},{height}",
            "--virtual-time-budget=8000",  # let the web font load
            "--default-background-color=00000000",  # transparent RGBA
            "--hide-scrollbars",
            wrapper.as_uri(),
        ],
        check=True,
        capture_output=True,
    )
    image = Image.open(out).convert("RGBA")
    if image.size != (width, height):
        raise SystemExit(f"{name}: Chrome rendered {image.size}, "
                         f"not {width}x{height}")
    return image


def brand(image: Image.Image, name: str, size: tuple[int, int]) -> None:
    """Write [image] at [size] (1x) and its 2.0x/3.0x variants to BRAND."""
    for folder, scale in [(BRAND, 1), (BRAND / "2.0x", 2), (BRAND / "3.0x", 3)]:
        folder.mkdir(parents=True, exist_ok=True)
        px = (size[0] * scale, size[1] * scale)
        out = folder / f"{name}.png"
        image.resize(px, Image.LANCZOS).save(out)
        print(f"wrote {out.relative_to(ROOT)} ({px[0]}x{px[1]}px)")


def brand_lockup(svg: Path, name: str, tmp: Path) -> None:
    source = svg.read_text()
    # Drop the opaque background, so the PNG is transparent.
    source = re.sub(r'<rect width="760" height="160" fill="[^"]*"/>', "",
                    source, count=1)
    image = render_inline(source, name, 3040, 640, tmp, font_css=LITERATA)
    # Crop left/right only: the SVG leaves ~200 units of air right of the
    # text, but the full height keeps the mark's top/bottom air.
    left, _, right, _ = image.getbbox()
    image = image.crop((left, 0, right, image.height))
    height = 48
    width = round(image.width * height / image.height)
    brand(image, name, (width, height))


def brand_google_g(tmp: Path) -> None:
    source = GOOGLE_G.read_text()
    # Drop the light tile behind the G, and crop the view to the G alone.
    source = re.sub(r'<path [^>]*fill="#F2F2F2"/>', "", source, count=1)
    source = source.replace('viewBox="0 0 40 40"', 'viewBox="10 10 20 20"', 1)
    image = render_inline(source, "google_g", RENDER, RENDER, tmp)
    brand(image, "google_g", (20, 20))


def android_legacy(master: Image.Image) -> None:
    tile = rounded_tile(master)
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
        master = render(LOGO / "mark-master.svg", tmp)
        android_legacy(master)
        ios_app_icon(render(LOGO / "ios-appicon-1024.svg", tmp))
        ios_launch_image(render(LOGO / "android-adaptive-foreground.svg", tmp))
        brand(rounded_tile(master), "mark", (56, 56))
        brand_lockup(LOGO / "lockup-en-light.svg", "lockup_light", tmp)
        brand_lockup(LOGO / "lockup-en-dark.svg", "lockup_dark", tmp)
        brand_google_g(tmp)


if __name__ == "__main__":
    main()
