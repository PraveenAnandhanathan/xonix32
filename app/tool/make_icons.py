#!/usr/bin/env python3
"""Generate all Android/iOS launcher icons from the original MainFrame.ico.

Decodes the 32x32 16-color icon (4bpp BMP-in-ICO with AND mask),
composites it on black (App Store icons must be opaque), and
nearest-neighbor upscales to every required size. No dependencies.

Run from app/:  python3 tool/make_icons.py
"""

import os
import struct
import zlib

ICO = os.path.join('..', 'src', 'res', 'MainFrame.ico')
if not os.path.exists(ICO):
    ICO = os.path.join('src', 'res', 'MainFrame.ico')


def decode_ico(path):
    d = open(path, 'rb').read()
    count = struct.unpack('<H', d[4:6])[0]
    assert count >= 1
    w, h, _, _, _, _, size, off = struct.unpack('<BBBBHHII', d[6:22])
    w, h = w or 256, h or 256
    bih = d[off:off + 40]
    (hsz, bw, bh, planes, bpp) = struct.unpack('<IiiHH', bih[:16])
    assert bpp == 4, f'expected 4bpp, got {bpp}'
    pal_off = off + hsz
    palette = [tuple(d[pal_off + 4 * i:pal_off + 4 * i + 3][::-1])
               for i in range(16)]  # BGR0 -> RGB
    xor_off = pal_off + 16 * 4
    xor_stride = ((w * 4 + 31) // 32) * 4
    and_off = xor_off + xor_stride * h
    and_stride = ((w + 31) // 32) * 4

    px = [[(0, 0, 0) for _ in range(w)] for _ in range(h)]
    for y in range(h):
        row = h - 1 - y  # bottom-up
        for x in range(w):
            b = d[xor_off + row * xor_stride + x // 2]
            idx = (b >> 4) if x % 2 == 0 else (b & 0x0F)
            mask_byte = d[and_off + row * and_stride + x // 8]
            transparent = (mask_byte >> (7 - x % 8)) & 1
            # composite on black
            px[y][x] = (0, 0, 0) if transparent else palette[idx]
    return w, h, px


def scale(px, sw, sh, dw, dh):
    return [[px[y * sh // dh][x * sw // dw] for x in range(dw)]
            for y in range(dh)]


def write_png(path, px):
    h, w = len(px), len(px[0])
    raw = b''.join(
        b'\x00' + b''.join(bytes(p) for p in row) for row in px)

    def chunk(t, data):
        c = t + data
        return struct.pack('>I', len(data)) + c + struct.pack(
            '>I', zlib.crc32(c) & 0xFFFFFFFF)

    ihdr = struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)
    png = (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr)
           + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(png)
    print(f'wrote {path} ({w}x{h})')


def main():
    w, h, px = decode_ico(ICO)
    print(f'decoded {ICO}: {w}x{h}')

    android = {
        'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
        'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
        'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
        'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    }
    ios_dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    ios = {
        'Icon-App-20x20@1x.png': 20, 'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60, 'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58, 'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40, 'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120, 'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180, 'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152, 'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
    }
    web = {
        'web/favicon.png': 32,
        'web/icons/Icon-192.png': 192,
        'web/icons/Icon-512.png': 512,
        'web/icons/Icon-maskable-192.png': 192,
        'web/icons/Icon-maskable-512.png': 512,
    }
    for path, size in android.items():
        write_png(path, scale(px, w, h, size, size))
    for name, size in ios.items():
        write_png(os.path.join(ios_dir, name), scale(px, w, h, size, size))
    for path, size in web.items():
        write_png(path, scale(px, w, h, size, size))
    # Play Store listing icon
    write_png('store/icon_512.png', scale(px, w, h, 512, 512))


if __name__ == '__main__':
    main()
