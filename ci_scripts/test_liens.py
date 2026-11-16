#!/usr/bin/env python3
"""Ce que `check_liens.py` doit voir, et ce qu'il ne doit pas inventer.

Les deux premiers cas sont le DÉFAUT RÉEL, recopié tel qu'il était : l'ancienne adresse, celle qui
répond 404 depuis que le dépôt a changé de propriétaire. Un garde qui ne la rattrape pas ne sert à
rien, et c'est la seule façon de le savoir.
"""

import pathlib
import sys

import check_liens as ck
import liens

def _chez(proprietaire: str) -> str:
    """L'adresse de la politique, servie par le compte `proprietaire` au lieu du nôtre.

    DÉRIVÉE, ET PLUS ÉCRITE EN DUR — correction du 16 novembre. Elle l'était, et le changement de
    nom de l'app l'a réécrite en masse avec tout le reste : son chemin a pris le nouveau nom, et
    elle a cessé d'être l'ancienne adresse de qui que ce soit. Les trois cas bâtis dessus ont
    continué de tourner en ne prouvant plus rien — le garde ne reconnaissait plus l'adresse qu'on
    lui donnait, donc il ne la signalait pas, donc le cas échouait. Il a échoué, et c'est la
    seule raison pour laquelle on le sait.

    Le défaut que ces cas décrivent n'est pas « cette chaîne-là » : c'est « le compte change,
    l'adresse reste ». On la fabrique donc à partir de celle qui est déclarée, en ne remplaçant
    que le compte.
    """
    _, _, suite = liens.CONFIDENTIALITE.partition("://")
    return f"https://{proprietaire}.github.io/{suite.split('/', 1)[1]}"


#: L'ancienne, celle qui répond 404 depuis que le dépôt a changé de compte.
ANCIENNE = _chez("hicsuntco")

cas = []


def cas_test(nom):
    def prendre(f):
        cas.append((nom, f))
        return f
    return prendre


def _ecarts(relatif: str, texte: str):
    """La règle sur un fichier, sans toucher au disque."""
    trouves = []
    for numero, ligne in enumerate(texte.splitlines(), start=1):
        for url in ck.ADRESSE.findall(ligne):
            if url.rstrip("/") not in {liens.CONFIDENTIALITE, liens.ASSISTANCE}:
                trouves.append((relatif, numero, url))
    return trouves


@cas_test("l'ancienne adresse de la politique est signalée")
def _():
    trouves = _ecarts("Haizo/Views/Paywall/PaywallView.swift",
                      f'    private let privacyURL = URL(string: "{ANCIENNE}")!\n')
    assert len(trouves) == 1, trouves
    assert trouves[0][2] == ANCIENNE, trouves


@cas_test("l'ancienne adresse dans une page HTML est signalée")
def _():
    trouves = _ecarts("support.html", f'<a href="{ANCIENNE}">politique</a>\n')
    assert len(trouves) == 1, trouves


@cas_test("les deux adresses déclarées passent")
def _():
    texte = f"{liens.CONFIDENTIALITE}\n{liens.ASSISTANCE}\n"
    assert _ecarts("APP_STORE_LISTING.md", texte) == []


@cas_test("un lien de spécification d'une dépendance n'est pas de notre ressort")
def _():
    # La première version du contrôle lisait `node_modules` et signalait cinquante et un liens
    # comme celui-ci. Le motif vise maintenant NOTRE projet, pas tout GitHub Pages.
    texte = "// https://w3c.github.io/FileAPI/\nhttps://jawj.github.io/zapatos/\n"
    assert _ecarts("node_modules/undici/x.js", texte) == []


@cas_test("une page de notre projet chez un autre propriétaire est signalée")
def _():
    # Le cœur du défaut : le dépôt change de compte, GitHub Pages suit, l'adresse reste.
    trouves = _ecarts("x.md", f"{_chez('quelquun-dautre')}\n")
    assert len(trouves) == 1, trouves


@cas_test("les dossiers qui ne sont pas à nous sont ignorés")
def _():
    lus = {relatif for relatif, _ in ck.fichiers()}
    assert not any(r.startswith("node_modules/") for r in lus), "node_modules est relu"
    assert any(r.startswith("Haizo/") for r in lus), "le code de l'app n'est pas relu"


@cas_test("les journaux gardent leurs anciennes adresses")
def _():
    # Ils racontent ce qui a été fait, y compris une adresse depuis corrigée. Les relire comme des
    # porteurs vivants obligerait à réécrire l'histoire à chaque renommage.
    lus = {pathlib.Path(relatif).name for relatif, _ in ck.fichiers()}
    for journal in ck.JOURNAUX:
        assert journal not in lus, f"{journal} est relu comme un porteur"


@cas_test("chaque page annoncée existe dans le dépôt")
def _():
    for url, fichier in liens.FICHIERS.items():
        assert (ck.RACINE / fichier).is_file(), f"{url} → {fichier} absent"


@cas_test("le dépôt tel qu'il est passe")
def _():
    assert ck.ecarts() == [], ck.ecarts()


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
