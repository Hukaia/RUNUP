#!/usr/bin/env python3
"""L'app s'appelle Haizo. Un seul mot subsiste de l'ancien nom, et chacun a sa raison écrite.

# POURQUOI CE CONTRÔLE EXISTE

Le 16 novembre 2026, RunUp est devenu Haizo. Le nom était écrit **1 415 fois dans 338
fichiers** : 174 fichiers Swift, 100 scripts, les cibles Xcode, les dossiers, 26 clés de
traduction et leurs 52 traductions, les documents, la fiche App Store.

À cette échelle, « j'ai bien regardé » n'est pas une réponse. Un renommage en masse laisse
toujours quelque chose, et ce quelque chose ne se voit pas : une chaîne traduite dans une seule
langue, un commentaire qui cite un chemin de fichier, un titre de page web. Ça ne casse rien à
la construction — ça se lit, un jour, sur un écran, dans la mauvaise marque.

Et l'inverse est pire. Un renommage en masse CASSE des choses en silence :

  - un identifiant d'abonnement App Store renommé, et tous les abonnements en cours cessent
    d'être reconnus ;
  - un groupe applicatif renommé, et le widget comme la montre repartent vides ;
  - une variable d'environnement Vercel renommée dans le code mais pas dans le tableau de bord,
    et le serveur ne démarre plus ;
  - un en-tête HTTP renommé des deux côtés, et toute app déjà installée perd le renouvellement
    de session pendant les jours que met un build à se livrer.

Ce contrôle tient les deux moitiés : l'ancien nom ne subsiste QUE dans la liste ci-dessous, et
cette liste est fermée, raisonnée, et comptée.

# CE QU'IL NE SAIT PAS FAIRE

Il ne lit pas les images. Un mot dessiné dans un PNG lui échappe — c'est la capture qui le dit.
Et il ne sait pas qu'une phrase écrite « Haizo » devrait dire « HAIZO » : la règle de graphie
est vérifiée par `graphies()`, qui ne couvre que les capitales.
"""
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from check_liens import JOURNAUX  # noqa: E402

RACINE = pathlib.Path(__file__).resolve().parent.parent

#: Les extensions relues. Les binaires et les dépendances sont hors sujet.
#:
#: `.xcstrings` A ÉTÉ AJOUTÉ APRÈS COUP, ET C'EST LA LEÇON DE CE FICHIER. La première version de
#: cette liste ne le portait pas. Le contrôle disait donc « l'ancien nom ne subsiste nulle part »
#: alors que `InfoPlist.xcstrings` en gardait dix-huit occurrences, et la montre neuf — c'est-à-
#: dire les textes des DEMANDES D'AUTORISATION iOS, « RunUp lit tes données Santé… », que tout le
#: monde lit à la première ouverture. Le garde était vert et l'app portait l'ancien nom dans la
#: première phrase qu'elle adresse à quelqu'un.
#:
#: Un garde qui choisit les fichiers qu'il regarde ne vaut que ce que vaut cette liste. Les deux
#: entrées sans extension sont là pour la même raison : `.gitignore` gardait six chemins de
#: l'ancienne arborescence, et personne ne l'aurait su.
EXTENSIONS = {".swift", ".py", ".js", ".jsx", ".md", ".yml", ".yaml", ".json",
              ".html", ".sql", ".sh", ".xcconfig", ".xcprivacy", ".xcstrings",
              ".txt", ".entitlements", ".plist", ".pbxproj", ".storyboard", ".xib"}
NOMS_EN_PLUS = {"apple-app-site-association", ".gitignore", "Package.swift"}
IGNORES = {".git", "node_modules", ".build", "DerivedData"}

