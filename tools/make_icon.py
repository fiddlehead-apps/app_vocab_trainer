"""Erzeugt das App-Icon (1024 px) neu: python3 tools/make_icon.py

Offenes Buch mit Sprechblase "Aa" auf Traubenlila, im flachen Stil der anderen Sola-Icons.
Braucht Pillow.
"""
import math
import os

from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   'Vocab', 'Assets.xcassets', 'AppIcon.appiconset', 'icon-1024.png')
SS = 4

BRAND = '#6C47FF'
PAGE = '#FFFFFF'
PAGE_SHADE = '#E4DCFF'
SPINE = '#3D22B8'
BUBBLE = '#FFC857'
LETTER = '#3D22B8'


def rrect(x0, y0, x1, y1, r, steps=12):
    pts = []
    for cx, cy, start in ((x1 - r, y0 + r, -90), (x1 - r, y1 - r, 0), (x0 + r, y1 - r, 90), (x0 + r, y0 + r, 180)):
        for i in range(steps + 1):
            a = math.radians(start + 90 * i / steps)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def quad(p0, c, p1, steps=20):
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t ** 2 * p1[0],
             (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t ** 2 * p1[1])
            for t in (i / steps for i in range(steps + 1))]


def page(left):
    # One page of the open book: curved top and bottom edge, meeting at the spine (x = 256).
    s = -1 if left else 1
    outer = 256 + s * 176
    top = quad((256, 268), (256 + s * 90, 236), (outer, 250))
    bottom = quad((outer, 420), (256 + s * 90, 406), (256, 438))
    return top + bottom


def lines(left):
    # Text lines on a page.
    s = -1 if left else 1
    out = []
    for i, y in enumerate((300, 330, 360, 390)):
        x0, x1 = 256 + s * 34, 256 + s * (150 if i % 2 == 0 else 120)
        out.append(rrect(min(x0, x1), y - 5, max(x0, x1), y + 5, 5, 4))
    return out


def bubble():
    body = rrect(176, 64, 336, 196, 40)
    tail = [(226, 190), (210, 236), (266, 192)]
    return body, tail


def letter_a(x, y, h, w, stroke):
    # Capital A: a lambda with a flat top plus a bar, polygons only (no font needed).
    cx = x + w / 2
    legs = [(x, y + h), (cx - stroke * 0.6, y), (cx + stroke * 0.6, y), (x + w, y + h), (x + w - stroke, y + h),
            (cx, y + stroke * 1.9), (x + stroke, y + h)]
    by = y + h * 0.6
    bar = [(x + w * 0.24, by), (x + w * 0.76, by), (x + w * 0.8, by + stroke * 0.8), (x + w * 0.2, by + stroke * 0.8)]
    return [legs, bar]


def letter_small_a(cx, cy, r, stroke, steps=40):
    # Lowercase a: a ring plus a stem on the right.
    outer = [(cx + r * math.cos(2 * math.pi * i / steps), cy + r * math.sin(2 * math.pi * i / steps)) for i in range(steps)]
    inner = [(cx + (r - stroke) * math.cos(2 * math.pi * i / steps), cy + (r - stroke) * math.sin(2 * math.pi * i / steps))
             for i in range(steps)]
    stem = rrect(cx + r - stroke, cy - r, cx + r, cy + r, stroke / 2, 4)
    return outer, inner, stem


if __name__ == '__main__':
    size = 1024
    big = size * SS
    k = big / 512.0
    place = lambda pts: [(x * k, y * k) for x, y in pts]
    im = Image.new('RGB', (big, big), BRAND)  # iOS rundet selbst ab, kein Alpha erlaubt
    d = ImageDraw.Draw(im)

    d.polygon(place(rrect(244, 262, 268, 446, 10)), fill=SPINE)
    for left in (True, False):
        d.polygon(place(page(left)), fill=PAGE)
        for line in lines(left):
            d.polygon(place(line), fill=PAGE_SHADE)

    body, tail = bubble()
    d.polygon(place(body), fill=BUBBLE)
    d.polygon(place(tail), fill=BUBBLE)
    for part in letter_a(206, 92, 78, 62, 17):
        d.polygon(place(part), fill=LETTER)
    outer, inner, stem = letter_small_a(288, 146, 25, 14)
    d.polygon(place(outer), fill=LETTER)
    d.polygon(place(inner), fill=BUBBLE)
    d.polygon(place(stem), fill=LETTER)

    im.resize((size, size), Image.LANCZOS).save(OUT, optimize=True)
    print('Icon geschrieben nach', OUT)
