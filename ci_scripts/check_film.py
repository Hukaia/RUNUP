#!/usr/bin/env python3
"""Le film se déclare, les photos non — et chacun garde ce qu'il lui faut.

# POURQUOI CE CONTRÔLE EXISTE

La campagne 166 a photographié `4-club.png` — une des six images livrées à Apple — PENDANT que le
tracé de la sortie se dessinait. La tête lumineuse de l'animation était figée au milieu du trait,
et la ligne s'arrêtait avant sa fin. La campagne 165, à six heures d'écart, l'avait eu fini.
Personne ne choisit : c'est le minutage qui décide de ce qu'Apple reçoit.

L'app fige donc ses animations en mode démonstration — sauf quand elle est FILMÉE, parce qu'un
film d'aperçu n'a d'intérêt que par son mouvement. La distinction tient à un seul argument de
lancement, `--film`, posé par `ApercuUITests` et par lui seul.

# POURQUOI LE DRAPEAU EST SUR LE FILM ET PAS SUR LES PHOTOS

Parce que les deux oublis ne coûtent pas la même chose.

Oublier de déclarer une photo laisserait les animations jouer : le défaut revient EN SILENCE, et
ne se voit qu'en comparant deux campagnes prises à des heures différentes — c'est-à-dire presque
jamais, et c'est exactement ainsi qu'il est arrivé.

Oublier de déclarer le film donne un film sans mouvement : ça se voit en le regardant. Mais
personne ne regarde le film à chaque campagne, d'où ce contrôle.

# CE QU'IL VÉRIFIE, ET CE QU'IL NE PEUT PAS VÉRIFIER

Trois faits, lisibles dans le code :

  1. `ApercuUITests` lance l'app avec `--film` ;
  2. `CapturesUITests` ne le fait PAS ;
  3. l'app lit ce drapeau et ne fige que si elle ne filme pas.

Et un quatrième, depuis le 23 novembre 2026 :

  4. le test du film appuie là où la barre flottante a ses entrées.

Le test appuie à des coordonnées, pas sur des éléments (interroger l'arbre d'accessibilité tuait
l'app sur les écrans denses). La barre a été refaite le 19 novembre : plus étroite, autre ordre,
le Profil sorti. Le test tapait toujours l'ancienne, et rien ne l'a dit avant qu'une campagne
de soixante-dix minutes n'arrive jusqu'au film, quatre jours plus tard. Les positions se
recalculent depuis les constantes de la barre : c'est une minute, à chaque build.

Ce qu'il ne sait pas faire : dire si l'image est effectivement posée. Aucun script ne lit une
animation. La preuve, elle, est la comparaison de deux campagnes prises à des heures différentes.
"""
import pathlib, re, sys

RACINE = pathlib.Path(__file__).resolve().parent.parent
DRAPEAU = "--film"

FICHIERS = {
    "film": RACINE / "HaizoUITests/ApercuUITests.swift",
    "photos": RACINE / "HaizoUITests/CapturesUITests.swift",
    "app": RACINE / "Haizo/HaizoApp.swift",
    "mode": RACINE / "Haizo/Shared/Demonstration.swift",
    "lecture": RACINE / "Haizo/Services/CaptureSeed.swift",
    "barre": RACINE / "Haizo/DesignSystem/Refonte/HZBarreFlottante.swift",
    "forme": RACINE / "Haizo/DesignSystem/Refonte/HZForme.swift",
}

#: L'écran sur lequel le film est tourné, en points : le plus grand iPhone, celui que
#: `captures.yml` choisit quand on lui dit « auto ». Les fractions du test en dépendent, puisque
#: la barre a une largeur fixe.
ECRAN = (440.0, 956.0)
#: De combien une position écrite peut s'écarter de la position calculée. Une entrée fait 52
#: points, soit 0,118 de la largeur : deux centièmes laissent l'appui au cœur de l'entrée.
TOLERANCE = 0.02


def code_nu(source):
    """Le code seul, sans les commentaires.

    SANS CECI, CE CONTRÔLE NE VOIT RIEN. Sa première version cherchait `--film` dans le fichier
    entier — or le commentaire qui explique le drapeau contient le drapeau, et celui qui explique
    la `transaction` contient `animationsFigees`. Retirer le vrai code laissait donc le contrôle
    vert, parce qu'il relisait sa propre explication. Deux des cas du banc tiennent cette
    correction, et c'est le même piège que `check_vides` avait rencontré.
    """
    source = re.sub(r"//[^\n]*", "", source)
    return re.sub(r"/\*.*?\*/", "", source, flags=re.S)


def lire(cle):
    chemin = FICHIERS[cle]
    if not chemin.is_file():
        return None
    return code_nu(chemin.read_text())


def _constante(source, nom):
    trouve = re.search(rf"static let {nom}\s*:\s*CGFloat\s*=\s*([0-9.]+)", source)
    return float(trouve.group(1)) if trouve else None


def _cas(source, enum):
    """Les cas d'une énumération, dans l'ordre, avec leur valeur brute s'ils en ont une."""
    bloc = re.search(rf"enum {enum}\b[^{{]*\{{(.*?)\}}", source, flags=re.S)
    if not bloc:
        return None
    ligne = re.search(r"case ([^\n]+)", bloc.group(1))
    if not ligne:
        return None
    cas = []
    for morceau in ligne.group(1).split(","):
        nom, _, valeur = morceau.partition("=")
        cas.append((nom.strip(), float(valeur) if valeur.strip() else None))
    return cas


