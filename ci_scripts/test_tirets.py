#!/usr/bin/env python3
"""Éprouve `check_tirets.py` : un contrôle qu'on n'a jamais vu échouer est un contrôle qu'on croit sur parole."""
import sys

import check_tirets as ck

cas = 0
echecs = 0


def verifie(nom, condition):
    global cas, echecs
    cas += 1
    if condition:
        print(f"  ok   {nom}")
    else:
        echecs += 1
        print(f"  ÉCHEC {nom}")


def entree(fr="x", en="x", es="x"):
    return {"localizations": {l: {"stringUnit": {"value": v}} for l, v in (("en", en), ("es", es))}}


verifie("une clé avec un tiret est refusée", len(ck.trouver({"Annulé — ton programme": entree()})) == 1)
verifie("une traduction avec un tiret est refusée", len(ck.trouver({"Annulé": entree(en="Undone — ok")})) == 1)
verifie("les deux traductions comptent", len(ck.trouver({"Annulé": entree(en="a — b", es="a — b")})) == 2)
verifie("le tiret seul est permis, en clé", ck.trouver({"—": entree()}) == [])
verifie("le tiret seul est permis, en valeur", ck.trouver({"Sans donnée": entree(en="—", es="—")}) == [])
verifie("un trait d'union ou une demi-cadratin ne comptent pas", ck.trouver({"Mi-séance 3–5 min": entree()}) == [])
verifie("une phrase propre passe", ck.trouver({"Annulé : ton programme n'a pas changé.": entree()}) == [])
verifie("le vrai catalogue passe", ck.main() == 0)

print(f"\n{cas - echecs}/{cas} cas passent.")
sys.exit(1 if echecs else 0)
