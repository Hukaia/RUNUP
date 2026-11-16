#!/usr/bin/env python3
"""Vérifie `check_marque.py` sur des cas écrits exprès.

Ce qui compte ici est autant ce qu'il doit LAISSER PASSER que ce qu'il doit refuser : une
barrière qui refuse un identifiant qu'on ne peut pas renommer finit contournée, et elle aura
coûté la panne qu'elle prétendait éviter.
"""
import pathlib
import sys
import tempfile

import check_marque as ck
import liens

cas = []
def cas_test(nom):
    def deco(f):
        cas.append((nom, f)); return f
    return deco


def _sur(contenu, nom="Haizo/X.swift"):
    """Fait tourner le contrôle sur une arborescence d'un seul fichier."""
    with tempfile.TemporaryDirectory() as d:
        racine = pathlib.Path(d)
        f = racine / nom
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_text(contenu, encoding="utf-8")
        return ck.main(racine)


@cas_test("un dépôt sans l'ancien nom passe")
def _():
    assert _sur('Text("Bienvenue dans Haizo Plus")\n') == 0


@cas_test("UNE SEULE OCCURRENCE OUBLIÉE SUFFIT À REFUSER")
def _():
    assert _sur('Text("Bienvenue dans RunUp Plus")\n') == 1


@cas_test("et la casse n'y change rien")
def _():
    for graphie in ("RUNUP", "runup", "RunUp", "Runup"):
        assert _sur(f'Text("{graphie}")\n') == 1, graphie


@cas_test("L'IDENTIFIANT DE L'APP PASSE — le renommer casse les abonnements")
def _():
    assert _sur('let id = "com.hicsuntco.runup.plus.yearly"\n') == 0


@cas_test("le groupe applicatif aussi — le renommer vide le widget et la montre")
def _():
    assert _sur('static let appGroupID = "group.com.hicsuntco.runup"\n') == 0


@cas_test("le domaine, les liens de club et le parrainage")
def _():
    assert _sur('if url.host == "runup-nu.vercel.app" { }\n') == 0


@cas_test("L'ADRESSE DE CONFIDENTIALITÉ, qui est sur la fiche App Store")
def _():
    # L'adresse est LUE dans `liens.py`, pas recopiée ici. `check_liens.py` refuse justement
    # toute copie en dur d'une adresse publiée — il a refusé ce cas-ci à sa première écriture,
    # et il avait raison : une copie ne se trompe pas le jour où on l'écrit, elle se trompe le
    # jour où l'original bouge. Le cas éprouve donc aussi que la tolérance couvre bien
    # l'adresse RÉELLE, et pas une qu'on aurait figée à côté.
    assert _sur(f'static let base = "{liens.BASE}"\n') == 0


@cas_test("le schéma d'URL déclaré chez Strava")
def _():
    assert _sur('URL(string: "runup://strava-callback")\n') == 0


@cas_test("l'en-tête HTTP partagé avec le serveur")
def _():
    assert _sur('static let header = "X-RunUp-Session-Renewed"\n') == 0


@cas_test("les variables d'environnement Vercel, qui vivent hors du dépôt")
def _():
    for v in ("RUNUP_APP_SECRET", "RUNUP_APP_SECRET_PREVIOUS",
              "RUNUP_SESSION_SECRET", "RUNUP_ADMIN_EMAILS"):
        assert _sur(f'process.env.{v}\n', nom="lib/a.js") == 0, v


@cas_test("UNE TOLÉRANCE NE COUVRE PAS SA LIGNE ENTIÈRE")
def _():
    # Le défaut qu'un masquage naïf par ligne aurait laissé passer : l'identifiant légitime
    # sert alors de laissez-passer à l'oubli qui le suit.
    assert _sur('let id = "com.hicsuntco.runup" // voir RunUp/Models/Liens.swift\n') == 1


@cas_test("LES CAPITALES SONT REFUSÉES HORS DU LOGO")
def _():
    assert _sur('Text("Bienvenue dans HAIZO Plus")\n') == 1


@cas_test("et acceptées dans les quatre fichiers qui portent le logo")
def _():
    assert _sur('Text(verbatim: "HAIZO")\n',
                nom="Haizo/Views/Components/SplashView.swift") == 0


@cas_test("UN JOURNAL GARDE L'ANCIEN NOM — c'est son travail de le raconter")
def _():
    assert _sur("## RunUp devient Haizo\n", nom="PROGRESS.md") == 0


@cas_test("et la liste des journaux est IMPORTÉE, pas recopiée")
def _():
    # Deux copies, et l'une des deux serait fausse le jour où un journal s'ajoute. C'est le
    # défaut que ce chantier a passé la matinée à corriger ailleurs.
    import check_liens
    assert ck.JOURNAUX is check_liens.JOURNAUX


@cas_test("mais un document qui DÉCRIT l'app est tenu au nom du jour")
def _():
    assert _sur("| L'app s'appelle RunUp |\n", nom="DESIGN.md") == 1


@cas_test("DEUX FICHIERS SEULEMENT S'EXEMPTENT, et ce sont le contrôle et ses cas")
def _():
    assert ck.SUR_LE_SUJET == {"ci_scripts/check_marque.py", "ci_scripts/test_marque.py"}


@cas_test("CHAQUE TOLÉRANCE PORTE UNE RAISON ÉCRITE, pas seulement un motif")
def _():
    for mot, raison in ck.TOLERES:
        assert len(raison) > 60, f"{mot} : raison trop courte pour être une raison"


@cas_test("le dépôt tel qu'il est passe")
def _():
    assert ck.main() == 0


def main():
    echecs = 0
    for nom, f in cas:
        try:
            f(); print(f"  ok   {nom}")
        except AssertionError as e:
            echecs += 1; print(f"  ÉCHEC {nom}\n        {e}")
    print(f"\n{len(cas) - echecs}/{len(cas)} cas passent.")
    return 1 if echecs else 0


if __name__ == "__main__":
    sys.exit(main())
