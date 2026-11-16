#!/usr/bin/env python3
"""La teinte d'un en-tête de carte est l'exception, et elle doit nommer quelque chose.

POURQUOI CETTE RÈGLE EXISTE.

Elle était passée explicitement à 55 endroits, sur huit valeurs, sans aucune règle. Sur la seule
feuille du triathlon : « Où passe la journée » violet, « On ne mange pas dans l'eau » rose,
« Les transitions » vert, « La combinaison » violet. Sur une seule rangée de l'écran Stats :
règle rose, coureur violet, horloge turquoise. Trois tuiles côte à côte, trois teintes.

Trois de ces couleurs — `lime`, `cyan`, `amber` — ne suivent pas le thème choisi : ce sont des
valeurs fixes. Un accent cyan laissait donc des icônes vertes et ambrées éparpillées dans une app
qu'on venait de repeindre.

Et c'est le coût réel : `lime` veut dire MIEUX, `amber` veut dire MOINS BIEN. L'écran Stats s'en
sert correctement pour ses pastilles d'écart, à deux centimètres d'une icône décorative de la même
couleur. Dépenser une couleur sémantique en décoration, c'est vider de son sens le seul endroit
où elle disait quelque chose.

Aucun compilateur ne peut refuser `tint: RUColor.lime` : c'est une couleur valide passée à un
paramètre qui l'accepte.
"""
import re, sys, pathlib

RACINE = pathlib.Path(__file__).resolve().parent.parent

# fichier → { ligne : raison }. La ligne est indicative ; c'est le COMPTE par fichier qui est
# tenu, pour qu'un ajout de code au-dessus ne fasse pas échouer le build pour rien.
AUTORISE = {
    "Haizo/Views/Profile/ProfileView.swift":
        (1, "« Session expirée » en ambre : la couleur nomme un avertissement"),
    "Haizo/Views/Race/RacePageView.swift":
        (1, "« Je prépare cette course » en vert : la couleur nomme un état confirmé"),
    "Haizo/Views/Profile/ShoesView.swift":
        (1, "« Retirées » en gris : volontairement éteint, ce sont des archives"),
    "Haizo/Views/Stats/StatsView.swift":
        (6, "le bloc Vélo, marqué en turquoise d'un bout à l'autre — un repère de discipline, "
            "et non une décoration, parce qu'il est tenu sur toute la section ; plus la flamme "
            "de la série, verte quand elle court et grise quand elle est cassée — la seule "
            "teinte conditionnelle de l'app, et c'est ce qui la justifie : elle ne décore pas "
            "la flamme, elle dit si la flamme est allumée"),
}

# UN APPEL, PAS UNE LIGNE — et c'est une correction de ce script lui-même.
#
# La première version cherchait `RUCardHeader(... tint:` sur UNE ligne. Deux teintes lui ont
# échappé parce qu'elles vivaient sur la ligne de continuation d'un appel écrit en plusieurs
# lignes, et le script a rendu « tout le reste sur l'accent » pendant que l'écran Stats gardait
# une flamme verte. C'est la capture qui l'a dit, pas lui.
#
# On suit donc la profondeur de parenthèses depuis l'ouverture de l'appel jusqu'à sa fermeture,
# et on regarde `tint:` n'importe où dedans.
OUVERTURE = re.compile(r"(?:RUCardHeader|RUStatTile)\(")
PROFONDEUR = 12

fautes = []
compte = {}
for chemin in sorted(RACINE.rglob("*.swift")):
    rel = str(chemin.relative_to(RACINE))
    lignes = chemin.read_text().split("\n")
    for num, ligne in enumerate(lignes, 1):
        if ligne.lstrip().startswith("//") or not OUVERTURE.search(ligne):
            continue
        profondeur, corps = 0, []
        for suite in lignes[num - 1:num - 1 + PROFONDEUR]:
            corps.append(suite)
            profondeur += suite.count("(") - suite.count(")")
            if profondeur <= 0 and len(corps) > 0:
                break
        # Les lignes de commentaire du corps ne comptent pas : une note qui mentionne `tint:`
        # n'est pas une teinte.
        if not any("tint:" in c for c in corps if not c.lstrip().startswith("//")):
            continue
        compte[rel] = compte.get(rel, 0) + 1
        if rel not in AUTORISE:
            fautes.append(f"{rel}:{num} : une teinte posée sur un en-tête de carte.\n"
                          f"    Si elle nomme vraiment quelque chose, inscris le fichier dans\n"
                          f"    AUTORISE de ci_scripts/check_teintes.py avec sa raison. Sinon,\n"
                          f"    retire-la : le défaut est l'accent de l'app.\n"
                          f"    {ligne.strip()}")

for rel, (attendu, raison) in sorted(AUTORISE.items()):
    n = compte.get(rel, 0)
    if n != attendu:
        fautes.append(f"{rel} : {n} teinte(s), {attendu} déclarée(s).\n"
                      f"    Raison inscrite : {raison}")

