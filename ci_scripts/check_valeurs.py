#!/usr/bin/env python3
"""Refuse un build où une vue de la refonte contient un nombre.

# POURQUOI CE CONTRÔLE EXISTE

La méthode de la refonte, point 5 : « Aucune valeur en dur dans les vues. » La phrase est sans
réserve, et le contrôle aussi : dans `Haizo/Views/Refonte/`, un nombre écrit dans le code est
refusé — une marge, une taille, un rayon, une opacité, un compte de colonnes, une teinte en
hexadécimal. Il n'y a pas de liste d'exceptions à tenir, donc pas de liste qui s'allonge.

`check_grille.py` ne pouvait pas faire ce travail. Il compare des écarts à la grille de
`RUSpacing`, celle de l'ancien système ; le canvas de la refonte a sa propre géométrie (22 sous
une rangée, 26 sous une autre, dix rayons), et il ne lisait que trois écritures — `spacing:`,
`.padding(`, `cornerRadius`. Un `.frame(width: 318)` ne l'a jamais intéressé. La leçon de la
semaine du 10 novembre tient en une ligne : un garde qui connaît une liste d'écritures ignore la
suivante. Ici il n'y a pas d'écriture à connaître — tout nombre est refusé.

# CE QUI PASSE, ET POURQUOI

- `0`, partout : ce n'est pas une mesure, c'est son absence (`spacing: 0`, `minLength: 0`).
- `1`, HORS d'une ligne de mise en page : l'unité d'un compte (`indice + 1`, `count > 1`).
  Sur une ligne de mise en page — un modificateur, une pile, une forme — il est refusé comme les
  autres : un filet d'un point écrit à la main est une valeur en dur.
- `.lineLimit(1)` : « tient sur une ligne » n'est pas une mesure.
- Les chaînes et les commentaires, qui ne sont pas du code.

# LE SYSTÈME DE DESIGN, LUI, DÉCLARE

`Haizo/DesignSystem/Refonte/` est l'endroit où les valeurs s'écrivent : `static let carte:
CGFloat = 36` y est la déclaration, pas un défaut. Le contrôle n'y refuse donc qu'une chose : un
nombre sur une LIGNE DE MISE EN PAGE — `.padding(.top, 9)`, `VStack(spacing: 9)`,
`cornerRadius: 9`, `lineWidth: 2`. C'est une liste d'écritures, avec la faiblesse dite plus
haut, et elle est assumée : dans ce dossier un nombre est légitime sur la plupart des lignes,
une règle sans écriture n'y est pas possible.

`HZDessins.swift` n'est pas lu : il est engendré par `icones.py` depuis `design/icones.json`, ce
sont des coordonnées de tracé, et `icones.py --verifier` le compare à sa source à chaque build.

# LA PORTÉE, ET SA DATE DE FIN

Un garde ne voit que les dossiers qu'on lui donne. Celui-ci voit `Haizo/Views/Refonte/` : chaque
écran refait y est écrit, à neuf, pendant que l'ancien continue de tourner à côté. Un écran
« refait » ailleurs lui échapperait — c'est pourquoi il échoue si le dossier est vide ou absent,
et pourquoi la dernière étape de la refonte, quand l'ancien système est retiré, est d'élargir
`VUES` à `Haizo/Views` tout entier.

# CE QU'IL NE DIT PAS

Qu'une valeur nommée est la bonne. `HZAccueil.sousLaSemaine = 26` peut être faux ; c'est la
comparaison côte à côte avec le rendu du canvas qui le dit, pas ce script.
"""
import pathlib
import re
import sys

RACINE = pathlib.Path(__file__).resolve().parent.parent
VUES = "Haizo/Views/Refonte"
SYSTEME = "Haizo/DesignSystem/Refonte"
ENGENDRES = {"HZDessins.swift"}

