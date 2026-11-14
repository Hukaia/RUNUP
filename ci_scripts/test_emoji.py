#!/usr/bin/env python3
"""Ce que `check_emoji.py` doit voir, et surtout ce qu'il ne doit PAS refuser.

Les cas négatifs comptent plus que les positifs ici. Le dépôt emploie `✓`, `▲`, `▼`, `·`, `—`,
`″` : ce sont des marques typographiques. La première version du garde prenait la plage
U+2600–U+27BF en bloc et signalait les huit `✓` du catalogue — un garde qui refuse du code juste
est pire qu'aucun garde, et celui-là aurait été désactivé dans la semaine.
"""

import sys

import check_emoji as ck

cas = []


def cas_test(nom):
    def prendre(f):
        cas.append((nom, f))
        return f
    return prendre


# ── CE QUI DOIT ÊTRE REFUSÉ ──────────────────────────────────────────────────────────────────

@cas_test("la montre du toast est refusée (le défaut réel du 14 novembre)")
def _():
    assert ck.emojis("Course reçue de ta montre ⌚") == ["⌚"]


@cas_test("les pictogrammes des plans hauts sont refusés")
def _():
    for e in ("🔥", "🏃", "✅", "🎉", "💪"):
        assert ck.emojis(f"Bravo {e}") == [e], e


@cas_test("UN CARACTÈRE SUIVI DE U+FE0F est refusé, car il DEMANDE la présentation emoji")
def _():
    # `☀` seul est typographique ; `☀️` est un emoji. C'est la même lettre et deux intentions.
    assert ck.emojis("Beau temps ☀️") == ["☀️"]
    assert ck.emojis("Beau temps ☀") == []


@cas_test("un drapeau est refusé")
def _():
    assert ck.emojis("🇫🇷") != []


# ── CE QUI DOIT PASSER ───────────────────────────────────────────────────────────────────────

@cas_test("LA COCHE TYPOGRAPHIQUE PASSE — huit clés du catalogue l'emploient")
def _():
    assert ck.emojis("✓ Terminé") == []
    assert ck.emojis("CONNECTÉ ✓") == []


@cas_test("les signes de hausse et de baisse passent")
def _():
    assert ck.emojis("▲ 18″/km") == []
    assert ck.emojis("▼ 2,4 km") == []


@cas_test("la ponctuation de l'app passe")
def _():
    assert ck.emojis("Semaine 1 · Bloc Base — 10 km") == []
    assert ck.emojis("5:24 /km · 12 sorties") == []


@cas_test("une lettre accentuée suivie d'un signe ne devient pas un emoji")
def _():
    assert ck.emojis("é à ù ñ ü") == []


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
