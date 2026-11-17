#!/usr/bin/env python3
r"""Qui décide de QUEL JOUR ON EST doit lire l'horloge de la scène.

# POURQUOI CE CONTRÔLE EXISTE

La fiche App Store se photographie sur une scène FIGÉE : `Demonstration.maintenant` rend « le
dernier dimanche à 18 h » pendant une campagne, et `.now` partout ailleurs. Sans elle, l'image
livrée à Apple dépendait du jour et de l'heure où la machine tournait — une app vide deux jours
sur sept, mesuré le 14 novembre.

ELLE A ÉTÉ POSÉE EN ÉNUMÉRANT SES LECTEURS, TROIS FOIS, ET IL EN MANQUAIT ENCORE SEPT.

  · 14 novembre — la graine est figée, pas l'app. L'accueil montrait 0,0 / 24 km.
  · 16 novembre — trois lecteurs ajoutés ; la remise à zéro du jour, la date de l'en-tête et les
    quantièmes du ruban manquaient. « Ta journée » est tombé à 0/3 sur la capture.
  · 17 novembre — `UserProfile.todayWeekdayIndex` lisait `.now`. La campagne 221 a franchi
    minuit, on est passé au mardi, mardi est un jour de REPOS dans la semaine de démonstration,
    et l'accueil de la fiche a perdu sa carte de séance : plus de durée, plus d'allure, PLUS DE
    BOUTON « DÉMARRER ». La carte portait deux horloges — son titre venait de la scène, son état
    de repos de la machine.

J'avais écrit la leçon le 16 sans en tirer la conséquence : « j'ai figé une horloge EN ÉNUMÉRANT
SES LECTEURS, et énumérer est exactement la façon d'en oublier un. » Une liste tenue à la main ne
se répare pas en la relisant mieux. Il faut que l'oubli soit IMPOSSIBLE.

# CE QUI EST VÉRIFIÉ

Toute expression qui lit l'horloge RÉELLE — `.now` ou `Date()` — en même temps qu'elle demande un
JOUR DE SEMAINE ou une SEMAINE CALENDAIRE est refusée, sauf déclaration écrite. Les deux motifs
qui comptent :

    Calendar…component(.weekday, from: .now)      quel jour on est
    …dateInterval(of: .weekOfYear, for: .now)     ce que la semaine courante contient

CE QU'IL NE REGARDE PAS, et c'est délibéré : les 170 autres lectures de l'horloge. Horodater une
course, mesurer un temps écoulé, dater un message — tout cela DOIT prendre l'heure réelle, même
en démonstration, et un garde qui les refuserait serait désactivé la semaine suivante. On ne juge
que la question « quel jour sommes-nous », parce que c'est la seule dont la scène dépend.

Les exceptions portent une raison écrite et sont comptées exactement : une qui ne correspond plus
à rien fait échouer le contrôle, dans les deux sens.
"""
import pathlib
import re
import sys

RACINE = pathlib.Path(__file__).resolve().parent.parent
CIBLES = ["Haizo", "HaizoWidgets"]

#: Les deux façons de demander « quel jour sommes-nous » à l'horloge réelle.
HORLOGE = re.compile(
    r"(?:component\(\s*\.weekday\s*,\s*from:\s*|dateInterval\(\s*of:\s*\.weekOfYear\s*,\s*for:\s*)"
    r"(?:\.now\b|Date\(\))")

#: fichier → (nombre d'emplois autorisés, pourquoi).
#:
#: VIDE, ET C'EST LE BON ÉTAT. Le widget serait le candidat naturel — il vit dans une extension,
#: ne connaît pas la démonstration et n'est jamais photographié par la campagne — mais il passe
#: par `WidgetWeekDay.rangDuJour`, qui prend sa date en paramètre. Rien ne reste.
PERMIS: dict = {}


def ecarts(racine=None, permis=None) -> list:
    racine = racine or RACINE
    permis = PERMIS if permis is None else permis
    problemes, compte = [], {}
    for dossier in CIBLES:
        base = racine / dossier
        if not base.exists():
            continue
        for chemin in sorted(base.rglob("*.swift")):
            relatif = chemin.relative_to(racine).as_posix()
            for numero, ligne in enumerate(chemin.read_text(encoding="utf-8").splitlines(), 1):
                if ligne.lstrip().startswith("//"):
                    continue
                for _ in HORLOGE.finditer(ligne):
                    compte[relatif] = compte.get(relatif, 0) + 1
                    if relatif in permis:
                        continue
                    problemes.append(
                        f"{relatif}:{numero} : le jour de la semaine est lu sur l'horloge "
                        f"RÉELLE.\n"
                        f"    Pendant une campagne de captures, la scène est figée au dernier "
                        f"dimanche 18 h.\n"
                        f"    Un lecteur qui prend `.now` fait porter DEUX HORLOGES au même "
                        f"écran.\n"
                        f"    `Demonstration.maintenant`, ou une entrée dans PERMIS avec sa "
                        f"raison.\n"
                        f"    {ligne.strip()[:110]}")

    for relatif, (attendu, raison) in sorted(permis.items()):
        reel = compte.get(relatif, 0)
        if reel != attendu:
            problemes.append(
                f"{relatif} : {reel} lecture(s) de l'horloge réelle, {attendu} déclarée(s).\n"
                f"    Raison inscrite : {raison}\n"
                f"    Un de plus : il faut le justifier. Un de moins : l'entrée doit maigrir.")
    return problemes


def main() -> int:
    problemes = ecarts()
    if problemes:
        print(f"{len(problemes)} lecture(s) d'horloge hors de la scène :\n")
        for p in problemes:
            print("  • " + p)
        return 1
    total = sum(n for n, _ in PERMIS.values())
    print(f"Horloge de la scène : aucune lecture du jour courant sur `.now`, "
          f"{total} déclarée(s) dans {len(PERMIS)} fichier(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
