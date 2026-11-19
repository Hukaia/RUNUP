#!/usr/bin/env python3
"""`DESIGN.md` décrit-il l'app telle qu'elle est ?

# POURQUOI CE GARDE EXISTE

`DESIGN.md` porte la direction artistique pour qu'elle ne dépende plus d'une conversation. Un tel
document a un mode de défaillance propre, et c'est le pire de tous : **il dérive sans bruit.**
Quelqu'un règle une valeur dans `HZCouleur.swift`, le document continue d'annoncer l'ancienne, et on
le lit en croyant savoir.

Le document cite donc le code, et ce script vérifie la citation. Il ne range AUCUNE valeur
attendue : il lit les deux côtés et les compare.

# CE QU'IL REGARDE

  1. chaque ligne de tableau qui nomme un jeton de `HZCouleur` et donne sa valeur hexadécimale ;
  2. les quatre accents (couleur, et encre d'un petit texte posé dessus) ;
  3. les trois teintes d'intensité (carte et point) ;
  4. les durées de `HZMouvement` que le document cite ;
  5. que les trois questions et le test final sont toujours là ;
  6. que chaque garde cité existe vraiment dans `ci_scripts/`.

# CE QU'IL NE REGARDE PAS

La prose. Les raisons écrites dans `DESIGN.md` ne sont pas vérifiables par un script, et c'est
normal : ce sont des décisions, pas des faits sur le code. Le script tient les NOMBRES, qui sont
les seuls à pouvoir dériver en silence.
"""

import pathlib
import re
import sys

RACINE = pathlib.Path(__file__).resolve().parent.parent
DESIGN = RACINE / "DESIGN.md"
COULEUR = RACINE / "Haizo/DesignSystem/Refonte/HZCouleur.swift"
MOUVEMENT = RACINE / "Haizo/DesignSystem/Refonte/HZMouvement.swift"

# Les phrases qui ne doivent pas disparaître du document. Un garde ne peut pas juger la DA, mais il
# peut refuser qu'on la vide : ce sont les trois questions et le test final, réduits à ce qui les
# identifie sans dépendre de leur ponctuation.
ANCRES = [
    "s'y sent à sa place",
    "le trouve sérieux",
    "qu'il a été généré",
    "reconnaissable comme Haizo",
]

#: Le minimum de lignes vérifiées : un document vidé de ses tableaux passerait sinon en silence.
MINIMUMS = {"jetons": 12, "accents": 4, "intensites": 3}


def _sans_commentaires(source: str) -> str:
    return re.sub(r"//[^\n]*", "", source)


def _cellules(ligne: str) -> list:
    if not ligne.lstrip().startswith("|"):
        return []
    return [c.strip() for c in ligne.strip().strip("|").split("|")]


def _hex(cellule: str):
    m = re.fullmatch(r"`#([0-9A-Fa-f]{6})`", cellule.strip())
    return int(m.group(1), 16) if m else None


def _jeton(cellule: str):
    m = re.fullmatch(r"`([a-zA-Z][a-zA-Z0-9]*)`", cellule.strip())
    return m.group(1) if m else None


def jetons() -> dict:
    """`HZCouleur.<jeton>` → valeur hexadécimale, pour les jetons opaques."""
    src = _sans_commentaires(COULEUR.read_text(encoding="utf-8"))
    return {nom: int(h, 16) for nom, h in
            re.findall(r"static let ([a-zA-Z]+) = Color\(hex: 0x([0-9A-Fa-f]{6})\)", src)}


def _cas(src: str, enum: str, propriete: str) -> dict:
    """`{cas: hex}` pour `var <propriete>: Color { switch … case .x: return Color(hex: 0x…) }`."""
    bloc = src.split(f"enum {enum}", 1)
    if len(bloc) < 2:
        return {}
    corps = bloc[1].split("\nenum ", 1)[0].split("\nstruct ", 1)[0]
    m = re.search(r"var " + propriete + r": Color \{(.*?)\n    \}", corps, re.S)
    if not m:
        return {}
    return {c: int(h, 16) for c, h in
            re.findall(r"case \.([a-z]+): return Color\(hex: 0x([0-9A-Fa-f]{6})\)", m.group(1))}


def durees() -> dict:
    src = _sans_commentaires(MOUVEMENT.read_text(encoding="utf-8"))
    return {nom: round(float(d) * 1000) for nom, d in
            re.findall(r"static let ([a-zA-Z]+) = Animation\.[^\n]*?duration: ([0-9.]+)", src)}


NOMS_ACCENTS = {"Rose": "rose", "Violet": "violet", "Bleu": "bleu", "Vert": "vert"}
NOMS_INTENSITES = {"Endurance, footing facile": "facile", "Récupération": "recuperation",
                   "Sortie longue": "longue"}


