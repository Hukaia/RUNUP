# Le kit de marque Haizo

Livré par Charlotte le 16 novembre 2026. **Ce dossier est la source, pas ce que l'app embarque.**

## Ce que l'app utilise, et d'où ça vient

| Dans l'app | Découpé de | Pourquoi |
| --- | --- | --- |
| `Haizo/Resources/Assets.xcassets/haizo-mot.imageset` | `haizo_A_white.png`, x 372–1066, y 83–304 | Le mot seul. L'écran de lancement compose déjà le symbole animé à côté ; poser le verrou entier aurait jeté l'animation. |

L'image est déclarée **template** : elle ne porte que sa forme et prend la couleur du contexte.
C'est ce qui permet à la carte de partage de la remplir d'un dégradé. `check_marque.py` refuse
que cette intention change, parce que la panne serait silencieuse.

`ci_scripts/montage.py` lit **ce même fichier** pour les cartons du film, et le teinte de son
côté. Un seul dessin ; pas de second exemplaire qui divergerait.

## Ce que l'app n'utilise pas, et pourquoi

**`haizo_app_icon.png` ne remplace pas l'icône en place.** Ses barres touchent le bord — 1 % de
marge à droite, 2,5 % en haut — et le masque d'iOS en rogne **1,21 %**, précisément la pointe
arrondie de la plus haute barre, dans la zone x 901–1015 / y 26–160 d'un rendu à 1024.

L'icône actuelle n'y perd aucun pixel, et porte déjà le même symbole avec le même dégradé, à
deux niveaux près. Le symbole à **94 %** de la toile suffit à tout faire rentrer : c'est la
seule retouche à demander avant de l'adopter.

Son canal alpha est opaque partout, donc Apple l'accepterait — ce n'est pas le problème.

## Mesures, pour qu'on n'ait pas à les refaire

- dégradé : linéaire, `#FF0F5C` en haut à gauche → `#7C5CFE` en bas à droite, vérifié à 1/255
  sur la diagonale ;
- encre du mot sombre : `#1A1023`, un noir **froid** — bleu 0x23 au-dessus du rouge 0x1A ;
- proportions du verrou : le mot fait **0,835** fois la hauteur du symbole, l'écart entre les
  deux **0,203** fois cette même hauteur.

## Ce qui manque

**Il n'y a pas de vectoriel.** Dix PNG, pas un SVG ni un PDF. C'est suffisant pour l'app — 1108
pixels de large couvrent le @3x d'un écran de lancement — mais un logo sans vectoriel se
redimensionne mal le jour où il faut l'imprimer ou l'afficher en grand.
