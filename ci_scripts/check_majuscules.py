#!/usr/bin/env python3
"""Refuse un libellé écrit TOUT EN CAPITALES, et nomme ceux qui ont le droit d'y rester.

# LA RÈGLE

Point 1 du brief du 15 novembre : « Supprimer les majuscules espacées ("TA JOURNÉE", "CE QU'IL
REGARDE", "ALLURE CIBLE") : ce sont des labels en 12 gris, casse normale. »

Les trois exemples sont des LABELS, et c'est ce que la règle vise. Un bouton en capitales est
autre chose : une convention assumée, que le brief ne nomme nulle part. La règle appliquée est
donc celle-ci :

    Un libellé affiché tout en capitales est interdit.
    Restent permis : un bouton, une image qu'on exporte, une constante technique.

# POURQUOI CE GARDE EXISTE

Les capitales ne vivaient pas à un seul endroit. Elles étaient de TROIS façons différentes, et
retirer l'une laissait les deux autres :

  • `.textCase(.uppercase)` posé sur la vue — sept emplois ;
  • `tracking(1.5)` avec une chaîne déjà en capitales — cinq copies du même style, dont
    `eyebrowStyle` s'était extrait le 15 novembre pendant que les cinq autres gardaient le leur ;
  • les CAPITALES DANS LA CHAÎNE ELLE-MÊME, au catalogue, en trois langues — quarante-trois
    clés. Celles-là ne se voient pas en relisant une vue : « ÉCHAUFFEMENT » est un littéral
    comme un autre.

C'est la troisième qui demande un garde. Les deux premières se voient à la lecture ; une clé de
catalogue en capitales, non.

# CE QU'IL NE VOIT PAS

Une chaîne mise en capitales à l'exécution — `.uppercased()`, un `textCase` reçu en paramètre.
Il lit des littéraux ; ce qui se voit à l'œil se voit sur une capture, et c'est l'autre moitié
du travail.
"""
import pathlib
import re
import sys

RACINE = pathlib.Path(__file__).resolve().parent.parent
CIBLES = ["Haizo", "HaizoWatch", "HaizoWidgets"]

#: Ce qui n'est pas un libellé : un verbe HTTP, un fuseau, un encodage, un gabarit de date, un
#: jeton à remplacer. Ces mots-là s'écrivent en capitales partout, et les mettre en minuscules
#: casserait le code au lieu de l'adoucir.
TECHNIQUES = {"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS",
              "UTC", "GMT", "UTF-8", "EEEE", "REPLACE_WITH_STRAVA_CLIENT_ID"}

BOUTON = ("le libellé d'un bouton — les capitales d'un bouton sont une convention assumée, et le "
          "brief du 15 novembre ne nomme que des LABELS. Le jour où elle tranche l'inverse, "
          "c'est cette liste qui se vide.")

