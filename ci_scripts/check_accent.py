#!/usr/bin/env python3
"""La couleur de marque est écrite dans quatre cibles. Elle doit y être écrite pareil.

# POURQUOI CE CONTRÔLE EXISTE

`AccentTheme` est la source : huit nuanciers, trois couleurs chacun. Mais une extension de widget,
une montre et une Live Activity sont des processus séparés qui ne peuvent PAS lire l'objet en
mémoire de l'app — chacune recopie donc les valeurs chez elle. Quatre écritures de la même chose,
dans quatre fichiers.

Le jour où le rose de marque a changé de teinte, il a fallu les retrouver une par une. En oublier
une n'aurait rien cassé : l'app aurait simplement eu un widget d'une autre couleur que l'écran
d'accueil, ou un chrono sur l'écran verrouillé dans l'ancien rose. Personne ne l'aurait signalé
comme un bug — ça ressemble à un choix.

C'est la même duplication que `check_events.py` surveille entre le client et le serveur, et elle
échoue de la même façon : en silence, et en ressemblant à une décision.
"""
import pathlib, re, sys

RACINE = pathlib.Path(__file__).resolve().parent.parent
SOURCE = RACINE / "Haizo" / "DesignSystem" / "AccentTheme.swift"
MIROIRS_COMPLETS = [RACINE / "HaizoWidgets" / "WidgetAccentPalette.swift"]
# Les copies qui ne gardent QUE le rose principal, parce qu'elles n'offrent pas le choix du
# nuancier : la montre et le widget d'activité en direct affichent la couleur de la marque.
MIROIRS_DU_ROSE = {
    RACINE / "HaizoWatch" / "WatchViews.swift": r"static let rose = Color\(hex: (0x[0-9A-Fa-f]{6})\)",
    RACINE / "HaizoWidgets" / "RunActivityWidget.swift":
        r"private static let accent = Color\(hex: (0x[0-9A-Fa-f]{6})\)",
}

_SOURCE = re.compile(
    r'AccentTheme\(id:\s*"(\w+)",\s*name:\s*"[^"]*",\s*'
    r'primary:\s*Color\(hex:\s*(0x[0-9A-Fa-f]{6})\),\s*'
    r'light:\s*Color\(hex:\s*(0x[0-9A-Fa-f]{6})\),\s*'
    r'tail:\s*Color\(hex:\s*(0x[0-9A-Fa-f]{6})\)\)')
_MIROIR = re.compile(r'"(\w+)":\s*\((0x[0-9A-Fa-f]{6}),\s*(0x[0-9A-Fa-f]{6}),\s*(0x[0-9A-Fa-f]{6})\)')

# ── LA TABLE CLAIRE EST UNE DEUXIÈME SOURCE, ET ELLE A DÉRIVÉ ────────────────────────────────
#
# Ce contrôle a longtemps comparé `AccentTheme.all` à ses copies, et il avait raison sur ce
# périmètre : les copies de `all` étaient exactes. Mais l'app n'AFFICHE pas `all` en thème clair.
# Elle affiche `resolvedOnLight`, qui remplace le nuancier par la valeur de la maquette quand
# `mockupLightPalettes` en fixe une — le rose y vaut `#F0225F` depuis le 15 novembre, pas le
# `#FF0A78` de `all`.
#
# Le widget, lui, dérivait sa couleur claire de `all` en l'assombrissant de 10 %. Il a donc rendu
# un rose différent de celui de l'app pendant une journée, sur l'écran d'accueil du téléphone,
# sans qu'aucun garde ne le dise : la copie surveillée était juste, c'est la table surveillée qui
# n'était pas celle qu'on regarde.
#
# Les deux tables claires sont donc comparées elles aussi. Seule la PRIMAIRE compte : c'est la
# seule des trois que le widget lit.
_MAQUETTE_SOURCE = re.compile(
    r'"(\w+)":\s*\(Color\(hex:\s*(0x[0-9A-Fa-f]{6})\)')
_MAQUETTE_MIROIR = re.compile(r'"(\w+)":\s*(0x[0-9A-Fa-f]{6})\b')
MAQUETTE_CLAIRE = RACINE / "HaizoWidgets" / "WidgetAccentPalette.swift"


def _bloc(source, apres):
    """Le corps du littéral de dictionnaire déclaré après `apres`.

    On cherche « = [ » et non le premier crochet : les deux déclarations portent une annotation
    de type qui en contient déjà un — `[String: UInt32]` — et s'arrêter dessus faisait lire le
    TYPE au lieu des valeurs. Le contrôle trouvait alors zéro nuancier et refusait un dépôt
    juste, ce qui est la façon la plus sûre de se faire désactiver.
    """
    i = source.find(apres)
    if i < 0:
        return ""
    debut = source.index("= [", i) + 2
    return source[debut:source.index("]", debut)]


