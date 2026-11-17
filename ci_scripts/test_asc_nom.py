#!/usr/bin/env python3
"""Les cas de `asc.py push-name`, contre une fausse API d'Apple.

Ce qui est éprouvé, c'est ce que la commande ÉCRIT et ce qu'elle refuse d'écrire :

  — rien du tout en essai à blanc ;
  — le NOM, et aucun autre attribut : ni sous-titre, ni description ;
  — rien quand le nom est déjà bon ;
  — un `appInfo` en vente qui refuse (409) n'empêche pas l'`appInfo` éditable d'accepter ;
  — et l'échec franc, avec la raison d'Apple, quand AUCUN ne l'accepte.

Une commande qui écrit sur la fiche publique d'une app en vente se vérifie avant, sur une
fausse API, pas pendant.
"""
import contextlib
import io
import sys

import asc

cas = []


def cas_de(nom):
    def decorateur(f):
        cas.append((nom, f))
        return f
    return decorateur


class FausseApi:
    """Une seule app, des `appInfo` aux états choisis, et le journal de ce qu'on y a écrit."""

    def __init__(self, infos, refus=()):
        # infos : {id d'appInfo: (état, {locale: nom})} ; refus : les états qui rendent un 409.
        self.infos, self.refus, self.ecritures = infos, set(refus), []

    def __call__(self, methode, chemin, corps=None, strict=True):
        if methode == "GET" and chemin == "apps":
            return {"data": []}
        if methode == "GET" and chemin.endswith("/appInfos"):
            return {"data": [{"id": i, "attributes": {"state": etat}}
                             for i, (etat, _) in self.infos.items()]}
        if methode == "GET" and chemin.endswith("/appInfoLocalizations"):
            i = chemin.split("/")[1]
            return {"data": [{"id": f"{i}:{loc}", "attributes": {"locale": loc, "name": nom}}
                             for loc, nom in self.infos[i][1].items()]}
        if methode == "PATCH":
            i = chemin.split("/")[1].split(":")[0]
            etat = self.infos[i][0]
            if etat in self.refus:
                raise asc.ErreurApple(409, [f"STATE_ERROR — l'appInfo est {etat}"])
            self.ecritures.append((chemin, corps["data"]["attributes"]))
            return {}
        raise AssertionError(f"appel imprévu : {methode} {chemin}")


NOMS = {"fr-FR": "Haizo : Coach de Course", "en-US": "Haizo: Running Coach",
        "es-ES": "Haizo: Entrenador Running"}
ANCIENS = {"fr-FR": "Ancien nom", "en-US": "Old name", "es-ES": "Nombre antiguo"}


def lancer(api, dry_run=False):
    """Exécute la commande ; rend (code de sortie, sortie imprimée)."""
    vraies = (asc.call, asc.app_id, asc.listing)
    asc.call = api
    asc.app_id = lambda: ("APP", "Ancien nom")
    asc.listing = lambda: {loc: {"name": nom} for loc, nom in NOMS.items()}
    sortie = io.StringIO()
    code = 0
    try:
        with contextlib.redirect_stdout(sortie), contextlib.redirect_stderr(sortie):
            asc.cmd_push_name(type("A", (), {"dry_run": dry_run})())
    except SystemExit as e:
        code = 1 if isinstance(e.code, str) or e.code else 0
        if isinstance(e.code, str):
            sortie.write(e.code)
    finally:
        asc.call, asc.app_id, asc.listing = vraies
    return code, sortie.getvalue()


@cas_de("l'essai à blanc n'écrit rien, et montre l'avant et l'après")
def _():
    api = FausseApi({"A": ("PREPARE_FOR_SUBMISSION", dict(ANCIENS))})
    code, sortie = lancer(api, dry_run=True)
    assert code == 0, sortie
    assert api.ecritures == [], f"l'essai à blanc a écrit : {api.ecritures}"
    assert "« Ancien nom » → « Haizo : Coach de Course »" in sortie, sortie
    assert "rien n'a été envoyé" in sortie, sortie


