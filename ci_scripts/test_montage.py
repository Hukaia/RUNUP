#!/usr/bin/env python3
"""Les cas de `montage.py` : ce qu'un film ne doit jamais reprendre d'un autre.

# POURQUOI CES CAS EXISTENT

Le 24 novembre 2026, la première campagne à sortir trois films depuis la refonte les a rendus
verts tous les trois. En les regardant : l'anglais et l'espagnol portaient les titres et la ligne
courante du FRANÇAIS, et les trois se terminaient sur la carte d'ouverture au lieu de la carte de
fin. Le montage ne redessinait un calque que si son fichier manquait, et les trois langues
partagent un dossier.

Aucune durée, aucun découpage ne pouvait le dire. Ces cas le disent en une seconde, sans ffmpeg
ni simulateur : ils ne dessinent que des calques.
"""
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest

from PIL import Image, ImageDraw

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import montage as M  # noqa: E402


class Calques(unittest.TestCase):
    def setUp(self):
        self.dossier = pathlib.Path(tempfile.mkdtemp())

    def test_un_titre_deja_la_nest_pas_repris(self):
        """Deux langues, le même dossier, le même rang : deux titres différents."""
        _, _, titre = M.plaque("Ta journée, en un écran", "Ta séance du jour.", 1, 7,
                               "un programme qui se recalcule", self.dossier)
        francais = titre.read_bytes()
        _, _, titre = M.plaque("Your day, on one screen", "Today's session.", 1, 7,
                               "a plan that recalculates", self.dossier)
        self.assertNotEqual(francais, titre.read_bytes(),
                            "le titre anglais est celui que le français avait laissé")

    def test_le_decor_suit_la_ligne_courante_de_sa_langue(self):
        fond, _, _ = M.plaque("a", "b", 1, 7, "un programme qui se recalcule", self.dossier)
        francais = fond.read_bytes()
        fond, _, _ = M.plaque("a", "b", 1, 7, "a plan that recalculates", self.dossier)
        self.assertNotEqual(francais, fond.read_bytes(),
                            "la ligne courante est restée dans la langue précédente")

    def test_la_carte_de_fin_nest_pas_celle_douverture(self):
        """Le même mot aux deux bouts du film, deux sous-titres : deux fichiers, deux images."""
        ouverture = M.carte_titre(self.dossier, "x", "Haizo", "Course · Trail · Triathlon",
                                  role="ouverture")
        fin = M.carte_titre(self.dossier, "x", "Haizo", "Sur l'App Store", role="fin")
        self.assertNotEqual(ouverture, fin)
        self.assertNotEqual(ouverture.read_bytes(), fin.read_bytes(),
                            "le film finirait sur sa carte d'ouverture")

    def test_une_carte_deja_la_nest_pas_reprise(self):
        premiere = M.carte_titre(self.dossier, "x", "Haizo", "Sur l'App Store",
                                 role="fin").read_bytes()
        seconde = M.carte_titre(self.dossier, "x", "Haizo", "On the App Store",
                                role="fin").read_bytes()
        self.assertNotEqual(premiere, seconde)


class Decalage(unittest.TestCase):
    """Le montage relit le décalage qu'on lui donne, dans un enregistrement déjà déroulé.

    Quarante secondes fabriquées, image par image : l'écran d'accueil du simulateur, puis
    l'accueil, le coach, les stats, le profil, l'accueil, et le simulateur de nouveau. Le test
    « a relevé » ses plans dix secondes après le début de ce déroulé.
    """

    VRAI = 10.0
    PLANS = [{"nom": "accueil", "debut": 0.0, "fin": 2.0},
             {"nom": "accueil-bas", "debut": 2.0, "fin": 4.0},
             {"nom": "coach", "debut": 5.0, "fin": 7.0},
             {"nom": "stats", "debut": 8.0, "fin": 10.0},
             {"nom": "profil", "debut": 12.0, "fin": 14.0},
             {"nom": "retour", "debut": 15.0, "fin": 17.0}]
    #: Ce que l'écran montre, en secondes du TEST : jusqu'à quand, et quoi.
    ECRANS = [(4.4, "accueil"), (7.4, "coach"), (11.4, "stats"), (14.4, "profil"),
              (17.5, "accueil")]

    @classmethod
    def setUpClass(cls):
        cls.dossier = pathlib.Path(tempfile.mkdtemp())
        cls.references = {}
        for rang, nom in enumerate(("accueil", "coach", "stats", "profil")):
            im = Image.new("L", (32, 60), 240)
            ImageDraw.Draw(im).rectangle((2, 4 + rang * 13, 30, 12 + rang * 13), fill=10)
            cls.references[nom] = im
        simulateur = Image.new("L", (32, 60), 120)
        cls.images = {}
        for n in range(int(40 * M.IPS)):
            seconde = n / M.IPS - cls.VRAI
            ecran = simulateur
            if seconde >= -0.5:
                ecran = next((cls.references[nom] for fin, nom in cls.ECRANS if seconde < fin),
                             simulateur)
            chemin = cls.dossier / f"{n:06d}.png"
            ecran.save(chemin)
            cls.images[n] = chemin

    def test_un_decalage_juste_nest_pas_touche(self):
        self.assertEqual(M.decalage_juste(self.PLANS, 10.0, self.images, self.references), 10.0)

    def test_sept_secondes_de_trop_sont_retrouvees(self):
        """Le film espagnol : un décalage reçu à sept secondes du vrai."""
        trouve = M.decalage_juste(self.PLANS, 17.0, self.images, self.references)
        self.assertIsNotNone(trouve)
        self.assertLess(abs(trouve - self.VRAI), 0.4, trouve)
        self.assertTrue(M.tient(self.PLANS, trouve, self.images, self.references))

    def test_un_plan_trop_tot_ne_tient_pas(self):
        """Une seconde d'avance : le plan du coach commencerait sur l'accueil."""
        self.assertFalse(M.tient(self.PLANS, 9.0, self.images, self.references))

    def test_hors_de_portee_il_ny_a_pas_de_film(self):
        self.assertIsNone(M.decalage_juste(self.PLANS, 30.0, self.images, self.references))

    def test_le_simulateur_nest_pas_un_ecran(self):
        """Un décalage qui met le dernier plan après la fin de l'app ne tient pas."""
        self.assertFalse(M.tient(self.PLANS, 10.8, self.images, self.references))