def maquette_claire(source, apres, motif):
    """`{nuancier: primaire}` d'une table de valeurs claires fixées par la maquette."""
    return {nom: val.lower() for nom, val in motif.findall(_bloc(source, apres))}


def _normalise(trouvees):
    return {nom: tuple(c.lower() for c in couleurs) for nom, *couleurs
            in ((t[0], t[1], t[2], t[3]) for t in trouvees)}


def nuanciers(source):
    """Les nuanciers déclarés par `AccentTheme`."""
    return _normalise(_SOURCE.findall(source))


def miroir(source):
    """Les nuanciers recopiés par une cible secondaire."""
    return _normalise(_MIROIR.findall(source))


def ecarts(reference, copie, nom_du_fichier):
    """Ce qui diffère entre la source et une copie, dans les deux sens."""
    problemes = []
    for cle in sorted(set(reference) - set(copie)):
        problemes.append(f"{nom_du_fichier} ne connaît pas le nuancier « {cle} » : "
                         f"qui le choisira verra la couleur d'un autre.")
    for cle in sorted(set(copie) - set(reference)):
        problemes.append(f"{nom_du_fichier} déclare « {cle} », que `AccentTheme` ne connaît plus.")
    for cle in sorted(set(reference) & set(copie)):
        if reference[cle] != copie[cle]:
            problemes.append(f"{nom_du_fichier} : « {cle} » vaut {', '.join(copie[cle])} "
                             f"au lieu de {', '.join(reference[cle])}.")
    return problemes


def main():
    source = SOURCE.read_text(encoding="utf-8")
    reference = nuanciers(source)
    if not reference:
        print("::error::Aucun nuancier lu dans AccentTheme.swift : ce contrôle ne surveille "
              "plus rien, corrige-le ou retire-le.", file=sys.stderr)
        return 1

    problemes = []
    for chemin in MIROIRS_COMPLETS:
        problemes += ecarts(reference, miroir(chemin.read_text(encoding="utf-8")),
                            chemin.relative_to(RACINE).as_posix())

    # Les tables claires de la maquette, source contre miroir.
    attendue = maquette_claire(source, "mockupLightPalettes", _MAQUETTE_SOURCE)
    if not attendue:
        problemes.append(
            "AccentTheme.swift : `mockupLightPalettes` ne se lit plus. Ce n'est pas un détail — "
            "c'est la table que le thème clair affiche vraiment, et plus personne ne la compare "
            "à la copie du widget.")
    copie = maquette_claire(MAQUETTE_CLAIRE.read_text(encoding="utf-8"), "mockupLight",
                            _MAQUETTE_MIROIR)
    nom_maquette = MAQUETTE_CLAIRE.relative_to(RACINE).as_posix()
    for cle in sorted(set(attendue) | set(copie)):
        if attendue.get(cle) != copie.get(cle):
            problemes.append(
                f"{nom_maquette} : le clair de « {cle} » vaut {copie.get(cle, 'rien')} "
                f"au lieu de {attendue.get(cle, 'rien')}. C'est la couleur que l'app DESSINE en "
                f"thème clair, pas celle du nuancier brut.")

    rose = reference.get("rose", (None,))[0]
    for chemin, motif in MIROIRS_DU_ROSE.items():
        nom = chemin.relative_to(RACINE).as_posix()
        trouve = re.search(motif, chemin.read_text(encoding="utf-8"))
        if not trouve:
            problemes.append(f"{nom} : la copie du rose de marque est introuvable — "
                             f"elle a été renommée, et plus personne ne la surveille.")
        elif trouve.group(1).lower() != rose:
            problemes.append(f"{nom} : le rose vaut {trouve.group(1).lower()} au lieu de {rose}.")

    if problemes:
        for p in problemes:
            print(f"::error::{p}", file=sys.stderr)
        print("::error::La source est Haizo/DesignSystem/AccentTheme.swift. Les autres cibles "
              "sont des processus séparés qui ne peuvent pas la lire : elles la recopient, et "
              "c'est à ce contrôle de tenir les copies d'accord.", file=sys.stderr)
        return 1

    print(f"Accents : {len(reference)} nuanciers, "
          f"{len(MIROIRS_COMPLETS) + len(MIROIRS_DU_ROSE)} copies d'accord avec la source.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
