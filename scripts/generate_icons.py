import os
from PIL import Image, ImageDraw

MASTER_PATH = r"C:\Users\Tushal\.gemini\antigravity-ide\brain\2384ca93-f2bc-4b56-87d9-3a65c5f69b37\.user_uploaded\media_1791376872444.jpg"
ASSETS_DIR = r"c:\Users\Tushal\Desktop\Dateora\assets"

def make_gradient(width, height, color1=(53, 102, 255), color2=(126, 84, 255)):
    base = Image.new("RGBA", (width, height), color1 + (255,))
    top = Image.new("RGBA", (width, height), color2 + (255,))
    mask = Image.new("L", (width, height))
    mask_data = []
    for y in range(height):
        for x in range(width):
            val = int(255 * ((x / width) * 0.45 + (y / height) * 0.55))
            mask_data.append(min(255, max(0, val)))
    mask.putdata(mask_data)
    return Image.composite(top, base, mask)

def main():
    master = Image.open(MASTER_PATH).convert("RGBA")
    w, h = master.size

    # The squircle bounding box in master image: (156, 152, 868, 864)
    squircle_box = (156, 152, 868, 864)
    squircle_cropped = master.crop(squircle_box)

    # 1. assets/icon.png (1024x1024)
    icon_1024 = squircle_cropped.resize((1024, 1024), Image.Resampling.LANCZOS)
    icon_1024.save(os.path.join(ASSETS_DIR, "icon.png"), "PNG")
    print("Saved assets/icon.png (1024x1024)")

    # 2. Extract foreground glyph with clean transparency
    fg_canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fg_mono = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    master_pixels = master.load()
    fg_pixels = fg_canvas.load()
    fg_mono_pixels = fg_mono.load()

    for y in range(150, 870):
        for x in range(150, 870):
            r, g, b, a = master_pixels[x, y]
            # White check & ring
            if r > 210 and g > 210 and b > 210:
                strength = min(255, int(((r + g + b) / 3 - 170) * 3.0))
                fg_pixels[x, y] = (255, 255, 255, max(0, strength))
                fg_mono_pixels[x, y] = (255, 255, 255, max(0, strength))

    # Add the coral dot cleanly using antialiased circle drawing
    draw_fg = ImageDraw.Draw(fg_canvas)
    draw_mono = ImageDraw.Draw(fg_mono)
    dot_cx, dot_cy, dot_r = 721, 292, 63
    draw_fg.ellipse([dot_cx - dot_r, dot_cy - dot_r, dot_cx + dot_r, dot_cy + dot_r], fill=(255, 88, 88, 255))
    draw_mono.ellipse([dot_cx - dot_r, dot_cy - dot_r, dot_cx + dot_r, dot_cy + dot_r], fill=(255, 255, 255, 255))

    glyph_box = (250, 220, 800, 760)
    glyph_cropped = fg_canvas.crop(glyph_box)
    glyph_mono_cropped = fg_mono.crop(glyph_box)

    # 3. Android adaptive icon foreground (512x512 with safe zone ~66%)
    adaptive_fg = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    glyph_resized = glyph_cropped.resize((310, 305), Image.Resampling.LANCZOS)
    offset_x = (512 - 310) // 2
    offset_y = (512 - 305) // 2
    adaptive_fg.paste(glyph_resized, (offset_x, offset_y), glyph_resized)
    adaptive_fg.save(os.path.join(ASSETS_DIR, "android-icon-foreground.png"), "PNG")
    print("Saved assets/android-icon-foreground.png (512x512)")

    # 4. Android adaptive icon background (512x512 gradient)
    adaptive_bg = make_gradient(512, 512)
    adaptive_bg.save(os.path.join(ASSETS_DIR, "android-icon-background.png"), "PNG")
    print("Saved assets/android-icon-background.png (512x512)")

    # 5. Android monochrome icon (512x512)
    adaptive_mono = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    glyph_mono_resized = glyph_mono_cropped.resize((310, 305), Image.Resampling.LANCZOS)
    adaptive_mono.paste(glyph_mono_resized, (offset_x, offset_y), glyph_mono_resized)
    adaptive_mono.save(os.path.join(ASSETS_DIR, "android-icon-monochrome.png"), "PNG")
    print("Saved assets/android-icon-monochrome.png (512x512)")

    # 6. Splash icon (512x512 clean white background with squircle mark)
    splash = Image.new("RGBA", (512, 512), (255, 255, 255, 255))
    squircle_for_splash = squircle_cropped.resize((260, 260), Image.Resampling.LANCZOS)
    s_offset = (512 - 260) // 2
    splash.paste(squircle_for_splash, (s_offset, s_offset), squircle_for_splash)
    splash.save(os.path.join(ASSETS_DIR, "splash-icon.png"), "PNG")
    print("Saved assets/splash-icon.png (512x512)")

    # 7. Favicon (48x48)
    favicon = icon_1024.resize((48, 48), Image.Resampling.LANCZOS)
    favicon.save(os.path.join(ASSETS_DIR, "favicon.png"), "PNG")
    print("Saved assets/favicon.png (48x48)")

if __name__ == "__main__":
    main()
