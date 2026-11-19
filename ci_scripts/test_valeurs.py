#!/usr/bin/env python3
"""Les cas de `check_valeurs.py`, sur une arborescence fabriquée.

Ce qui est éprouvé : que le contrôle refuse un nombre dans une vue QUELLE QUE SOIT SON ÉCRITURE
— c'est sa raison d'être, `check_grille.py` n'en lisait que trois — ; qu'il laisse passer ce qui
n'est pas une mesure ; qu'il ne lit ni les chaînes ni les commentaires ; que le système de
design peut déclarer mais pas mettre en page à la main ; et qu'il ne rend pas un vert quand il
n'a rien lu.
"""
import pathlib
import subprocess
import sys
import tempfile

ICI = pathlib.Path(__file__).resolve().parent

cas = []


def cas_de(nom):
    def decorateur(f):
        cas.append((nom, f))
        return f
    return decorateur


PROPRE = "struct A: View { var body: some View { Text(nom).padding(.top, HZEspace.marge) } }\n"
JETONS = "enum HZEspace {\n    static let marge: CGFloat = 20\n}\n"


def lancer_sur(vues: dict, systeme: dict | None = None, sans: str | None = None):
    """Lance une copie du contrôle sur un faux dépôt ; rend (code, sortie)."""
    with tempfile.TemporaryDirectory() as tmp:
        racine = pathlib.Path(tmp)
        dossier_vues = racine / "Haizo" / "Views" / "Refonte"
        dossier_systeme = racine / "Haizo" / "DesignSystem" / "Refonte"
        dossier_vues.mkdir(parents=True)
        dossier_systeme.mkdir(parents=True)
        for nom, contenu in vues.items():
            (dossier_vues / nom).write_text(contenu)
        for nom, contenu in ({"HZForme.swift": JETONS} if systeme is None else systeme).items():
            (dossier_systeme / nom).write_text(contenu)
        if sans == "vues":
            dossier_vues.rmdir()
            dossier_vues.parent.rmdir()
        (racine / "ci_scripts").mkdir()
        copie = racine / "ci_scripts" / "check_valeurs.py"
        copie.write_text((ICI / "check_valeurs.py").read_text())
        r = subprocess.run([sys.executable, str(copie)], capture_output=True, text=True)
        return r.returncode, r.stdout + r.stderr


def vue(corps: str) -> dict:
    return {"A.swift": PROPRE, "B.swift": corps + "\n"}


def refuse(corps: str, attendu: str, pourquoi: str):
    code, sortie = lancer_sur(vue(corps))
    assert code == 1, f"{pourquoi} — c'est passé :\n{sortie}"
    assert f"B.swift:1 : {attendu} est écrit en dur" in sortie, sortie


def passe(corps: str, pourquoi: str):
    code, sortie = lancer_sur(vue(corps))
    assert code == 0, f"{pourquoi} — c'est refusé :\n{sortie}"


@cas_de("une vue sans un nombre passe")
def _():
    code, sortie = lancer_sur({"A.swift": PROPRE})
    assert code == 0, sortie
    assert "1 vue(s)" in sortie, sortie


@cas_de("une marge écrite à la main est refusée")
def _():
    refuse("    .padding(.top, 22)", "22", "la marge de la planche du 17 novembre")


@cas_de("UN `.frame(width: 318)` EST REFUSÉ — l'écriture que check_grille n'a jamais lue")
def _():
    refuse("    .frame(width: 318, height: 430)", "318", "une taille en dur")


@cas_de("une teinte en hexadécimal est refusée")
def _():
    refuse("let rose = Color(hex: 0xFF2E6E)", "0xFF2E6E", "une couleur recopiée dans une vue")


@cas_de("une opacité est refusée")
def _():
    refuse("    .opacity(0.5)", "0.5", "une opacité en dur")


@cas_de("une valeur négative est refusée")
def _():
    refuse("    .padding(.leading, -5)", "5", "un débord en dur")


@cas_de("une constante DÉCLARÉE DANS LA VUE est refusée — la déclaration va dans le système")
def _():
    refuse("private enum Mise { static let ecart: CGFloat = 10 }", "10",
           "une valeur nommée en tête de vue reste une valeur dans la vue")


@cas_de("un compte de colonnes ou de lignes est refusé")
def _():
    refuse("let colonnes = 8", "8", "un compte en dur")
    refuse("    .lineLimit(2)", "2", "deux lignes est une décision de mise en page")