def ecarts() -> list:
    if not DESIGN.is_file():
        return [("DESIGN.md", "", "Le fichier n'existe pas. La DA ne doit pas redevenir orale.")]
    texte = DESIGN.read_text(encoding="utf-8")
    src = COULEUR.read_text(encoding="utf-8")
    src_sans = _sans_commentaires(src)
    valeurs = jetons()
    accents = _cas(src_sans, "HZAccent", "couleur")
    cartes = _cas(src_sans, "HZIntensite", "couleur")
    points = _cas(src_sans, "HZIntensite", "point")
    problemes = []
    vus = {"jetons": 0, "accents": 0, "intensites": 0}

    for numero, ligne in enumerate(texte.splitlines(), start=1):
        cs = _cellules(ligne)
        if len(cs) < 2:
            continue
        # 1 — un jeton et sa valeur.
        nom = _jeton(cs[0])
        if nom in valeurs and _hex(cs[1]) is not None:
            vus["jetons"] += 1
            if _hex(cs[1]) != valeurs[nom]:
                problemes.append((f"DESIGN.md:{numero}", f"HZCouleur.{nom}",
                                  f"Le document dit #{_hex(cs[1]):06X}, le code dit #{valeurs[nom]:06X}."))
        # 2 — un accent : sa couleur, puis l'encre d'un petit texte posé dessus.
        if cs[0] in NOMS_ACCENTS and len(cs) >= 3 and _hex(cs[1]) is not None:
            vus["accents"] += 1
            cle = NOMS_ACCENTS[cs[0]]
            if accents.get(cle) != _hex(cs[1]):
                problemes.append((f"DESIGN.md:{numero}", f"accent {cs[0]}",
                                  f"Le document dit #{_hex(cs[1]):06X}, le code dit "
                                  f"{('#%06X' % accents[cle]) if cle in accents else 'rien'}."))
        # 3 — une teinte d'intensité : la carte, puis le point.
        if cs[0] in NOMS_INTENSITES and len(cs) >= 4 and _hex(cs[2]) is not None:
            vus["intensites"] += 1
            cle = NOMS_INTENSITES[cs[0]]
            if cartes.get(cle) != _hex(cs[2]) or points.get(cle) != _hex(cs[3]):
                problemes.append((f"DESIGN.md:{numero}", f"intensité {cs[0]}",
                                  "La carte ou le point ne dit pas ce que dit `HZIntensite`."))

    # 4 — les durées citées : « 220 ms » à côté d'un jeton de `HZMouvement`.
    mouvement = durees()
    for nom, ms in mouvement.items():
        for m in re.finditer(r"`" + nom + r"`[^\n|]*?(\d+)\s*ms", texte):
            if int(m.group(1)) != ms:
                problemes.append(("DESIGN.md", f"HZMouvement.{nom}",
                                  f"Le document dit {m.group(1)} ms, le code dit {ms} ms."))

    # 5 — les trois questions.
    for ancre in ANCRES:
        if ancre not in texte:
            problemes.append((
                "DESIGN.md", ancre,
                "Cette phrase a disparu. Les trois questions et le test final sont la raison "
                "d'être du fichier : un document de DA sans elles est une liste de valeurs."))

    # 6 — chaque garde cité existe-t-il ?
    for cite in sorted(set(re.findall(r"`(check_[a-z_0-9]+\.py)`", texte))):
        if not (RACINE / "ci_scripts" / cite).is_file():
            problemes.append((
                "DESIGN.md", cite,
                "Garde cité qui n'existe pas dans ci_scripts/. Le document promettrait une "
                "barrière que personne ne tient."))

    for quoi, seuil in MINIMUMS.items():
        if vus[quoi] < seuil:
            problemes.append((
                "DESIGN.md", quoi,
                f"Seulement {vus[quoi]} ligne(s) de « {quoi} » vérifiée(s), au moins {seuil} "
                "attendue(s). Soit le tableau a été retiré, soit son format a changé et le garde "
                "ne le lit plus — dans les deux cas il ne garde plus rien."))
    return problemes


def main() -> int:
    problemes = ecarts()
    if problemes:
        print(f"{len(problemes)} écart(s) entre DESIGN.md et l'app :\n")
        for ou, quoi, raison in problemes:
            print(f"  • {ou} — {quoi}")
            print(f"      {raison}\n")
        print("DESIGN.md cite le code ; il ne le recopie pas. Corrigez le document, ou le code.")
        return 1
    print("DESIGN.md décrit l'app telle qu'elle est : jetons, accents, teintes d'intensité, "
          "durées cités, et les trois questions sont là.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
