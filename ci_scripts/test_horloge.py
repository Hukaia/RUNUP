#!/usr/bin/env python3
r"""Les cas de `check_horloge.py`.

CE QU'ILS EMPÊCHENT DE REVENIR. Huit lecteurs de l'horloge réelle ont été oubliés en trois
énumérations successives, les 14, 16 et 17 novembre. Le dernier a coûté le BOUTON « DÉMARRER »
sur l'image de tête de la fiche App Store : la campagne a franchi minuit, on est passé au mardi,
mardi est un jour de repos dans la semaine de démonstration, et la carte de séance s'est vidée.

ET LE CAS QUI COMPTE LE PLUS : « les autres lectures de l'horloge passent ». Un garde qui
refuserait les 170 horodatages de l'app serait désactivé la semaine suivante. On ne juge que la
question « quel jour sommes-nous ».
"""
import pathlib
import sys
import tempfile

ICI = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(ICI))
import check_horloge as ck  # noqa: E402

cas = []


def cas_de(nom):
    def decorateur(f):
        cas.append((nom, f))
        return f
    return decorateur


def avec(fichiers, permis=None):
    racine = pathlib.Path(tempfile.mkdtemp())
    for chemin, contenu in fichiers.items():
        f = racine / chemin
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_text(contenu, encoding="utf-8")
    return ck.ecarts(racine, permis or {})


@cas_de("LE JOUR DE LA SEMAINE LU SUR `.now` EST REFUSÉ — le défaut du 17 novembre")
def _():
    src = "        (Calendar.current.component(.weekday, from: .now) + 5) % 7"
    p = avec({"Haizo/P.swift": src})
    assert len(p) == 1 and "horloge RÉELLE" in p[0], p


@cas_de("et avec `Date()` plutôt que `.now`")
def _():
    p = avec({"Haizo/P.swift": "Calendar.current.component(.weekday, from: Date())"})
    assert len(p) == 1, p


@cas_de("LA SEMAINE COURANTE AUSSI — c'est l'autre façon de poser la même question")
def _():
    p = avec({"Haizo/V.swift": "cal.dateInterval(of: .weekOfYear, for: .now)?.start"})
    assert len(p) == 1, p


@cas_de("l'horloge de la scène passe")
def _():
    bon = {"Haizo/P.swift":
           "Calendar.current.component(.weekday, from: Demonstration.maintenant)\n"
           "cal.dateInterval(of: .weekOfYear, for: Demonstration.maintenant)?.start"}
    assert avec(bon) == []


@cas_de("LES AUTRES LECTURES DE L'HORLOGE PASSENT, et c'est tout l'équilibre du garde")
def _():
    # Horodater une course, mesurer un temps écoulé, dater un message : ces lectures DOIVENT
    # prendre l'heure réelle, même en démonstration. Un garde qui les refuserait serait
    # désactivé la semaine suivante.
    ordinaires = {"Haizo/S.swift":
                  "let debut = Date()\n"
                  "record.date = .now\n"
                  "let ecoule = Date().timeIntervalSince(debut)\n"
                  "let depuis = cal.dateComponents([.day], from: start, to: .now).day"}
    assert avec(ordinaires) == []


@cas_de("un commentaire qui cite le motif ne compte pas")
def _():
    src = "        // on lisait component(.weekday, from: .now) ici, voir check_horloge"
    assert avec({"Haizo/P.swift": src}) == []


@cas_de("une dispense comptée juste passe")
def _():
    d = {"Haizo/W.swift": "Calendar.current.component(.weekday, from: .now)"}
    assert avec(d, {"Haizo/W.swift": (1, "une extension qui ne connaît pas la démonstration")}) == []


@cas_de("un de plus sonne")
def _():
    d = {"Haizo/W.swift": "a(Calendar.current.component(.weekday, from: .now))\n"
                          "b(cal.dateInterval(of: .weekOfYear, for: .now))"}
    p = avec(d, {"Haizo/W.swift": (1, "une extension qui ne connaît pas la démonstration")})
    assert len(p) == 1 and "2 lecture(s)" in p[0], p


@cas_de("un de moins sonne AUSSI — une dispense qui ne maigrit pas devient un passe-droit")
def _():
    p = avec({"Haizo/W.swift": "// rien\n"},
             {"Haizo/W.swift": (1, "une extension qui ne connaît pas la démonstration")})
    assert len(p) == 1 and "0 lecture(s)" in p[0], p


@cas_de("le dépôt tel qu'il est passe")
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