#: fichier → (nombre de libellés en capitales autorisés, pourquoi)
PERMIS = {
    # ── 1. DES BOUTONS ────────────────────────────────────────────────────────────────────────
    "Haizo/Views/Auth/SignInView.swift": (2, BOUTON),
    "Haizo/Views/Club/ClubView.swift": (1, BOUTON),
    "Haizo/Views/Club/FriendsView.swift": (1, BOUTON),
    "Haizo/Views/Club/PublicProfileView.swift": (4, BOUTON),
    "Haizo/Views/Club/PublishRouteSheet.swift": (4, BOUTON),
    "Haizo/Views/Club/RouteDetailSheet.swift": (3, BOUTON),
    "Haizo/Views/Club/WallView.swift": (1, BOUTON),
    "Haizo/Views/Home/HomeView.swift": (1, BOUTON),
    "Haizo/Views/Home/Sheets/ProgramSettingsSheet.swift": (1, BOUTON),
    "Haizo/Views/Home/Sheets/SessionDetailSheet.swift": (1, BOUTON),
    "Haizo/Views/Live/DebriefSheet.swift": (1, BOUTON),
    "Haizo/Views/Live/LiveRunView.swift": (1, BOUTON),
    "Haizo/Views/Live/RecapView.swift": (6, BOUTON),
    "Haizo/Views/Onboarding/HealthConnectStepView.swift": (1, BOUTON),
    "Haizo/Views/Onboarding/OnboardingComponents.swift": (1, BOUTON),
    "Haizo/Views/Onboarding/PlanRecapView.swift": (1, BOUTON),
    "Haizo/Views/Onboarding/StatistiquesStepView.swift": (2, BOUTON),
    "Haizo/Views/Onboarding/WelcomeView.swift": (1, BOUTON),
    "Haizo/Views/Profile/ProfileView.swift": (2, BOUTON),
    "Haizo/Views/Profile/SauvegardeView.swift": (2, BOUTON),
    "Haizo/Views/ProgramEnd/NewGoalWizardView.swift": (5, BOUTON),
    "Haizo/Views/ProgramEnd/RecoveryView.swift": (2, BOUTON),
    "Haizo/Views/Race/CreateRaceSheet.swift": (1, BOUTON),
    "Haizo/Views/Race/RaceDiscoveryView.swift": (1, BOUTON),
    "Haizo/Views/Race/RacePageView.swift": (5, BOUTON),

    # ── 2. UNE IMAGE PRODUITE, PAS UN ÉCRAN ───────────────────────────────────────────────────
    "Haizo/Views/Live/RunShareCardView.swift": (
        4, "la carte qu'on partage après une course. C'est une affiche qu'on poste ailleurs, pas "
           "un écran de l'app — la même distinction que `check_degrade.py` fait pour les "
           "dégradés."),
    "Haizo/Views/Live/RunVideoFrameView.swift": (
        3, "les images de la vidéo d'export. Même raison."),

    # ── 3. UNE DETTE NOMMÉE, QUI ATTEND UNE MACHINE ──────────────────────────────────────────
    #
    # « EN PAUSE » et « EN COURS » sur la montre et sur le widget. Les deux sont des LABELS, et
    # la règle devrait les prendre. Ils restent pour une raison qui n'a rien d'esthétique :
    #
    # `check_requis.py` empreinte la capture montre livrée à Apple contre TOUT le code de la
    # cible `HaizoWatch`. Changer un mot là-dedans rend l'image périmée — et elle ne se recompose
    # pas ici : elle se prend sur un simulateur watchOS, donc sur une machine macOS. Deux mots en
    # casse normale contre une capture App Store qui montrerait autre chose que l'app : le
    # marché est mauvais.
    #
    # Le widget les garde par symétrie. Il n'est sous aucune empreinte, mais le même état écrit
    # de deux façons sur deux surfaces est pire que les deux en capitales.
    #
    # CE QUI LÈVE LA DETTE : refaire la capture montre sur un Mac, puis ces deux entrées
    # disparaissent d'ici. Le compte à zéro fera parler le garde tout seul.
    "HaizoWatch/WatchViews.swift": (
        3, "« OK » est un bouton ; « EN PAUSE » et « EN COURS » sont une dette nommée — voir "
           "le bloc ci-dessus, la capture montre livrée à Apple est empreintée contre toute la "
           "cible et ne se refait pas sans machine macOS."),
    "HaizoWidgets/DailyGoalsWidget.swift": (
        2, "« EN PAUSE » et « EN COURS », par symétrie avec la montre : le même état écrit de "
           "deux façons sur deux surfaces est pire que les deux en capitales."),

    # ── 4. UN MOT QUI EST SUR UN BOUTON DEPUIS LE PREMIER JOUR ────────────────────────────────
    "Haizo/Shared/Discipline.swift": (
        4, "`tabLabel` — « RUN » sur l'onglet du milieu, et ses trois jumeaux. Son propre "
           "commentaire le dit : « c'est le mot qui est sur ce bouton depuis le premier jour et "
           "le changer n'apporterait rien ». À SURVEILLER : il sert AUSSI de libellé de "
           "discipline à l'historique et aux statistiques, où ce n'est plus un bouton. Deux "
           "rôles, une chaîne — ça se sépare le jour où quelqu'un s'en occupe."),
}

MOTIF = re.compile(r'"([^"\\]{2,60})"')


def ecarts() -> list:
    problemes, compte = [], {}
    for dossier in CIBLES:
        for chemin in sorted((RACINE / dossier).rglob("*.swift")):
            relatif = str(chemin.relative_to(RACINE))
            for numero, ligne in enumerate(chemin.read_text(encoding="utf-8").split("\n"), 1):
                if ligne.lstrip().startswith("//"):
                    continue
                for trouve in MOTIF.finditer(ligne):
                    texte = trouve.group(1)
                    if texte in TECHNIQUES:
                        continue
                    lettres = [c for c in texte if c.isalpha()]
                    if len(lettres) < 2 or not all(c.isupper() for c in lettres):
                        continue
                    compte[relatif] = compte.get(relatif, 0) + 1
                    if relatif not in PERMIS:
                        problemes.append(
                            f"{relatif}:{numero} : « {texte} » est écrit tout en capitales.\n"
                            f"    Casse normale, ou une entrée dans PERMIS avec sa raison.")

    for relatif, (attendu, raison) in sorted(PERMIS.items()):
        reel = compte.get(relatif, 0)
        if reel != attendu:
            problemes.append(
                f"{relatif} : {reel} libellé(s) en capitales, {attendu} déclaré(s).\n"
                f"    Raison inscrite : {raison}\n"
                f"    Un de plus : il faut le justifier. Un de moins : l'entrée doit maigrir.")
    return problemes


def main() -> int:
    problemes = ecarts()
    if problemes:
        print(f"{len(problemes)} écart(s) sur les libellés en capitales :\n")
        for p in problemes:
            print("  " + p)
        return 1
    total = sum(n for n, _ in PERMIS.values())
    print(f"Libellés en capitales : {total} déclarés dans {len(PERMIS)} fichiers — "
          f"des boutons, deux affiches, un onglet, et une dette nommée sur la montre.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
