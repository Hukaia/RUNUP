# La direction artistique de Haizo

Tenu par la direction artistique. Ce fichier existe pour que la DA ne dépende plus d'une conversation : les trois questions, les
couleurs, la typographie, la forme, les composants, les feuilles et le mouvement sont ici, pas dans un fil de discussion. À jour au
19 novembre 2026.

Il décrit **un seul système de design : le système HZ**, dessiné par Charlotte sur un canvas de dix écrans (Accueil, Plan, Run,
Résumé, Coach, Stats, Club, Explorer, Profil, Réglages) et repris dans le code à la valeur près. Le système vit dans
`Haizo/DesignSystem/Refonte/` (préfixe `HZ`), les écrans dans `Haizo/Views/Refonte/`. Le système précédent n'est plus la référence
de rien : ce que le canvas a renversé de ses décisions est daté au § 10.

`RELEASE.md` garde les questions de **livraison** : les captures montrent-elles l'app d'aujourd'hui, la production est-elle debout,
est-ce que ça se lit dans les trois langues, la politique publiée dit-elle vrai. Ce fichier porte les questions de **design**.

**Ce fichier ne recopie pas le code, il le cite.** Chaque tableau dit de quel fichier viennent ses valeurs. Si le code et ce
document divergent, le code a raison et le document est à corriger : un document de DA qui dérive de l'app est pire qu'aucun
document, on le lit en croyant savoir.

---

## 1. Les trois questions, à appliquer à chaque écran avant de le présenter

1. **Est-ce qu'une débutante qui (re)commence à courir s'y sent à sa place ?** Pas intimidant, pas
   réservé aux performeurs.
2. **Est-ce qu'un traileur ou un triathlète le trouve sérieux ?** Précis, crédible, pas gadget.
3. **Est-ce qu'on devine qu'il a été généré ?** Template, dégradé, emoji, texte générique,
   composant sans intention.

**Un oui à la 3, ou un non à la 1 ou à la 2 : on recommence l'écran.**

### Le test final

Sorti de son cadre de téléphone et sans logo, l'écran doit être reconnaissable comme Haizo.

