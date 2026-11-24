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
import sys
import tempfile
import unittest

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


if __name__ == "__main__":
    unittest.main(verbosity=2)