# ── LA PALETTE PARALLÈLE DE LA CLOCHE ────────────────────────────────────────────────────────
#
# Le relevé du 16 novembre a trouvé NEUF couleurs de notification écrites en dur, une par site
# d'appel : trois roses voisins — dont deux qui n'étaient pas l'accent — deux verts, un orange,
# un violet, un turquoise et un ambre. Personne ne les avait choisies ensemble.
#
# C'est le même défaut que les teintes d'en-tête ci-dessus, dans un autre coin de l'app : une
# couleur posée au moment où on écrit la ligne, qui ne s'accorde avec rien et ne dit rien. Et il
# était plus difficile à voir, parce qu'une notification ne paraît qu'après un geste précis — une
# course récupérée, une paire usée — donc jamais sur une capture.
#
# Ce qu'une cloche a besoin de dire tient en trois registres, et `AppNotification` les nomme :
# `accent` pour un fait, `avertissement` pour un écart à surveiller, `incident` pour une panne
# dont on s'est relevé.
CLOCHE_EN_DUR = re.compile(r"colorHex:\s*(0x[0-9A-Fa-f]{6})")

#: valeur → pourquoi cette couleur-là n'est pas encore passée par un nom.
#:
#: VIDE, ET C'EST LE BON ÉTAT. Elle a porté une entrée pendant une heure, le 16 novembre : la
#: flamme de la série, `0xFF6B4A`, parce que le brief demandait le gris quand ce fichier
#: justifiait la couleur comme porteuse de sens. La contradiction était réelle et l'entrée
#: servait à la rendre visible plutôt qu'à la cacher.
#:
#: Elle a été tranchée par une synthèse, pas par un camp : ce qui devait partir était une
#: TROISIÈME couleur dans une app qui n'en a qu'une, pas le fait qu'allumée et éteinte se
#: distinguent. La flamme est à l'accent quand la série court, au gris quand elle est cassée.
#: L'exception part donc avec la question qui la justifiait.
CLOCHE_TOLEREE = {}

for f in sorted((RACINE / "Haizo").rglob("*.swift")):
    for num, ligne in enumerate(f.read_text(encoding="utf-8").splitlines(), start=1):
        if ligne.lstrip().startswith("//"):
            continue
        for valeur in CLOCHE_EN_DUR.findall(ligne):
            if valeur in CLOCHE_TOLEREE:
                continue
            rel = f.relative_to(RACINE).as_posix()
            fautes.append(
                f"{rel}:{num} : une couleur de cloche écrite en dur, {valeur}.\n"
                f"    Passe par `AppNotification.accent`, `.avertissement` ou `.incident`.\n"
                f"    Si ce message dit vraiment autre chose, nomme la valeur dans\n"
                f"    `AppNotification` et explique ce qu'elle dit.\n"
                f"    {ligne.strip()[:110]}")

# ── LES TROIS COULEURS SÉMANTIQUES, PARTOUT OÙ ELLES SONT POSÉES ─────────────────────────────
#
# CE QUE LA PREMIÈRE VERSION NE VOYAIT PAS, ET CE QUE ÇA A COÛTÉ.
#
# Ce script n'inspectait que `RUCardHeader(tint:)` et `RUStatTile(tint:)`. Une couleur posée en
# `.foregroundColor(RUColor.lime)` — l'écriture la plus courante — était HORS DE SA PORTÉE.
#
# Le 16 novembre à midi, la flamme de la série est passée « allumée à l'accent, éteinte au gris »
# sur l'écran des stats, dans le bilan hebdo, dans la feuille de débriefing et dans le widget.
# PAS SUR L'ACCUEIL, l'écran qu'on ouvre tous les jours. Le garde s'est tu, et il avait raison de
# se taire : la pastille de série est un `.foregroundColor`. Le relevé complet en a trouvé
# SOIXANTE-QUATORZE, dans trente-deux fichiers.
#
# LA RÈGLE EST LA MÊME QU'EN HAUT, appliquée à toutes les écritures : `lime` veut dire MIEUX,
# `amber` veut dire MOINS BIEN, `cyan` ne veut rien dire du tout. Une couleur sémantique dépensée
# en décoration est vidée de son sens là où elle disait quelque chose.
DIRECTES = re.compile(r"RUColor\.(lime|cyan|amber|amberText)\b")

AVERTISSEMENT = ("un avertissement : `amber` y veut dire MOINS BIEN, et c'est exactement ce que "
                 "la ligne annonce. C'est l'emploi qui justifie la couleur, pas celui qui la vide.")