Ce qui le rend reconnaissable, dans le système HZ : un aplat plein (l'accent ou le noir) portant un très grand chiffre en Archivo
large, une feuille blanche aux coins de 30 qui remonte par-dessus, des pilules noires ou blanches, une barre flottante noire. Ni
dégradé, ni ombre décorative, ni trait décoratif.

### Ce que les trois questions veulent dire quand on tient un écran dans les mains

Elles ne se répondent pas de mémoire. Elles se répondent sur une image, dans les trois langues — la campagne `captures.yml` existe
pour ça.

**Question 1, en pratique.** Est-ce que le premier chiffre que l'œil rencontre est une performance ou un repère ? Est-ce qu'un
écran vide dit quoi faire, ou constate un manque ? Est-ce qu'une séance ratée est écrite comme un échec ou comme une information ?
Un écran qui n'a de sens qu'avec trois mois d'historique échoue à cette question même s'il est beau.

**Question 2, en pratique.** Est-ce que les nombres sont justes, datés, et sourcés quand ils viennent d'un règlement ? Est-ce que
les unités sont là ? Est-ce qu'une allure est donnée au format qu'un coureur lit — `4:45/km` et pas `4,75 min/km` ? Un écran qui
arrondit pour faire joli échoue ici.

**Question 3, en pratique.** C'est la seule des trois qui a des gardes automatiques, et ils ne couvrent qu'une partie :

| Ce qu'on cherche | Ce qui le tient |
| --- | --- |
| Dégradé décoratif | `check_degrade.py` |
| Verre dépoli | `check_verre.py` |
| Emoji dans l'interface ou au catalogue | `check_emoji.py` |
| Libellé en capitales | `check_majuscules.py` |
| Mesure écrite à la main dans une vue | `check_valeurs.py` |

Ce qu'aucun garde ne voit : **le texte générique et le composant sans intention.** Une carte qui dit « Continuez comme ça ! » passe
tous les contrôles. C'est à l'œil, sur l'image, et c'est pourquoi cette question est posée à chaque écran et pas une fois par
version.

---

## 2. Les couleurs

Déclarées dans `HZCouleur.swift` (`HZCouleur`, `HZAccent`, `HZIntensite`). Les jetons sont nommés par **rôle**, pas par teinte, et
n'ont **qu'une valeur** : le canvas ne dessine qu'un rendu de chaque écran. Des aplats — l'accent, le noir, le blanc, le gris clair
— et rien d'autre. Aucun dégradé, aucun verre.

### 2.1 L'accent : quatre choix, un seul jeton

`HZCouleur.accent` est le seul jeton d'accent. La coureuse choisit parmi quatre couleurs dans les réglages
(`HZPastilleDeCouleur`) ; rose est le défaut.

| Choix | Couleur | Encre d'un petit texte posé dessus |
| --- | --- | --- |
| Rose | `#FC105E` | `#2B0011` |
| Violet | `#7B3FE4` | `#FFFFFF` |
| Bleu | `#2F6BFF` | `#FFFFFF` |
| Vert | `#12A56B` | `#FFFFFF` |

**La règle du rose.** Jamais de petit texte blanc à même le rose : un libellé posé sur l'accent s'écrit dans
`HZCouleur.encreSurAccent`, qui vaut l'encre sombre pour le rose et le blanc pour les trois autres. Le blanc pur est réservé aux
grands chiffres et aux titres. Ce n'est pas un oubli à corriger sur le violet, le bleu et le vert : le rose est le seul des quatre
assez clair pour qu'un petit texte blanc y devienne illisible.

**Le très grand chiffre est dans l'accent (20 novembre).** Un par écran, au corps de 100 points et plus : la distance de la sortie
(`resume`), le total de la période (`total`), le nombre de la séance du jour (`seance`), l'allure en direct (`direct`), et le grand nombre d'une
carte du plan quand sa carte est neutre. Il se pose avec `hzVedette()`. C'est la réponse à « le noir et blanc fait trop fade » après
« le rose est trop présent » : le rose reste une touche — un seul chiffre par écran, rien d'autre à cette taille — mais chaque écran a
son point d'accroche. Sur une teinte d'intensité (vert, bleu…), le grand nombre reste blanc : du rose sur ces teintes serait une
collision. Un chiffre de cette taille passe le seuil de contraste des grands textes (3:1) sur blanc et sur noir pour les quatre accents.
Pour revenir en arrière : une ligne, `hzVedette()` dans `HZPolice.swift`.

**Le voile.** Un petit texte blanc qui doit vivre sur l'accent ou sur une teinte d'intensité (pastille, bouton rond, champ de
recherche) vit sur `HZCouleur.voile`, un noir à 26 %.

**Le réglage enregistré.** Le choix est lu dans `ThemeStore`, le réglage que l'app et le widget portent déjà. Qui avait l'un des
anciens huit thèmes se retrouve ainsi : violet, bleu et rose gardent leur nom ; cyan, lime et vert deviennent le vert ; les autres
reviennent au rose. La valeur enregistrée n'est réécrite que lorsque la personne choisit.

### 2.2 Les trois teintes d'intensité

`HZIntensite`. Une séance facile, de récupération ou longue a sa teinte, la même partout. La carte porte la couleur pleine ; le
point, qui vit sur le noir à huit points de diamètre, est plus clair.

| Famille | Jeton | Carte | Point |
| --- | --- | --- | --- |
| Endurance, footing facile | `facile` | `#177A50` | `#2FB37A` |
| Récupération | `recuperation` | `#2B6CB8` | `#5AA9E6` |
| Sortie longue | `longue` | `#6B35D6` | `#9B6BF2` |

Une de ces teintes sert aussi de couleur à un club dans la découverte : le club n'a pas de couleur en donnée, elle est tirée de son
identifiant (`HZIntensite.pourClub(id:)`, un hachage stable, donc la même partout et d'une session à l'autre).

Le canvas n'en dessine pas d'autre. Une séance de seuil, de fractionné ou de renforcement n'a pas de teinte : elle prend l'accent,
et se lit par ce qui est écrit dessus. Un repos prend le noir doux (`surfaceSombre`) et son point éteint. C'est une hypothèse de
l'équipe, à confirmer (§ 11).

### 2.3 Les surfaces et les textes

| Jeton | Valeur | Rôle |
| --- | --- | --- |
| `noir` | `#0B0B0C` | le fond des écrans sombres : plan, stats, coach, club, profil |
| `encre` | `#111111` | la barre flottante, les boutons pleins, le texte sur une feuille blanche |
| `surfaceSombre` | `#1C1C1E` | une surface posée sur le noir : bouton rond, pilule, tuile, carte de repos |
| `filetSombre` | `#2C2C2E` | un filet ou un segment éteint sur le noir |
| `pointEteint` | `#3A3A3C` | le point d'un jour de repos, dans la rangée de la semaine |
| `noirFranc` | `#000000` | le panneau de la séance en direct : plus profond, parce qu'il se lit au soleil et en courant |
| `blanc` | `#FFFFFF` | la feuille, et le texte sur sombre |
| `surfaceClaire` | `#F4F4F6` | une surface posée sur la feuille : tuile, groupe, bandeau, champ |
| `filetFeuille` | `#F0F0F2` | le filet entre deux lignes, directement sur la feuille |
| `filetGroupe` | `#E4E4E8` | le filet à l'intérieur d'un groupe gris, et la gorge d'un sélecteur |
| `contour` | `#DCDCE0` | le contour d'une pilule vide, et la gorge d'une barre de progression |
| `secondaireSurClair` | `#6E6E73` | légende, précision, sous-titre sur la feuille |
| `secondaireSurSombre` | `#A1A1A6` | la même chose sur le noir |
| `chevron` | `#8E8E93` | le chevron au bout d'une ligne de liste |
| `ongletEteint` | `#C7C7CC` | l'icône d'une entrée éteinte de la barre flottante |
| `voile` | noir à 26 % | porte les petits textes blancs sur l'accent ou une teinte |
| `pointSurCouleur` | noir à 28 % | le point d'un jour sans séance, sur l'accent |
| `filetSurCouleur` | blanc à 40 % | le filet d'une carte-affiche, au-dessus de sa rangée de chiffres |

Le texte principal est `encre` sur clair et `blanc` sur sombre. Un texte secondaire est un jeton opaque, jamais une opacité.

### 2.4 Ce qui ne change jamais

- **Le sens d'une teinte d'intensité** : le vert, le bleu et le violet du § 2.2 disent la même chose dans tous les écrans.
- **La règle du rose** : l'encre d'un petit texte sur l'accent ne dépend que de l'accent.
- **L'encre de la marque** : le mot de la marque, à l'écran de lancement, s'écrit en `#1A1023` (`HZLancement.encreDeMarque`), un noir
  froid. Un logo garde son encre ; ce n'est pas celle de l'interface.
- **La couleur ne porte jamais seule** : elle appuie ce qui est écrit, ou dessiné par sa forme, elle ne le remplace pas.

### 2.5 Le mode clair et sombre

Le canvas montre un interrupteur Clair / Sombre dans les réglages et ne dessine qu'un seul rendu : les jetons ci-dessus n'ont donc
qu'une valeur. Le réglage « Mode » reste dans l'app et règle l'apparence du système ; la seconde ambiance des jetons n'est pas
dessinée. Elle se posera dans `HZCouleur` le jour où elle le sera, sans toucher une vue : c'est pourquoi les jetons sont nommés par
rôle. Question ouverte, § 11.

---

## 3. La typographie

Une seule famille : **Archivo**, variable, fichier `Haizo/Resources/Fonts/Archivo-Variable.ttf` (licence OFL à côté), livré avec
l'app. Elle se règle sur deux axes, graisse et largeur, que `Font.custom` ne sait pas atteindre : `HZPolice` passe par un
descripteur UIKit et un attribut de variation CoreText. La planche de captures imprime la famille résolue et l'état des deux axes,
pour qu'une fonte mal déclarée ne retombe pas en silence sur la fonte du système.

| Registre | Largeur | Graisses | Sert à | API |
| --- | --- | --- | --- | --- |
| Affichage | 125 % | 800 | les grands chiffres et les titres | `hzAffichage(style)` |
| Interface | 100 % | 500, 600, 700 | tout le reste | `hzTexte(corps, graisse)`, `hzParagraphe(corps, graisse, interligne:)` |

Le canvas ne charge que quatre faces (500, 600 et 700 en largeur 100, 800 en largeur 125) : la référence est ce qu'on voit, donc
il n'y a ni 400 ni 800 d'interface.

### 3.1 Les corps et les graisses de l'interface

Huit corps (`HZCorps`) : 12, 13, 14, 15, 16, 17, 20, 24. Trois graisses (`HZGraisse`) : `medium` 500, `semi` 600, `gras` 700.

- `hzTexte` pose **une ligne**, de la hauteur que le canvas lui donne : libellés, valeurs, boutons.
- `hzParagraphe` pose un texte qui peut passer à la ligne, avec l'interligne du canvas (1,35 pour le bandeau du coach, les précisions
  de réglage et les états vides ; 1,4 pour une bulle). Un paragraphe ne se coupe jamais en hauteur : sur un écran plus court que son
  contenu, c'est l'écran qui coupe la feuille.
- Les chiffres alignés ou qui changent (durées, allures, compteurs, valeurs de liste) se composent avec `tabulaire: true`.
- La hauteur d'une ligne est celle que compte le canvas, qui est du HTML : `HZLigne` arrondit l'ascendante (0,878 du corps) et la
  descendante (0,210) à l'entier, comme le navigateur, et `hzLigne` pose la ligne de base par un guide d'alignement. Sans cela
  chaque ligne s'écarte d'un tiers de point de la référence, et l'écart se cumule jusqu'en bas de l'écran.

### 3.2 Les styles d'affichage

`HZAffichage` : un corps, un interlettrage, une hauteur de ligne en multiple du corps (« naturel » : 1,088, celle de la fonte).
**Ce n'est pas une échelle, c'est une table** : le canvas compose trente-trois titres et chiffres, et l'interlettrage ne suit pas le
corps par une règle — 40 points se serrent de 2 dans une tuile et de 1,5 devant un nombre. Chaque style est relevé tel quel et
nommé par ce qu'il sert. « Tab. » dit si les chiffres sont tabulaires : le canvas ne le pose pas partout, et un « 1 »
proportionnel est plus étroit (« 1h20 » rend 2 % plus large en tabulaire).