@cas_de("l'envoi écrit le nom, et SEULEMENT le nom, dans les trois langues")
def _():
    api = FausseApi({"A": ("PREPARE_FOR_SUBMISSION", dict(ANCIENS))})
    code, sortie = lancer(api)
    assert code == 0, sortie
    assert len(api.ecritures) == 3, api.ecritures
    for chemin, attributs in api.ecritures:
        assert list(attributs) == ["name"], f"autre chose que le nom a été envoyé : {attributs}"
    ecrits = {chemin.split(":")[1]: a["name"] for chemin, a in api.ecritures}
    assert ecrits == NOMS, ecrits


@cas_de("un nom déjà bon n'est pas réécrit")
def _():
    api = FausseApi({"A": ("PREPARE_FOR_SUBMISSION", {**ANCIENS, "fr-FR": NOMS["fr-FR"]})})
    code, sortie = lancer(api)
    assert code == 0, sortie
    assert {c.split(":")[1] for c, _ in api.ecritures} == {"en-US", "es-ES"}, api.ecritures
    assert "déjà à jour" in sortie, sortie


@cas_de("l'appInfo en vente refuse, l'éditable accepte : c'est un succès, et le refus est dit")
def _():
    api = FausseApi({"VENTE": ("READY_FOR_SALE", dict(ANCIENS)),
                     "EDIT": ("PREPARE_FOR_SUBMISSION", dict(ANCIENS))},
                    refus={"READY_FOR_SALE"})
    code, sortie = lancer(api)
    assert code == 0, sortie
    assert len(api.ecritures) == 3 and all(c.startswith("appInfoLocalizations/EDIT") for c, _ in api.ecritures)
    assert "refusé (READY_FOR_SALE)" in sortie, sortie
    assert "prochaine version" in sortie, sortie


@cas_de("si AUCUN appInfo n'accepte, la commande échoue et dit pourquoi")
def _():
    api = FausseApi({"VENTE": ("READY_FOR_SALE", dict(ANCIENS))}, refus={"READY_FOR_SALE"})
    code, sortie = lancer(api)
    assert code == 1, f"un refus total a rendu un succès :\n{sortie}"
    assert "STATE_ERROR" in sortie and "creer-la-version" in sortie, sortie


@cas_de("un nom de plus de 30 caractères arrête la commande AVANT tout appel d'écriture")
def _():
    api = FausseApi({"A": ("PREPARE_FOR_SUBMISSION", dict(ANCIENS))})
    vraies = (asc.call, asc.app_id, asc.listing)
    asc.call, asc.app_id = api, lambda: ("APP", "x")
    asc.listing = lambda: {"fr-FR": {"name": "H" * (asc.LIMITE_DU_NOM + 1)}}
    try:
        try:
            asc.cmd_push_name(type("A", (), {"dry_run": False})())
            sortie = ""
        except SystemExit as e:
            sortie = str(e.code)
    finally:
        asc.call, asc.app_id, asc.listing = vraies
    assert "limite d'Apple" in sortie, f"le nom trop long n'a pas arrêté la commande : {sortie!r}"
    assert api.ecritures == [], "une écriture est partie malgré un nom trop long"


@cas_de("une langue absente de l'appInfo est signalée, pas inventée")
def _():
    api = FausseApi({"A": ("PREPARE_FOR_SUBMISSION", {"fr-FR": "Ancien", "en-US": "Old"})})
    code, sortie = lancer(api)
    assert code == 1, sortie
    assert "es-ES" in sortie and "aucune fiche pour cette langue" in sortie, sortie
    assert len(api.ecritures) == 2, api.ecritures


@cas_de("les trois noms de la fiche tiennent dans la limite d'Apple")
def _():
    reel = asc.listing()
    for locale, champs in reel.items():
        assert 0 < len(champs["name"]) <= asc.LIMITE_DU_NOM, (locale, champs["name"])
        assert champs["name"].startswith("Haizo"), (locale, champs["name"])


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