@cas_de("les deux bornes d'un intervalle sont lues — le point devant un nombre ne le cache pas")
def _():
    refuse("ForEach(1...6, id: \\.self) { _ in }", "6", "la borne haute d'un intervalle")


@cas_de("zéro passe partout : ce n'est pas une mesure")
def _():
    passe("VStack(alignment: .leading, spacing: 0) { Spacer(minLength: 0) }", "spacing: 0")


@cas_de("`.lineLimit(1)` passe")
def _():
    passe("    .lineLimit(1)", "tenir sur une ligne n'est pas une mesure")


@cas_de("un `1` de compte passe, un `1` de mise en page non")
def _():
    passe("let suivant = indice + 1", "l'unité d'un compte")
    refuse("    .padding(.top, 1)", "1", "un point de marge écrit à la main")
    refuse("Rectangle().frame(height: 1)", "1", "un filet d'un point écrit à la main")


@cas_de("un nombre dans une chaîne ou dans un commentaire ne compte pas")
def _():
    passe('Text(verbatim: "5 × 500") // 128 points dans le canvas', "un spécimen et sa note")
    passe("/* avant : .padding(.top, 22) */ Text(nom)", "un commentaire en bloc")
    passe("/// `.padding(.top, 22)` était la valeur du canvas", "un commentaire de documentation")


@cas_de("un // DANS UNE CHAÎNE n'ouvre pas de commentaire")
def _():
    refuse('let u = "https://haizo.app"; let largeur = 318', "318",
           "la ligne a été coupée sur le // d'une URL")


@cas_de("une chaîne sur plusieurs lignes est sautée, et le code qui la suit est lu")
def _():
    code, sortie = lancer_sur(vue('let t = """\n  12 km\n  """\nlet marge = 14'))
    assert code == 1, sortie
    assert "B.swift:4 : 14" in sortie and "B.swift:2" not in sortie, sortie


@cas_de("le nom d'un jeton qui finit par un chiffre n'est pas un nombre")
def _():
    passe("Text(nom).font(HZPolice.texte(.c15, .gras)); let a = paire.0; let b = $0", "c15")


@cas_de("le système de design DÉCLARE : ses constantes passent")
def _():
    code, sortie = lancer_sur({"A.swift": PROPRE}, {
        "HZForme.swift": JETONS + "enum F { case a\n    var l: CGFloat { self == .a ? 150 : 160 }\n}\n"})
    assert code == 0, f"une déclaration du système a été refusée :\n{sortie}"


@cas_de("mais il ne met pas en page à la main : marge, pile, rayon, trait")
def _():
    for ligne, attendu in (("            .padding(.top, 9)", "9"),
                           ("        VStack(alignment: .leading, spacing: 9) {", "9"),
                           ("            in: RoundedRectangle(cornerRadius: 14, style: .circular))", "14"),
                           ("                         lineWidth: 2)", "2"),
                           ("            .frame(width: 318)", "318")):
        code, sortie = lancer_sur({"A.swift": PROPRE}, {"HZForme.swift": JETONS,
                                                       "HZCarte.swift": "struct C: View {\n" + ligne + "\n}\n"})
        assert code == 1, f"`{ligne.strip()}` est passé dans le système :\n{sortie}"
        assert f"HZCarte.swift:2 : {attendu}" in sortie, sortie


@cas_de("le fichier d'icônes engendré n'est pas lu")
def _():
    code, sortie = lancer_sur({"A.swift": PROPRE}, {
        "HZForme.swift": JETONS,
        "HZDessins.swift": "extension HZDessin {\n    static let a = HZDessin(traces: [\n"
                           "            .ligne(5, 11),\n        ])\n}\n"})
    assert code == 0, f"des coordonnées de tracé ont été prises pour des mesures :\n{sortie}"


@cas_de("sans dossier de vues, le contrôle le dit")
def _():
    code, sortie = lancer_sur({}, sans="vues")
    assert code != 0, f"un dépôt sans le dossier de la refonte a rendu un vert :\n{sortie}"
    assert "introuvable" in sortie, sortie


@cas_de("un dossier de vues VIDE ne rend pas un vert")
def _():
    code, sortie = lancer_sur({})
    assert code != 0, f"le contrôle n'a rien lu et a rendu un vert :\n{sortie}"
    assert "ne garderait rien" in sortie, sortie


@cas_de("le vrai dépôt passe")
def _():
    r = subprocess.run([sys.executable, str(ICI / "check_valeurs.py")], capture_output=True, text=True)
    assert r.returncode == 0, f"le dépôt tel qu'il est ne passe pas :\n{r.stdout}{r.stderr}"


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
