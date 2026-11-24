#!/usr/bin/env python3
"""Monte l'aperçu App Store : la fiche, mais animée.

    Entrée  : un enregistrement du simulateur, et une liste de plans
    Sortie  : un .mp4 de 886 × 1920, 30 i/s, H.264, prêt pour App Store Connect

    python3 ci_scripts/montage.py --entree brut.mov --sortie apercu.mp4 --plans plans.json

# POURQUOI UN MONTAGE, ET PAS LA CAPTATION

La première version envoyait l'enregistrement brut, conformé au format d'Apple. Verdict :
« niveau débutant ». Il était juste. Un enregistrement d'écran n'est pas un film — c'est
quelqu'un qui tapote des onglets. Pas de rythme, pas de cadrage, pas d'emphase, et surtout rien
de la fiche : ni le fond os, ni la typographie, ni les filets. Les captures et la vidéo
racontaient deux produits différents.

Ce script fait de la vidéo ce que `screenshots.py` fait des captures, et avec les MÊMES pièces :
le même fond, le même châssis d'appareil, la même police de titrage, les mêmes filets, la même
ligne courante. Une fiche qu'on fait défiler, et une vidéo qui se joue, doivent se reconnaître.

# COMMENT

Chaque plan est un morceau de l'enregistrement, posé dans l'écran du châssis, sur un fond
composé par Pillow — exactement l'image d'une capture, mais avec de la vidéo dans l'écran. Les
plans s'enchaînent par des coupes franches : un fondu entre deux plans de trois secondes mange
un cinquième du film pour ne rien dire.

Le titre de chaque plan entre par un glissement court. Le reste ne bouge pas : ce qui doit bouger
dans un aperçu d'app, c'est l'app.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import shutil
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import screenshots as S  # noqa: E402
import bascules as B  # noqa: E402
from PIL import Image, ImageDraw, ImageFilter  # noqa: E402

RACINE = pathlib.Path(__file__).resolve().parent.parent
LARGEUR, HAUTEUR = 886, 1920
IPS = 30
DEBIT = "11M"
SECONDES_MIN, SECONDES_MAX = 15, 30

# Le châssis, calculé une fois depuis les constantes de la fiche : les deux images doivent poser
# l'appareil au même endroit, à la même taille, sinon on voit qu'elles ont été faites séparément.
BEZEL = round(S.SCREEN_W * S.BEZEL)
CHASSIS = (S.SCREEN_W + 2 * BEZEL, round(S.SCREEN_W * 2868 / 1320) + 2 * BEZEL)
CHASSIS_X = (S.CANVAS[0] - CHASSIS[0]) // 2
ECRAN_XY = (CHASSIS_X + BEZEL, S.DEVICE_TOP + BEZEL)
ECRAN_WH = (S.SCREEN_W, CHASSIS[1] - 2 * BEZEL)


def fond(rang: int, bandeau: str) -> Image.Image:
    """Le décor d'un plan, SANS son titre : le fond, les filets, la ligne courante.

    Le cadre est pris dans la bande des six : chaque plan hérite donc d'un morceau DIFFÉRENT du
    fond et de la ligne courante, et celle-ci avance d'un plan à l'autre comme elle avance d'une
    capture à l'autre. Au-delà du sixième, on reboucle plutôt que de sortir de la bande.
    """
    return S.cadre((rang - 1) % S.TOTAL + 1, bandeau).convert("RGB")


def titre_calque(titre: str, sous: str, rang: int, total: int) -> Image.Image:
    """Le titre seul, sur du transparent, pour pouvoir le faire ENTRER.

    Il était cuit dans le fond, donc il apparaissait d'un bloc avec le reste : sept mises en page
    fixes qui se succèdent. Séparé, il peut monter de quarante pixels en un tiers de seconde,
    ce qui suffit à faire d'une coupe un début de plan.

    C'est le SEUL mouvement ajouté. Dans l'aperçu d'une app, ce qui doit bouger est l'app ; tout
    le reste qui s'agite lui vole l'attention qu'on a trois secondes pour lui donner.
    """
    calque = Image.new("RGBA", S.CANVAS, (0, 0, 0, 0))
    S._accroche(calque, (titre, sous), rang, total, numero=False)
    return calque


def chassis() -> Image.Image:
    """Le châssis seul, écran TRANSPARENT, pour se poser par-dessus la vidéo.

    `S.device` exige une capture : on lui en donne une noire, puis on perce l'écran. Reprendre
    son dessin à la main donnerait un deuxième châssis à maintenir, et les deux divergeraient —
    c'est le défaut que `screenshots.py` a déjà corrigé trois fois sur d'autres valeurs.
    """
    noir = Image.new("RGB", (1320, 2868), (0, 0, 0))
    corps, _, b = S.device(noir, screen_w=S.SCREEN_W)
    trou = Image.new("L", ECRAN_WH, 255)
    rayon = S.SCREEN_W * S.SCREEN_RADIUS
    masque = Image.new("L", ECRAN_WH, 0)
    ImageDraw.Draw(masque).rounded_rectangle((0, 0, ECRAN_WH[0] - 1, ECRAN_WH[1] - 1),
                                             radius=rayon, fill=255)
    vide = Image.new("RGBA", ECRAN_WH, (0, 0, 0, 0))
    corps.paste(vide, (b, b), masque)
    return corps


def plaque(titre: str, sous: str, rang: int, total: int, bandeau: str,
           dossier: pathlib.Path) -> tuple[pathlib.Path, pathlib.Path, pathlib.Path]:
    """Les trois calques d'un plan : le décor (avec l'ombre portée), le châssis percé, le titre.

    # RIEN N'EST REPRIS D'UN FICHIER DÉJÀ LÀ, ET C'EST LA CORRECTION DU 24 NOVEMBRE.

    Chaque calque n'était dessiné que si son fichier manquait. Or le workflow monte les trois
    langues dans le même dossier de travail, le français d'abord : les films anglais et espagnol
    reprenaient donc `titre-1.png`, `fond-1.png`… tels que le français les avait laissés. L'app à
    l'écran parlait anglais, le titre au-dessus et la ligne courante en dessous parlaient
    français. Rien ne le disait : le montage réussissait, les durées étaient justes.

    Un calque coûte une fraction de seconde à dessiner, et chacun n'est demandé qu'une fois par
    film. Il n'y avait rien à économiser, seulement de quoi se tromper de langue.
    """
    dossier.mkdir(parents=True, exist_ok=True)
    f = dossier / f"fond-{rang}.png"
    img = fond(rang, bandeau).convert("RGBA")
    # L'ombre de l'appareil appartient au FOND : posée avec le châssis, elle s'appliquerait
    # par-dessus la vidéo et noircirait le bas de l'écran.
    silhouette = Image.new("L", CHASSIS, 0)
    ImageDraw.Draw(silhouette).rounded_rectangle(
        (0, 0, CHASSIS[0] - 1, CHASSIS[1] - 1),
        radius=S.SCREEN_W * S.SCREEN_RADIUS + BEZEL, fill=255)
    ombre = Image.new("RGBA", S.CANVAS, (0, 0, 0, 0))
    ombre.paste(Image.new("RGBA", CHASSIS, (0, 0, 0, 120)), (CHASSIS_X, S.DEVICE_TOP + 26),
                silhouette)
    img.alpha_composite(ombre.filter(ImageFilter.GaussianBlur(40)))
    img.convert("RGB").save(f)
    c = dossier / "chassis.png"
    chassis().save(c)
    tt = dossier / f"titre-{rang}.png"
    titre_calque(titre, sous, rang, total).save(tt)
    return f, c, tt


#: Le mot de la marque, dessiné. Lu dans les ressources de l'app : un seul fichier porte la
#: forme, et `check_marque.py` vérifie qu'il existe toujours là où les scripts le cherchent.
MARQUE = "Haizo/Resources/Assets.xcassets/haizo-mot.imageset/haizo-mot.png"


def carte_titre(dossier: pathlib.Path, bandeau: str, mot: str, sous: str,
                role: str) -> pathlib.Path:
    """L'image d'ouverture ou de fin : le fond de la fiche, et le nom au centre.

    Deux secondes à l'entrée, une et demie à la sortie, sur vingt-quatre : Apple demande qu'un
    aperçu soit d'abord du contenu capturé dans l'app, et c'est aussi ce qu'on veut — une carte
    de titre longue est une publicité, pas une démonstration.
    """
    # NOMMÉE PAR SON RÔLE, ET TOUJOURS REDESSINÉE. Le fichier portait le MOT (« haizo »), qui
    # est le même à l'ouverture et à la fin : la carte de fin trouvait celle d'ouverture déjà
    # là et la rendait telle quelle. Le film se terminait sur « Course · Trail · Triathlon » au
    # lieu de « Sur l'App Store », dans les trois langues.
    f = dossier / f"carte-{role}.png"
    img = S.cadre(1, bandeau).convert("RGBA")
    d = ImageDraw.Draw(img)
    from PIL import ImageFont

    # LE MOT EST POSÉ, PAS COMPOSÉ — correction du 16 novembre.
    #
    # Il était écrit à 220 points dans Bricolage Grotesque Condensed, c'est-à-dire dans une
    # TROISIÈME fonte : ni celle de l'app, ni celle du logo. Ce carton est la première et la
    # dernière image que quelqu'un voit de la marque sur l'App Store, et il y montrait le nom
    # composé au lieu de la marque dessinée.
    #
    # LA FORME VIENT DU FICHIER DE L'APP, et il n'y en a qu'un. `haizo-mot.png` est une image
    # template : elle ne porte que l'alpha, donc on la teinte ici de l'encre du cadre comme
    # SwiftUI la teinte là-bas. Un seul dessin, deux rendus — plutôt qu'un second exemplaire
    # dans `appstore/` qui divergerait au premier ajustement.
    #
    # LA TAILLE EST MESURÉE SUR CE QU'ELLE REMPLACE : le nom composé en capitales rendait
    # 151 pixels d'encre de haut. Le mot dessiné est posé à cette hauteur-là, et fait alors
    # 473 pixels de large, soit 37 % du cadre. Le poids vertical de la carte ne bouge pas.
    forme = Image.open(S.ROOT / MARQUE).convert("RGBA")
    hauteur = 151
    largeur_marque = round(forme.width * hauteur / forme.height)
    forme = forme.resize((largeur_marque, hauteur), Image.LANCZOS)
    encre = Image.new("RGBA", forme.size, S.ENCRE + (255,))
    encre.putalpha(forme.getchannel("A"))
    y = S.CANVAS[1] // 2 - 190
    img.alpha_composite(encre, ((S.CANVAS[0] - largeur_marque) // 2, y))

    petite = ImageFont.truetype(str(S.FONTS / "InstrumentSans-Regular.ttf"), 54)
    w = d.textlength(sous, font=petite)
    d.text(((S.CANVAS[0] - w) / 2, y + 250), sous, font=petite, fill=S.ENCRE + (160,))
    img.convert("RGB").save(f)
    return f


# L'ENTRÉE DU TITRE. Quarante pixels de montée, un tiers de seconde, et une opacité qui suit.
ENTREE_DUREE = 0.34
ENTREE_MONTEE = 40


def plan_video(entree: pathlib.Path, debut: float, duree: float,
               fond_png: pathlib.Path, chassis_png: pathlib.Path, titre_png: pathlib.Path,
               sortie: pathlib.Path) -> None:
    """Un plan : l'enregistrement dans l'écran, entre le décor et le châssis, titre par-dessus."""
    d, h = ENTREE_DUREE, ENTREE_MONTEE
    # `fps` AVANT `trim`, ET C'EST LE DÉFAUT QUI A FAIT UN FILM TROP COURT.
    #
    # `simctl recordVideo` écrit en cadence VARIABLE : quand l'écran ne bouge pas, il n'émet
    # presque aucune image. Un plan fixe de deux secondes ne contenait donc qu'une poignée
    # d'images, et `trim` en rendait un peu plus d'une seconde — tandis que les plans où l'on
    # défile, eux, sortaient entiers. La version française est descendue à 12,8 s, sous le
    # plancher de quinze d'Apple.
    #
    # Remis en cadence fixe AVANT la découpe, les périodes immobiles retrouvent leurs images et
    # une seconde de source fait une seconde de film.
    filtre = (
        f"[0:v]fps={IPS},trim=start={debut}:duration={duree},setpts=PTS-STARTPTS,"
        f"scale={ECRAN_WH[0]}:{ECRAN_WH[1]}[ecran];"
        f"[1:v]loop=loop=-1:size=1:start=0,setpts=N/{IPS}/TB[bg];"
        f"[bg][ecran]overlay={ECRAN_XY[0]}:{ECRAN_XY[1]}:shortest=1[pose];"
        f"[2:v]loop=loop=-1:size=1:start=0,setpts=N/{IPS}/TB[ch];"
        f"[pose][ch]overlay={CHASSIS_X}:{S.DEVICE_TOP}:shortest=1[avecapp];"
        # Le titre monte et se révèle. `fade` agit sur l'alpha du calque, pas sur l'image dessous.
        f"[3:v]loop=loop=-1:size=1:start=0,setpts=N/{IPS}/TB,"
        f"format=rgba,fade=t=in:st=0:d={d}:alpha=1[titre];"
        f"[avecapp][titre]overlay=0:'if(lt(t,{d}), {h}*(1-t/{d}), 0)':shortest=1,"
        f"fps={IPS}[v]"
    )
    subprocess.run(
        ["ffmpeg", "-y", "-v", "error",
         "-i", str(entree), "-i", str(fond_png), "-i", str(chassis_png), "-i", str(titre_png),
         "-filter_complex", filtre, "-map", "[v]",
         "-t", f"{duree}", "-c:v", "libx264", "-crf", "16", "-pix_fmt", "yuv420p",
         str(sortie)], check=True)


#: Au-delà de cet écart, l'écran du plan ne ressemble à AUCUNE capture, même à la plus proche.
#: Un plan posé sur son écran rend 3 dans les campagnes (0,9 sur un enregistrement fabriqué) ; le
#: plus proche des autres écrans, 45 et plus. Sans ce plafond, l'écran d'accueil du simulateur
#: — sur lequel le film espagnol du 24 novembre finissait — passait pour « le plus proche de
#: l'accueil », à 108.
ECART_MAXIMUM = 20.0


def ecran_monte(morceau: pathlib.Path, duree: float, sortie: pathlib.Path) -> Image.Image:
    """Ce que l'écran du téléphone montre au milieu d'un plan MONTÉ, prêt à être comparé.

    Le même rognage que `bascules.py` (le haut de l'écran, au-dessus de la barre d'onglets), pris
    dans le morceau tel qu'il partira dans le film : derrière le châssis, à sa place.
    """
    sortie.unlink(missing_ok=True)
    x, y = ECRAN_XY
    largeur, hauteur = ECRAN_WH
    subprocess.run(
        ["ffmpeg", "-y", "-v", "error", "-ss", f"{duree / 2:.3f}", "-i", str(morceau),
         "-frames:v", "1",
         "-vf", f"crop={largeur}:{int(hauteur * B.HAUT_UTILE)}:{x}:{y},scale=258:-2,format=gray",
         str(sortie)], check=True)
    with Image.open(sortie) as im:
        return im.convert("L").copy()


def verifier_le_plan(nom: str, morceau: pathlib.Path, duree: float, temoins: pathlib.Path,
                     travail: pathlib.Path) -> str | None:
    """Le plan monté montre-t-il l'écran que son titre annonce ? Rend la plainte, ou rien.

    # POURQUOI LE MONTAGE SE RELIT

    `bascules.py` vérifie le découpage sur l'enregistrement, AVANT le montage. Le 24 novembre
    2026 il a validé l'espagnol — huit bascules sur huit — et le film monté sur ce même découpage
    posait « Tu día, en una pantalla » sur le Coach, puis chaque titre sur l'écran suivant, et
    finissait sur l'écran d'accueil du simulateur. La campagne était verte.

    Les deux outils ne lisaient pas l'enregistrement de la même façon, et un contrôle fait sur
    autre chose que ce qui sort ne contrôle pas ce qui sort. Celui-ci regarde le morceau qui
    part dans le film.
    """
    vise = B.ecran_vise(nom)
    image = ecran_monte(morceau, duree, travail / f"vu-{nom}.png")
    references = B.temoins(temoins, image)
    if vise not in references:
        return None
    classement = B.le_plus_proche(image, references)
    proche, ecart = classement[0]
    if proche == vise and ecart <= ECART_MAXIMUM:
        print(f"           écran « {vise} » sous son titre (écart {ecart:.1f})")
        return None
    if proche == vise:
        return (f"le plan « {nom} » ne montre aucun écran de l'app : le plus proche est "
                f"« {vise} », à {ecart:.1f} (plafond {ECART_MAXIMUM:.0f}) — image gardée : "
                f"{travail / f'vu-{nom}.png'}")
    return (f"le plan « {nom} » montre « {proche} » (écart {ecart:.1f}) et non « {vise} » "
            f"({dict(classement)[vise]:.1f}) — image gardée : {travail / f'vu-{nom}.png'}")


# ── LE DÉCALAGE, RELU DANS LA LECTURE DU MONTAGE ────────────────────────────────────────────────
#
# `bascules.py` cherche le décalage en demandant à ffmpeg « la première image après tel
# instant ». Le montage, lui, déroule l'enregistrement à trente images par seconde et coupe dans
# ce déroulé (`fps` puis `trim`, voir `plan_video`). Sur un enregistrement à cadence variable,
# ces deux lectures ne désignent pas toujours le même endroit : le 24 novembre 2026, sur
# l'espagnol, elles étaient à sept secondes l'une de l'autre. Le contrôle a validé huit bascules
# sur huit ; le film posait chaque titre sur l'écran suivant.
#
# On ne sait pas encore dire POURQUOI ces sept secondes (l'enregistrement fautif n'était pas
# gardé ; il l'est désormais quand un film échoue). On sait en revanche comment ne plus en
# dépendre : le montage vérifie le décalage qu'on lui donne DANS SA PROPRE LECTURE, et le
# recherche s'il ne tient pas.

#: De part et d'autre de chaque plan, l'instant où l'écran doit DÉJÀ et ENCORE être le bon. Le
#: test appuie 0,6 s avant le début du plan et le fondu dure 0,22 s : à 0,15 s du début, l'écran
#: est posé depuis un quart de seconde.
MARGE_DU_PLAN = 0.15
#: Aux BORDS d'un plan, l'écran peut encore s'installer (une courbe qui se trace, un chiffre qui
#: monte) : on y demande seulement qu'il soit reconnu, sans être plus loin de sa capture qu'un
#: AUTRE écran ne le serait (45 et plus, mesuré). Au MILIEU, il doit être posé : `ECART_MAXIMUM`.
ECART_AUX_BORDS = 40.0
#: Jusqu'où chercher autour du décalage reçu, et à quel pas.
RECHERCHE, PAS_DE_RECHERCHE = 10.0, 0.25


def derouler(entree: pathlib.Path, travail: pathlib.Path) -> dict[int, pathlib.Path]:
    """L'enregistrement déroulé à trente images par seconde, en petit et en gris.

    LE MÊME `fps` QUE `plan_video`, et c'est tout l'intérêt : une image numéro N est ici ce que
    `trim=start=N/30` rendra là-bas. Les fichiers portent leur numéro d'image (`-frame_pts`), donc
    aucune recherche dans un conteneur n'intervient entre « tel instant » et « telle image ».
    """
    dossier = travail / "deroule"
    shutil.rmtree(dossier, ignore_errors=True)
    dossier.mkdir(parents=True)
    subprocess.run(
        ["ffmpeg", "-y", "-v", "error", "-i", str(entree), "-an",
         "-vf", f"fps={IPS},crop=in_w:in_h*{B.HAUT_UTILE}:0:0,scale=258:-2,format=gray",
         "-frame_pts", "1", str(dossier / "%06d.png")], check=True)
    return {int(f.stem): f for f in dossier.glob("*.png")}


def _ecran_a(images: dict[int, pathlib.Path], seconde: float) -> Image.Image | None:
    chemin = images.get(round(seconde * IPS))
    if chemin is None:
        return None
    with Image.open(chemin) as im:
        return im.convert("L").copy()


def tient(plans: list[dict], decalage: float, images: dict[int, pathlib.Path],
          references: dict[str, Image.Image]) -> bool:
    """Chaque plan qui a une capture montre-t-il son écran, du début à la fin, à ce décalage ?"""
    juges = 0
    for p in plans:
        vise = B.ecran_vise(p["nom"])
        if vise not in references:
            continue
        regards = ((p["debut"] + MARGE_DU_PLAN, ECART_AUX_BORDS),
                   ((p["debut"] + p["fin"]) / 2, ECART_MAXIMUM),
                   (p["fin"] - MARGE_DU_PLAN, ECART_AUX_BORDS))
        for instant, plafond in regards:
            image = _ecran_a(images, instant + decalage)
            if image is None:
                return False
            proche, ecart = B.le_plus_proche(image, references)[0]
            if proche != vise or ecart > plafond:
                return False
        juges += 1
    return juges > 0


def decalage_juste(plans: list[dict], decalage: float, images: dict[int, pathlib.Path],
                   references: dict[str, Image.Image]) -> float | None:
    """Le décalage reçu s'il tient ; sinon le milieu de la plage qui tient, la plus proche.

    Rend `None` quand aucun décalage ne met tous les plans sur leur écran : il n'y a alors pas
    de film à monter, et c'est au montage de le dire.
    """
    if tient(plans, decalage, images, references):
        return decalage
    n = int(round(RECHERCHE / PAS_DE_RECHERCHE))
    bons = [k for k in range(-n, n + 1)
            if decalage + k * PAS_DE_RECHERCHE >= 0
            and tient(plans, decalage + k * PAS_DE_RECHERCHE, images, references)]
    if not bons:
        return None
    # Les plages de décalages CONSÉCUTIFS qui tiennent ; on garde la plus proche du décalage
    # reçu, et son MILIEU : le bord d'une plage est un plan qui commence ou finit dans un fondu.
    plages, courante = [], [bons[0]]
    for k in bons[1:]:
        if k == courante[-1] + 1:
            courante.append(k)
        else:
            plages.append(courante); courante = [k]
    plages.append(courante)
    plage = min(plages, key=lambda pl: min(abs(k) for k in pl))
    return decalage + (plage[0] + plage[-1]) / 2 * PAS_DE_RECHERCHE


def plan_fixe(image: pathlib.Path, duree: float, sortie: pathlib.Path) -> None:
    """Une carte de titre, tenue le temps voulu."""
    subprocess.run(
        ["ffmpeg", "-y", "-v", "error", "-loop", "1", "-i", str(image),
         "-t", f"{duree}", "-r", str(IPS), "-c:v", "libx264", "-crf", "16",
         "-pix_fmt", "yuv420p", str(sortie)], check=True)


def secondes(chemin: pathlib.Path) -> float:
    """La durée RÉELLE d'un fichier, telle que ffprobe la lit."""
    return float(subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
         str(chemin)], capture_output=True, text=True, check=True).stdout.strip())


