#!/usr/bin/env python3
"""Les cas de `check_majuscules.py`.

CE QU'ILS EMPÊCHENT DE REVENIR. Les capitales vivaient de trois façons — un `textCase` sur la
vue, un `tracking` sur une chaîne déjà capitalisée, et les CAPITALES DANS LA CHAÎNE elle-même, au
catalogue, en trois langues. Seule la troisième est invisible à la relecture, et c'est elle que
ce garde tient.

ET CEUX QUI DISENT L'INVERSE. Une liste d'exceptions est une porte : les cas « un de plus sonne »
et « un de moins sonne » vérifient qu'elle ne s'ouvre pas plus large qu'écrit. Un garde qui ne
refuse que dans un sens laisse dormir des entrées devenues inutiles, et une liste de passe-droits
est ce qu'on obtient au bout de quelques mois.
"""
import pathlib
import sys
import tempfile

ICI = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import check_majuscules as ck  # noqa: E402

cas = []


def cas_de(nom):
    def decorateur(f):
        cas.append((nom, f))
        return f
    return decorateur


def faux_depot(fichiers):
    racine = pathlib.Path(tempfile.mkdtemp())
    for chemin, contenu in fichiers.items():
        f = racine / chemin
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_text(contenu, encoding="utf-8")
    return racine


def avec(fichiers, permis):
    """Fait tourner le garde sur un faux dépôt, avec une liste d'exceptions donnée."""
    racine, cibles, anciens = ck.RACINE, ck.CIBLES, ck.PERMIS
    try:
        ck.RACINE = faux_depot(fichiers)
        ck.CIBLES = sorted({c.split("/")[0] for c in fichiers})
        ck.PERMIS = permis
        return ck.ecarts()
    finally:
        ck.RACINE, ck.CIBLES, ck.PERMIS = racine, cibles, anciens


@cas_de("un libellé en capitales est refusé")
def _():
    p = avec({"Haizo/V.swift": 'Text("ALLURE CIBLE")'}, {})
    assert len(p) == 1 and "ALLURE CIBLE" in p[0], p


@cas_de("la casse normale passe")
def _():
    assert avec({"Haizo/V.swift": 'Text("Allure cible")'}, {}) == []


@cas_de("un mot d'une seule lettre n'est pas un libellé")
def _():
    assert avec({"Haizo/V.swift": 'Text("J")\nText("5 KM")'}, {})[0].count("5 KM") == 1


@cas_de("un verbe HTTP et un gabarit de date ne comptent pas")
def _():
    assert avec({"Haizo/S.swift": 'r.method = "POST"\nf.dateFormat = "EEEE"\nlet z = "UTC"'},
                {}) == []


@cas_de("un commentaire qui cite des capitales ne compte pas")
def _():
    assert avec({"Haizo/V.swift": '// « ALLURE CIBLE » est parti le 16 novembre.'}, {}) == []


@cas_de("un fichier permis passe au compte exact")
def _():
    assert avec({"Haizo/B.swift": 'Text("DÉMARRER")'}, {"Haizo/B.swift": (1, "bouton")}) == []


@cas_de("un de plus sonne")
def _():
    p = avec({"Haizo/B.swift": 'Text("DÉMARRER")\nText("ARRÊTER")'},
             {"Haizo/B.swift": (1, "bouton")})
    assert len(p) == 1 and "2 libellé" in p[0], p


@cas_de("un de moins sonne AUSSI")
def _():
    p = avec({"Haizo/B.swift": 'Text("Démarrer")'}, {"Haizo/B.swift": (1, "bouton")})
    assert len(p) == 1 and "0 libellé" in p[0], p


@cas_de("chaque exception porte une raison écrite, et pas un mot")
def _():
    maigres = [f"{f} : « {r} »" for f, (_, r) in ck.PERMIS.items() if len(r) < 40]
    assert not maigres, "\n".join(maigres)


@cas_de("le dépôt tel qu'il est passe")
def _():
    p = ck.ecarts()
    assert p == [], "\n".join(p)


def main():
    echecs = 0
    for nom, f in cas:
        try:
            f()
            print(f"  ok   {nom}")
        except AssertionError as e:
            echecs += 1
            print(f"  ÉCHEC {nom}\n        {e}")
    print(f"\n{len(cas) - echecs}/{len(cas)} cas passent.")
    return 1 if echecs else 0


if __name__ == "__main__":
    sys.exit(main())