def barre_et_film(sources):
    """Le test du film appuie-t-il sur les entrées de la barre telle qu'elle est dessinée ?"""
    plaintes = []
    onglets = _cas(sources["barre"], "HZOnglet")
    entrees = _cas(sources["film"], "Entree")
    mesures = {nom: _constante(sources["barre"], nom)
               for nom in ("hauteur", "marge", "ecart", "largeurDEntree")}
    sous = _constante(sources["forme"], "sousLaBarre")
    hauteur_ecrite = re.search(r"static let barre\s*:\s*CGFloat\s*=\s*([0-9.]+)", sources["film"])
    if not onglets or None in mesures.values() or sous is None:
        return ["Les constantes de `HZBarreFlottante` (ou `HZEspace.sousLaBarre`) ne se lisent "
                "plus : le contrôle ne sait plus où sont les entrées de la barre."]
    if not entrees or not hauteur_ecrite:
        return ["ApercuUITests n'a plus son énumération `Entree` ou sa constante `barre` : le "
                "contrôle ne sait plus où le film appuie."]

    if [n for n, _ in entrees] != [n for n, _ in onglets]:
        plaintes.append(
            "Les entrées du film ne sont pas celles de la barre : le test connaît "
            f"« {', '.join(n for n, _ in entrees)} », la barre montre "
            f"« {', '.join(n for n, _ in onglets)} ». Chaque appui ouvrirait un autre écran.")
        return plaintes

    largeur, haut = ECRAN
    pas = mesures["largeurDEntree"] + mesures["ecart"]
    milieu = (len(onglets) - 1) / 2
    for rang, (nom, ecrite) in enumerate(entrees):
        attendue = (largeur / 2 + (rang - milieu) * pas) / largeur
        if ecrite is None or abs(ecrite - attendue) > TOLERANCE:
            plaintes.append(
                f"L'entrée « {nom} » est écrite à {ecrite} dans ApercuUITests, la barre la "
                f"dessine à {attendue:.3f} de la largeur : l'appui tomberait à côté.")
    y_attendu = (haut - sous - mesures["hauteur"] / 2) / haut
    y_ecrit = float(hauteur_ecrite.group(1))
    if abs(y_ecrit - y_attendu) > TOLERANCE / 2:
        plaintes.append(
            f"Le milieu de la barre est écrit à {y_ecrit} dans ApercuUITests, il est à "
            f"{y_attendu:.3f} de la hauteur : l'appui passerait au-dessus ou en dessous.")
    return plaintes


def controler():
    """Les plaintes, en clair. Liste vide = tout va bien."""
    plaintes = []
    sources = {cle: lire(cle) for cle in FICHIERS}
    for cle, texte in sources.items():
        if texte is None:
            plaintes.append(f"{FICHIERS[cle].relative_to(RACINE)} est introuvable : "
                            f"le contrôle ne peut rien vérifier.")
    if plaintes:
        return plaintes

    if DRAPEAU not in sources["film"]:
        plaintes.append(
            f"ApercuUITests ne lance plus l'app avec `{DRAPEAU}` : le film d'aperçu sera figé, "
            f"et un film sans mouvement ne se voit qu'en le regardant.")

    if DRAPEAU in sources["photos"]:
        plaintes.append(
            f"CapturesUITests pose `{DRAPEAU}` : les animations joueront pendant les photos, et "
            f"une capture prise en plein vol part chez Apple.")

    if "Demonstration.filmer()" not in sources["app"]:
        plaintes.append(
            "HaizoApp n'allume plus le mode film : le drapeau est posé mais personne ne l'écoute.")

    if "filmDemande" not in sources["lecture"]:
        plaintes.append("CaptureSeed ne lit plus `--film`.")

    # La règle elle-même : figer quand on photographie, pas quand on filme.
    regle = re.search(r"animationsFigees:\s*Bool\s*\{([^}]*)\}", sources["mode"])
    if not regle:
        plaintes.append("`Demonstration.animationsFigees` n'existe plus.")
    elif "enCours" not in regle.group(1) or "!filme" not in regle.group(1):
        plaintes.append(
            "`animationsFigees` ne dit plus « en démonstration ET pas en train de filmer » : "
            f"elle vaut « {regle.group(1).strip()} ».")

    if ".transaction" not in sources["app"] or "animationsFigees" not in sources["app"]:
        plaintes.append(
            "La racine des vues ne fige plus rien : c'est la `transaction` qui vide l'animation "
            "de tout ce qui passe en dessous, et sans elle chaque vue retrouve la sienne.")

    plaintes += barre_et_film(sources)
    return plaintes


def main():
    plaintes = controler()
    for p in plaintes:
        print(f"  · {p}")
    if plaintes:
        print(f"\ncheck_film : {len(plaintes)} problème(s).")
        return 1
    print("check_film : le film se déclare, les photos sont figées, la racine applique la règle, "
          "et le film appuie sur les entrées de la barre.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
