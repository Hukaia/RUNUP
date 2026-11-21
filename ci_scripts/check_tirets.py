#!/usr/bin/env python3
"""Aucun texte de l'app ne contient de tiret cadratin.

# POURQUOI CE CONTRÔLE EXISTE

Le tiret cadratin (—) est de la ponctuation française légitime ; c'est sa répétition mécanique qui se
lit comme un tic, et la fondatrice l'a retiré des textes de l'app (21 novembre 2026) : cent soixante-dix-sept
phrases du catalogue, en trois langues, réécrites avec un point, une virgule, deux-points ou des
parenthèses selon la phrase. Sans garde, la prochaine phrase écrite à la main le ramène, et personne ne le
voit : il n'y a rien à compiler.

Ce que le contrôle lit : le catalogue de chaînes (`Haizo/Resources/Localizable.xcstrings`), clés ET traductions,
puisque la clé française est le texte affiché en français. Le tiret SEUL (« — »), qui est un espace réservé
pour une valeur absente (« — /km » n'existe plus, mais « — » reste « pas de donnée »), est permis.

    python3 ci_scripts/check_tirets.py
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOGUE = ROOT / "Haizo/Resources/Localizable.xcstrings"
TIRET = "—"


def trouver(chaines: dict) -> list[str]:
    """Les emplacements (clé, langue) dont le texte contient un tiret cadratin."""
    fautes = []
    for cle, entree in chaines.items():
        if TIRET in cle and cle.strip() != TIRET:
            fautes.append(f"clé : {cle[:100]}")
        for langue, loc in entree.get("localizations", {}).items():
            valeur = (loc.get("stringUnit") or {}).get("value", "")
            if TIRET in valeur and valeur.strip() != TIRET:
                fautes.append(f"{langue} de « {cle[:60]} » : {valeur[:80]}")
    return fautes


def main() -> int:
    chaines = json.loads(CATALOGUE.read_text(encoding="utf-8"))["strings"]
    fautes = trouver(chaines)
    if fautes:
        print(f"{len(fautes)} texte(s) avec un tiret cadratin dans le catalogue :\n")
        for f in fautes[:40]:
            print("  " + f)
        print("\n  Un point, une virgule, deux-points ou des parenthèses : la phrase se lit sans lui.")
        return 1
    print(f"Tirets cadratins : aucun dans les {len(chaines)} chaînes du catalogue, clés et traductions.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
