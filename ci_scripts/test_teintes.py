#!/usr/bin/env python3
r"""Les cas de `check_teintes.py`.

CE FICHIER N'EXISTAIT PAS, ET C'EST LA RAISON DE SA NAISSANCE. Soixante-quatre gardes du dépôt
ont un `test_*.py` ; celui-ci n'en avait aucun, parce qu'il était écrit en code de PREMIER
NIVEAU : il s'exécutait à l'import et appelait `sys.exit`. On ne pouvait donc pas le faire tourner
sur un faux dépôt.

Le 16 novembre il a gagné une troisième règle — les valeurs recopiées à la main — et porte
maintenant QUATRE listes d'exceptions. Chacune doit pouvoir MAIGRIR, et c'est ce sens-là qui
pourrit quand personne ne le vérifie : une liste d'exceptions qui ne se vide jamais devient une
liste de passe-droits. Les deux sens de la nouvelle règle avaient été éprouvés à la main ce
jour-là. Une vérification faite une fois n'est pas un banc.
"""
import pathlib
import sys
import tempfile

ICI = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import check_teintes as ck  # noqa: E402

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


def avec(fichiers, autorise=None, cloche=None, directes=None, recopiees=None, valeurs=None):
    """Fait tourner les quatre règles sur un faux dépôt, avec les tables données."""
    anciens = (ck.AUTORISE, ck.CLOCHE_TOLEREE, ck.DIRECTES_AUTORISEES,
               ck.RECOPIEES_AUTORISEES, ck.VALEURS_DECORATIVES)
    try:
        ck.AUTORISE = autorise or {}
        ck.CLOCHE_TOLEREE = cloche or {}
        ck.DIRECTES_AUTORISEES = directes or {}
        ck.RECOPIEES_AUTORISEES = recopiees or {}
        ck.VALEURS_DECORATIVES = valeurs if valeurs is not None else {"38E0D0": {"cyanSombre"}}
        return ck.ecarts(faux_depot(fichiers))[0]
    finally:
        (ck.AUTORISE, ck.CLOCHE_TOLEREE, ck.DIRECTES_AUTORISEES,
         ck.RECOPIEES_AUTORISEES, ck.VALEURS_DECORATIVES) = anciens


# ── RÈGLE 1 : LES TEINTES D'EN-TÊTE ─────────────────────────────────────────────────────────

@cas_de("une teinte posée sur un en-tête de carte est refusée")
def _():
    # UNE TEINTE NEUTRE DANS LE FIXTUR, ET C'EST LE BANC QUI L'A DIT. Le premier jet posait
    # `RUColor.lime`, qui déclenche AUSSI la règle 3 : un cas qui réveille deux règles à la fois
    # n'éprouve ni l'une ni l'autre. Chaque cas ne touche qu'un garde.
    p = avec({"Haizo/V.swift": 'RUCardHeader(icon: "x", title: "Y", tint: Discipline.velo.teinte)'})
    assert len(p) == 1 and "une teinte posée sur un en-tête" in p[0], p


@cas_de("un `tint:` cité dans un COMMENTAIRE du corps ne compte pas")
def _():
    src = 'RUCardHeader(\n    icon: "x",\n    // on avait un tint: ici, il est parti\n    title: "Y")'
    assert avec({"Haizo/V.swift": src}) == []


@cas_de("une teinte déclarée au compte juste passe")
def _():
    d = {"Haizo/V.swift": 'RUCardHeader(icon: "x", title: "Y", tint: Discipline.velo.teinte)'}
    assert avec(d, autorise={"Haizo/V.swift": (1, "elle nomme la discipline")}) == []


@cas_de("une de plus sonne")
def _():
    d = {"Haizo/V.swift": 'RUCardHeader(title: "A", tint: a)\nRUStatTile(title: "B", tint: b)'}
    p = avec(d, autorise={"Haizo/V.swift": (1, "une seule")})
    assert any("2 teinte(s), 1 déclarée(s)" in x for x in p), p


@cas_de("une de MOINS sonne aussi — une liste qui ne maigrit pas devient un passe-droit")
def _():
    p = avec({"Haizo/V.swift": "// rien\n"}, autorise={"Haizo/V.swift": (1, "elle a disparu")})
    assert any("0 teinte(s), 1 déclarée(s)" in x for x in p), p


# ── RÈGLE 2 : LA CLOCHE ─────────────────────────────────────────────────────────────────────

