#!/usr/bin/env python3
"""Les bornes du filtre de distance sont les mêmes sur le serveur et dans l'app.

# POURQUOI CE CONTRÔLE EXISTE

Le filtre « 5 km », « 10 km », « Semi »… de l'écran des courses est appliqué deux fois : par le
serveur (`lib/courses.js`, `BANDES_DE_DISTANCE`, avant de couper la liste à quarante) et par l'app
(`Haizo/Models/RaceEvent.swift`, `FiltreDeDistance.bandes`), qui refiltre derrière un serveur plus
ancien et range ses propres courses. Si les deux bornes divergent, une course rendue par le serveur
sous « 10 km » disparaît à l'écran, et rien ne le dit : il n'y a pas d'erreur, juste une liste plus
courte. Ce contrôle compare les deux écritures.

    python3 ci_scripts/check_bandes_distance.py
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
JS = ROOT / "lib/courses.js"
SWIFT = ROOT / "Haizo/Models/RaceEvent.swift"
NOMS_SWIFT = {"cinq": "5k", "dix": "10k", "semi": "semi", "marathon": "marathon"}


def bandes_js(texte):
    bloc = re.search(r"const BANDES_DE_DISTANCE = \{(.*?)\};", texte, re.S)
    if not bloc:
        return None
    return {cle.strip("'\""): (float(a), float(b))
            for cle, a, b in re.findall(r"('?[\w]+'?):\s*\[([\d.]+),\s*([\d.]+)\]", bloc.group(1))}


def bandes_swift(texte):
    bloc = re.search(r"static let bandes:.*?=\s*\[(.*?)\n\s*\]", texte, re.S)
    if not bloc:
        return None
    return {NOMS_SWIFT.get(nom, nom): (float(a), float(b))
            for nom, a, b in re.findall(r"\(\.(\w+),\s*([\d.]+)\.\.\.([\d.]+)\)", bloc.group(1))}


def ultra_js(texte):
    m = re.search(r"const ULTRA_AU_DELA_DE = BANDES_DE_DISTANCE\.marathon\[1\];", texte)
    return "marathon" if m else None


def ultra_swift(texte):
    m = re.search(r"static let ultraAuDelaDe = ([\d.]+)", texte)
    return float(m.group(1)) if m else None


def comparer(js, swift):
    erreurs = []
    a, b = bandes_js(js), bandes_swift(swift)
    if not a:
        erreurs.append("lib/courses.js : BANDES_DE_DISTANCE introuvable")
    if not b:
        erreurs.append("RaceEvent.swift : FiltreDeDistance.bandes introuvable")
    if erreurs:
        return erreurs
    if a != b:
        erreurs.append(f"bornes différentes : serveur {a}, app {b}")
    if ultra_js(js) != "marathon":
        erreurs.append("lib/courses.js : ULTRA_AU_DELA_DE doit être la borne haute du marathon")
    elif ultra_swift(swift) != a.get("marathon", (None, None))[1]:
        erreurs.append(f"RaceEvent.swift : ultraAuDelaDe ({ultra_swift(swift)}) n'est pas la borne haute du marathon")
    return erreurs


def main():
    erreurs = comparer(JS.read_text(), SWIFT.read_text())
    if erreurs:
        for e in erreurs:
            print("✗", e)
        sys.exit(1)
    print("Filtre de distance : mêmes bornes sur le serveur et dans l'app.")


if __name__ == "__main__":
    main()