def assembler(morceaux: list[pathlib.Path], sortie: pathlib.Path, fond_hex: str) -> None:
    """Les plans bout à bout, puis une seule passe au format d'Apple.

    Coupes FRANCHES. Un fondu d'une demi-seconde entre deux plans de trois mange un sixième du
    film pour ne rien dire de plus, et brouille précisément l'instant où le plan change — qui est
    la seule chose qui donne du rythme.
    """
    liste = sortie.parent / "plans.txt"
    liste.write_text("".join(f"file '{m.resolve()}'\n" for m in morceaux), encoding="utf-8")
    filtre = (f"scale={LARGEUR}:{HAUTEUR}:force_original_aspect_ratio=decrease,"
              f"pad={LARGEUR}:{HAUTEUR}:(ow-iw)/2:(oh-ih)/2:color={fond_hex},fps={IPS}")
    subprocess.run(
        ["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", str(liste),
         "-f", "lavfi", "-i", "anullsrc=channel_layout=stereo:sample_rate=48000",
         "-vf", filtre, "-c:v", "libx264", "-profile:v", "high", "-pix_fmt", "yuv420p",
         "-b:v", DEBIT, "-maxrate", DEBIT, "-bufsize", "22M",
         "-c:a", "aac", "-b:a", "256k", "-ar", "48000", "-ac", "2",
         "-movflags", "+faststart", "-shortest", str(sortie)], check=True)