@cas_de("une couleur de cloche écrite en dur est refusée")
def _():
    p = avec({"Haizo/N.swift": "AppNotification(colorHex: 0xFF6B4A, title: t)"})
    assert any("couleur de cloche écrite en dur, 0xFF6B4A" in x for x in p), p


@cas_de("et une valeur tolérée passe")
def _():
    d = {"Haizo/N.swift": "AppNotification(colorHex: 0xFF6B4A, title: t)"}
    assert avec(d, cloche={"0xFF6B4A": "la flamme, le temps d'une décision"}) == []


# ── RÈGLE 3 : LES TROIS COULEURS SÉMANTIQUES, POSÉES EN DIRECT ──────────────────────────────

@cas_de("`RUColor.lime` posé en direct est refusé")
def _():
    p = avec({"Haizo/V.swift": ".foregroundColor(RUColor.lime)"})
    assert any("`RUColor.lime` posé en direct" in x for x in p), p


@cas_de("un commentaire qui en parle ne compte pas")
def _():
    assert avec({"Haizo/V.swift": "// RUColor.lime est parti d'ici le 16"}) == []


@cas_de("un emploi direct de plus sonne")
def _():
    d = {"Haizo/V.swift": "a(RUColor.amber)\nb(RUColor.cyan)"}
    p = avec(d, directes={"Haizo/V.swift": (1, "un avertissement")})
    assert any("2 emploi(s) direct(s), 1 déclaré(s)" in x for x in p), p


@cas_de("un de moins sonne AUSSI")
def _():
    p = avec({"Haizo/V.swift": "// vide\n"}, directes={"Haizo/V.swift": (1, "un avertissement")})
    assert any("0 emploi(s) direct(s), 1 déclaré(s)" in x for x in p), p


# ── RÈGLE 4 : LA MÊME TEINTE, RECOPIÉE À LA MAIN ────────────────────────────────────────────

@cas_de("UNE VALEUR RECOPIÉE EST REFUSÉE — c'est le turquoise des kcal du 16 novembre")
def _():
    # `LiveRunView` déclarait `static let cyan = Color(hex: 0x38E0D0)`, la valeur exacte de
    # `RUColor.cyanSombre`. Les trois règles au-dessus cherchent des NOMS ; celle-ci compare les
    # valeurs, et c'est tout ce qui la sépare d'un garde qui dit « 29 emplois, tous déclarés »
    # pendant que la couleur est à l'écran.
    p = avec({"Haizo/V.swift": "static let cyan = Color(hex: 0x38E0D0)"})
    assert any("est la valeur de `RUColor.cyanSombre`, recopiée" in x for x in p), p


@cas_de("une valeur VOISINE n'est pas la même couleur, et ne sonne pas")
def _():
    # Le contrôle ne juge que l'identité. L'app porte beaucoup de valeurs proches, et refuser la
    # ressemblance en ferait un garde qu'on désactive.
    assert avec({"Haizo/V.swift": "Color(hex: 0x38E0D1)"}) == []


@cas_de("une valeur recopiée de plus sonne")
def _():
    d = {"Haizo/V.swift": "a(0x38E0D0)\nb(0x38e0d0)"}
    p = avec(d, recopiees={"Haizo/V.swift": (1, "sémantique, et sa raison est écrite")})
    assert any("2 valeur(s) recopiée(s), 1 déclarée(s)" in x for x in p), p


@cas_de("une de moins sonne AUSSI")
def _():
    p = avec({"Haizo/V.swift": "// vide\n"},
             recopiees={"Haizo/V.swift": (1, "sémantique, et sa raison est écrite")})
    assert any("0 valeur(s) recopiée(s), 1 déclarée(s)" in x for x in p), p


@cas_de("la casse de l'hexadécimal ne change rien")
def _():
    p = avec({"Haizo/V.swift": "Color(hex: 0x38e0d0)"})
    assert len(p) == 1, p


# ── LE DÉPÔT ────────────────────────────────────────────────────────────────────────────────

@cas_de("chaque exception des quatre listes porte une raison écrite")
def _():
    for table, nom in ((ck.AUTORISE, "AUTORISE"), (ck.DIRECTES_AUTORISEES, "DIRECTES_AUTORISEES"),
                       (ck.RECOPIEES_AUTORISEES, "RECOPIEES_AUTORISEES")):
        for cle, (_, raison) in table.items():
            assert len(raison) > 40, f"{nom}[{cle}] : raison trop courte pour être une raison"


@cas_de("le dépôt tel qu'il est passe")
def _():
    fautes, _ = ck.ecarts()
    assert fautes == [], fautes


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
