#!/usr/bin/env python3
"""Generate assessment illustration assets for GrowERP."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

REPO_ROOT = Path(__file__).resolve().parents[1]
REFERENCE_IMAGE = REPO_ROOT / "flutter/packages/growerp_core/lib/images/check-in-out.png"
OUTPUT_DIR = REPO_ROOT / "flutter/packages/growerp_core/lib/images"
COLOR_IMAGE = OUTPUT_DIR / "assessment-color.png"
GREY_IMAGE = OUTPUT_DIR / "assessment-grey.png"


def create_color_image(size: tuple[int, int]) -> Image.Image:
    width, height = size
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))

    draw = ImageDraw.Draw(canvas)

    # Shadow for the central card
    card_bounds = (
        int(width * 0.12),
        int(height * 0.18),
        int(width * 0.88),
        int(height * 0.84),
    )
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        card_bounds,
        radius=int(width * 0.08),
        fill=(0, 0, 0, 90),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=width * 0.035))
    canvas.alpha_composite(shadow)

    # Card body
    draw.rounded_rectangle(
        card_bounds,
        radius=int(width * 0.08),
        fill=(255, 255, 255, 255),
    )

    # Header strip
    header_height = int(height * 0.18)
    header_bounds = (
        card_bounds[0],
        card_bounds[1],
        card_bounds[2],
        card_bounds[1] + header_height,
    )
    draw.rounded_rectangle(
        header_bounds,
        radius=int(width * 0.08),
        fill=(82, 116, 255, 255),
    )

    # Clip header bottom corners to align with card
    draw.rectangle(
        (
            card_bounds[0],
            card_bounds[1] + header_height - int(width * 0.08),
            card_bounds[2],
            card_bounds[1] + header_height,
        ),
        fill=(82, 116, 255, 255),
    )

    # Circular avatar placeholder
    avatar_radius = int(width * 0.11)
    avatar_centre = (
        card_bounds[0] + avatar_radius + int(width * 0.06),
        card_bounds[1] + avatar_radius + int(width * 0.04),
    )
    draw.ellipse(
        (
            avatar_centre[0] - avatar_radius,
            avatar_centre[1] - avatar_radius,
            avatar_centre[0] + avatar_radius,
            avatar_centre[1] + avatar_radius,
        ),
        fill=(255, 255, 255, 255),
    )
    draw.ellipse(
        (
            avatar_centre[0] - int(avatar_radius * 0.6),
            avatar_centre[1] - int(avatar_radius * 0.6),
            avatar_centre[0] + int(avatar_radius * 0.6),
            avatar_centre[1] + int(avatar_radius * 0.6),
        ),
        fill=(82, 116, 255, 255),
    )

    # Assessment title bar
    text_start_x = avatar_centre[0] + avatar_radius + int(width * 0.04)
    text_line_height = int(height * 0.035)
    primary_bar_width = int(width * 0.42)
    draw.rounded_rectangle(
        (
            text_start_x,
            card_bounds[1] + int(height * 0.05),
            text_start_x + primary_bar_width,
            card_bounds[1] + int(height * 0.05) + text_line_height,
        ),
        radius=int(text_line_height / 2),
        fill=(255, 255, 255, 230),
    )

    draw.rounded_rectangle(
        (
            text_start_x,
            card_bounds[1] + int(height * 0.1),
            text_start_x + int(primary_bar_width * 0.7),
            card_bounds[1] + int(height * 0.1) + text_line_height,
        ),
        radius=int(text_line_height / 2),
        fill=(236, 243, 255, 220),
    )

    # Question checklist rows
    row_top = header_bounds[3] + int(height * 0.04)
    row_height = int(height * 0.09)
    row_spacing = int(height * 0.03)
    check_box_size = int(width * 0.12)

    for index in range(3):
        top = row_top + index * (row_height + row_spacing)
        bottom = top + row_height

        # Row background
        draw.rounded_rectangle(
            (
                card_bounds[0] + int(width * 0.05),
                top,
                card_bounds[2] - int(width * 0.05),
                bottom,
            ),
            radius=int(row_height / 2.5),
            fill=(243, 247, 255, 255),
        )

        # Checkbox outline
        check_left = card_bounds[0] + int(width * 0.08)
        check_top = top + int((row_height - check_box_size) / 2)
        check_bounds = (
            check_left,
            check_top,
            check_left + check_box_size,
            check_top + check_box_size,
        )
        draw.rounded_rectangle(
            check_bounds,
            radius=int(check_box_size * 0.25),
            fill=(255, 255, 255, 255),
            outline=(82, 116, 255, 255),
            width=max(2, int(width * 0.015)),
        )

        # Checkmark
        mark = Image.new("RGBA", size, (0, 0, 0, 0))
        mark_draw = ImageDraw.Draw(mark)
        start = (
            check_bounds[0] + int(check_box_size * 0.25),
            check_bounds[1] + int(check_box_size * 0.55),
        )
        mid = (
            check_bounds[0] + int(check_box_size * 0.45),
            check_bounds[1] + int(check_box_size * 0.75),
        )
        end = (
            check_bounds[0] + int(check_box_size * 0.78),
            check_bounds[1] + int(check_box_size * 0.28),
        )
        mark_draw.line([start, mid, end], fill=(56, 182, 84, 255), width=max(4, int(width * 0.02)))
        mark = mark.filter(ImageFilter.GaussianBlur(radius=1.2))
        canvas.alpha_composite(mark)

        # Text bars
        text_left = check_bounds[2] + int(width * 0.05)
        draw.rounded_rectangle(
            (
                text_left,
                check_bounds[1],
                text_left + int(width * 0.42),
                check_bounds[1] + int(height * 0.025),
            ),
            radius=int(height * 0.012),
            fill=(82, 116, 255, 180),
        )

        draw.rounded_rectangle(
            (
                text_left,
                check_bounds[1] + int(height * 0.035),
                text_left + int(width * 0.3),
                check_bounds[1] + int(height * 0.06),
            ),
            radius=int(height * 0.012),
            fill=(190, 214, 255, 200),
        )

    return canvas


def create_greyscale_variant(source: Image.Image) -> Image.Image:
    greyscale = source.convert("L")
    alpha = source.getchannel("A")
    grey_rgba = Image.merge("RGBA", (greyscale, greyscale, greyscale, alpha))

    # Subtle tint for better legibility
    tint = Image.new("RGBA", source.size, (225, 228, 235, 0))
    grey_rgba = Image.blend(grey_rgba, tint, alpha=0.25)
    return grey_rgba


def main() -> None:
    if not REFERENCE_IMAGE.exists():
        raise FileNotFoundError(f"Reference image not found at {REFERENCE_IMAGE}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    with Image.open(REFERENCE_IMAGE) as reference:
        size = reference.size

    color_image = create_color_image(size)
    grey_image = create_greyscale_variant(color_image)

    color_image.save(COLOR_IMAGE)
    grey_image.save(GREY_IMAGE)

    print(f"Created {COLOR_IMAGE.relative_to(REPO_ROOT)} ({color_image.size[0]}x{color_image.size[1]})")
    print(f"Created {GREY_IMAGE.relative_to(REPO_ROOT)} ({grey_image.size[0]}x{grey_image.size[1]})")


if __name__ == "__main__":
    main()
