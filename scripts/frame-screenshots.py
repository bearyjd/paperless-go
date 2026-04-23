#!/usr/bin/env python3
"""Add device frames and captions to Play Store screenshots."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

SCREENSHOTS_DIR = Path(__file__).parent.parent / "metadata/en-US/images/phoneScreenshots"
OUTPUT_DIR = SCREENSHOTS_DIR / "framed"

CANVAS_W, CANVAS_H = 1080, 2400
SCREENSHOT_W, SCREENSHOT_H = 920, 1880
CORNER_RADIUS = 36
DEVICE_RADIUS = 44
BORDER_WIDTH = 3

BG_COLOR = (245, 243, 237)
DEVICE_BG = (255, 255, 255)
BORDER_COLOR = (180, 180, 180)
TEXT_COLOR = (40, 40, 40)
ACCENT_COLOR = (23, 162, 98)

CAPTIONS = {
    "1_document_list.png": "Browse & search your documents",
    "2_scan_upload.png": "Scan or upload in seconds",
    "3_ai_chat.png": "Ask AI about your documents",
    "4_login.png": "Connect to your server",
}


def round_corners(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, img.width, img.height], radius=radius, fill=255)
    result = img.copy()
    result.putalpha(mask)
    return result


def find_font(size: int) -> ImageFont.FreeTypeFont:
    candidates = [
        "/usr/share/fonts/google-noto-sans-fonts/NotoSans-Bold.ttf",
        "/usr/share/fonts/noto-sans/NotoSans-Bold.ttf",
        "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/dejavu-sans-fonts/DejaVuSans-Bold.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def frame_screenshot(src: Path, caption: str, dst: Path) -> None:
    screenshot = Image.open(src).convert("RGBA")
    screenshot = screenshot.resize((SCREENSHOT_W, SCREENSHOT_H), Image.LANCZOS)
    screenshot = round_corners(screenshot, CORNER_RADIUS)

    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), BG_COLOR)
    draw = ImageDraw.Draw(canvas)

    font = find_font(72)

    bbox = draw.textbbox((0, 0), caption, font=font)
    text_w = bbox[2] - bbox[0]
    text_x = (CANVAS_W - text_w) // 2
    text_y = 100

    draw.text((text_x, text_y), caption, fill=TEXT_COLOR, font=font)

    accent_y = text_y + (bbox[3] - bbox[1]) + 28
    accent_w = 80
    draw.rounded_rectangle(
        [(CANVAS_W - accent_w) // 2, accent_y,
         (CANVAS_W + accent_w) // 2, accent_y + 6],
        radius=3, fill=ACCENT_COLOR,
    )

    device_x = (CANVAS_W - SCREENSHOT_W) // 2 - 12
    device_y = accent_y + 44
    device_w = SCREENSHOT_W + 24
    device_h = SCREENSHOT_H + 24

    draw.rounded_rectangle(
        [device_x, device_y, device_x + device_w, device_y + device_h],
        radius=DEVICE_RADIUS, fill=DEVICE_BG, outline=BORDER_COLOR,
        width=BORDER_WIDTH,
    )

    shot_x = (CANVAS_W - SCREENSHOT_W) // 2
    shot_y = device_y + 12
    canvas.paste(screenshot, (shot_x, shot_y), screenshot)

    canvas = canvas.convert("RGB")
    canvas.save(dst, "PNG", optimize=True)
    print(f"  {dst.name} ({canvas.size[0]}x{canvas.size[1]})")


def main() -> None:
    OUTPUT_DIR.mkdir(exist_ok=True)
    print("Framing screenshots...")
    for filename, caption in CAPTIONS.items():
        src = SCREENSHOTS_DIR / filename
        if not src.exists():
            print(f"  SKIP {filename} (not found)")
            continue
        dst = OUTPUT_DIR / filename
        frame_screenshot(src, caption, dst)
    print(f"\nDone. Framed screenshots in {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
