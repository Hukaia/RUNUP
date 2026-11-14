#!/usr/bin/env python3
"""La règle 7 interdit les emojis dans l'interface. Rien ne la tenait.

# CE QUE LA RÈGLE DIT, ET POURQUOI ELLE EST DURE À TENIR

« Pas de “Claude touch” — pas de dégradés dans l'interface, pas de glassmorphism, PAS D'EMOJIS,
pas de textes génériques. » Les dégradés ont `check_degrade.py`, le verre dépoli a le sien. Les
emojis n'avaient personne, et DESIGN.md le disait depuis le 13 novembre : « aucun garde ne tient
l'emoji ». `check_strings.py` ne pouvait pas s'en charger — il ignore explicitement les chaînes
sans lettre, parce que son sujet est la traduction.

Le risque n'est pas théorique. Une chaîne traduite revient d'une relecture avec un 🔥 ajouté « pour
faire vivant », et personne ne relit les 2 118 clés du catalogue à l'œil.

# CE QU'EST UN EMOJI, PRÉCISÉMENT

Pas « tout ce qui n'est pas une lettre ». Le dépôt emploie `✓`, `▲`, `▼`, `·`, `—`, `″` : ce sont
des marques typographiques, et les refuser serait refuser du code juste. La première version de ce
garde prenait la plage U+2600–U+27BF en bloc et signalait les huit `✓` du catalogue — un garde qui
refuse du code juste est pire qu'aucun garde.

La règle d'Unicode est nette : un caractère est un emoji s'il a la PRÉSENTATION EMOJI PAR DÉFAUT
(`Emoji_Presentation=Yes`), ou si on la lui demande explicitement avec U+FE0F derrière. `✓` (U+2713)
ne l'a pas ; `✅` (U+2705) l'a. C'est cette règle-là qui est écrite ci-dessous.
"""

import json
import pathlib
import sys

import couleurs
import swift

RACINE = couleurs.RACINE
CATALOGUE = RACINE / "RunUp/Resources/Localizable.xcstrings"

#: Les plans entiers où tout est emoji : pictogrammes, transports, symboles, drapeaux.
PLANS = [(0x1F000, 0x1FAFF), (0x1F1E6, 0x1F1FF)]

#: Le sélecteur de variante qui DEMANDE la présentation emoji. `☀` est un caractère
#: typographique ; `☀️` — le même suivi de U+FE0F — est un emoji.
VARIANTE_EMOJI = 0xFE0F

#: Les caractères du plan de base qui ont la présentation emoji PAR DÉFAUT.
#:
#: La liste est écrite plutôt que devinée : c'est `Emoji_Presentation=Yes` hors des plans
#: ci-dessus, d'après la table d'Unicode. Tout ce qui n'y est pas et qui n'est pas suivi de
#: U+FE0F est une marque typographique, et passe.
BASE = (
    "⌚⌛⏩⏪⏫⏬⏰⏳◽◾"
    "☔☕♈♉♊♋♌♍♎♏"
    "♐♑♒♓♿⚓⚡⚪⚫⚽"
    "⚾⛄⛅⛎⛔⛪⛲⛳⛵⛺"
    "⛽✅✊✋✨❌❎❓❔❕"
    "❗➕➖➗➰➿⬛⬜⭐⭕"
)


def emojis(texte: str) -> list:
    """Les emojis d'un texte, dans l'ordre où ils apparaissent."""
    trouves = []
    for i, caractere in enumerate(texte):
        point = ord(caractere)
        if point == VARIANTE_EMOJI:
            continue
        suivant = texte[i + 1] if i + 1 < len(texte) else ""
        demande = ord(suivant) == VARIANTE_EMOJI if suivant else False
        if (any(a <= point <= b for a, b in PLANS)
                or caractere in BASE
                or (demande and not caractere.isalnum())):
            trouves.append(caractere + (suivant if demande else ""))
    return trouves


def ecarts() -> list:
    problemes = []

    # ── Le catalogue, dans les TROIS langues ──────────────────────────────────────────────────
    #
    # La clé française est le texte affiché en français : elle compte autant que ses traductions.
    if CATALOGUE.is_file():
        catalogue = json.loads(CATALOGUE.read_text(encoding="utf-8"))
        for cle, valeur in catalogue.get("strings", {}).items():
            textes = {"la clé": cle}
            for langue, bloc in valeur.get("localizations", {}).items():
                unite = bloc.get("stringUnit", {}).get("value")
                if unite:
                    textes[langue] = unite
            for ou, texte in textes.items():
                for emoji in emojis(texte):
                    problemes.append((f"Localizable.xcstrings ({ou})", cle[:60], emoji))
    else:
        problemes.append(("Localizable.xcstrings", "", "introuvable"))

    # ── Le code, commentaires retirés et chaînes gardées ──────────────────────────────────────
    #
    # Un emoji dans un commentaire ne s'affiche pas — celui-ci en cite d'ailleurs. Un emoji dans
    # un littéral, si.
    for chemin in sorted((RACINE / "RunUp").rglob("*.swift")):
        source = swift.sans_commentaires_seuls(chemin.read_text(encoding="utf-8"))
        for numero, ligne in enumerate(source.split("\n"), 1):
            for emoji in emojis(ligne):
                problemes.append((str(chemin.relative_to(RACINE)), f"ligne {numero}", emoji))
    return problemes


def main() -> int:
    problemes = ecarts()
    if problemes:
        print(f"{len(problemes)} emoji(s) dans l'interface — la règle 7 les interdit :\n")
        for ou, quoi, emoji in problemes:
            print(f"  • {ou} — {quoi}")
            print(f"      {emoji}\n")
        return 1
    print("Aucun emoji dans l'interface, ni au catalogue dans les trois langues.")
    print("Les marques typographiques (✓, ▲, ▼, ·, —, ″) ne sont pas des emojis et passent.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
