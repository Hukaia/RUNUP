#!/usr/bin/env python3
r"""Ce que `check_guillemets.py` doit voir, et surtout ce qu'il ne doit PAS refuser.

Le défaut réel est celui du 15 novembre, lu sur la première capture de la feuille de séance :
`à \"Niveau 2\"`. Les cas négatifs comptent autant — le catalogue est plein de barres obliques
inversées légitimes (`\n`, `é`) et de guillemets JSON qui ouvrent et ferment les chaînes,
et un garde qui refuserait ceux-là serait désactivé dans la semaine.
"""

import sys

import check_guillemets as ck

cas = []


def cas_test(nom):
    def prendre(f):
        cas.append((nom, f))
        return f
    return prendre


# ── CE QUI DOIT ÊTRE REFUSÉ ──────────────────────────────────────────────────────────────────

@cas_test("la phrase du coach, telle qu'elle était (le défaut réel du 15 novembre)")
def _():
    texte = '      "value": "El coach ajusto esta semana a \\"%@\\" segun tu forma."'
    assert len(ck.fautes(texte)) == 1


@cas_test("la clé elle-même, pas seulement la traduction")
def _():
    texte = '    "Le coach a ajuste cette semaine a \\"%@\\" d\'apres ta forme.": {'
    assert len(ck.fautes(texte)) == 1


@cas_test("une seule citation droite suffit, l'ouvrante comme la fermante")
def _():
    assert len(ck.fautes('      "value": "Il a dit \\"oui."')) == 1


@cas_test("le numéro de ligne est celui du fichier, pas celui du bloc")
def _():
    texte = "\n".join(["ligne une", "ligne deux", '  "value": "a \\"b\\" c"'])
    assert ck.fautes(texte)[0][0] == 3, ck.fautes(texte)


@cas_test("plusieurs fautes sont toutes rendues")
def _():
    texte = "\n".join(['"a \\"x\\""', "rien", '"b \\"y\\""'])
    assert len(ck.fautes(texte)) == 2


# ── CE QUI DOIT PASSER ───────────────────────────────────────────────────────────────────────

@cas_test("les guillemets français passent")
def _():
    assert ck.fautes('      "value": "On leve le pied sur « %@ »"') == []


@cas_test("les guillemets anglais courbes passent")
def _():
    assert ck.fautes('      "value": "Easing off on “%@”"') == []


@cas_test("les guillemets espagnols collés passent")
def _():
    assert ck.fautes('      "value": "Bajamos el ritmo en «%@»"') == []


@cas_test("les guillemets JSON qui délimitent une chaîne ne sont pas des citations")
def _():
    assert ck.fautes('    "une cle": {') == []
    assert ck.fautes('      "value": "une phrase ordinaire."') == []


@cas_test("une barre oblique inversée qui n'ouvre pas un guillemet passe")
def _():
    assert ck.fautes('      "value": "premiere ligne\\nseconde ligne"') == []
    assert ck.fautes('      "value": "cafe\\u00e9"') == []


@cas_test("un texte vide ne signale rien")
def _():
    assert ck.fautes("") == []


@cas_test("le dépôt tel qu'il est passe")
def _():
    texte = ck.CATALOGUE.read_text(encoding="utf-8")
    assert ck.fautes(texte) == [], ck.fautes(texte)[:3]


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
