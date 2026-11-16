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
        # `noms` et non `main` : ce dépôt d'un seul fichier ne contient pas le catalogue de
        # l'app, dont `le_mot` a son propre jeu de cas.
        return 1 if ck.noms(racine) else 0


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


@cas_test("et acceptées dans CHAQUE fichier de la liste, quelle qu'elle soit")
def _():
    # Épinglé sur SplashView jusqu'au 16 novembre, où cet écran a cessé de composer le nom en
    # capitales pour poser le mot dessiné. Le cas a alors éprouvé une exemption qui n'existait
    # plus. Il porte maintenant sur la PROPRIÉTÉ — tout ce qui est dans la liste passe, tout ce
    # qui n'y est pas est refusé — et il survit au prochain élagage.
    assert ck.PORTEURS_DU_LOGO, "la liste est vide : ce cas ne prouverait rien"
    for nom in ck.PORTEURS_DU_LOGO:
        assert _sur('le mot HAIZO\n', nom=nom) == 0, nom
    assert _sur('le mot HAIZO\n', nom="Haizo/Views/Ailleurs.swift") == 1


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


@cas_test("LA BRANCHE DE TRAVAIL EST TOLÉRÉE — c'est son absence qui a éteint TestFlight")
def _():
    # Elle n'était pas dans la liste le 16 novembre. Le balayage l'a donc renommée dans
    # `testflight.yml`, vers une branche inexistante, et le workflow s'est tu douze commits.
    # Ce cas rougit le jour où quelqu'un retire l'entrée en croyant nettoyer.
    mots = [m for m, _ in ck.TOLERES]
    assert "claude/runup-ios-swiftui-app-5b1yv6" in mots, mots
    # Et le contrôle ne doit plus la voir comme un reste, où qu'elle soit écrite.
    assert ck.restes("on:\n  push:\n    branches:\n"
                     "      - claude/runup-ios-swiftui-app-5b1yv6\n") == []


@cas_test("UN FICHIER QUE GIT IGNORE N'EST PAS JUGÉ — c'est l'échec de TestFlight 576")
def _():
    # `Haizo.xcodeproj/project.pbxproj` est FABRIQUÉ par XcodeGen au début du workflow et écarté
    # par `.gitignore`. Il n'existe pas en local. Le contrôle lisait donc un ensemble de fichiers
    # en local et un autre en CI, sans que rien ne le dise : la barrière passait, la chaîne
    # refusait sur trois lignes, et le groupe qu'elle nommait était le nom du DÉPÔT.
    import subprocess
    with tempfile.TemporaryDirectory() as d:
        racine = pathlib.Path(d)
        for cmd in (["git", "init", "-q"], ["git", "config", "user.email", "x@y.z"],
                    ["git", "config", "user.name", "x"]):
            subprocess.run(cmd, cwd=racine, check=True, capture_output=True)
        (racine / ".gitignore").write_text("*.xcodeproj/\n", encoding="utf-8")
        (racine / "Haizo.xcodeproj").mkdir()
        (racine / "Haizo.xcodeproj" / "project.pbxproj").write_text(
            "name = RUNUP;\n", encoding="utf-8")
        lus = {str(f.relative_to(racine)) for f in ck.fichiers(racine)}
        assert "Haizo.xcodeproj/project.pbxproj" not in lus, lus
        assert ".gitignore" in lus, "le .gitignore lui-même reste lu"


@cas_test("mais un fichier SUIVI par git l'est, même avec la même extension")
def _():
    # L'exclusion porte sur « git l'ignore », pas sur « ça ressemble à une sortie de build ».
    import subprocess
    with tempfile.TemporaryDirectory() as d:
        racine = pathlib.Path(d)
        subprocess.run(["git", "init", "-q"], cwd=racine, check=True, capture_output=True)
        (racine / "garde.pbxproj").write_text("name = RUNUP;\n", encoding="utf-8")
        lus = {str(f.relative_to(racine)) for f in ck.fichiers(racine)}
        assert "garde.pbxproj" in lus, lus


@cas_test("sans git, le contrôle lit tout plutôt que de ne rien lire")
def _():
    # Un dossier qui n'est pas un dépôt : `git check-ignore` échoue. Se taire reviendrait à ne
    # plus rien juger du tout, ce qui est pire que de juger un fichier de trop.
    with tempfile.TemporaryDirectory() as d:
        racine = pathlib.Path(d)
        (racine / "a.swift").write_text("// RUNUP\n", encoding="utf-8")
        assert ck.ignores_par_git(racine, [pathlib.Path("a.swift")]) == set()
        assert {str(f.relative_to(racine)) for f in ck.fichiers(racine)} == {"a.swift"}


@cas_test("CHAQUE TOLÉRANCE PORTE UNE RAISON ÉCRITE, pas seulement un motif")
def _():
    for mot, raison in ck.TOLERES:
        assert len(raison) > 60, f"{mot} : raison trop courte pour être une raison"


# --- LE MOT DE LA MARQUE, SON FICHIER ET SON INTENTION DE RENDU ---------------------------

def _catalogue(contents: str, avec_png=True):
    """Un dépôt d'un seul imageset, pour éprouver `le_mot`."""
    with tempfile.TemporaryDirectory() as d:
        racine = pathlib.Path(d)
        dossier = racine / ck.MOT
        dossier.mkdir(parents=True)
        (dossier / "Contents.json").write_text(contents, encoding="utf-8")
        if avec_png:
            (dossier / "haizo-mot.png").write_bytes(b"\x89PNG\r\n")
        return ck.le_mot(racine)


BON = ('{"images":[{"filename":"haizo-mot.png","idiom":"universal"}],'
       '"properties":{"template-rendering-intent":"template"}}')


@cas_test("un imageset complet et template ne pose aucun problème")
def _():
    assert _catalogue(BON) == []


@cas_test("UN FICHIER DÉCLARÉ MAIS ABSENT EST SIGNALÉ — la panne de la campagne 207")
def _():
    p = _catalogue(BON, avec_png=False)
    assert len(p) == 1 and "absent" in p[0], p


@cas_test("UNE INTENTION DE RENDU CHANGÉE EST SIGNALÉE — la panne qui ne fait aucun bruit")
def _():
    p = _catalogue(BON.replace('"template"', '"original"'))
    assert len(p) == 1 and "template" in p[0], p


@cas_test("et une intention ABSENTE aussi, parce que le défaut n'est pas template")
def _():
    p = _catalogue('{"images":[{"filename":"haizo-mot.png","idiom":"universal"}]}')
    assert len(p) == 1 and "template" in p[0], p


@cas_test("un catalogue qui ne nomme aucun fichier est signalé")
def _():
    p = _catalogue('{"images":[{"idiom":"universal"}],'
                   '"properties":{"template-rendering-intent":"template"}}')
    assert len(p) == 1 and "aucun fichier" in p[0], p


@cas_test("et un imageset disparu tout entier")
def _():
    with tempfile.TemporaryDirectory() as d:
        p = ck.le_mot(pathlib.Path(d))
    assert len(p) == 1 and "introuvable" in p[0], p


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
