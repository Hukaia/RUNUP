#!/usr/bin/env python3
r"""Un workflow déclenché sur une branche qui n'existe pas ne se plaint jamais.

# POURQUOI CE CONTRÔLE EXISTE

Le 16 novembre, le renommage de la marque (`f4dcc9b`) a remplacé `claude/runup-ios-swiftui-app-5b1yv6`
par `claude/haizo-ios-swiftui-app-5b1yv6` dans `testflight.yml`. CETTE BRANCHE N'EXISTE PAS. Le
développement continue sur l'ancienne, qui est la seule que Charlotte a nommée.

`testflight.yml` a donc cessé de partir, EN SILENCE, pendant douze commits — tout le brief de
direction artistique. GitHub ne signale pas un déclencheur qui ne correspond à rien : il n'y a
pas d'exécution, donc pas de rouge, donc rien à remarquer. Et ce fichier porte à lui seul 122
appels de gardes, plus la seule build qu'on puisse installer sur un téléphone.

Un renommage de marque a touché une ADRESSE. Un nom de branche, un identifiant de paquet, un
domaine ne sont pas des mots de marque : ce sont des endroits où quelque chose se trouve.
Charlotte l'avait d'ailleurs tranché le même jour pour les deux autres — le paquet reste
`com.hicsuntco.runup`, le domaine reste `runup-nu.vercel.app` — et la branche a glissé parce
qu'elle n'était pas dans la question.

CE QU'UN CONTRÔLE DE COHÉRENCE N'AURAIT PAS VU. Le renommage a changé TOUTES les occurrences, de
la même façon : les sept étaient d'accord entre elles, et toutes les sept étaient fausses.
Vérifier qu'un nom est écrit partout pareil ne dit rien. IL FAUT LE COMPARER À LA VRAIE BRANCHE.

# CE QUI EST VÉRIFIÉ

Tout nom de branche de travail écrit dans le dépôt — forme `claude/…` — est la branche courante.
Deux endroits comptent :

1. les `on: push: branches:` des workflows, où une branche fausse éteint le workflow ;
2. partout ailleurs — un défaut de documentation, mais du même genre : `PROGRESS.md` affirmait
   « confirmé dans les réglages Vercel le 7 novembre : Branch Tracking porte `claude/haizo-…` »,
   une OBSERVATION DATÉE que le renommage a rendue fausse. Un relevé qu'on réécrit à l'aveugle
   ne relève plus rien.

Un `**` ou un `*` dans la liste des branches est accepté : il couvre la branche courante par
construction. Les exceptions portent une raison écrite et sont comptées exactement, donc une qui
ne correspond plus à rien fait échouer le contrôle.

CE QU'IL NE DIT PAS : que la branche courante est la bonne. Il dit que le dépôt est d'accord avec
elle. Le jour où Charlotte renomme la branche, ce contrôle rougit partout où il faut passer.
"""
import os
import pathlib
import re
import subprocess
import sys

RACINE = pathlib.Path(__file__).resolve().parent.parent

# La forme d'un nom de branche de travail de ce dépôt.
BRANCHE = re.compile(r"claude/[A-Za-z0-9._-]+")

# Les fichiers où un nom de branche peut légitimement être écrit sans être la branche courante,
# avec le nombre exact d'occurrences et la raison. Le compte est exact dans les deux sens : un nom
# de branche inconnu qui apparaît sonne, et une entrée devenue inutile sonne aussi.
AUTRES = ("deux branches qui EXISTENT vraiment sur le distant et portent du travail qui n'est ni "
          "sur `main` ni ici — `claude/running-club-finance-wwuq46` (neuf commits, dont une "
          "direction artistique concurrente) et `claude/new-session-otcd8z` (`ef3ad89`). Les "
          "nommer est tout l'intérêt de la note : c'est le seul endroit où ce travail est "
          "répertorié.")

PERMIS: dict[str, tuple[int, str]] = {
    # Le journal est le seul endroit qui doive nommer ce qui a changé, et il le fait de deux
    # façons : il répertorie les deux branches qui existent vraiment, et il CITE la branche morte
    # du 16 novembre pour raconter la panne — dont le relevé Vercel faux, recopié tel qu'il était
    # écrit. Un journal qu'un garde empêche de citer une adresse morte ne raconte plus rien.
    #
    # Le compte reste exact, et c'est voulu : une citation de plus demande de relire si c'est un
    # RELEVÉ (alors il est faux, et il faut le corriger) ou une CITATION (alors elle appartient au
    # récit). C'est la distinction qui a coûté quatre documents ce jour-là.
    "PROGRESS.md": (5, AUTRES + " S'y ajoutent deux citations de la branche morte "
                       "`claude/haizo-…`, dans le récit de la panne du 16 novembre."),
    "PHASE2.md": (2, AUTRES),
    "RELEASE.md": (2, AUTRES),
    # Celui-ci est d'une autre nature, et il compte : un garde doit pouvoir CITER l'orthographe
    # qu'il refuse. C'est la leçon du 16 novembre — un garde se vérifie en changeant l'écriture
    # qu'il surveille — et elle ne s'écrit pas sans écrire l'écriture fautive.
    "ci_scripts/check_branche.py": (5, "le garde cite les branches dont il parle : la fausse qui "
                                       "l'a fait naître, deux fois dans sa documentation et une "
                                       "fois dans la dispense du journal juste au-dessus, plus "
                                       "les deux vraies dans la raison commune. Sans elles, ni la "
                                       "raison d'être du contrôle ni ses dispenses ne sont "
                                       "lisibles. TROIS DE CES CINQ SONT ARRIVÉES EN ÉCRIVANT CES "
                                       "ENTRÉES, et le garde les a comptées à chaque fois, sans "
                                       "que j'aie eu à le relire. C'est exactement son travail, "
                                       "et c'est aussi la leçon du jour : un garde se vérifie en "
                                       "changeant ce qu'il surveille."),
}