def main() -> int:
    a = argparse.ArgumentParser(description="Monte l'aperçu App Store.")
    a.add_argument("--entree", type=pathlib.Path, required=True)
    a.add_argument("--sortie", type=pathlib.Path, required=True)
    a.add_argument("--plans", type=pathlib.Path, default=None,
                   help="JSON : { ouverture, fin, bandeau, plans: [{debut, duree, titre, sous, rang}] }")
    # LE DÉCOUPAGE ET LES TEXTES VIENNENT DE DEUX ENDROITS DIFFÉRENTS, ET C'EST VOULU.
    #
    # Le découpage est une mesure : le test le relève pendant qu'il tourne, parce qu'un
    # glissement lent dure ce qu'il dure. Les textes sont du contenu : ils se relisent, se
    # traduisent et se corrigent sans rien refilmer. Les mêler dans un seul fichier obligerait à
    # refaire une prise pour changer une virgule.
    a.add_argument("--temps", type=pathlib.Path, default=None,
                   help="Le découpage relevé par le test (temps.json)")
    a.add_argument("--textes", type=pathlib.Path, default=None,
                   help="Les titres, par langue (appstore/apercu.json)")
    a.add_argument("--langue", default="fr-FR")
    a.add_argument("--bandeau", default="")
    # Le décalage entre le début de l'ENREGISTREMENT et le début de la PRISE. La caméra tourne
    # pendant l'installation et le lancement de l'app ; les temps relevés par le test, eux,
    # comptent depuis l'instant où la prise commence. Sans ce décalage, le montage irait chercher
    # ses plans dans l'écran d'accueil du simulateur.
    #
    # ET CE DÉCALAGE SE COMPTE DEPUIS LA PREMIÈRE IMAGE ENREGISTRÉE, PAS DEPUIS L'APPEL À
    # `simctl`. Les deux sont séparés de trois secondes — le temps que la caméra démarre — et
    # pendant plusieurs exécutions le film a été coupé trois secondes trop tard : sous chaque
    # titre, l'écran du plan SUIVANT, et pour finir l'écran d'accueil du simulateur.
    #
    # Mesuré sur l'enregistrement brut, sur les huit changements d'onglet d'une prise : écart
    # constant de −3,17 s, étendue 0,7 s sur trente-cinq secondes de matière. C'est un retard au
    # démarrage, pas une dérive — une première correction l'avait pris pour une différence de
    # rythme entre les deux horloges et mettait les repères à l'échelle, ce qui déplaçait le
    # découpage dans l'autre sens. Le workflow horodate maintenant la ligne « Recording started »
    # de `simctl`, et il n'y a plus rien à corriger ici.
    a.add_argument("--decalage", type=float, default=0.0)
    a.add_argument("--travail", type=pathlib.Path, default=None)
    a.add_argument("--temoins", type=pathlib.Path, default=None,
                   help="Les captures claires de la langue : chaque plan monté leur est confronté")
    # LA COULEUR DES MARGES, s'il en reste une fois le plan mis au format d'Apple : le papier de
    # la fiche, lu dans `screenshots.py`, qui dessine déjà le décor de chaque plan.
    #
    # Elle était lue dans `Colors.swift` (« le fond de la fiche est le fond de l'app »). Ce
    # fichier est parti avec l'ancien design system le 19 novembre, et le montage plantait sur
    # son absence : la campagne 271 a passé le découpage, huit plans sur huit sur le bon écran,
    # puis s'est arrêtée ici. Et la raison ne tenait plus : la fiche est composée sur un papier
    # os, pas sur le fond de l'app.
    a.add_argument("--fond", default="0x%02X%02X%02X" % S.PAPIER[0][1])
    options = a.parse_args()

    if shutil.which("ffmpeg") is None or shutil.which("ffprobe") is None:
        raise SystemExit("ffmpeg et ffprobe sont nécessaires.")
    if not options.entree.is_file():
        raise SystemExit(f"Enregistrement introuvable : {options.entree}")

    if options.plans:
        script = json.loads(options.plans.read_text(encoding="utf-8"))
    else:
        if not (options.temps and options.textes):
            raise SystemExit("Donne --plans, ou bien --temps et --textes.")
        bornes = json.loads(options.temps.read_text(encoding="utf-8"))
        textes = json.loads(options.textes.read_text(encoding="utf-8"))
        if options.langue not in textes:
            raise SystemExit(f"Langue absente de {options.textes.name} : {options.langue}")
        bloc = textes[options.langue]
        manquants = [b["nom"] for b in bornes if b["nom"] not in bloc["plans"]]
        if manquants:
            raise SystemExit(
                f"Le test a filmé des plans sans texte en {options.langue} : "
                f"{', '.join(manquants)}. Ajoute-les à {options.textes.name}.")
        if options.temoins:
            # Le dossier de travail n'est pas encore posé : la relecture a le sien, à côté.
            relecture = (options.travail or options.sortie.parent / "montage"
                         / options.sortie.stem)
            relecture.mkdir(parents=True, exist_ok=True)
            images = derouler(options.entree, relecture)
            references = B.temoins(options.temoins, next(iter(
                Image.open(f).convert("L") for f in list(images.values())[:1])))
            juste = decalage_juste(bornes, options.decalage, images, references)
            if juste is None:
                raise SystemExit(
                    f"Aucun décalage, à {RECHERCHE:.0f} s près de {options.decalage:.2f} s, ne "
                    f"met chaque plan sur son écran dans l'enregistrement déroulé. Pas de film.")
            if juste != options.decalage:
                print(f"  DÉCALAGE RELU : {options.decalage:.2f} s ne tient pas dans la lecture "
                      f"du montage ; {juste:.2f} s met chaque plan sur son écran "
                      f"({juste - options.decalage:+.2f} s).")
                options.decalage = juste
            else:
                print(f"  décalage {options.decalage:.2f} s : chaque plan sur son écran, "
                      f"à ses deux bords, dans la lecture du montage.")
            shutil.rmtree(relecture / "deroule", ignore_errors=True)
        script = {
            "bandeau": options.bandeau,
            "ouverture": bloc.get("ouverture"),
            "fin": bloc.get("fin"),
            "plans": [{"debut": b["debut"] + options.decalage,
                       "duree": b["fin"] - b["debut"],
                       "rang": i, "nom": b["nom"], "titre": bloc["plans"][b["nom"]][0],
                       "sous": bloc["plans"][b["nom"]][1]}
                      for i, b in enumerate(bornes, start=1)],
        }
    # UN DOSSIER DE TRAVAIL PAR FILM. Le workflow monte les trois langues l'une après l'autre
    # dans le même dossier de sortie : un dossier commun mêlait leurs calques et leurs morceaux.
    travail = options.travail or options.sortie.parent / "montage" / options.sortie.stem
    travail.mkdir(parents=True, exist_ok=True)
    bandeau = script.get("bandeau", "")

    morceaux: list[pathlib.Path] = []
    manques: list[str] = []
    egares: list[str] = []
    duree_totale = 0.0

    ouverture = script.get("ouverture")
    if ouverture:
        img = carte_titre(travail, bandeau, ouverture["mot"], ouverture.get("sous", ""),
                          role="ouverture")
        m = travail / "00-ouverture.mp4"
        plan_fixe(img, ouverture["duree"], m)
        morceaux.append(m); duree_totale += ouverture["duree"]

    for i, p in enumerate(script["plans"], start=1):
        f, c, tt = plaque(p["titre"], p.get("sous", ""), p.get("rang", i),
                          len(script["plans"]), bandeau, travail)
        m = travail / f"{i:02d}-plan.mp4"
        plan_video(options.entree, p["debut"], p["duree"], f, c, tt, m)
        # CHAQUE PLAN EST MESURÉ, PAS SUPPOSÉ — mais le seuil a été posé trop serré.
        #
        # À deux dixièmes près, le contrôle a refusé deux montages entiers pour un DERNIER plan
        # qui rendait 1,40 s au lieu de 2,01. Or la caméra perd toujours un peu de sa fin, d'une
        # quantité qui varie d'une exécution à l'autre, et un plan final de 1,4 s au lieu de 2
        # ne se voit pas : ce qu'il fallait attraper, c'est le plan d'UNE IMAGE du premier essai,
        # pas six dixièmes de moins sur le dernier.
        #
        # Le contrôle qui compte vraiment est ailleurs, et il est plus sûr : la durée du FICHIER
        # final, mesurée après encodage, contre les bornes d'Apple. Celui-ci ne garde que les
        # cas où un plan est manifestement amputé.
        rendu = secondes(m)
        if rendu < max(0.8, p["duree"] * 0.6):
            manques.append(f"plan {i} « {p['titre']} » : {rendu:.2f} s rendues pour "
                           f"{p['duree']:.2f} s demandées")
        elif rendu < p["duree"] - 0.2:
            print(f"    (plan {i} raccourci de {p['duree'] - rendu:.2f} s — la caméra n'a pas "
                  f"couvert toute la prise)")
        morceaux.append(m); duree_totale += rendu
        print(f"  plan {i} : {p['debut']:.1f} → {p['debut'] + p['duree']:.1f} s  "
              f"({rendu:.2f} s)  « {p['titre']} »")
        if options.temoins and p.get("nom"):
            plainte = verifier_le_plan(p["nom"], m, rendu, options.temoins, travail)
            if plainte:
                egares.append(plainte)

    fin = script.get("fin")
    if fin:
        img = carte_titre(travail, bandeau, fin["mot"], fin.get("sous", ""), role="fin")
        m = travail / "99-fin.mp4"
        plan_fixe(img, fin["duree"], m)
        morceaux.append(m); duree_totale += fin["duree"]

    # UN PLAN PLUS COURT QUE DEMANDÉ EST UNE ERREUR, pas un détail de rendu. C'est par là que le
    # film est passé sous le plancher d'Apple sans que rien ne le dise.
    if manques:
        print("\nDes plans sont plus courts que l'enregistrement ne le permettait :", file=sys.stderr)
        for x in manques:
            print(f"  {x}", file=sys.stderr)
        raise SystemExit(
            "\nLa caméra n'a pas couvert toute la prise, ou le décalage est faux.")

    # UN TITRE SUR LE MAUVAIS ÉCRAN, ET IL N'Y A PAS DE FILM. Voir `verifier_le_plan`.
    if egares:
        print("\nLe film poserait des titres sur le mauvais écran :", file=sys.stderr)
        for x in egares:
            print(f"  {x}", file=sys.stderr)
        raise SystemExit("\nLe découpage ne désigne pas, dans l'enregistrement, ce qu'il croit.")

    options.sortie.parent.mkdir(parents=True, exist_ok=True)
    assembler(morceaux, options.sortie, options.fond)

    # LES DEUX BORNES D'APPLE SE VÉRIFIENT SUR LE FICHIER, PAS SUR LE PLAN.
    #
    # Elles l'étaient sur la somme des durées DEMANDÉES. Le premier montage en annonçait 17,8 et
    # en a produit 12,8 : le contrôle validait une intention. Un contrôle qui ne mesure pas ce
    # qui sort ne contrôle rien.
    duree_reelle = secondes(options.sortie)
    poids = options.sortie.stat().st_size / 1_000_000
    print(f"\n{options.sortie} — {duree_reelle:.1f} s, {poids:.1f} Mo")
    if not SECONDES_MIN <= duree_reelle <= SECONDES_MAX:
        raise SystemExit(
            f"Le montage fait {duree_reelle:.1f} s, et Apple en veut entre {SECONDES_MIN} et "
            f"{SECONDES_MAX}. Ajoute ou retire un plan, ou change leur durée.")
    if poids > 500:
        raise SystemExit("Au-delà des 500 Mo qu'Apple accepte.")
    # Les morceaux ont servi : ils pèsent autant que le film, et il y en a un jeu par langue
    # depuis que chaque film a son dossier. Les calques, eux, restent — quelques images, et la
    # preuve de ce qui a été écrit sur chaque plan.
    if options.travail is None:
        for morceau in morceaux:
            morceau.unlink(missing_ok=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
