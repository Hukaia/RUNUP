#!/usr/bin/env python3
r"""Aucune chaîne affichée ne cite avec le guillemet droit de la machine à écrire.

# POURQUOI CE CONTRÔLE EXISTE

La feuille de la séance du jour a été photographiée pour la première fois le 15 novembre. On y
lisait, en français :

    Le coach a ajusté cette semaine à "Niveau 2" d'après ta forme la semaine dernière.

Le guillemet droit `"` n'existe pas en typographie française. L'app, elle, savait déjà le faire :
à deux centimètres de là, la notification qui annonce LE MÊME ajustement écrit
« On lève un peu le pied sur « %@ » », et sa version anglaise « Easing off on “%@” ». La règle
existait, en trois langues, et cette phrase-là ne la suivait pas.

C'est la forme de défaut la plus fréquente de ce dépôt : une règle écrite à un endroit et pas
appliquée à un autre. Elle ne se corrige pas en relisant, elle se corrige en posant une machine.

# CE QUI EST REGARDÉ

Le catalogue, et lui seul. Il est écrit en JSON, donc un guillemet droit à l'intérieur d'une
chaîne y apparaît échappé — `\"`. Il n'y a rien d'autre dans ce fichier que du texte destiné à
être lu par quelqu'un : la recherche est donc exacte, et ne peut pas se tromper sur du code.

Et elle suffit. `check_strings.py` refuse déjà toute chaîne affichée absente du catalogue : un
`Text("… \" …")` écrit dans une vue doit donc arriver ici pour que la construction passe. Il n'y
a pas de second chemin à surveiller.

# CE QUI N'EST PAS REGARDÉ, ET POURQUOI

QUEL guillemet courbe employer. Le français veut « », l'anglais “ ”, l'espagnol « » sans espaces
— mais une chaîne française a le droit de citer de l'anglais, et un contrôle qui imposerait la
paire par la langue refuserait du texte juste. La règle tenue ici est la seule qui n'ait aucune
exception : le guillemet de la machine à écrire ne s'affiche jamais.

L'APOSTROPHE. Le catalogue en porte 827, toutes droites, zéro courbe : c'est un choix uniforme,
pas un oubli. Le changer est une décision de direction artistique sur 827 chaînes, pas une
correction.
"""
import pathlib, sys

RACINE = pathlib.Path(__file__).resolve().parent.parent
CATALOGUE = RACINE / "Haizo" / "Resources" / "Localizable.xcstrings"


def fautes(texte):
    """Les lignes qui portent un guillemet droit À L'INTÉRIEUR d'une chaîne JSON.

    Rendues comme `(numéro, ligne)`, dans l'ordre du fichier.
    """
    trouvees = []
    for n, ligne in enumerate(texte.split("\n"), start=1):
        if '\\"' in ligne:
            trouvees.append((n, ligne.strip()))
    return trouvees


def main():
    if not CATALOGUE.exists():
        print(f"Catalogue introuvable : {CATALOGUE}")
        return 1
    texte = CATALOGUE.read_text(encoding="utf-8")
    mauvaises = fautes(texte)
    if mauvaises:
        print(f"{len(mauvaises)} chaîne(s) affichée(s) citent avec le guillemet droit :\n")
        for n, ligne in mauvaises[:20]:
            print(f"  Localizable.xcstrings:{n}")
            print(f"    {ligne[:120]}")
        print()
        print("Le guillemet droit \" est celui de la machine à écrire, pas de la typographie.")
        print("La maison écrit « … » en français, “ … ” en anglais, «…» en espagnol —")
        print("voir « On lève un peu le pied sur « %@ » », qui dit le même ajustement.")
        return 1
    # Comptés plutôt qu'écrits : un nombre en dur dans un message devient faux au premier
    # ajout, et un garde qui ment sur ce qu'il a vu n'inspire plus rien.
    francais = texte.count("«")
    anglais = texte.count("“")
    print("Guillemets : le catalogue ne cite nulle part avec le guillemet droit.")
    print(f"            {francais} citation(s) en « », {anglais} en “ ”.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