#: fragment toléré → pourquoi il ne peut PAS être renommé.
#:
#: Chacun est un identifiant qu'une personne ne voit jamais, et dont le renommage coûte une
#: panne. L'ordre importe : le plus long d'abord, pour qu'un préfixe n'avale pas son extension.
TOLERES = [
    ("com.hicsuntco.runup",
     "L'identifiant de l'app, et ses variantes — widget, montre, tests, et SURTOUT les produits "
     "d'abonnement `.plus.monthly` et `.plus.yearly`. Chez Apple, un identifiant différent est "
     "une app différente : nouvelle fiche, zéro avis, aucune mise à jour pour qui a déjà l'app, "
     "et les abonnements en cours cessent d'être reconnus."),
    ("group.com.hicsuntco.runup",
     "Le groupe applicatif, seul canal par lequel le widget et la montre lisent les données de "
     "l'app. Le renommer les vide."),
    ("runup-nu.vercel.app",
     "Le domaine. Il porte les domaines associés, les liens de club `/club/`, le parrainage "
     "`/r/CODE` et `/api/coach`. Tout lien déjà partagé meurt avec lui. Décision de Charlotte, "
     "16 novembre : il reste, et se migrera à part, avec une redirection."),
    ("hukaia.github.io/RUNUP",
     "L'adresse des pages publiées, et c'est la plus dangereuse : `privacy.html` est l'adresse "
     "de confidentialité INSCRITE SUR LA FICHE APP STORE. Elle contient le nom du dépôt GitHub, "
     "donc renommer le dépôt la casse — ce qui est déjà arrivé une fois au changement de "
     "propriétaire, et que `Liens.swift` raconte en entier."),
    ("runup://",
     "Le schéma d'URL. `runup://strava-callback` est déclaré dans les réglages de l'app chez "
     "Strava, hors de notre portée, et `runup://live` est dans les widgets déjà posés sur des "
     "écrans d'accueil."),
    ("X-RunUp-Session-Renewed",
     "Un en-tête HTTP partagé avec le serveur. Le renommer des DEUX côtés passerait les gardes, "
     "et casserait quand même : l'app se livre en jours par TestFlight quand le serveur se "
     "déploie en minutes, et toute app encore installée perdrait le renouvellement de session "
     "pendant cette fenêtre."),
    ("RUNUP_APP_SECRET",
     "Une variable d'environnement du projet Vercel, et la suivante aussi. Elles vivent dans le "
     "tableau de bord, pas dans le dépôt : les renommer ici sans les renommer là-bas fait "
     "échouer `requireEnv` et coupe le serveur net."),
    ("RUNUP_SESSION_SECRET",
     "La clé qui signe les sessions, dans le tableau de bord Vercel. La renommer ici seulement "
     "fait échouer `requireEnv` au premier appel, et plus personne ne se connecte."),
    ("RUNUP_ADMIN_EMAILS",
     "La liste des comptes de la maison, dans le tableau de bord Vercel. Elle est citée telle "
     "quelle dans deux phrases de l'app, qui expliquent où aller la créer : la renommer rendrait "
     "ces phrases fausses en plus de couper l'accès."),
    ("vercel.com/hic-sunt/runup",
     "L'adresse du projet dans le tableau de bord Vercel, citée en commentaire pour qu'on la "
     "retrouve. Elle désigne un projet existant ; elle ne se décrète pas."),
]

ANCIEN = re.compile(r"runup", re.IGNORECASE)
#: Les capitales ne servent qu'au logo. Partout ailleurs, Haizo est un mot dans une phrase.
CAPITALES = re.compile(r"\bHAIZO\b")
PORTEURS_DU_LOGO = {
    "Haizo/Views/Components/SplashView.swift",
    "Haizo/Views/Club/BadgeShareCardView.swift",
    "Haizo/Views/Live/RunShareCardView.swift",
    "Haizo/Views/Live/RunVideoFrameView.swift",
    "appstore/apercu.json",
    "ci_scripts/check_marque.py",
    "ci_scripts/test_marque.py",
    "HaizoTests/ContactMatcherTests.swift",
}


def fichiers(racine=RACINE):
    for p in sorted(racine.rglob("*")):
        if not p.is_file() or set(p.relative_to(racine).parts) & IGNORES:
            continue
        if p.suffix in EXTENSIONS or p.name in NOMS_EN_PLUS:
            yield p


