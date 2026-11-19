#!/usr/bin/env python3
"""Ce que `check_design.py` doit voir, et ce qu'il ne doit pas inventer.

Trois des cas viennent de défauts réels commis en écrivant `DESIGN.md` : des gardes CITÉS QUI
N'EXISTAIENT PAS, une valeur recopiée qui a dérivé, et le document VIDÉ de ses tableaux, qui
passait tous les contrôles en silence.
"""

import pathlib
import sys
import tempfile

import check_design as ck

cas = []


def cas_test(nom):
    def prendre(f):
        cas.append((nom, f))
        return f
    return prendre


def _sur(document: str) -> list:
    """Les écarts que le garde relève sur un faux `DESIGN.md`, sans toucher au vrai."""
    faux = pathlib.Path(tempfile.gettempdir()) / "faux_design.md"
    faux.write_text(document, encoding="utf-8")
    vrai = ck.DESIGN
    try:
        ck.DESIGN = faux
        return ck.ecarts()
    finally:
        ck.DESIGN = vrai
        faux.unlink(missing_ok=True)


def _vrai_document() -> str:
    return ck.DESIGN.read_text(encoding="utf-8")


def _fausse(avant: str, apres: str) -> str:
    """Le document avec une substitution qui a VRAIMENT eu lieu : un cas qui ne teste plus rien
    est pire qu'un cas absent, il rassure."""
    document = _vrai_document()
    assert avant in document, (
        f"« {avant} » n'est plus dans DESIGN.md — ce cas ne teste plus rien. "
        "Reprenez-le sur la valeur actuelle au lieu de le laisser passer.")
    return document.replace(avant, apres, 1)


@cas_test("le dépôt tel qu'il est passe")
def _():
    assert ck.ecarts() == [], ck.ecarts()


@cas_test("un jeton dont la valeur a dérivé est refusé")
def _():
    assert any("noir" in quoi for _, quoi, _ in _sur(_fausse("`#0B0B0C`", "`#0B0B0D`")))


@cas_test("un accent dont la couleur a dérivé est refusé")
def _():
    assert any("accent Rose" in quoi for _, quoi, _ in _sur(_fausse("`#FF2E6E`", "`#FF2E6F`")))


@cas_test("une teinte d'intensité qui a dérivé est refusée")
def _():
    assert any("intensité" in quoi for _, quoi, _ in _sur(_fausse("`#177A50`", "`#177A51`")))


@cas_test("une des trois questions disparue est refusée")
def _():
    assert any(ck.ANCRES[0] in quoi for _, quoi, _ in _sur(_fausse(ck.ANCRES[0], "xxx")))


@cas_test("un garde cité qui n'existe pas est refusé")
def _():
    assert any("check_inexistant.py" in quoi
               for _, quoi, _ in _sur(_vrai_document() + "\n`check_inexistant.py`\n"))


@cas_test("le document vidé de ses tableaux est refusé, pas laissé passer")
def _():
    vide = "\n".join(ck.ANCRES)
    assert any(quoi in ("jetons", "accents", "intensites") for _, quoi, _ in _sur(vide))


@cas_test("chaque jeton du code se lit")
def _():
    j = ck.jetons()
    assert j.get("noir") == 0x0B0B0C and len(j) >= 12, j


@cas_test("les durées du mouvement se lisent")
def _():
    d = ck.durees()
    for jeton in ("ecran", "chiffre", "ressort", "glisse", "trace", "choix"):
        assert jeton in d, (jeton, sorted(d))


def main() -> int:
    echecs = 0
    for nom, f in cas:
        try:
            f()
            print(f"  ok   {nom}")
        except AssertionError as e:
            echecs += 1
            print(f"  FAIL {nom}\n       {e}")
    print(f"\n{len(cas) - echecs}/{len(cas)} cas passent.")
    return 1 if echecs else 0


if __name__ == "__main__":
    sys.exit(main())
