#!/usr/bin/env python3
r"""Les cas de `check_branche.py`.

CE QU'ILS EMPÊCHENT DE REVENIR. Le 16 novembre, un renommage de marque a remplacé le nom de la
branche de travail dans `on: push: branches:`. La branche d'arrivée n'existait pas, le workflow a
cessé de partir, et RIEN NE L'A DIT pendant douze commits — il n'y a pas d'exécution ratée quand
il n'y a pas d'exécution.

ET CELUI QUI COMPTE LE PLUS. « un renommage cohérent partout passerait quand même » : le défaut
d'origine a changé les sept occurrences de la même façon. Un contrôle de cohérence interne les
aurait trouvées d'accord. Il faut comparer à la VRAIE branche, et ce cas-là le vérifie.
"""
import pathlib
import sys
import tempfile

ICI = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import check_branche as ck  # noqa: E402

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


def avec(fichiers, permis, courante="claude/vraie-branche"):
    return ck.ecarts(racine=faux_depot(fichiers), courante=courante, permis=permis)


DECLENCHEUR = ("name: TestFlight\non:\n  push:\n    branches:\n      - %s\n"
               "jobs:\n  build:\n    runs-on: macos-15\n")


@cas_de("un déclencheur sur une autre branche est refusé, et c'est LE défaut du 16 novembre")
def _():
    p = avec({".github/workflows/testflight.yml": DECLENCHEUR % "claude/fausse-branche"}, {})
    assert len(p) == 1, p
    assert "claude/fausse-branche" in p[0] and "ne partira jamais" in p[0], p[0]


@cas_de("UN RENOMMAGE COHÉRENT PARTOUT PASSE QUAND MÊME, et c'est pour ça qu'on compare au réel")
def _():
    # Le défaut d'origine : sept occurrences changées de la même façon, toutes d'accord entre
    # elles, toutes fausses. Un contrôle qui ne vérifierait que l'unicité de l'orthographe
    # verrait un dépôt parfaitement cohérent.
    renomme = {
        ".github/workflows/testflight.yml": DECLENCHEUR % "claude/haizo-truc",
        "PROGRESS.md": "La branche de travail est `claude/haizo-truc`.\n",
        "AUDIT.md": "Relevé sur `claude/haizo-truc`.\n",
    }
    p = avec(renomme, {})
    assert len(p) == 3, p
    assert all("claude/haizo-truc" in x for x in p), p


@cas_de("la branche courante passe, où qu'elle soit écrite")
def _():
    bon = {
        ".github/workflows/testflight.yml": DECLENCHEUR % "claude/vraie-branche",
        "PROGRESS.md": "Tout se passe sur `claude/vraie-branche`, et rien ailleurs.\n",
    }
    assert avec(bon, {}) == []


@cas_de("un joker couvre la branche courante par construction")
def _():
    glob = {".github/workflows/captures.yml":
            'name: C\non:\n  push:\n    branches:\n      - "**"\njobs:\n  x:\n    runs-on: a\n'}
    assert avec(glob, {}) == []


@cas_de("un nom hors déclencheur est signalé autrement — c'est un relevé faux, pas un silence")
def _():
    p = avec({"PROGRESS.md": "Branch Tracking porte `claude/autre`.\n"}, {})
    assert len(p) == 1 and "à côté de la vraie" in p[0], p


@cas_de("une dispense comptée juste passe")
def _():
    d = {"RELEASE.md": "Deux branches : `claude/a` et `claude/b`.\n"}
    assert avec(d, {"RELEASE.md": (2, "elles existent vraiment")}) == []


@cas_de("un de plus sonne")
def _():
    d = {"RELEASE.md": "Trois : `claude/a`, `claude/b`, `claude/c`.\n"}
    p = avec(d, {"RELEASE.md": (2, "elles existent vraiment")})
    assert len(p) == 1 and "3 nom(s)" in p[0], p


@cas_de("un de moins sonne AUSSI — une dispense qui ne se vide pas devient un passe-droit")
def _():
    d = {"RELEASE.md": "Une seule : `claude/a`.\n"}
    p = avec(d, {"RELEASE.md": (2, "elles existent vraiment")})
    assert len(p) == 1 and "1 nom(s)" in p[0], p


@cas_de("sans branche courante, le contrôle REFUSE plutôt que de se taire")
def _():
    p = avec({".github/workflows/testflight.yml": DECLENCHEUR % "claude/x"}, {}, courante="")
    assert len(p) == 1 and "introuvable" in p[0], p


@cas_de("un binaire ou un dossier de dépendances n'est pas lu")
def _():
    d = {"node_modules/truc/index.js": "// claude/autre\n",
         "build/sortie.txt": "claude/autre\n",
         "image.png": "claude/autre\n"}
    assert avec(d, {}) == []


@cas_de("un fichier de cas nomme des branches fictives, et c'est son travail")
def _():
    assert avec({"ci_scripts/test_truc.py": 'avec({"w.yml": "- claude/fausse"}, {})\n'}, {}) == []


@cas_de("mais un GARDE reste lu : sa documentation est de la prose, et elle vieillit")
def _():
    # L'exclusion est étroite exprès. Si elle portait sur tout `ci_scripts`, la documentation de
    # ce contrôle-ci pourrait nommer une branche morte sans que rien ne le dise — or c'est
    # exactement le genre de relevé périmé qu'il existe pour attraper.
    p = avec({"ci_scripts/check_truc.py": '"""On travaille sur claude/vieille-branche."""\n'}, {})
    assert len(p) == 1 and "claude/vieille-branche" in p[0], p


@cas_de("le dépôt tel qu'il est passe au compte exact")
def _():
    assert ck.ecarts() == [], ck.ecarts()


def main():
    rouges = 0
    for nom, f in cas:
        try:
            f()
            print(f"  ok   {nom}")
        except AssertionError as e:
            rouges += 1
            print(f"  ROUGE {nom}\n        {e}")
    print(f"\n{len(cas) - rouges}/{len(cas)} cas passent.")
    return 1 if rouges else 0


if __name__ == "__main__":
    sys.exit(main())
