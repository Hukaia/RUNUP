#!/usr/bin/env python3
"""Cas de check_bandes_distance.py : il attrape une borne qui diverge, et accepte le dépôt tel quel."""
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import check_bandes_distance as C  # noqa: E402

JS = C.JS.read_text()
SWIFT = C.SWIFT.read_text()


class Bandes(unittest.TestCase):
    def test_le_depot_est_coherent(self):
        self.assertEqual(C.comparer(JS, SWIFT), [])

    def test_une_borne_changee_cote_app_est_refusee(self):
        self.assertTrue(C.comparer(JS, SWIFT.replace("9.7...10.3", "9.7...10.6")))

    def test_une_borne_changee_cote_serveur_est_refusee(self):
        self.assertTrue(C.comparer(JS.replace("[20.9, 21.3]", "[20.5, 21.3]"), SWIFT))

    def test_une_categorie_retiree_est_refusee(self):
        self.assertTrue(C.comparer(JS, SWIFT.replace("        (.cinq, 4.8...5.2),\n", "")))

    def test_un_seuil_ultra_different_est_refuse(self):
        self.assertTrue(C.comparer(JS, SWIFT.replace("ultraAuDelaDe = 42.5", "ultraAuDelaDe = 50")))

    def test_un_fichier_illisible_est_refuse(self):
        self.assertTrue(C.comparer("", SWIFT))
        self.assertTrue(C.comparer(JS, ""))


if __name__ == "__main__":
    unittest.main()
