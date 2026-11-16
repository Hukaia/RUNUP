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


def avec(fichiers, permis, volee=None):
    """Fait tourner le garde sur un faux dépôt, avec les deux listes d'exceptions données."""
    racine, cibles, anciens = ck.RACINE, ck.CIBLES, ck.PERMIS
    anciennes_volee = ck.PERMIS_A_LA_VOLEE
    try:
        ck.RACINE = faux_depot(fichiers)
        ck.CIBLES = sorted({c.split("/")[0] for c in fichiers})
        ck.PERMIS = permis
        ck.PERMIS_A_LA_VOLEE = {} if volee is None else volee
        return ck.ecarts()
    finally:
        ck.RACINE, ck.CIBLES, ck.PERMIS = racine, cibles, anciens
        ck.PERMIS_A_LA_VOLEE = anciennes_volee


@cas_de("un libellé en capitales est refusé")
def _():
    p = avec({"Haizo/V.swift": 'Text("ALLURE CIBLE")'}, {})
    assert len(p) == 1 and "ALLURE CIBLE" in p[0], p


@cas_de("la casse normale passe")
def _():
    assert avec({"Haizo/V.swift": 'Text("Allure cible")'}, {}) == []


@cas_de("un mot d'une seule lettre n'est pas un libellé")
def _():
    p = avec({"Haizo/V.swift": 'Text("J")\nText("CE SOIR")'}, {})
    assert len(p) == 1 and "CE SOIR" in p[0], p


@cas_de("UN LITTÉRAL CACHÉ DERRIÈRE UNE INTERPOLATION EST VU")
def _():
    # LE CAS QUI MANQUAIT, ET IL A COÛTÉ UNE CAMPAGNE. Le motif d'origine cherchait `"…"` avec
    # `[^"\\]` : le premier littéral contenant une interpolation, il appariait le guillemet
    # FERMANT du premier avec le guillemet OUVRANT du second, et « GARDÉ » n'était dans aucune
    # paire. Vingt-et-un libellés sortaient par là, dont quatre titres d'écran.
    p = avec({"Haizo/V.swift": 'statTile("\\(n)", String(localized: "GARDÉ"))'}, {})
    assert len(p) == 1 and "GARDÉ" in p[0], p


@cas_de("un littéral À L'INTÉRIEUR d'une interpolation est vu aussi")
def _():
    p = avec({"Haizo/V.swift": 'Text("x \\(cond ? "OUI" : "non")")'}, {})
    assert len(p) == 1 and "OUI" in p[0], p


@cas_de("une échappée ordinaire ne coupe pas le littéral en deux")
def _():
    p = avec({"Haizo/V.swift": 'Text("COMMENT\\nTU T\'APPELLES ?")'}, {})
    assert len(p) == 1 and "COMMENT" in p[0] and "APPELLES" in p[0], p


@cas_de("un sigle ou un nom propre dans une phrase ne compte pas")
def _():
    assert avec({"Haizo/V.swift": 'Text("HYROX · Semaine 3")\nText("120 XP")'}, {}) == []


@cas_de("mais un libellé qui ne contient QUE des capitales compte, sigle ou pas")
def _():
    p = avec({"Haizo/V.swift": 'Text("XP GAGNÉS")'}, {})
    assert len(p) == 1, p


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


@cas_de("UN `uppercased()` SUR UN LIBELLÉ EST REFUSÉ — le cas qui manquait le 16 novembre")
def _():
    # Le catalogue dit « Hier », en casse normale et en trois langues. L'écran affichait
    # « HIER », avec un `tracking(1.2)` par-dessus : les majuscules espacées que le point 1 du
    # brief nomme en exemple. Ce garde lit des LITTÉRAUX, donc il ne voyait rien.
    p = avec({"Haizo/V.swift": 'return Text(label.uppercased())'}, {})
    assert len(p) == 1 and "À L'EXÉCUTION" in p[0], p


@cas_de("et la chaîne du catalogue, elle, reste en casse normale — donc rien d'autre ne sonne")
def _():
    # Le piège serait de croire que le littéral fautif est quelque part. Il n'y est pas : c'est
    # tout ce qui rendait ce défaut invisible.
    p = avec({"Haizo/V.swift": 'let label = String(localized: "Hier")\nText(label.uppercased())'},
             {})
    assert len(p) == 1 and "Hier" not in p[0].split("\n")[0].split("`")[0], p


@cas_de("un commentaire qui cite `uppercased()` ne compte pas")
def _():
    assert avec({"Haizo/V.swift": '// On évitait un uppercased() ici, voir plus bas.'}, {}) == []


@cas_de("une dispense de capitalisation comptée juste passe")
def _():
    d = {"Haizo/A.swift": 'Text(initiale.uppercased())\nText(autre.uppercased())'}
    assert avec(d, {}, {"Haizo/A.swift": (2, "des initiales, pas des mots")}) == []


@cas_de("un `uppercased()` de plus sonne")
def _():
    d = {"Haizo/A.swift": 'Text(a.uppercased())\nText(b.uppercased())\nText(c.uppercased())'}
    p = avec(d, {}, {"Haizo/A.swift": (2, "des initiales, pas des mots")})
    assert len(p) == 1 and "3 `uppercased()`" in p[0], p


@cas_de("un de moins sonne AUSSI — une dispense qui ne maigrit pas devient un passe-droit")
def _():
    d = {"Haizo/A.swift": 'Text(a.uppercased())'}
    p = avec(d, {}, {"Haizo/A.swift": (2, "des initiales, pas des mots")})
    assert len(p) == 1 and "1 `uppercased()`" in p[0], p


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