CHAINE = re.compile(r'"(?:[^"\\]|\\.)*"')
NOMBRE = re.compile(r"(?<![\w$])(?<![\w)\]]\.)(0x[0-9A-Fa-f_]+|\d[\d_]*(?:\.\d+)?)(?![\w])")
UNE_LIGNE = re.compile(r"\.lineLimit\(1\)")
#: Une ligne de mise en page : un modificateur, une pile, une forme, ou l'une des étiquettes
#: par lesquelles SwiftUI reçoit une mesure.
MISE_EN_PAGE = re.compile(
    r"^\s*\.\w+\(|\b(?:[VHZ]Stack|Lazy[VH](?:Stack|Grid)|Spacer|Grid|GridItem|"
    r"RoundedRectangle|UnevenRoundedRectangle|Capsule|Circle|Rectangle)\(|"
    r"\b\w*[rR]adius\w*: ?-?[\d.]|\b(?:lineWidth|spacing|size|minLength): ?-?[\d.]")


def code(texte: str):
    """Le code d'un fichier, ligne à ligne, sans ses chaînes ni ses commentaires."""
    dans_bloc = False     # un /* … */ ouvert
    dans_texte = False    # une chaîne sur plusieurs lignes ouverte par trois guillemets
    for num, ligne in enumerate(texte.split("\n"), 1):
        if dans_texte:
            if '"""' in ligne:
                dans_texte = False
            continue
        if ligne.count('"""') == 1:
            dans_texte = True
            ligne = ligne.split('"""')[0]
        ligne = CHAINE.sub('""', ligne)
        if dans_bloc:
            if "*/" not in ligne:
                continue
            ligne = ligne.split("*/", 1)[1]
            dans_bloc = False
        ligne = re.sub(r"/\*.*?\*/", "", ligne)
        if "/*" in ligne:
            ligne = ligne.split("/*", 1)[0]
            dans_bloc = True
        ligne = ligne.split("//", 1)[0]
        yield num, ligne


def nombres(ligne: str, tout: bool):
    """Les nombres refusés d'une ligne. `tout` : la règle des vues ; sinon celle du système."""
    ligne = UNE_LIGNE.sub("", ligne)
    en_page = bool(MISE_EN_PAGE.search(ligne))
    if not tout and not en_page:
        return []
    refuses = []
    for brut in NOMBRE.findall(ligne):
        valeur = None if brut.startswith("0x") else float(brut.replace("_", ""))
        if valeur == 0:
            continue
        if valeur == 1 and not en_page:
            continue
        refuses.append(brut)
    return refuses


def main():
    if not (RACINE / VUES).is_dir() or not (RACINE / SYSTEME).is_dir():
        print(f"`{VUES}` ou `{SYSTEME}` est introuvable — le contrôle tourne au mauvais endroit, "
              f"ou la refonte a changé de dossier sans lui.")
        return 1
    fautes, lus = [], {VUES: 0, SYSTEME: 0}
    for dossier, tout in ((VUES, True), (SYSTEME, False)):
        for chemin in sorted((RACINE / dossier).rglob("*.swift")):
            if chemin.name in ENGENDRES:
                continue
            lus[dossier] += 1
            rel = chemin.relative_to(RACINE)
            for num, ligne in code(chemin.read_text()):
                for brut in nombres(ligne, tout):
                    fautes.append(f"{rel}:{num} : {brut} est écrit en dur.\n    {ligne.strip()}")
    if lus[VUES] == 0:
        print(f"`{VUES}` ne contient aucun fichier Swift : le contrôle ne garderait rien.")
        return 1
    if fautes:
        print(f"{len(fautes)} valeur(s) en dur dans la refonte :\n")
        for f in fautes[:40]:
            print("  • " + f)
        if len(fautes) > 40:
            print(f"\n  … et {len(fautes) - 40} autres.")
        print("\n  Une vue de la refonte ne contient pas un nombre : la valeur se déclare, avec")
        print(f"  son nom, dans `{SYSTEME}/` — un jeton partagé (`HZEspace`, `HZRayon`), la")
        print("  constante d'un composant, ou la mesure d'un écran (`HZEcrans.swift`).")
        return 1
    print(f"Aucune valeur en dur : {lus[VUES]} vue(s) de la refonte sans un nombre, "
          f"{lus[SYSTEME]} fichier(s) du système sans nombre sur une ligne de mise en page.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
