# Outils de comparaison de la refonte

Trois outils, écrits pour la méthode de la refonte : « capture dans le simulateur, comparaison
côte à côte avec la référence, liste des écarts, correction, nouvelle capture ».

Les fichiers du canvas ne sont PAS dans ce dépôt : ils portent des données d'exemple
personnelles, et le dépôt est public. Seuls ces outils, qui n'en contiennent aucune, y sont.

- `rendre_canvas.js` : rend une planche du canvas en image à l'échelle 3 (390 points de large),
  sans exécuter aucun script du canvas, sans réseau, avec les quatre mêmes faces de fonte que
  lui. C'est la RÉFÉRENCE.
  Arguments : dossier du canvas, dossier de sortie, fichier de la fonte, fichier JSON des valeurs
  à poser dans les trous du balisage (transcrites à la main depuis le canvas, jamais calculées
  par lui), suffixe des fichiers, puis les noms des planches.
- `cote_a_cote.py` : pose la capture, la référence et leur différence l'une à côté de l'autre.
- `decalage.py` : mesure, par bande, le décalage vertical et horizontal en dixièmes de point.
  Un décalage vertical NÉGATIF veut dire que la capture est plus BAS que la référence.

Python avec Pillow et numpy : `python3 -I design/outils/decalage.py capture.png reference.png`.