# Les extensions où l'on cherche. Pas de binaire, pas de dossier de dépendances.
SUFFIXES = {".yml", ".yaml", ".md", ".py", ".sh", ".json", ".swift", ".js", ".txt"}
IGNORES = {".git", "node_modules", "build", ".build", "DerivedData", "Pods"}

# LES FICHIERS DE CAS SONT HORS PÉRIMÈTRE, ET C'EST UNE RÈGLE, PAS UNE DISPENSE.
#
# Un `ci_scripts/test_*.py` existe pour NOMMER des entrées fausses : `test_branche.py` écrit une
# vingtaine de branches fictives, et c'est ce qui prouve que le contrôle refuse. Les compter
# obligerait à retoucher le nombre à chaque cas ajouté — le meilleur moyen d'obtenir un garde
# qu'on desserre d'un chiffre plutôt qu'on ne corrige.
#
# Ce que ça n'ouvre pas : un nom de branche dans un fichier de cas n'est ni un déclencheur ni un
# relevé. C'est un gabarit. Les `check_*.py`, eux, RESTENT dans le périmètre : leur documentation
# est de la prose, elle se lit, et elle peut vieillir — celle-ci porte ses quatre citations
# déclarées.
CAS = re.compile(r"^ci_scripts/test_[a-z_]+\.py$")


def branche_courante() -> str:
    """La branche sur laquelle on est — en CI comme en local."""
    # GitHub Actions la donne directement, et c'est la seule source juste quand le checkout est
    # détaché, ce qu'il est par défaut.
    depuis_ci = os.environ.get("GITHUB_REF_NAME", "").strip()
    if depuis_ci:
        return depuis_ci
    try:
        sortie = subprocess.run(["git", "branch", "--show-current"], cwd=RACINE,
                                capture_output=True, text=True, timeout=10)
        return sortie.stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def fichiers():
    for f in sorted(RACINE.rglob("*")):
        if not f.is_file() or f.suffix not in SUFFIXES:
            continue
        relatif = f.relative_to(RACINE)
        if any(p in IGNORES for p in relatif.parts):
            continue
        if CAS.match(relatif.as_posix()):
            continue
        yield f


def ecarts(racine: pathlib.Path | None = None, courante: str | None = None,
           permis: dict | None = None) -> list[str]:
    global RACINE
    ancienne = RACINE
    if racine is not None:
        RACINE = racine
    try:
        courante = courante if courante is not None else branche_courante()
        permis = PERMIS if permis is None else permis
        problemes: list[str] = []

        if not courante:
            return ["La branche courante est introuvable.\n"
                    "    Ni GITHUB_REF_NAME ni `git branch --show-current` ne répondent.\n"
                    "    Ce contrôle compare le dépôt à sa branche : sans elle il ne peut rien "
                    "dire, et se taire serait pire."]

        compte: dict[str, int] = {}
        for f in fichiers():
            relatif = str(f.relative_to(RACINE))
            try:
                lignes = f.read_text(encoding="utf-8").splitlines()
            except UnicodeDecodeError:
                continue
            for numero, ligne in enumerate(lignes, 1):
                for trouve in BRANCHE.finditer(ligne):
                    nom = trouve.group(0)
                    if nom == courante:
                        continue
                    compte[relatif] = compte.get(relatif, 0) + 1
                    if relatif in permis:
                        continue
                    dans_declencheur = relatif.startswith(".github/workflows/")
                    problemes.append(
                        f"{relatif}:{numero} : « {nom} » n'est pas la branche courante "
                        f"« {courante} ».\n"
                        + ("    C'est un `on: push: branches:` : le workflow ne partira jamais, "
                           "et son silence ne se voit pas.\n" if dans_declencheur else
                           "    Un nom de branche écrit à côté de la vraie.\n")
                        + "    Le corriger, ou une entrée dans PERMIS avec sa raison.")

        for relatif, (attendu, raison) in sorted(permis.items()):
            reel = compte.get(relatif, 0)
            if reel != attendu:
                problemes.append(
                    f"{relatif} : {reel} nom(s) de branche étrangers, {attendu} déclaré(s).\n"
                    f"    Raison inscrite : {raison}\n"
                    f"    Un de plus : il faut le justifier. Un de moins : l'entrée doit maigrir.")
        return problemes
    finally:
        RACINE = ancienne


def main() -> int:
    courante = branche_courante()
    problemes = ecarts(courante=courante)
    if problemes:
        print(f"{len(problemes)} écart(s) sur le nom de la branche :\n")
        for p in problemes:
            print("  " + p)
        return 1
    declencheurs = 0
    for f in sorted((RACINE / ".github/workflows").glob("*.yml")):
        if re.search(r"(?ms)^\s*branches:\n(\s+- .*\n)+", f.read_text(encoding="utf-8")):
            declencheurs += 1
    print(f"Branche : « {courante} ». Aucun nom de branche étranger dans le dépôt, "
          f"et {declencheurs} workflow(s) déclarent une liste de branches.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
