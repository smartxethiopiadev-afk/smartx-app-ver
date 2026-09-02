import struct, zlib, math, os

def create_smart_x_png(width, height):
    # Scale factors
    cx = width / 2.0
    cy = height / 2.0
    r_corner = width * 0.22

    # Ethiopian flag colors
    c_green = (0, 154, 68)
    c_yellow = (255, 209, 0)
    c_red = (239, 51, 64)
    c_blue_bg1 = (10, 17, 40)
    c_blue_bg2 = (24, 38, 70)
    c_cyan = (56, 189, 248)
    c_white = (255, 255, 255)
    c_gold = (245, 158, 11)

    # Simple 5x7 bitmap font definitions for letters
    # S, M, A, R, T, X, E, T, H, I, O, P, I, A, N
    font_5x7 = {
        'S': [" 0111", "10000", "10000", " 0110", "00001", "00001", "11110"],
        'M': ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
        'A': [" 0110", "10001", "10001", "11111", "10001", "10001", "10001"],
        'R': ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
        'T': ["11111", " 0100", " 0100", " 0100", " 0100", " 0100", " 0100"],
        'X': ["10001", "10001", " 01010", " 0100", " 01010", "10001", "10001"],
        'E': ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
        'H': ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
        'I': ["11111", " 0100", " 0100", " 0100", " 0100", " 0100", "11111"],
        'O': [" 0110", "10001", "10001", "10001", "10001", "10001", " 0110"],
        'P': ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
        'N': ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
        ' ': ["00000", "00000", "00000", "00000", "00000", "00000", "00000"]
    }

    def in_rounded_rect(px, py, w, h, radius):
        # squircle distance check
        dx = max(abs(px - w/2.0) - (w/2.0 - radius), 0)
        dy = max(abs(py - h/2.0) - (h/2.0 - radius), 0)
        return (dx*dx + dy*dy) <= (radius*radius)

    def draw_pixel(x, y, w, h):
        # 1. Outer transparency / squircle check
        if not in_rounded_rect(x, y, w, h, r_corner):
            return (0, 0, 0, 0)

        # 2. Gradient background (dark navy to deep blue)
        t_bg = y / float(h)
        bg_r = int(c_blue_bg1[0] * (1 - t_bg) + c_blue_bg2[0] * t_bg)
        bg_g = int(c_blue_bg1[1] * (1 - t_bg) + c_blue_bg2[1] * t_bg)
        bg_b = int(c_blue_bg1[2] * (1 - t_bg) + c_blue_bg2[2] * t_bg)

        # 3. Ethiopian Flag Top Accent Arc/Bar
        # Y range: 0.08*h to 0.12*h
        y_norm = y / float(h)
        x_norm = x / float(w)

        if 0.07 <= y_norm <= 0.11 and 0.15 <= x_norm <= 0.85:
            # 3 vertical flag stripes: Green, Yellow, Red
            if 0.15 <= x_norm < 0.383:
                return (*c_green, 255)
            elif 0.383 <= x_norm < 0.616:
                return (*c_yellow, 255)
            elif 0.616 <= x_norm <= 0.85:
                return (*c_red, 255)

        # 4. Central Geometric "X" Mark + Grad Cap / Sparkle
        # Center of X is at (cx, cy - 0.04*h)
        x_ctr = cx
        y_ctr = cy - h * 0.05
        x_rel = x - x_ctr
        y_rel = y - y_ctr

        # Thick stylized "X" strokes
        size_x = w * 0.22
        thick = w * 0.055

        d_diag1 = abs(x_rel - y_rel) / 1.4142
        d_diag2 = abs(x_rel + y_rel) / 1.4142

        in_arm1 = (d_diag1 <= thick) and (abs(x_rel) <= size_x) and (abs(y_rel) <= size_x)
        in_arm2 = (d_diag2 <= thick) and (abs(x_rel) <= size_x) and (abs(y_rel) <= size_x)

        if in_arm1 or in_arm2:
            # Gold/Cyan highlight gradient on X
            glow = max(0, 1.0 - (math.sqrt(x_rel*x_rel + y_rel*y_rel) / size_x))
            r_x = int(c_white[0] * glow + c_cyan[0] * (1 - glow))
            g_x = int(c_white[1] * glow + c_cyan[1] * (1 - glow))
            b_x = int(c_white[2] * glow + c_cyan[2] * (1 - glow))
            return (r_x, g_x, b_x, 255)

        # Graduation cap diamond icon floating above X
        cap_y = y_ctr - size_x * 1.15
        dx_cap = abs(x - x_ctr)
        dy_cap = abs(y - cap_y)
        if (dx_cap / (w * 0.12) + dy_cap / (h * 0.06)) <= 1.0:
            return (*c_gold, 255)

        # 5. Text Drawing at bottom ("SMART X", "ETHIOPIAN")
        # Text 1: "SMART X"
        t1_str = "SMART X"
        scale1 = max(1, int(w / 72))
        t1_y = int(cy + h * 0.20)

        # Text 2: "ETHIOPIAN"
        t2_str = "ETHIOPIAN"
        scale2 = max(1, int(w / 110))
        t2_y = int(cy + h * 0.33)

        # Check SMART X
        total_w1 = len(t1_str) * (6 * scale1)
        start_x1 = int(cx - total_w1 / 2)
        if t1_y <= y < t1_y + 7 * scale1 and start_x1 <= x < start_x1 + total_w1:
            char_idx = (x - start_x1) // (6 * scale1)
            if char_idx < len(t1_str):
                ch = t1_str[char_idx]
                if ch in font_5x7:
                    px_x = ((x - start_x1) % (6 * scale1)) // scale1
                    px_y = (y - t1_y) // scale1
                    if px_x < 5 and px_y < 7:
                        if font_5x7[ch][px_y][px_x] != ' ':
                            return (*c_white, 255)

        # Check ETHIOPIAN
        total_w2 = len(t2_str) * (6 * scale2)
        start_x2 = int(cx - total_w2 / 2)
        if t2_y <= y < t2_y + 7 * scale2 and start_x2 <= x < start_x2 + total_w2:
            char_idx = (x - start_x2) // (6 * scale2)
            if char_idx < len(t2_str):
                ch = t2_str[char_idx]
                if ch in font_5x7:
                    px_x = ((x - start_x2) % (6 * scale2)) // scale2
                    px_y = (y - t2_y) // scale2
                    if px_x < 5 and px_y < 7:
                        if font_5x7[ch][px_y][px_x] != ' ':
                            return (*c_gold, 255)

        return (bg_r, bg_g, bg_b, 255)

    # Encode PNG
    raw_pixels = bytearray()
    for y in range(height):
        raw_pixels.append(0) # filter
        for x in range(width):
            r, g, b, a = draw_pixel(x, y, width, height)
            raw_pixels.extend([r, g, b, a])

    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)

    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    idat = zlib.compress(bytes(raw_pixels))
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) + chunk(b'IEND', b'')

# Generate all icons
targets = [
    ('android/app/src/main/res/mipmap-mdpi/ic_launcher.png', 48),
    ('android/app/src/main/res/mipmap-hdpi/ic_launcher.png', 72),
    ('android/app/src/main/res/mipmap-xhdpi/ic_launcher.png', 96),
    ('android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png', 144),
    ('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 192),
    ('assets/images/smart_x_logo.png', 512),
    ('web/icons/Icon-192.png', 192),
    ('web/icons/Icon-512.png', 512),
    ('web/favicon.png', 64),
    ('build/web/assets/assets/images/smart_x_logo.png', 512),
    ('build/web/favicon.png', 64),
]

for path, size in targets:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    png_data = create_smart_x_png(size, size)
    with open(path, 'wb') as f:
        f.write(png_data)
    print(f"Generated {path} ({size}x{size})")

print("All app icons updated successfully!")