| Style | Corps | Interlettrage | Ligne | Tab. | Où |
| --- | --- | --- | --- | --- | --- |
| `total` | 156 | -9 | 0,92 | oui | Stats : le total de kilomètres |
| `seance` | 128 | -7 | 0,92 | oui | Accueil : le nombre de la séance du jour |
| `carte` | 112 | -5 | 0,92 | oui | Plan : le nombre d'une carte-affiche |
| `carteDuJour` | 112 | -6 | 0,92 | oui | Plan : le même, pour le jour en cours |
| `resume` | 104 | -6 | 0,95 | oui | Résumé : la distance de la sortie |
| `direct` | 100 | -6 | 0,95 | oui | En direct : l'allure |
| `carteLongue` | 84 | -4 | 0,92 | oui | Plan : une durée de quatre signes, « 1h20 » |
| `fil` | 76 | -4 | 1 | oui | Fil du club : la distance d'une sortie |
| `heros` | 64 | -3,5 | 1 | oui | Explorer : la distance du parcours mis en avant |
| `record` | 52 | -2,5 | 1 | oui | Stats : un record |
| `tuile` | 46 | -2 | 1 | non | Accueil : la durée d'une séance à venir |
| `tuileDeCourse` | 44 | -2 | 1 | non | Explorer : la distance d'une course |
| `prefixeDeSeance` | 44 | -1,5 | 1 | non | Accueil : « 5 × », devant un grand chiffre |
| `prefixeDeCarte` | 40 | -1,5 | 1 | non | Plan : le même, sur une carte |
| `chiffre` | 40 | -2 | 1 | oui | Coach, et l'allure moyenne des stats |
| `chiffreDeTuile` | 36 | -1,6 | 1 | oui | Stats : les quatre tuiles |
| `chiffreDeProfil` | 34 | -1,5 | 1 | oui | Profil : les trois totaux |
| `mesure` | 30 | -1,4 | naturel | oui | Résumé : allure et durée |
| `chiffreDuDirect` | 28 | -1,2 | naturel | oui | En direct : temps, kilomètres, cardio |
| `chiffreDeLigne` | 22 | -0,8 | naturel | oui | valeur en bout de ligne : cible, temps possibles |
| `seanceDuCoach` | 21 | -1 | 1 | oui | Coach : la séance du jour, « 5×500 » |
| `duree` | 20 | -1 | naturel | non | Coach : la durée d'une proposition |
| `badge` | 17 | -0,6 | naturel | oui | Profil : la marque d'un badge |
| `prenom` | 36 | -1,6 | 1,05 | non | Profil : le prénom |
| `titreDePage` | 34 | -1,4 | 1,1 | non | Plan : « Ta semaine » |
| `titreDeCarte` | 34 | -1,6 | 1 | non | Club : le nom du club, sur sa carte |
| `titreDeReglages` | 32 | -1,2 | naturel | non | Réglages : le titre de l'écran |
| `offre` | 30 | -1,2 | 1 | non | Réglages : « Haizo Plus » |
| `initiales` | 30 | -1 | naturel | non | Profil : les initiales dans l'avatar |
| `titreDEcran` | 26 | -0,8 | naturel | non | le titre d'un écran d'onglet : Stats, Club |
| `titreDuCoach` | 26 | -0,8 | 1,1 | non | Coach : le même, au-dessus d'un sous-titre |
| `titreDeTuile` | 24 | -1 | 1,05 | non | Plan : le nom d'un objectif, sur sa tuile |
| `section` | 22 | -0,6 | naturel | non | le titre d'une section, et d'une feuille |

### 3.3 La casse : pas de capitales

Le canvas n'écrit **aucun libellé en capitales**. Les étiquettes (« Ta journée », « Allure cible ») sont en 12 à 13 points, casse
de phrase, graisse 600 ou 700, **sans interlettrage positif** : il existe pour rendre des capitales lisibles, et en casse normale
il ne fait qu'écarter les lettres d'un mot qui se lit très bien sans. Les boutons aussi sont en casse de phrase (« Démarrer »,
« Partager »).

Les seules capitales sont des lettres, pas des mots : les initiales de l'avatar (calculées à l'exécution, `HZAvatar.initiales`), la
capitale initiale d'une date (« Mardi 17 novembre »), et la graphie de la marque. `check_majuscules.py` refuse un libellé tout en
capitales, au catalogue des trois langues comme dans le code, et tient la liste fermée de ce qui a le droit d'y rester, avec une
raison par entrée.

### 3.4 Un grand chiffre ne se tronque pas

`lineLimit(1)` sans réduction tronque, et sur un nombre la troncature ment : « 1:23:45 » devient « 1:23… » sans que rien dise que
ce n'est pas l'heure complète. Tout nombre tenu sur une ligne peut donc rétrécir avant de se couper (`minimumScaleFactor`), et le
facteur est un jeton : 0,5 pour le très grand chiffre de l'accueil, 0,6 pour un nom d'objectif ou un prénom, 0,7 pour une tuile de
chiffre, 0,8 pour un libellé d'action ou une durée de tuile. Une durée tronquée est une durée fausse, un nom tronqué est un nom faux.

### 3.5 Les icônes

Les **vingt-neuf dessins du canvas**, trait pour trait, dans `HZDessins.swift` : `aujourdhui`, `barres`, `bulle`, `calendrier`,
`chevron`, `cloche`, `coche`, `coeur`, `curseurs`, `deplacer`, `drapeau`, `envoyer`, `fermer`, `fil`, `groupe`, `haltere`,
`itineraire`, `lecture`, `marque`, `micro`, `options`, `partager`, `recentrer`, `recherche`, `reduire`, `relief`, `retour`,
`route`, `trophee`.

Le fichier est **engendré** : on corrige `design/icones.json` et on relance `ci_scripts/icones.py` ; `icones.py --verifier` échoue
si le Swift n'est plus à jour avec sa source. Un dessin est une boîte de 24 (14 pour le triangle de lecture), au trait ou plein.
`HZIcone` le rend à la taille et au trait demandés, le trait étant donné **dans la boîte de 24**, comme le canvas l'écrit. Elle
est toujours muette pour VoiceOver : c'est la commande qui la porte qui a un nom.

---

## 4. La forme

### 4.1 Les rayons

`HZRayon`, dans `HZForme.swift` : douze noms, onze valeurs. Les angles sont des **quarts de cercle** (`.circular`), pas la courbe
continue qu'iOS dessine par défaut : le canvas est écrit en CSS, où `border-radius` trace un cercle. Un bouton est une capsule, un
bouton rond un cercle.

