#!/usr/bin/env python3
"""Generate a LeetCode-style app icon and convert to .icns"""
import subprocess, os, struct, zlib

SIZE = 1024

def create_png(width, height, pixels):
    """Create PNG from RGBA pixel data without PIL."""
    def chunk(chunk_type, data):
        c = chunk_type + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    
    raw = b''
    for y in range(height):
        raw += b'\x00'  # filter none
        for x in range(width):
            idx = (y * width + x) * 4
            raw += bytes(pixels[idx:idx+4])
    
    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    idat = zlib.compress(raw, 9)
    return sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) + chunk(b'IEND', b'')

def draw_icon(size):
    """Draw LeetCode-style icon: dark rounded rect bg with orange LeetCode logo."""
    pixels = [0] * (size * size * 4)
    
    # Colors
    bg_r, bg_g, bg_b = 26, 26, 26        # #1a1a1a dark background
    orange_r, orange_g, orange_b = 255, 161, 22  # #ffa116 LeetCode orange
    
    corner_radius = size // 5  # macOS-style rounded corners
    
    def in_rounded_rect(x, y, w, h, r):
        if x < r and y < r:
            return (x - r)**2 + (y - r)**2 <= r**2
        if x >= w - r and y < r:
            return (x - (w - r - 1))**2 + (y - r)**2 <= r**2
        if x < r and y >= h - r:
            return (x - r)**2 + (y - (h - r - 1))**2 <= r**2
        if x >= w - r and y >= h - r:
            return (x - (w - r - 1))**2 + (y - (h - r - 1))**2 <= r**2
        return True
    
    def set_pixel(x, y, r, g, b, a=255):
        if 0 <= x < size and 0 <= y < size:
            idx = (y * size + x) * 4
            pixels[idx] = r
            pixels[idx+1] = g
            pixels[idx+2] = b
            pixels[idx+3] = a
    
    def fill_circle(cx, cy, radius, r, g, b):
        for dy in range(-radius, radius+1):
            for dx in range(-radius, radius+1):
                if dx*dx + dy*dy <= radius*radius:
                    set_pixel(cx+dx, cy+dy, r, g, b)
    
    def fill_rect(x1, y1, x2, y2, r, g, b):
        for y in range(max(0,y1), min(size,y2)):
            for x in range(max(0,x1), min(size,x2)):
                set_pixel(x, y, r, g, b)
    
    # Draw background
    for y in range(size):
        for x in range(size):
            if in_rounded_rect(x, y, size, size, corner_radius):
                set_pixel(x, y, bg_r, bg_g, bg_b)
    
    # Draw LeetCode logo: stylized "{ }" brackets
    # Left bracket "{"
    cx = size // 2
    cy = size // 2
    
    # Scale factors
    s = size / 1024.0
    
    # Thick line width
    lw = int(48 * s)
    
    # Left curly brace
    brace_h = int(500 * s)  # total height
    brace_w = int(140 * s)  # width of curve
    tip_ext = int(60 * s)   # how far the middle tip extends
    
    left_x = cx - int(180 * s)
    top_y = cy - brace_h // 2
    mid_y = cy
    bot_y = cy + brace_h // 2
    
    # Draw left brace as thick lines
    # Top vertical
    fill_rect(left_x, top_y, left_x + lw, mid_y - int(30*s), orange_r, orange_g, orange_b)
    # Bottom vertical
    fill_rect(left_x, mid_y + int(30*s), left_x + lw, bot_y, orange_r, orange_g, orange_b)
    # Top hook (horizontal going right)
    fill_rect(left_x, top_y, left_x + brace_w, top_y + lw, orange_r, orange_g, orange_b)
    # Bottom hook (horizontal going right)
    fill_rect(left_x, bot_y - lw, left_x + brace_w, bot_y, orange_r, orange_g, orange_b)
    # Middle tip (pointing left)
    fill_rect(left_x - tip_ext, mid_y - lw//2, left_x + lw, mid_y + lw//2, orange_r, orange_g, orange_b)
    
    # Right curly brace (mirrored)
    right_x = cx + int(180 * s) - lw
    
    # Top vertical
    fill_rect(right_x, top_y, right_x + lw, mid_y - int(30*s), orange_r, orange_g, orange_b)
    # Bottom vertical
    fill_rect(right_x, mid_y + int(30*s), right_x + lw, bot_y, orange_r, orange_g, orange_b)
    # Top hook (horizontal going left)
    fill_rect(right_x - brace_w + lw, top_y, right_x + lw, top_y + lw, orange_r, orange_g, orange_b)
    # Bottom hook (horizontal going left)
    fill_rect(right_x - brace_w + lw, bot_y - lw, right_x + lw, bot_y, orange_r, orange_g, orange_b)
    # Middle tip (pointing right)
    fill_rect(right_x, mid_y - lw//2, right_x + lw + tip_ext, mid_y + lw//2, orange_r, orange_g, orange_b)
    
    # Add a small dot between braces (like LeetCode's logo dot)
    dot_r = int(28 * s)
    fill_circle(cx, cy + int(140*s), dot_r, orange_r, orange_g, orange_b)
    
    return pixels

def main():
    os.makedirs('AppIcon.iconset', exist_ok=True)
    
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    
    for sz in sizes:
        print(f"  Generating {sz}x{sz}...")
        px = draw_icon(sz)
        png_data = create_png(sz, sz, px)
        
        if sz <= 512:
            with open(f'AppIcon.iconset/icon_{sz}x{sz}.png', 'wb') as f:
                f.write(png_data)
        if sz >= 32:
            half = sz // 2
            with open(f'AppIcon.iconset/icon_{half}x{half}@2x.png', 'wb') as f:
                f.write(png_data)
    
    print("  Converting to .icns...")
    subprocess.run(['iconutil', '-c', 'icns', 'AppIcon.iconset', '-o', 'AppIcon.icns'], check=True)
    print("✅ AppIcon.icns generated!")

if __name__ == '__main__':
    main()