@unittest.skipUnless(shutil.which("ffmpeg"), "ffmpeg absent : ce cas tourne après son installation")
class PlanMonte(unittest.TestCase):
    """Le montage relit ce qu'il vient de monter. Trois écrans fabriqués, un morceau par cas."""

    def setUp(self):
        self.dossier = pathlib.Path(tempfile.mkdtemp())
        self.temoins = self.dossier / "clair"
        (self.temoins / "diagnostic").mkdir(parents=True)
        self.ecrans = {}
        for rang, (nom, fichier) in enumerate(M.B.TEMOINS.items()):
            im = Image.new("RGB", (660, 1434), (245, 245, 245))
            d = ImageDraw.Draw(im)
            # Un motif propre à chaque écran : des bandes sombres à des hauteurs différentes.
            for k in range(4):
                haut = 80 + rang * 130 + k * 260
                d.rectangle((40, haut, 620, haut + 90), fill=(20, 20, 24))
            im.save(self.temoins / fichier)
            self.ecrans[nom] = im

    def morceau(self, ecran: Image.Image, nom: str) -> pathlib.Path:
        """Une seconde de film : l'écran donné, posé là où le montage pose le téléphone."""
        cadre = Image.new("RGB", M.S.CANVAS, (240, 236, 228))
        cadre.paste(ecran.resize(M.ECRAN_WH), M.ECRAN_XY)
        image = self.dossier / f"{nom}.png"
        cadre.save(image)
        sortie = self.dossier / f"{nom}.mp4"
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-loop", "1", "-i", str(image), "-t", "1",
                        "-r", "30", "-c:v", "libx264", "-pix_fmt", "yuv420p", str(sortie)],
                       check=True)
        return sortie

    def test_le_bon_ecran_passe(self):
        m = self.morceau(self.ecrans["coach"], "bon")
        self.assertIsNone(M.verifier_le_plan("coach", m, 1.0, self.temoins, self.dossier))

    def test_lecran_du_plan_suivant_est_refuse(self):
        """Le défaut du film espagnol : le titre du Coach posé sur les Stats."""
        m = self.morceau(self.ecrans["stats"], "decale")
        plainte = M.verifier_le_plan("coach", m, 1.0, self.temoins, self.dossier)
        self.assertIsNotNone(plainte)
        self.assertIn("stats", plainte)

    def test_un_ecran_qui_nest_pas_lapp_est_refuse(self):
        """L'écran d'accueil du simulateur n'est « le plus proche » de rien d'acceptable."""
        m = self.morceau(Image.new("RGB", (660, 1434), (70, 140, 200)), "simulateur")
        for nom in ("retour", "coach", "profil"):
            self.assertIsNotNone(M.verifier_le_plan(nom, m, 1.0, self.temoins, self.dossier), nom)

    def test_un_plan_sans_capture_nest_pas_juge(self):
        """« accueil-bas » et « stats-bas » n'ont pas de capture à eux : rien à confronter."""
        m = self.morceau(self.ecrans["stats"], "bas")
        self.assertIsNone(M.verifier_le_plan("stats-bas", m, 1.0, self.temoins, self.dossier))


if __name__ == "__main__":
    unittest.main(verbosity=2)