def restes(texte: str) -> list:
    """Les occurrences de l'ancien nom qu'aucune tolérance n'explique, avec leur ligne."""
    masque = texte
    for mot, _ in sorted(TOLERES, key=lambda t: -len(t[0])):
        masque = masque.replace(mot, " " * len(mot))
    return [(i, ligne.strip()[:120])
            for i, ligne in enumerate(masque.splitlines(), start=1)
            if ANCIEN.search(ligne)]


def graphies(texte: str) -> list:
    """Les HAIZO en capitales. Elles n'ont leur place que dans le logo."""
    return [(i, ligne.strip()[:120])
            for i, ligne in enumerate(texte.splitlines(), start=1)
            if CAPITALES.search(ligne)]


#: Les deux seuls fichiers qui ont le droit d'épeler l'ancien nom hors tolérance : ce contrôle,
#: et ses cas.
#:
#: Ils doivent l'écrire pour le chercher — dans la recherche, dans les raisons qui expliquent
#: pourquoi tel identifiant le garde, et dans les cas qui prouvent qu'il est bien refusé.
#: L'alternative serait de fabriquer le motif par morceaux pour que le mot n'apparaisse jamais ;
#: ce serait un garde que personne ne peut relire, et des cas qui ne montrent pas ce qu'ils
#: éprouvent. Deux exemptions, nommées, pour les deux fichiers dont c'est le sujet.
#:
#: Elles ne portent QUE sur l'ancien nom. Les capitales de « HAIZO » y restent jugées comme
#: partout ailleurs — d'où leur présence dans `PORTEURS_DU_LOGO`, qui est une autre liste.
SUR_LE_SUJET = {"ci_scripts/check_marque.py", "ci_scripts/test_marque.py"}

#: Les journaux gardent l'ancien nom, et c'est leur travail.
#:
#: Ils racontent ce qui a été fait — « RunUp devient Haizo », « le remplacement a transformé
#: TEST@RUNUP.APP en TEST@Haizo.APP ». Un journal qui ne peut pas nommer ce qui a changé ne
#: raconte rien, et un garde qui l'y oblige réécrit l'histoire à chaque renommage.
#:
#: La liste est IMPORTÉE de `check_liens.py`, qui tient exactement la même exception pour les
#: anciennes adresses et pour la même raison. Deux copies de cette liste, et l'une des deux
#: serait fausse le jour où un journal s'ajoute : c'est précisément le défaut que tout ce
#: chantier a passé la matinée à corriger ailleurs.


def main(racine=RACINE) -> int:
    plaintes = []
    for p in fichiers(racine):
        try:
            texte = p.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        nom = p.relative_to(racine).as_posix()
        if nom not in SUR_LE_SUJET and p.name not in JOURNAUX:
            for ligne, extrait in restes(texte):
                plaintes.append(f"{nom}:{ligne} — l'ancien nom subsiste : {extrait}")
        if nom not in PORTEURS_DU_LOGO and p.name not in JOURNAUX:
            for ligne, extrait in graphies(texte):
                plaintes.append(
                    f"{nom}:{ligne} — « HAIZO » en capitales hors du logo. Dans une phrase, "
                    f"c'est « Haizo » : {extrait}")

    if plaintes:
        for plainte in plaintes:
            print(f"::error::{plainte}", file=sys.stderr)
        print("::error::L'app s'appelle Haizo. Ce qui garde l'ancien nom est dans la liste "
              "fermée de ci_scripts/check_marque.py, avec une raison par entrée — ce sont des "
              "identifiants qu'une personne ne voit jamais et dont le renommage coûte une "
              "panne. Tout le reste se lit, et doit dire Haizo.", file=sys.stderr)
        return 1

    print(f"Marque : l'ancien nom ne subsiste que dans {len(TOLERES)} identifiants, "
          f"chacun avec sa raison. Le logo porte les capitales, les phrases non.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
