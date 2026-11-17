"""Décalage vertical et horizontal (en points) qui rapproche le plus la capture de la référence,
bande par bande. Négatif : la capture est PLUS BAS (vertical) / PLUS À GAUCHE (horizontal) que la référence. Vérifié sur une image décalée de 3 px."""
import sys
import numpy as np
from PIL import Image
cap = np.asarray(Image.open(sys.argv[1]).convert("L"), dtype=np.float32)
ref = np.asarray(Image.open(sys.argv[2]).convert("L"), dtype=np.float32)
E = 3
bande = int(sys.argv[3]) if len(sys.argv) > 3 else 40
debut = int(sys.argv[4]) if len(sys.argv) > 4 else 60
fin = int(sys.argv[5]) if len(sys.argv) > 5 else 820
for y in range(debut, fin, bande):
    c = cap[y*E:(y+bande)*E]
    meilleur = None
    for dy in range(-9, 10):
        for dx in range(-9, 10):
            r = ref[y*E+dy:(y+bande)*E+dy]
            if r.shape != c.shape or r.shape[0] == 0: continue
            if dx >= 0: a, b = c[:, dx:], r[:, :r.shape[1]-dx]
            else:       a, b = c[:, :dx], r[:, -dx:]
            e = float(np.mean(np.abs(a - b)))
            if meilleur is None or e < meilleur[0]: meilleur = (e, dy, dx)
    e0 = float(np.mean(np.abs(c - ref[y*E:(y+bande)*E])))
    print(f"{y:4d}-{y+bande:<4d} pt : décalage vertical {meilleur[1]/E:+.2f} pt, horizontal {meilleur[2]/E:+.2f} pt   (erreur {e0:.1f} → {meilleur[0]:.1f})")
