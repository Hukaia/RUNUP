#!/usr/bin/env python3
"""Engendre `Haizo/DesignSystem/Refonte/HZDessins.swift` depuis `design/icones.json`.

# POURQUOI DES ICÔNES DESSINÉES, ET PLUS DES SF SYMBOLS

Le canvas de la refonte (17 novembre 2026) dessine ses icônes lui-même : vingt-neuf formes au
trait, dans une boîte de 24. La consigne est de reproduire, pas de réinterpréter — et un SF Symbol
« approchant » est une réinterprétation qui se voit au premier côte-à-côte : la bulle du coach est
à angles vifs, l'entrée « Aujourd'hui » est un rectangle arrondi de 14 × 18 qu'aucun symbole
système ne dessine.

Le 11 novembre, la décision était « SF Symbols restent », contre Phosphor et Lucide : gain
esthétique, coût structurel. Elle tenait pour une bibliothèque tierce de deux cents appels. Ici la
source est le dessin arrêté de l'app elle-même, et il n'y a aucune dépendance : les formes
deviennent des `Path` SwiftUI.

# POURQUOI UN GÉNÉRATEUR

Recopier à la main vingt-neuf chemins SVG en appels `addCurve`, c'est vingt-neuf occasions de se
tromper d'un chiffre sans que rien le dise — et les arcs elliptiques de SVG (`a6 6 0 0 1 12 0`)
n'ont pas d'équivalent direct : il faut les convertir en courbes de Bézier. `fontTools` le fait,
et c'est une bibliothèque qui dessine des glyphes depuis vingt ans.

Le JSON ne contient que de la géométrie. Le canvas, lui, porte des contenus d'exemple et n'entre
pas dans le dépôt.

    python3 ci_scripts/icones.py            # réécrit le fichier Swift
    python3 ci_scripts/icones.py --verifier # échoue si le fichier n'est pas à jour

`fontTools` n'est nécessaire qu'à qui régénère : `pip install fonttools`.
"""
import json
import pathlib
import sys

RACINE = pathlib.Path(__file__).resolve().parent.parent
SOURCE = RACINE / "design" / "icones.json"
CIBLE = RACINE / "Haizo" / "DesignSystem" / "Refonte" / "HZDessins.swift"


def n(x: float) -> str:
    """Un nombre comme on l'écrirait : `4`, `3.5`, `-0.25` — trois décimales au plus."""
    t = f"{round(x, 3):.3f}".rstrip("0").rstrip(".")
    return "0" if t in ("-0", "") else t


def traces(icone: dict) -> list:
    from fontTools.pens.recordingPen import RecordingPen
    from fontTools.svgLib.path import parse_path

    sortie = []
    for f in icone["formes"]:
        if f["t"] == "cercle":
            sortie.append(f".ellipse({n(f['cx'] - f['r'])}, {n(f['cy'] - f['r'])}, "
                          f"{n(2 * f['r'])}, {n(2 * f['r'])})")
        elif f["t"] == "rect":
            sortie.append(f".rectangle({n(f['x'])}, {n(f['y'])}, {n(f['l'])}, {n(f['h'])}, {n(f['r'])})")
        else:
            stylo = RecordingPen()
            parse_path(f["d"], stylo)
            for ordre, points in stylo.value:
                if ordre == "moveTo":
                    sortie.append(f".depart({n(points[0][0])}, {n(points[0][1])})")
                elif ordre == "lineTo":
                    sortie.append(f".ligne({n(points[0][0])}, {n(points[0][1])})")
                elif ordre == "curveTo":
                    plat = ", ".join(n(c) for p in points for c in p)
                    sortie.append(f".courbe({plat})")
                elif ordre == "closePath":
                    sortie.append(".fermer")
                elif ordre == "endPath":
                    pass
                else:
                    raise SystemExit(f"ordre de tracé inconnu : {ordre} dans « {f['d']} »")
    return sortie


def engendrer() -> str:
    icones = json.loads(SOURCE.read_text(encoding="utf-8"))
    lignes = [
        "// ENGENDRÉ par `ci_scripts/icones.py` depuis `design/icones.json`.",
        "// Ne pas modifier à la main : corriger le JSON, relancer le script.",
        "//",
        "// Les vingt-neuf icônes du canvas de la refonte, trait pour trait. Voir l'en-tête du script",
        "// pour la raison — et `HZIcone` pour la vue qui les dessine.",
        "",
        "import SwiftUI",
        "",
        "extension HZDessin {",
    ]
    for nom, icone in sorted(icones.items()):
        lignes.append(f"    static let {nom} = HZDessin(")
        lignes.append(f"        boite: {icone['boite']}, plein: {'true' if icone['plein'] else 'false'}, "
                      f"bout: .{icone['bout']}, joint: .{icone['joint']},")
        lignes.append("        traces: [")
        for t in traces(icone):
            lignes.append(f"            {t},")
        lignes.append("        ])")
        lignes.append("")
    lignes.append("    /// Toutes, dans l'ordre alphabétique — pour la planche, qui les montre d'un coup.")
    lignes.append("    static let toutes: [(nom: String, dessin: HZDessin)] = [")
    for nom in sorted(icones):
        lignes.append(f'        ("{nom}", .{nom}),')
    lignes.append("    ]")
    lignes.append("}")
    return "\n".join(lignes) + "\n"


def main() -> int:
    texte = engendrer()
    if "--verifier" in sys.argv:
        if not CIBLE.exists() or CIBLE.read_text(encoding="utf-8") != texte:
            print(f"✗ {CIBLE.relative_to(RACINE)} n'est pas à jour avec {SOURCE.relative_to(RACINE)}.\n"
                  f"  Relancer : python3 ci_scripts/icones.py")
            return 1
        print("✓ Les icônes dessinées correspondent à leur source.")
        return 0
    CIBLE.write_text(texte, encoding="utf-8")
    print(f"{CIBLE.relative_to(RACINE)} : {texte.count('static let ') - 1} icônes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
