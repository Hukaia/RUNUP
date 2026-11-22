#!/usr/bin/env python3
"""Refuse un dégradé dans l'interface, et nomme ceux qui ont le droit d'y rester.

# LA RÈGLE, ET POURQUOI ELLE A UNE LISTE D'EXCEPTIONS

Règle 7 du brief : « pas de dégradés dans l'interface ». La direction artistique précise où le
dégradé rose-violet a le droit d'exister : « sur l'icône, le splash et le logo », nulle part
ailleurs.

Appliquée à la lettre, cette règle interdirait aussi le voile noir qui rend un titre lisible
par-dessus un tracé GPS, et l'anneau dont chaque arc vire vers la couleur de son voisin pour se
lire comme un seul ruban. Ni l'un ni l'autre n'est de la décoration : le premier sert à LIRE, le
second PORTE une information. La règle visée est donc celle-ci, et c'est elle que ce script
applique :

    Un dégradé est interdit comme DÉCORATION d'un écran.
    Il reste permis quand il porte une information, quand il rend lisible,
    ou quand il appartient à une image produite — la marque, un avatar.

Les exceptions sont nommées, comptées, et chacune porte sa raison écrite ci-dessous. Tout le
reste est refusé. Une liste d'exceptions sans raisons devient une liste de passe-droits ; celle-ci se
relit.

# POURQUOI UN COMPTE EXACT PAR FICHIER

Autoriser un fichier en bloc rouvrirait la porte qu'on vient de fermer : il suffirait d'ajouter un
dégradé décoratif dans `AvatarView` pour qu'il passe. Chaque entrée dit COMBIEN de dégradés ce
fichier a le droit de porter. Un de plus, un de moins, et le script parle — dans les deux sens,
parce qu'un dégradé qui disparaît est une exception devenue inutile, et qu'elle doit sortir de la
liste au lieu d'y dormir.

# CE QU'IL NE VOIT PAS

Un dégradé fabriqué autrement : une image qui en contient un, un `Canvas`, un `.shadow` assez
large pour en faire un. Ce script lit du texte Swift ; ce qui se voit à l'œil se voit sur une
capture, et c'est l'autre moitié du travail.
"""
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from swift import sans_commentaires  # noqa: E402

RACINE = pathlib.Path(__file__).resolve().parent.parent
CIBLES = ["Haizo", "HaizoWatch", "HaizoWidgets"]

# `.gradient` est le raccourci de SwiftUI (`Color.rose.gradient`), et il est TOUJOURS précédé
# d'un identifiant — une première version excluait justement ce cas-là par une anti-recherche
# arrière, et ne voyait donc que ce qui n'existe pas. `(?!\w)` suffit à écarter
# `seg.gradientStartDegrees`, qui n'est pas un dégradé mais un angle.
DEGRADE = re.compile(
    r"\b(LinearGradient|RadialGradient|AngularGradient|EllipticalGradient|MeshGradient)\s*\(|"
    r"\.gradient(?!\w)")

#: fichier → (nombre de dégradés autorisés, pourquoi)
PERMIS = {
    # ── 1. LA MARQUE ──────────────────────────────────────────────────────────────────────
    #
    # Le dégradé rose-violet du logo, celui de l'icône : la direction artistique le permet « sur
    # l'icône, le splash et le logo ». Un seul, défini une fois dans `HZMarque.degrade` et lu par la
    # tuile de la marque (lancement, carte de partage, vidéo). La tuile le portait avant le 15 novembre,
    # puis a pris la couleur d'accentuation — et le logo à l'ouverture n'était plus celui de l'icône.
    "Haizo/DesignSystem/Refonte/HZMarque.swift": (1, "le dégradé rose-violet du logo : celui de l'icône, que la tuile de la marque porte sur le lancement et les images de partage"),

    # ── 2. UNE IMAGE PRODUITE, PAS UN ÉCRAN ───────────────────────────────────────────────────
    #
    # Elle a tenu deux entrées : la carte de partage (style « Haizo ») et les images de la vidéo
    # (deux halos et un titre). Les deux sont passées en aplats le 20 novembre — trace d'accent d'un
    # seul trait, fond noir franc, chiffres blancs — et sont sorties de la liste avec les dégradés
    # qu'elles couvraient. Une image qu'on poste porte la DA comme un écran.

    # ── 3. UN VOILE QUI SERT À LIRE ───────────────────────────────────────────────────────────

    # ── 4. LA QUATRIÈME CATÉGORIE A ÉTÉ FERMÉE ────────────────────────────────────────────────
    #
    # Elle s'appelait « la couleur porte une information » et tenait trois entrées : l'anneau des
    # objectifs, le même anneau dans le widget, et l'aire sous la courbe des stats. Les trois
    # raisons étaient bonnes dans leur cadre — l'anneau reliait trois teintes par ses jonctions,
    # l'aire disait « ce n'est pas une surface pleine » par son fondu.
    #
    # Le brief du 15 novembre retire le cadre : l'anneau est mono-accent, et il n'y a plus trois
    # teintes à relier ; l'aire est un aplat à 8 %, et huit pour cent disent la même chose que le
    # fondu sans dégradé. Une exception dont la raison a disparu n'est plus une exception, c'est
    # un passe-droit — et le compte exact par fichier fait que le script le dit tout seul : il se
    # plaint aussi d'un dégradé qui MANQUE.
    #
    # Les trois entrées sont donc parties avec les dégradés qu'elles couvraient, le 16 novembre.
}


def releve(racine=RACINE):
    """fichier (relatif) → nombre de dégradés dans son code."""
    compte = {}
    for cible in CIBLES:
        dossier = racine / cible
        if not dossier.is_dir():
            continue
        for f in sorted(dossier.rglob("*.swift")):
            n = len(DEGRADE.findall(sans_commentaires(f.read_text(encoding="utf-8"))))
            if n:
                compte[f.relative_to(racine).as_posix()] = n
    return compte


def verifier(racine=RACINE, permis=None):
    permis = PERMIS if permis is None else permis
    compte = releve(racine)
    plaintes = []
    for fichier, n in sorted(compte.items()):
        if fichier not in permis:
            plaintes.append(
                f"{fichier} : {n} dégradé(s) dans l'interface. La règle 7 les interdit — "
                f"pose un aplat, ou ajoute ce fichier à `PERMIS` avec la raison écrite.")
            continue
        attendu, _ = permis[fichier]
        if n != attendu:
            plaintes.append(
                f"{fichier} : {n} dégradé(s), {attendu} autorisé(s). "
                + ("Un de plus que ce que la raison couvre." if n > attendu
                   else "Un de moins : l'exception a servi, elle ne sert plus. Retire-la."))
    for fichier in sorted(permis):
        if fichier not in compte:
            plaintes.append(
                f"{fichier} : plus aucun dégradé, mais le fichier est encore dans `PERMIS`. "
                f"Une exception qui dort finit par servir à autre chose.")
    return plaintes


def main():
    plaintes = verifier()
    for p in plaintes:
        print(f"✗ {p}")
    if plaintes:
        print(f"\n{len(plaintes)} problème(s). Les exceptions et leurs raisons sont en tête de "
              f"ci_scripts/check_degrade.py.")
        return 1
    total = sum(n for n, _ in PERMIS.values())
    print(f"✓ Aucun dégradé décoratif. {total} autorisés dans {len(PERMIS)} fichiers, chacun avec "
          f"sa raison.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