| Jeton | Valeur | Où |
| --- | --- | --- |
| `carte` | 36 | la carte-affiche d'un jour, dans le plan |
| `carteDeClub` | 32 | la carte du club |
| `feuille` | 30 | le haut d'une feuille, et le héros d'Explorer |
| `carteDuFil` | 28 | la carte d'une sortie dans le fil |
| `offre` | 28 | la carte d'offre des réglages |
| `tuile` | 24 | une tuile : séance, record, course, objectif ; une réponse |
| `groupe` | 22 | un groupe de lignes, une tuile de chiffre, une plaque, une bulle du coach |
| `mesure` | 20 | une tuile de mesure du résumé, une ligne d'activité du fil |
| `bandeau` | 18 | le bandeau du coach, un champ de formulaire |
| `proposition` | 16 | la proposition du coach, dans une bulle |
| `vignette` | 14 | la vignette carrée d'une sortie |
| `coinDeBulle` | 6 | le coin d'une bulle, du côté de celui qui parle |

### 4.2 Les espaces nommés

`HZEspace`, les blancs qui reviennent d'un écran à l'autre : `marge` 20 (rangées de commandes, intérieur d'une feuille),
`margeDeTitre` 24 (textes posés à même un fond de couleur), `tuile` 14 (intérieur d'une tuile), `groupe` 16 (intérieur d'un groupe
ou d'un bandeau), `entreTuiles` 12, `entreCommandes` 10, `entrePilules` 8, `sousUnTitre` 14, `entreSections` 28, `sousLaBarre` 28
(dont la barre flottante se tient au-dessus du bord bas) et `haut` 60 (où commence le contenu d'un écran, depuis le bord haut).

**Les blancs qu'un seul écran emploie ne sont pas des jetons de rythme.** Le canvas les règle écran par écran (22 sous une rangée,
26 sous une autre) ; les ranger de force sur une grille serait le réinterpréter. Ils portent un nom dans `HZEcrans.swift`, un espace
de noms par écran : `HZAccueil`, `HZPlan`, `HZStats`, `HZCoach`, `HZFil`, `HZProfil`, `HZReglages`, `HZLive`, `HZResume`,
`HZExplorer`, `HZRecap`, `HZEntree`, `HZPaywall`. Les mesures d'un composant vivent dans l'enum du composant (`HZDiametre`,
`HZHauteurDeBouton`, `HZMesuresDeLigne`, `HZReglages`…).

### 4.3 La page : un haut noir, une feuille blanche qui remonte

La structure de presque tous les écrans du canvas : en haut une couleur pleine ou le noir, avec un seul grand chiffre ; en bas le
détail, sur le blanc. Elle s'écrit une fois, dans `HZPage` :

- le haut commence à `HZEspace.haut` (60) et finit 22 points avant le bord de la feuille, avant le rayon que celle-ci remonte ;
- la feuille (`HZFeuille`) **remonte sur le haut de `HZRayon.feuille`** (30), par une marge négative, pour que le haut passe dessous
  au lieu de s'arrêter net ;
- le contenu de la feuille descend sous son bord arrondi de 24, 22 ou 20 selon l'écran (`HZRetraitDeFeuille` : `ample`, `courant`,
  `serre`) et garde 20 de marge de chaque côté ;
- le fond est en deux moitiés, noir en haut et blanc en bas, pour qu'un tirage ne montre jamais le fond du système ; la zone sûre du
  haut est ignorée et la barre d'état masquée : l'écran peint jusqu'au bord ; le bas laisse 112 points libres pour la barre.

Deux règles de construction, nées de mesures :

- **`HZEspace.haut` est une constante.** On ne lit pas la zone sûre de la fenêtre dans le corps d'une vue : cela suffisait à figer le
  contenu qui défile. Si un encart plus profond devient nécessaire, il se lit hors du corps d'une vue.
- **La racine d'un écran est une surface de la taille de l'écran, le contenu en `overlay(alignment: .top)`.** Jamais un
  `.frame(maxHeight: .infinity)` autour d'un contenu qui peut dépasser : il grandit avec lui, puis son parent le recentre, et tout
  l'écran monte.

### 4.4 La barre flottante

Une pilule noire (`encre`), cinq entrées, l'active dans une pastille blanche (`HZBarreFlottante`). Elle ne touche aucun bord : elle
flotte à 28 du bas, centrée, 60 de haut, et le contenu passe dessous. Pas de libellé visible : chaque entrée porte son nom pour
VoiceOver. Les cinq entrées (`HZOnglet`), dans l'ordre du canvas : **Aujourd'hui, Explorer, Club, Statistiques, Coach**, de 52 sur
44 chacune. L'active passe en encre sur blanc et le trait de son icône s'épaissit d'un cran ; les éteintes sont en `ongletEteint`.
Il n'y a pas de bouton de course : démarrer est la première des quatre actions de l'accueil. Le profil n'est pas dans la barre : on
y entre par l'avatar, et sur son écran la barre n'allume aucune entrée (`aucuneActive`).

### 4.5 « Aucune valeur en dur »

Une vue de la refonte **ne contient pas un nombre.** Toute mesure — marge, taille, rayon, opacité, compte de colonnes, teinte en
hexadécimal — porte un nom et se déclare dans le système de design : un blanc d'écran dans `HZEcrans.swift`, une mesure de
composant dans l'enum du composant, un rayon ou un espace partagé dans `HZForme.swift`.

`check_valeurs.py` le tient, **sans liste d'exceptions** : il lit tout nombre, pas une liste d'écritures, parce qu'un garde qui
connaît une liste d'écritures ignore la suivante. Restent permis `0` partout, `1` hors d'une ligne de mise en page (l'unité d'un
compte), `.lineLimit(1)`, les chaînes et les commentaires. Dans `Haizo/DesignSystem/Refonte/`, où les valeurs se déclarent, il ne
refuse qu'un nombre sur une **ligne de mise en page** (`.padding(.top, 9)`, `VStack(spacing: 9)`). `HZDessins.swift` n'est pas lu :
il est engendré, ce sont des coordonnées de tracé.

Ce que le garde ne dit pas : qu'une valeur nommée est la bonne. `HZAccueil.sousLaSemaine = 26` peut être faux ; c'est la
**comparaison côte à côte** qui le dit. Chaque écran est photographié sur un simulateur de 390 points de large, la largeur des
planches du canvas, et posé à côté du rendu de sa référence (workflow `refonte.yml`, planche `PlancheView`).

---

### 4.6 Le widget, la Live Activity et la montre

Ces trois surfaces ne compilent pas `Haizo/DesignSystem` : elles en recopient les jetons par rôle (`WG` pour le widget et la Live Activity,
`WT` pour la montre), avec la même règle : des aplats, aucun dégradé, aucune ombre, un texte secondaire en gris OPAQUE et jamais en
opacité, l'accent en touche. Même fonte que l'app : Archivo, le fichier variable, réglée par CoreText.

**Le widget d'accueil est l'accueil en miniature.** Fond `0B0B0C` dans les deux modes, la semaine en points (aujourd'hui cerclé), le grand
chiffre de la séance du jour dans l'accent, en fonte d'affichage (graisse 800, largeur 125 %, comme `hzVedette`), son préfixe, son titre
et ses mesures. Le moyen ajoute l'anneau des objectifs. La séance vient de `AccueilModele.hero`, par l'instantané partagé : le widget n'en
recompose rien. Il désactive les marges système (`contentMarginsDisabled`) : les siennes sont les seules.

**La Live Activity est une carte de moins de 158 points** (iOS coupe vers 160), noir franc : l'état (point d'accent, éteint en pause, coche à la fin),
le chrono en fonte d'affichage, une barre pleine largeur vers la durée prévue, la distance et l'allure côte à côte dans deux tuiles
`surfaceSombre`. Le plafond est tenu par un test, pas par un commentaire : `WidgetRenduTests` refuse toute carte plus haute. La barre se masque
quand la séance n'a pas de durée prévue. L'île dynamique reprend la même fonte pour son chrono.

**Les deux se vérifient en image, en CI** (`widget.yml`, artifact `widget`) : un rendu de test avec les vraies vues et le vrai Archivo. Il n'est
pas celui d'iOS (ni marges ni coins du système) : la mise en page, la fonte et les débordements y sont vrais.

## 5. Les composants

À quoi il sert, quand l'employer, son nom Swift. Un écran est **refait à partir de ces composants, jamais repeint par-dessus** : si
le canvas dessine quelque chose que la liste ne contient pas, on ajoute un composant, on ne récrit pas le dessin dans la vue.

**Boutons — `HZBoutons.swift`**
- `HZBoutonRond` : un disque et une icône (retour, fermer, outil de carte, envoi). Huit diamètres (`HZDiametre`) : `pas` 36,
  `commande` 40, `filtre` 42, `outil` 44, `categorie` 56, `action` 58, `controle` 62, `principal` 88. Le nom lu par VoiceOver est
  obligatoire ; sous 44, la zone tactile s'étend sans bouger le dessin.
- `HZAction` : l'une des quatre actions de l'accueil, un disque de 58 et son libellé dessous. La première (démarrer) est pleine,
  disque blanc et icône noire ; les trois autres sont voilées.
- `HZBoutonPilule` : l'action d'un écran. **Noir ou blanc, jamais dans la couleur d'accent**, qui reste aux surfaces et aux chiffres.
  Quatre hauteurs (`HZHauteurDeBouton`) : `petite` 40, `moyenne` 44, `reponse` 46 (la pilule noire d'une réponse du coach), `grande`
  56. `HZBoutonSuivre` en est la forme « suivre » : noire, puis grise une fois suivi.
- `HZAvatar` : un disque de 40, deux initiales, il ouvre le profil. Uni, jamais dégradé. La photo, quand il y en a une, est
  `HZPhotoDePersonne` (`HZPileDAvatars` les empile).
- `HZAmorceDeRecherche` : la pilule voilée de l'accueil qui mène à Explorer — on la touche, on n'y écrit pas. `HZCategorie` : un
  disque clair de 56, une icône au trait fin, son nom. `HZVignette` : un carré noir de 48, rayon 14, le tracé en blanc.

**Pilules — `HZPilules.swift`**
- `HZPilule` : un mot ou une mesure dans une capsule ; ce n'est pas un bouton. Quatre styles (`HZStyleDePilule`) : `etiquette`
  (« Aujourd'hui »), `etiquetteGrasse` (« Record »), `chiffres` (« 45 min · 4:22/km · Z3 », tabulaire), `etat` (« Mode course
  libre »). Voilée sur l'accent ou une teinte, pleine sur le blanc ou le noir.
- `HZFiltre` : une pilule qu'on choisit, dans une rangée. Trois fonds (`HZFondDeFiltre`) : `sombre` (l'active est blanche), `clair`
  (l'active est noire), `contour` (une suggestion, jamais d'état actif). L'état actif est annoncé à VoiceOver.

**Cartes et tuiles — `HZCartes.swift`**
- `HZCarteAffiche` : un jour écrit comme une affiche — une couleur pleine, la date, la séance en très grand, trois colonnes de
  mesures sous un filet. 318 sur 430, rayon 36. L'objet du plan ; le haut de l'accueil en est la version plein écran.
- `HZTuile` : un libellé en haut, un grand chiffre en bas, rayon 24. Quatre formats (`HZFormatDeTuile`) : `seance` 160 × 190,
  `course` 160 × 150, `record` 150 × 150, `objectif` 150 × 170. `HZTuileLegendee` y ajoute le titre et sa précision dessous.
- `HZTuileChiffre` : ce qu'on mesure, puis sa valeur, sur la surface claire — `stats` (rayon 22) ou `resume` (20). L'option `sombre`
  en fait la tuile noire de la série en cours, la seule des quatre qui dise quelque chose d'aujourd'hui.

**Listes — `HZListe.swift`**
- `HZLigneDeListe` : une tête, un titre et son sous-titre, une queue (distance, chevron) laissées à l'appelant. La dernière ligne
  d'une liste n'a pas de filet. `HZChevron`, `HZValeurDeLigne` (« 8,9 km » sur « 6:14/km »).
- `HZSemaineEnPoints` : sept jours sur l'accent, quatre états (`HZEtatDeJour`) — fait (point plein), aujourd'hui (grand anneau), à
  venir (petit anneau), repos (point éteint). Le canvas ne montre plus la charge de chaque jour : c'est la porte vers le plan, pas un
  graphique. L'état se lit par la **forme** autant que par la teinte.

**Réglages — `HZReglages.swift`**
- `HZGroupeDeReglages` (un titre au-dessus d'un groupe gris de rayon 22) et `HZLigneDeReglage` (64 de haut sans précision, plus haute
  avec). `HZStyleDInterrupteur` : un vrai `Toggle` que VoiceOver annonce comme tel, capsule noire de 52 sur 32, bouton blanc de 26.
- `HZCompteur` (− valeur +), `HZChoixADeux` (une piste grise, la valeur choisie dans une pastille blanche), `HZPastilleDeCouleur`
  (32, anneau noir détaché quand elle est choisie), `HZCarteDOffre` (le noir, le nom de l'offre en grand, un bouton blanc).

**Pages, feuilles, formulaires — `HZFeuille.swift`, `HZHub.swift`**
- `HZPage`, `HZCommandesDuHaut` (§ 4.3) ; `HZFeuille`, `HZTitreDeSection` (le titre à `section`, et le lien qui lui fait face),
  `HZBandeauDuCoach` (la marque dans un disque noir, une phrase, rayon 18, toujours en tête de feuille).
- `HZChampDeRecherche` (une pilule de 48 où l'on écrit, voilée sur le noir), `HZChampDeTexte` (le titre en gris au-dessus, la saisie
  dans une pastille claire de rayon 18 ; `securise` pour un mot de passe), `HZPhrase` (un vide, une erreur, une invitation : un état
  vide dit quoi faire), `HZPlaque` (un bloc de surface claire de rayon 22 qui n'est ni une tuile de chiffre ni une ligne).
- `HZJauge` (un rail et son remplissage), `HZCouronne` (le pourcentage d'un objectif), `HZReponse` (une grande ligne tapable de 68 au
  moins, la choisie en noir), `HZSegments` (un segment par question), `HZLigneDePersonne` (photo, nom, ligne grise, et ce qu'on veut
  à droite).

**Le coach — `HZConversation.swift`.** `HZTuileDuCoach` (« ce qu'il regarde », 104 de haut ; la première à l'accent, les autres sur le
noir doux), `HZBulle` et `HZTexteDeBulle` (15 points, interligne 1,4 ; blanc sur la bulle noire, encre sur la claire ; `HZAuteurDeBulle`
dit qui parle), `HZSaisie` (une capsule claire de 54, le bouton d'envoi noir à droite).

**Explorer, fil, stats, plan**
- `HZCarteDeDecouverte` (un club à découvrir : aplat de sa teinte, rayon `carteDeClub` 32, 168 de haut, 214 sur sa fiche sans action ;
  pilule voilée « Ouvert », « Sur demande » ou « Sur code » en haut à gauche, pilule blanche « Demande envoyée » quand il y en a une,
  nom en `titreDeCarte`, « ville · membres » en 15/600) et `HZLigneDeDemande` (une demande d'adhésion : photo, nom, « il y a… », puis
  deux pilules `petite` dessous, Accepter noire et Refuser grise).
- `HZChampDExploration`, `HZCarteDItineraire` (un grand bloc noir, le tracé en accent, la distance en très grand), `HZTuileDeCourse`.
- `HZCarteDeClub`, `HZSortieDuFil` (le bloc est à l'accent quand la sortie est un record, noir sinon ; le nom ouvre la personne, le
  bloc ouvre la sortie), `HZNoteDuFil` (une phrase et une coche : ce n'est pas une sortie), `HZMiniatureDeSortie` (le tracé, ou le
  dessin d'itinéraire quand il n'y en a pas).
- `HZCourbeDAllure` (la forme de l'allure, trait de 4 ; le calcul reste dans l'écran), `HZCarteDAllure`, `HZLigneDeTemps`,
  `HZCarteDeLien`, `HZPeriode` (7 j, 4 sem., 3 mois, 1 an), `HZSplits` (les barres de kilomètres, qui balaient l'une après l'autre),
  `HZColonneDeJour` (la colonne tapable de la rangée des jours du plan), `HZCarrousel` (§ 7).

**La course et ce qui l'entoure**
- **Course en direct** : une carte de 400 de haut, qui cède la place au panneau sur un écran plus court, puis un panneau en
  `noirFranc` — l'allure en `direct`, trois mesures en `chiffreDuDirect`, les commandes du pouce (terminer 62, pause 88, coach 62).
  Les chiffres sont tabulaires et rétrécissent plutôt que de se couper. Les bandeaux GPS sont noirs, texte blanc.
- `HZCourseEnCours` : la pastille qui ramène à une course commencée quand on a quitté son écran — accent plein, encre sur l'accent,
  chrono tabulaire pour qu'elle ne tremble pas. Elle se pose au-dessus de la barre flottante.
- `HZToast` (avec `ToastCenter`) : le message qui passe, une pilule noire au-dessus de la barre, 2,2 s à l'écran. Avec les repères
  posés sur une carte et le cœur du double-tape, c'est l'un des endroits où une ombre légère existe : ce qui flotte sur un
  contenu qui bouge. Le quatrième est la carte de partage au style « Blanc » : elle est transparente, on la pose sur la photo de
  son choix, et du blanc sans ombre ne se lit pas sur une photo claire (`HZJournee.ombreDuTexte`, noir à 35 %, flou 3, sur le bloc
  entier). Les styles « Noir » et « Haizo » n'en ont pas.
- `HZLancement` : la tuile de la marque (72, rayon égal à 0,26 de son côté), son tracé, puis le mot qui se dévoile (§ 7).
- `HZEntree` : l'entrée dans l'app, cinq écrans, une question chacun — le nom, l'objectif, les jours, le niveau, le compte.
  `HZPaywall` : noir plein écran, « Haizo Plus » en grand, tout ce que l'App Store exige visible sans défiler. `HZRecap` : le bilan
  de la semaine, ce que le haut noir ajoute à celui des Stats.

---

## 6. Les feuilles

Toute feuille présentée par-dessus un écran est la même, et s'écrit en deux morceaux, parce que le second ne se pose que sur la vue
présentée :

```
.sheet { HZFeuilleModale(titre: …) { … }.hzFeuille() }
```

`HZFeuilleModale` dessine le contenu ; `.hzFeuille()` règle la présentation. Ensemble :

| Pièce | Valeur |
| --- | --- |
| Coins du haut | `HZRayon.feuille`, 30 |
| Poignée | celle du système, toujours visible |
| Fond | `blanc` |
| Titre | `HZAffichage.section`, 22, à gauche |
| Fermeture | bouton rond de 44 (`HZDiametre.outil`), fond `surfaceClaire`, icône `fermer`, nom « Fermer » |
| Marges | 20 de chaque côté (`HZEspace.marge`), 12 au-dessus du titre, 14 en dessous |
| Hauteurs | moyenne et grande par défaut ; `detents:` pour n'en offrir qu'une (souvent `.large`) |
| Actions | en pilules (`HZBoutonPilule`) dans le contenu : une feuille n'invente pas un second style de bouton |

**`gereSonBas`.** Par défaut, `.hzFeuille()` réserve 28 points au pied de la feuille pour que le dernier élément ne colle pas au
bord. Une feuille qui gère elle-même son bas — un bouton collé en bas, un défilement qui va jusqu'au bord, un écran plein comme les
réglages — se déclare `.hzFeuille(gereSonBas: true)`, sans quoi on aurait deux réserves l'une sur l'autre.

Une feuille ne s'ouvre jamais avec l'habillage du système : fond blanc, coins de 30, poignée, ou ce n'est pas une feuille de Haizo.
`check_feuilles.py` le tient.

---

## 7. Le mouvement

`HZMouvement`, dans `HZMouvement.swift` : quelques réglages, pas une collection ; chacun garde la raison qu'il avait.

| Jeton | Réglage | Pour quoi |
| --- | --- | --- |
| `ecran` | `easeOut`, 220 ms | un changement d'écran : assez court pour ne pas se faire attendre, assez long pour que le fond vide des deux écrans croisés se couvre |
| `chiffre` | `easeOut`, 180 ms | un chiffre qui change (chrono, allure) : sous les 200 ms au-delà desquelles un chrono tremble au lieu de défiler |
| `ressort` | ressort, 280 ms, rebond 0,12 | ce qui arrive à l'écran et se pose : une carte, une pastille |
| `glisse` | ressort, 500 ms, sans rebond | une valeur qui se parcourt : une barre qui avance. Elle ne remplace rien, elle montre une quantité qui se remplit |
| `trace` | courbe (0,22 ; 0,61 ; 0,36 ; 1), 700 ms | un tracé qui se dessine : il doit être fini avant qu'on ait besoin de le lire |
| `choix` | ressort, 260 ms, rebond 0,26 | un choix qui s'ouvre sous le doigt, avec un léger rebond |

Une page ouverte depuis une autre se décale de 28 points en entrant (`decalageDePage`) ; la racine d'un onglet se fond en passant par
une échelle de 0,98 (`echelleDOnglet`). Chaque écran emporte sa transition (`AppScreen.transitionDecran`) : rien ne se croise, parce
qu'un seul des deux écrans se déplace. Le carrousel du plan a son mouvement propre (`HZCarrousel`) : 340 ms, la courbe du canvas
(0,2 ; 0,8 ; 0,2 ; 1), qui part vite et se pose doucement, quand c'est la rangée des jours qui le commande. Le geste du doigt est le défilement horizontal natif
du système, calé sur les cartes (`viewAligned`) : il n'a ni seuil ni résistance qui lui soient propres.

**« Réduire les animations » ne veut pas dire des animations plus courtes : la valeur doit SAUTER.** C'est
`HZMouvement.respecter(reduireLeMouvement, animation)`, qui rend `nil` quand la personne a demandé moins de mouvement. Une animation
ne s'appelle pas directement : elle passe par `respecter`. Deux réglages n'y passent pas encore par ce jeton : l'interrupteur des
réglages (150 ms, sans `respecter`) et le ressort de l'écran de course (400 ms, que l'écran coupe lui-même).

Une animation de **transition** remplace une chose par une autre et reste courte. Une animation de **valeur**, un tracé qui se
dessine ou une barre qui se remplit, ne remplace rien : sa seule contrainte est d'être finie avant qu'on ait besoin de lire ou
d'agir.

**L'ouverture est finie avant que l'écran ne s'efface.** `HZLancement.Tempo` donne les départs et les durées (tuile à 0,42 s,
dévoilement à 0,58 s, tracé de 0,75 s) et le début du fondu (1,15 s, pour une durée de 0,28 s). Chaque valeur est raisonnable toute
seule ; le défaut ne vit que dans leur somme, et `check_lancement.py` refait l'addition à chaque CI.

---

## 8. Les trois langues et l'accessibilité

**Les trois langues.** Français, anglais, espagnol, au catalogue `Localizable.xcstrings` (le français est la langue de développement).
Toute chaîne affichée existe dans les trois, et **la mise en page se tient dans la plus longue** : un libellé anglais ou espagnol plus
long rétrécit avant de se couper (`HZAction.retraitDuLibelle`), et une hauteur ne dépend pas de la langue. Le tutoiement s'accorde
au féminin comme au masculin ; les nombres décimaux s'écrivent avec la virgule en français et en espagnol ; l'allure au format qu'un
coureur lit (`4:45/km`) ; on cite « comme ceci » ou “comme cela”, jamais avec le guillemet droit de la machine à écrire.

**Les cibles et les noms.**
- **Toute cible tactile fait au moins 44 sur 44** (`HZBoutonRond.zoneTactile`). Un dessin plus petit étend sa zone sans bouger :
  disques de 36 et de 40, interrupteur, compteur, pastilles de couleur, croix d'effacement d'un champ.
- **Une commande qui n'est qu'une icône a un nom.** `HZBoutonRond`, `HZAvatar` et `HZCompteur` exigent le nom que VoiceOver annonce ;
  `HZIcone` est muette, c'est la commande qui parle.
- **L'état se dit.** Un filtre, un segment, une pastille de couleur ou une réponse choisie porte le trait « sélectionné ». Une carte
  qui regroupe plusieurs textes se lit comme un seul élément. La progression d'une inscription dit « Question 2 sur 5 », pas cinq
  segments.
- **La forme porte autant que la couleur** : les quatre états d'un jour (plein, anneau, grand anneau, éteint) et les trois
  intensités ne reposent jamais sur la seule teinte. Les petits textes sur l'accent suivent la règle du rose (§ 2.1) ; un texte
  secondaire est un jeton opaque, jamais une opacité.

**Les grands textes.** Le texte d'**interface** suit le réglage « Taille du texte » d'iOS **jusqu'à 1,3 fois** sa taille
(`HZPolice.plafondDInterface`) ; l'**affichage** ne grandit pas — un « 500 » de 128 points occupe déjà la largeur de l'écran. Le
plafond est celui où les hauteurs fixes du canvas (pilule de 40, ligne de 64) tiennent encore. Aller plus haut demande de
réorganiser chaque écran et de le photographier aux grandes tailles : ce travail est à faire écran par écran (§ 11).

---

## 9. Les gardes

Les contrôles de `ci_scripts/` qui tiennent cette DA ; `check_cablage.py` vérifie que chacun est bien lancé par un workflow.

| Garde | Ce qu'il tient |
| --- | --- |
| `check_valeurs.py` | une vue de la refonte ne contient pas un nombre (§ 4.5) |
| `check_majuscules.py` | aucun libellé tout en capitales, sauf entrée comptée avec sa raison (§ 3.3) |
| `check_degrade.py` | aucun dégradé décoratif : seuls la marque et les images qu'on exporte peuvent en porter, à compte exact par fichier |
| `check_verre.py` | aucun verre dépoli (`Material`) |
| `check_emoji.py` | aucun emoji dans le code ni dans les trois langues du catalogue ; `✓`, `▲`, `▼`, `·`, `—` sont des marques typographiques et passent |
| `check_fonts.py` | toute police demandée par le code est livrée, enregistrée dans la cible, et son nom est celui du fichier |
| `ci_scripts/icones.py --verifier` | `HZDessins.swift` est à jour avec `design/icones.json` (§ 3.5) |
| `check_feuilles.py` | toute feuille s'ouvre avec le fond, les coins et la poignée de l'app (§ 6) |
| `check_grands_chiffres.py` | un grand corps tenu sur une ligne peut rétrécir (§ 3.4) |
| `check_lancement.py` | l'animation d'ouverture est finie quand l'écran commence à s'effacer (§ 7) |
| `check_a11y.py` | une commande qui n'est qu'une icône a un nom prononçable (§ 8) |
| `check_grand_texte.py` | la campagne en grand texte a bien pris le réglage : ses images diffèrent des ordinaires |
| `check_etapes.py` | les cinq écrans de l'inscription disent la même chose dans `HZEntree` et dans le conteneur |
| `check_strings.py` | toute chaîne affichée existe au catalogue, donc dans les trois langues |
| `check_guillemets.py` | aucune chaîne n'est citée avec le guillemet droit de la machine à écrire |
| `check_decimales.py` | un nombre à virgule s'affiche avec la locale : la virgule en français et en espagnol |
| `check_marque.py` | l'app s'appelle Haizo ; l'ancien nom ne subsiste que là où une raison est écrite |
| `check_design.py` | compare les valeurs de ce document au code du système de design |

Ce qu'aucun garde ne voit, et que la comparaison côte à côte avec le canvas attrape seule : qu'une valeur nommée est la bonne, qu'un
écran ressemble à sa planche, qu'un texte n'est pas générique.

---

## 10. Ce que Charlotte a décidé, et qu'on ne rouvre pas

| Décision | Quand |
| --- | --- |
| **La barre garde cinq entrées** (le brief en demandait trois). Ce ne sont plus les mêmes : Aujourd'hui, Explorer, Club, Statistiques, Coach. | 9 novembre 2026 (D3), 17 novembre 2026 |
| **L'inscription vise le plan le plus sur mesure possible.** Le critère est la qualité du plan, pas le nombre d'écrans ; le brief demandait trois questions. | 9 novembre 2026 (D4) |
| **D1 à D4 tiennent, face au brief re-transmis.** | 11 novembre 2026 |
| **L'app s'appelle Haizo.** L'identifiant de l'app, le groupe applicatif, le domaine, le schéma d'URL, l'en-tête HTTP et les variables Vercel ne changent PAS : invisibles, et leur renommage coûte une panne. Le dépôt GitHub non plus, parce que l'adresse de confidentialité de la fiche App Store contient son nom. `check_marque.py` tient l'après. | 16 novembre 2026 |
| **La graphie : en capitales au logo et à l'écran de lancement, en capitale initiale dans les phrases.** Dans une phrase, c'est un mot, pas un cri. | 16 novembre 2026 |
| **La refonte visuelle : le canvas fait foi.** « Le design est arrêté. Tu ne réinterprètes pas, tu reproduis. » Tailles, couleurs, rayons, espacements et graisses y sont écrits en clair. | 17 novembre 2026 |
| **Les hypothèses faute de canvas sont laissées à l'équipe** : « Fait tout comme il te semble parfait, ajoute s'il faut ajouter, enlève s'il faut enlever, et on tranchera une fois qu'on aura la maquette sous les yeux. » Elles sont provisoires, et listées au § 11. | 17 novembre 2026 |
| **Tout passe sous la nouvelle DA, par lots**, chacun vérifié par captures : « tu mets tout sous la nouvelle DA ». Fin de la méthode « un écran, une validation, puis le suivant ». | 18 novembre 2026 |
| **La photo de profil reste modifiable** : le crayon sur l'avatar est conservé, c'est ce que voit tout le club. | 18 novembre 2026 |
| **Le fil rend le double-tape pour applaudir**, la ligne « Aimé par … » et l'aperçu du dernier commentaire sous Bravo et Commenter. | 18 novembre 2026 |
| **Le logo à l'ouverture porte le dégradé de l'icône** (rose `#FC105E` en haut à gauche, violet `#7F5AFB` en bas à droite), `HZMarque.degrade`, et non la couleur d'accent choisie dans les réglages : il prenait l'accent, donc un logo violet ou vert chez qui avait choisi cette couleur. L'écran de lancement du système est blanc, comme l'ouverture (il était lavande). | 22 novembre 2026 |
| **Le rose de l'app est celui du logo, `#FC105E`** (il valait `#FF2E6E`, celui du canvas, depuis le 19 novembre). L'icône garde son dégradé du rose au violet : c'est le seul dégradé de Haizo, et le logo. L'app reste en aplats. Le choix d'accent (violet, bleu, vert) et les teintes d'intensité du Plan ne changent pas. | 22 novembre 2026 |

### Ce que le canvas a renversé

Ces décisions portaient sur l'ancien système et ne sont plus en vigueur. La ligne reste pour qu'on ne les redécide pas sans le savoir.

| Décision d'avant | Ce que le canvas en fait |
| --- | --- |
| D1 — les huit nuanciers d'accent restent (9, 11 et 15 novembre) | **quatre couleurs, un seul jeton d'accent** : rose, violet, bleu, vert. « 4 choix seulement, un seul token accent. Supprimer l'habillage Teinté et les autres couleurs. » |
| D2 — fond clair par défaut (9 novembre) | le fond est l'aplat du canvas : noir en haut, feuille blanche, gris clair `#F4F4F6` ; plus de fond « chaud » ou « froid » à trancher |
| Le Club reste sous l'onglet Profil, ne pas y revenir (11 novembre) | le Club est une entrée de la barre flottante, le profil s'ouvre par l'avatar |
| Les SF Symbols restent (11 novembre) | remplacés par les vingt-neuf dessins du canvas, là où le canvas en dessine un |
| Les six teintes d'intensité, ardoise `#44506B` comprise (15 novembre) | trois : vert, bleu, violet |
| La signature de la carte de nuit (13 et 16 novembre) | la signature est l'aplat d'accent ou noir et le très grand chiffre |
| L'en-tête d'accueil porte le tracé GPS, pas une photo (15 novembre) | le haut de l'accueil est la carte-affiche de la séance du jour |
| L'avatar et le récap gardent leur dégradé, comme le logo (15 novembre) | l'avatar est un disque uni portant deux initiales ; aucun dégradé dans l'interface |
| Le thème sombre sera redessiné après le clair (15 novembre) | le canvas ne dessine qu'un rendu ; voir § 2.5 et § 11 |

---

## 11. Ce qui attend une décision de Charlotte

D'après `PROGRESS.md`. Les contenus du canvas sont des exemples ; là où il se tait, l'équipe a posé une hypothèse, écrite ici pour
qu'on la retrouve, à revoir sur la maquette.

| Question | L'état |
| --- | --- |
| **Le mode clair et sombre** | Le canvas montre un interrupteur Clair / Sombre et ne dessine qu'un mode. Les jetons n'ont qu'une valeur ; le réglage « Mode » règle l'apparence du système. Dessiner la seconde ambiance, ou retirer l'interrupteur ? |
| **La couleur d'une séance de qualité** | Le canvas n'a que trois intensités. Le seuil, le fractionné et le renforcement prennent l'accent, avec son encre (accueil, plan). Un repos prend le noir doux. |
| **Le texte agrandi** | L'interface suit le réglage jusqu'à 1,3 fois, l'affichage ne bouge pas. Faire le travail écran par écran pour aller plus haut, ou garder 1,3 ? |
| **La course libre d'une autre discipline** | La barre du canvas n'a pas de bouton de course : sur l'accueil on démarre la séance du jour. Où va, dans le design, une sortie libre à vélo, en trail ou en natation ? Posée le 17 novembre, non tranchée dans `PROGRESS.md`. |
| **Les écrans hors canvas** | L'app comptait cinquante-trois écrans au 17 novembre, le canvas dix. Le plan complet, les phases Récupération et Choix, le plan verrouillé, l'historique, le récap hebdo, les chaussures, la carte de chaleur, les pages de course et le hub du Club sont habillés avec les mêmes composants, à montrer avant validation. |
| **Ce que l'équipe a posé faute de canvas** | Une séance passée et non faite porte une pastille « Non faite » (plan) ou s'affiche comme un repos (accueil) ; les calories ne s'affichent plus pendant la course (elles restent enregistrées et au résumé) ; la marque d'un badge est son symbole et non un court texte ; la flamme de la série est retirée ; « Passer à un objectif » propose quatre tuiles au plus ; le bandeau du coach du plan dit ce que le déplacement fait vraiment, pas « je réorganise le reste ». |
| **La couleur de la carte du club** | Dans la découverte, chaque club prend l'une des trois teintes d'intensité. La carte du club dans l'onglet Club reste bleue comme sur le canvas. Unifier (une ligne : `couleur: HZIntensite.pourClub(id:)`) ou garder le bleu ? |
| **La longueur de l'inscription** | D4 (9 novembre) fait de la qualité du plan sur mesure le critère. L'inscription compte aujourd'hui cinq écrans, une question chacun, et `PROGRESS.md` n'enregistre pas d'arbitrage de Charlotte sur ce raccourcissement : confirmer que les cinq écrans tiennent D4. |

Les trois questions ouvertes le 15 novembre — la chaleur du fond de consultation, la teinte des surfaces secondaires, l'app qui n'a
de signature que sur deux écrans sur six — disparaissent avec l'ancien système : le canvas fixe le fond, les surfaces et la
signature. Les questions hors design (contenu des séances HYROX, branches à reprendre, production) sont dans `PROGRESS.md`.
