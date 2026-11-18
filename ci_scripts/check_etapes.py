#!/usr/bin/env python3
"""Les questions de l'inscription disent la même chose partout.

L'inscription compte TROIS questions, une par écran (`OnboardingContainerView`). Elle les décrit à
trois endroits : le nombre d'écrans et les noms que mesure l'analytique (`HZEntree`), et le
`switch` du conteneur qui choisit la question. Ajouter une question et oublier l'un des trois est
une étape qui s'affiche sans se mesurer, ou qui se mesure sans s'afficher.

Ce script vérifie :

  1. `HZEntree.ecrans` est le nombre de noms de `HZEntree.noms` ;
  2. le `switch` du conteneur couvre les indices de 0 à `ecrans - 1`, le dernier par `default` ;
  3. l'inscription n'a jamais plus de trois écrans : c'est la règle de la refonte, et une
     quatrième question demande une décision, pas une ligne.
"""
import re
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
SYSTEME = RACINE / "Haizo/DesignSystem/Refonte/HZEcrans.swift"
CONTENEUR = RACINE / "Haizo/Views/Refonte/OnboardingContainerView.swift"
MAXIMUM = 3


def sans_commentaires(source: str) -> str:
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.S)
    return re.sub(r"//[^\n]*", "", source)


def main() -> int:
    fautes = []
    systeme = sans_commentaires(SYSTEME.read_text())
    bloc = re.search(r"enum HZEntree \{(.*?)\n\}", systeme, re.S)
    if not bloc:
        print("`HZEntree` est introuvable dans HZEcrans.swift.")
        return 1
    ecrans = re.search(r"static let ecrans = (\d+)", bloc.group(1))
    noms = re.search(r"static let noms = \[(.*?)\]", bloc.group(1), re.S)
    if not ecrans or not noms:
        print("`HZEntree.ecrans` ou `HZEntree.noms` est introuvable.")
        return 1
    nombre = int(ecrans.group(1))
    liste = re.findall(r'"([^"]+)"', noms.group(1))
    if nombre != len(liste):
        fautes.append(f"`HZEntree.ecrans` vaut {nombre} mais `noms` en compte {len(liste)}.")
    if nombre > MAXIMUM:
        fautes.append(f"L'inscription compte {nombre} écrans : la règle en autorise {MAXIMUM}.")
    source = sans_commentaires(CONTENEUR.read_text())
    depart = source.find("switch etape {")
    if depart == -1:
        fautes.append("Le conteneur n'a plus de `switch etape` : le contrôle ne lit plus rien.")
    else:
        suite = source[depart:]
        cas = [int(n) for n in re.findall(r"case (\d+):", suite.split("\n            }")[0])]
        attendus = list(range(nombre - 1))
        if cas != attendus or "default:" not in suite.split("\n            }")[0]:
            fautes.append(f"Le `switch etape` couvre {cas} et un `default`, il devrait couvrir "
                          f"{attendus} et un `default` ({nombre} écrans).")
    if fautes:
        print("L'inscription se contredit :\n")
        for f in fautes:
            print("  • " + f)
        return 1
    print(f"Inscription : {nombre} écrans, nommés et aiguillés de la même façon.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
