"""Pose une capture du simulateur À CÔTÉ de sa référence (le canvas rendu), et mesure l'écart.

    cote_a_cote.py capture.png reference.png sortie.png [--ref-y N] [--cap-y N] [--hauteur N]

Les deux images sont à l'échelle 3. `--ref-y` et `--cap-y` (en POINTS) disent où commence la
bande comparée dans chacune ; `--hauteur` sa hauteur. Sortie : référence | capture | différence.

L'écart est compté en pixels dont la couleur s'éloigne de plus de 40 sur 255 — assez pour ignorer
l'anticrénelage, pas assez pour ignorer un trait déplacé d'un point."""
import sys
from PIL import Image, ImageChops, ImageDraw

args = sys.argv[1:]
def opt(nom, defaut):
    return int(args[args.index(nom) + 1]) if nom in args else defaut
cap, ref, sortie = Image.open(args[0]).convert("RGB"), Image.open(args[1]).convert("RGB"), args[2]
E = 3
ry, cy = opt("--ref-y", 0) * E, opt("--cap-y", 0) * E
if cap.width != ref.width:
    print(f"LARGEURS DIFFÉRENTES : capture {cap.width}px, référence {ref.width}px — la référence est centrée, sans mise à l'échelle.")
h = min(cap.height - cy, ref.height - ry, opt("--hauteur", 10**6) * E)
l = min(cap.width, ref.width)
c = cap.crop(((cap.width - l) // 2, cy, (cap.width - l) // 2 + l, cy + h))
r = ref.crop(((ref.width - l) // 2, ry, (ref.width - l) // 2 + l, ry + h))
d = ImageChops.difference(c, r).convert("L").point(lambda v: 255 if v > 40 else 0)
n = sum(d.histogram()[255:])
print(f"bande de {h // E} pt : {n} px en écart sur {l * h} ({100 * n / (l * h):.2f} %)")
# où sont les écarts, par tranche de 40 points
for y in range(0, h, 40 * E):
    t = d.crop((0, y, l, min(h, y + 40 * E)))
    k = sum(t.histogram()[255:])
    if k > 0.004 * l * 40 * E:
        print(f"   {cy // E + y // E:4d} → {cy // E + y // E + 40:4d} pt (capture) : {100 * k / (l * 40 * E):5.1f} %")
planche = Image.new("RGB", (l * 3 + 40, h), "white")
planche.paste(r, (0, 0)); planche.paste(c, (l + 20, 0))
rouge = Image.merge("RGB", (Image.new("L", d.size, 255), d.point(lambda v: 255 - v), d.point(lambda v: 255 - v)))
planche.paste(Image.blend(c.convert("L").convert("RGB"), rouge, 0.6), (2 * l + 40, 0))
planche.save(sortie)