#: fichier → (nombre d'emplois directs autorisés, pourquoi)
DIRECTES_AUTORISEES = {
    # ── 1. DES AVERTISSEMENTS ─────────────────────────────────────────────────────────────────
    "Haizo/Views/Auth/AccountSwitchSheet.swift": (1, AVERTISSEMENT),
    "Haizo/Views/Club/EditActivitySheet.swift": (1, AVERTISSEMENT),
    "Haizo/Views/Coach/CoachView.swift": (3, AVERTISSEMENT + " La bulle d'erreur du coach : "
                                          "l'icône, son texte et son bord."),
    "Haizo/Views/Home/Sheets/MoveSessionSheet.swift": (1, AVERTISSEMENT),
    "Haizo/Views/Live/RecapView.swift": (1, AVERTISSEMENT),
    "Haizo/Views/Onboarding/RaceDetailsStepView.swift": (2, AVERTISSEMENT + " Un dénivelé de "
                                                        "course qu'on n'a pas renseigné."),
    "Haizo/Views/Onboarding/RunningDaysStepView.swift": (1, AVERTISSEMENT + " Moins de jours "
                                                         "cochés que le minimum de l'objectif."),
    "Haizo/Views/Profile/ProfileView.swift": (1, AVERTISSEMENT + " « Session expirée »."),
    "Haizo/Views/Profile/ShoesView.swift": (2, AVERTISSEMENT + " Une paire au-delà de 80 % de sa "
                                            "durée de vie, et la ligne qui le dit."),
    "Haizo/Views/Race/RacePageView.swift": (3, AVERTISSEMENT + " Un bandeau d'alerte de course, "
                                            "plus la teinte d'« état confirmé » déjà déclarée "
                                            "en haut de ce fichier."),
    "Haizo/Views/Stats/HistoryView.swift": (1, AVERTISSEMENT),
    "Haizo/Views/Stats/StatsView.swift": (6, "cinq pour le bloc Vélo, marqué en turquoise d'un "
                                          "bout à l'autre — un repère de discipline tenu sur "
                                          "toute la section, et non une décoration — plus une "
                                          "charge d'entraînement élevée, qui est un "
                                          "avertissement."),

    # ── 2. DEUX PALETTES QUI ATTENDENT UNE DÉCISION ───────────────────────────────────────────
    #
    # Elles ne sont pas des oublis : ce sont deux tables cohérentes, chacune décidée une fois,
    # qui distribuent une couleur par CATÉGORIE. Le brief du 15 novembre les condamne toutes les
    # deux sans les nommer — « un seul accent #F0225F […] tout le reste disparaît » — et la
    # première a même sa consigne précise au point 4 : « les badges deviennent des cercles 64 px
    # sur fond #F3EEF4, icône noire, ACCENT POUR LES OBTENUS ».
    #
    # Les retirer touche sept écrans pour la première et l'onboarding entier pour la seconde.
    # C'est un chantier, pas une ligne, et il attend d'être fait plutôt que d'être oublié : le
    # compte ci-dessous le dira tant qu'il reste à faire.
    "Haizo/Models/ClubBadgeCatalog.swift": (
        3, "une couleur par FAMILLE de badge — série en ambre, dénivelé en lime, volume en "
           "turquoise. Sept écrans la lisent. Le point 4 du brief dit ce qui doit la remplacer : "
           "l'accent pour les obtenus, le gris pour les autres."),
    "Haizo/DesignSystem/Colors.swift": (
        3, "`GoalType.tint` — une couleur par OBJECTIF, posée sur les cartes de l'onboarding. "
           "Huit teintes dont trois sémantiques. Le brief n'en veut qu'une."),
}

compte_direct = {}
for f in sorted((RACINE / "Haizo").rglob("*.swift")):
    rel = f.relative_to(RACINE).as_posix()
    for num, ligne in enumerate(f.read_text(encoding="utf-8").splitlines(), start=1):
        if ligne.lstrip().startswith("//"):
            continue
        for trouve in DIRECTES.finditer(ligne):
            compte_direct[rel] = compte_direct.get(rel, 0) + 1
            if rel not in DIRECTES_AUTORISEES:
                fautes.append(
                    f"{rel}:{num} : `RUColor.{trouve.group(1)}` posé en direct.\n"
                    f"    `lime` veut dire MIEUX, `amber` veut dire MOINS BIEN, `cyan` ne dit\n"
                    f"    rien. Si celle-ci nomme vraiment quelque chose, inscris le fichier\n"
                    f"    dans DIRECTES_AUTORISEES avec sa raison. Sinon, c'est l'accent ou le\n"
                    f"    gris.\n"
                    f"    {ligne.strip()[:110]}")

for rel, (attendu, raison) in sorted(DIRECTES_AUTORISEES.items()):
    n = compte_direct.get(rel, 0)
    if n != attendu:
        fautes.append(f"{rel} : {n} emploi(s) direct(s), {attendu} déclaré(s).\n"
                      f"    Raison inscrite : {raison}\n"
                      f"    Un de plus : il faut le justifier. Un de moins : l'entrée maigrit.")

if fautes:
    print("Des teintes hors de ce qui est déclaré :\n")
    for f in fautes:
        print("  • " + f)
    sys.exit(1)

print(f"Teintes d'en-tête : {sum(compte.values())} déclarée(s) dans {len(AUTORISE)} fichiers. "
      f"Emplois directs de lime/cyan/ambre : {sum(compte_direct.values())} dans "
      f"{len(DIRECTES_AUTORISEES)} fichiers — des avertissements, un repère de discipline, "
      f"et deux palettes qui attendent une décision.")
