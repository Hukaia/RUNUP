# La direction artistique de Haizo

Tenu par la direction artistique. Ce fichier existe pour que la DA ne dépende plus d'une
conversation : les trois questions, la palette, la typographie, les deux thèmes et les règles de
l'écran de séance sont ici, pas dans un fil de discussion.

`RELEASE.md` garde les questions de **livraison** — est-ce que les captures montrent l'app
d'aujourd'hui, est-ce que la production est debout, est-ce que ça se lit dans les trois langues,
est-ce que la politique publiée dit vrai. Ce fichier porte les questions de **design**.

**Ce fichier ne recopie pas le code, il le cite.** Chaque valeur ci-dessous est donnée avec sa
déclaration, et `ci_scripts/check_design.py` vérifie à chaque CI que les deux s'accordent. Un
document de DA qui dérive de l'app est pire qu'aucun document : on le lit en croyant savoir.

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

### Ce que les trois questions veulent dire quand on tient un écran dans les mains

Elles ne se répondent pas de mémoire. Elles se répondent sur une image, dans les trois langues, et
dans les deux thèmes — la campagne `captures.yml` existe pour ça.

**Question 1, en pratique.** Est-ce que le premier chiffre que l'œil rencontre est une performance
ou un repère ? Est-ce qu'un écran vide dit quoi faire, ou constate un manque ? Est-ce qu'une
séance ratée est écrite comme un échec ou comme une information ? Un écran qui n'a de sens qu'avec
trois mois d'historique échoue à cette question même s'il est beau.

**Question 2, en pratique.** Est-ce que les nombres sont justes, datés, et sourcés quand ils
viennent d'un règlement ? Est-ce que les unités sont là ? Est-ce qu'une allure est donnée au
format qu'un coureur lit — `4:45/km` et pas `4,75 min/km` ? Un écran qui arrondit pour faire
joli échoue ici.

**Question 3, en pratique.** C'est la seule des trois qui a des gardes automatiques, et ils ne
couvrent qu'une partie :

| Ce qu'on cherche | Ce qui le tient |
| --- | --- |
| Dégradé décoratif | `check_degrade.py` — autorisé dans le logo seul |
| Verre dépoli | `check_verre.py` |
| Taille d'icône écrite à la main | `check_icones.py` |
| Cran de titrage hors échelle | `check_echelle.py` |
| Écart, marge ou rayon hors de la géométrie déclarée | `check_grille.py` |
| Chiffre et unité composés à la main | `check_chiffres.py` |
| Grand chiffre qui peut se tronquer en silence | `check_grands_chiffres.py` |
| Ouverture qui déborde sur son propre fondu | `check_lancement.py` |
| Jeton de texte hors famille ou en opacité | `check_jetons_de_texte.py` |
| Emoji dans l'interface ou au catalogue | `check_emoji.py` |

**L'emoji a enfin son garde**, et cette ligne du tableau a été fausse pendant un jour : en écrivant
ce fichier le 13 novembre, j'avais cité un contrôle des emojis qui n'existait pas, et
`check_design.py` l'a refusé — un nom de garde entre accents graves est une promesse.
`check_strings.py` ne pouvait pas s'en charger : il ignore au contraire toute chaîne sans lettre,
puisque son sujet est la traduction.

`check_emoji.py` lit la règle d'Unicode plutôt que de deviner : un caractère est un emoji s'il a la
présentation emoji **par défaut**, ou si on la lui demande avec U+FE0F derrière. `✓`, `▲`, `▼`, `·`,
`—`, `″` sont des marques typographiques et passent — une première version les refusait, et un
garde qui refuse du code juste est pire qu'aucun garde. Il scanne le code ET les trois langues du
catalogue, parce qu'une traduction est exactement l'endroit par où un 🔥 revient « pour faire
vivant ».

À sa première exécution, il a trouvé **« Course reçue de ta montre ⌚ »** : un toast, dans les trois
langues, qui doublait une notification portant déjà le symbole `applewatch`.

Ce qu'aucun garde ne voit non plus : **le texte générique et le composant sans intention.** Une
carte qui dit « Continuez comme ça ! » passe tous les contrôles. C'est à l'œil, sur l'image, et
c'est la raison pour laquelle cette question est posée à chaque écran et pas une fois par
version.

---

## 2. La palette

Déclarée dans `Haizo/DesignSystem/Colors.swift` (`RUColor`) et
`Haizo/DesignSystem/AccentTheme.swift`. Les valeurs ci-dessous sont celles du code, vérifiées par
`check_design.py`.

### 2.1 L'accent est au choix de la coureuse — huit nuanciers

**Décision D1 de Charlotte, 9 novembre 2026.** Le brief demandait une couleur d'accent unique.
L'app en propose huit. Conséquence directe sur la DA : **aucun jeton dérivé de l'accent ne peut
être écrit en dur**, et tout écran doit être juste pour les huit.

Valeurs de thème sombre, `AccentTheme.all` — `primary`, `light`, `tail` :

| Nuancier | `primary` | `light` | `tail` |
| --- | --- | --- | --- |
| Rose | `#FF0A78` | `#FF4D9E` | `#7C5CFF` |
| Violet | `#7C5CFF` | `#A78BFF` | `#FF0A78` |
| Bleu | `#3D8BFF` | `#8AB8FF` | `#7C5CFF` |
| Cyan | `#2FD9C4` | `#7CF0E4` | `#3D8BFF` |
| Lime | `#9FE83D` | `#DFFF8C` | `#2FD9C4` |
| Ambre | `#FFB03D` | `#FFD08A` | `#FF4D9E` |
| Corail | `#FF5A3D` | `#FF9478` | `#FFB03D` |
| Magenta | `#D633B8` | `#F07ADB` | `#7C5CFF` |

**Sur fond clair, ces valeurs ne sont pas utilisées telles quelles.** `AccentTheme` les descend
par recherche dichotomique jusqu'à 3,5:1 sur blanc (`meetingContrastOnWhite`), une fois par
nuancier. Sans ça, Lime et Cyan donnaient un mode clair inutilisable. Les jetons à lire sont donc
`RUColor.rose`, `rose2` et `violet`, jamais les valeurs du tableau.

### 2.2 Les couleurs qui veulent dire quelque chose ne suivent pas l'accent

Elles sont FIXES, parce qu'une information ne change pas de sens quand on change de goût. Deux
valeurs par jeton : clair, puis sombre. Les valeurs claires sont plus profondes — les valeurs
sombres sont réglées pour ressortir sur du presque-noir et deviendraient illisibles sur blanc.

| Jeton | Clair | Sombre | Ce que ça dit |
| --- | --- | --- | --- |
| `lime` | `#6B9E00` | `#C8FF3D` | forme, disponibilité |
| `cyan` | `#0E9C8C` | `#38E0D0` | récupération |
| `amber` | `#B86A00` | `#FFB03D` | attention, tempo |
| `amberText` | `#8A5A00` | `#FFD79A` | de l'ambre sur une carte ambrée, à lire en longueur |
| `ember` | `#C2352A` | `#FF6B5A` | fractionné |
| `azure` | `#0F62C8` | `#5AA9FF` | fonctionnel |
| `grape` | `#5B3FD6` | `#9B7CFF` | sortie longue |
| `cycle` | `#80462E` | `#F2B8A0` | la phase du cycle, les quatre confondues |
| `cycleSurface` | `#F6EAE5` | `#130702` | le fond d'un bloc qui appartient au cycle |

**Une seule teinte pour les quatre phases, et c'est une mesure.** Elles empruntaient leurs
couleurs : `.menstrual` prenait `rose`, c'est-à-dire **l'accent choisi par la coureuse** — donc la
phase menstruelle était rose pour l'une et vert lime pour celle qui a pris le nuancier Lime. Les
trois autres prenaient `lime`, `cyan` et `amber`, les teintes des familles de séance : un point
lime disait « endurance » sur un écran et « phase folliculaire » sur l'autre.

L'app n'affiche jamais deux phases à la fois, et celle du moment est nommée en toutes lettres à
côté du point. Quatre couleurs distinguaient donc des choses qu'on ne voit jamais ensemble.

`#F2B8A0` est la valeur de la DA, ici telle quelle en sombre. En clair elle donne 1,73:1 sur une
carte blanche — la branche claire descend à la même teinte, jusqu'à 5,93:1 au pire des cinq fonds.
La surface, elle, a repris la teinte de `#FDF1EC` mais pas sa luminosité : sur notre page chaude,
la valeur de la DA donnait **1,006:1**, c'est-à-dire rien.

### 2.3 Une teinte par famille de séance, la même partout

`SessionFamily.tint`, dans `Colors.swift` et non dans le modèle : `SessionFamily` reste une
classification d'entraînement, lisible et testable sans SwiftUI.

| Famille | Teinte | Clair | Symbole |
| --- | --- | --- | --- |
| Repos | `text3` | `#5B5651` | `moon.zzz.fill` |
| Récupération | `recuperation` | `#5AA9E6` | `leaf.fill` |
| Endurance | `facile` | `#2FB37A` | `figure.run` |
| Sortie longue | `sortieLongue` | `#7B3FE4` | `arrow.right.to.line` |
| Tempo | `seuil` | `#F5A524` | `speedometer` |
| Fractionné | `intervalles` | `#F0225F` | `bolt.fill` |
| Fonctionnel | `fonctionnel` | `#44506B` | — |

**Chaque famille porte aussi une forme, et ce n'est pas une décoration.** Environ un homme sur
douze distingue mal le rouge du vert, et ce sont précisément les deux extrémités de cette palette
— le footing facile et le fractionné.

#### Ce tableau a changé d'avis, et les deux décisions sont de Charlotte

**11 novembre 2026 — les sept teintes d'interface restent.** La raison était mesurée : les cinq
valeurs du brief sont construites pour un fond sombre, `#F5A524` donne 1,9:1 sur blanc, et le
clair venait de passer en thème par défaut.

**15 novembre 2026 — le brief de direction artistique les redemande, nommément, en tête de ses
cinq corrections obligatoires.** C'est la décision la plus récente, et elle est prise en
connaissance du thème clair, puisque le même brief redessine le clair autour d'elles. Le tableau
ci-dessus est donc celui du 15 novembre.

CE QUE ÇA COÛTE, MESURÉ SUR BLANC ET NON ESTIMÉ :

| Teinte | Avant | Après |
| --- | --- | --- |
| Récupération | `#0E9C8C` 3,41:1 | `#5AA9E6` **2,54:1** |
| Endurance | `#6B9E00` 3,22:1 | `#2FB37A` **2,68:1** |
| Tempo | `#B86A00` 4,12:1 | `#F5A524` **2,04:1** |
| Fractionné | `#C2352A` 5,47:1 | `#F0225F` 4,12:1 |
| Sortie longue | `#5B3FD6` 6,72:1 | `#7B3FE4` 5,72:1 |
| Fonctionnel | `#0F62C8` 5,83:1 | `#44506B` 8,06:1 |

Trois passent sous 3:1, le seuil demandé à un objet graphique PORTEUR DE SENS. Elles n'en sont
pas : la famille est portée par la FORME, colonne de droite du tableau, et la couleur ne fait que
l'appuyer. C'est la même raison qui justifiait déjà les symboles. Le chiffre est écrit ici parce
qu'il est bas, pas parce qu'il est faux — et parce qu'une décision qui s'inverse doit laisser la
mesure derrière elle, sinon elle s'inversera encore.

**La sixième teinte est l'ardoise `#44506B`, tranchée le 15 novembre.** Les cinq autres sont des
couleurs de course ; le renforcement n'en est pas une. Une teinte froide et sourde le range à part
sans l'éteindre.

**Ces six jetons ne sont PAS `lime` / `cyan` / `amber` / `ember` / `grape` / `azure`.** Ces
six-là sont des couleurs sémantiques d'interface — `lime` veut dire MIEUX, `amber` veut dire MOINS
BIEN — et `check_teintes.py` tient la liste fermée de leurs emplois. Les faire servir aussi de
palette d'entraînement, c'était deux grammaires sur un même jeton.

### 2.4 Le texte

Quatre jetons, **opaques et dans la famille du fond**. Voir § 3 pour la règle, et
`check_jetons_de_texte.py` pour la barrière.

| Jeton | Clair | Sombre | Emplois |
| --- | --- | --- | --- |
| `textPrimary` | `#181511` | blanc pur | 265 |
| `text2` | `#443F3A` | `#BBB6C3` | 244 |
| `text3` | `#5B5651` | `#9893A0` | 318 |
| `text4` | `#B7B2AD` | `#514C59` | 8 |

`text4` **ne colore pas du texte à lire** : points médians, filets, pastilles inertes. Ses 1,7:1
sont voulus, et `check_contraste.py` tient la liste fermée de ses emplois avec une raison par
entrée.

Le primaire sombre est le blanc pur, délibérément hors famille : c'est le seul jeton dont on veut
le maximum de lisibilité.

Le primaire CLAIR, lui, a bougé le 12 novembre avec le fond, et c'est le garde qui l'a vu. Il était
resté `#15151C` au premier chantier, à juste titre — il portait le bleu 7 points au-dessus du
rouge, donc il était déjà dans la famille des fonds lavande. Quand les fonds sont passés au chaud,
cette raison est devenue fausse sans que rien ne l'écrive, et `check_jetons_de_texte.py` l'a refusé
à la première exécution. `#181511` garde sa luminance — 18,19:1 sur une carte contre 18,17.

### 2.5 Les surfaces

| Jeton | Clair | Sombre | Rôle |
| --- | --- | --- | --- |
| `card` | `#FFFFFF` | `#16161F` | la carte |
| `card2` | `#EEECE7` | `#201F2A` | une sous-surface DANS une carte |
| `bg2` | `#E8E6DF` | `#121118` | le second fond |
| `traceBackground` | `#14131E` | les deux | le fond d'un tracé de sortie |

Le fond de page, `RUColor.bg`, n'est pas une constante : c'est un neutre — `#F5F4F1` en clair,
`#08070D` en sombre — sur lequel l'habillage « teinté » mélange **3,5 % de l'accent en clair, 10 %
en sombre**. Une trace, pas un aplat : au-delà, le fond cesse d'être un fond et concurrence les
cartes posées dessus. La valeur claire a été à 7 % — sept pour cent du rose sur le neutre donne une
page franchement rose, et les cartes blanches censées flotter dessus se lisaient comme des trous.

**Le neutre clair est chaud depuis le 12 novembre, et il a été froid.** Il penchait vers le violet
de l'accent, avec cette raison : « un gris pur à côté d'un rose vif prend l'air sale, un gris qui
partage sa famille non ». L'argument est bon et il ne tient pas, parce qu'il suppose UN accent :
l'app en propose huit (D1), dont le cyan, le lime et le bleu. Un fond lavande ne partageait la
famille que de deux nuanciers sur huit.

Le fond prend donc la position du **papier** — un blanc cassé chaud sur lequel n'importe quelle
encre se pose — plutôt que celle d'un écho de l'accent.

**La teinte du brief, pas sa luminosité**, comme pour les jetons de texte. `#FBF9F7` est presque
blanc : sous une carte blanche il ne recule que de 1,050:1, contre 1,104 pour l'ancien froid. C'est
la moitié de la séparation, et ce recul est précisément ce qui empêche une carte à image pleine de
se lire comme un trou. `#F5F4F1` garde la luminance de l'ancien et retourne sa famille : 1,100:1.

**Les trois surfaces claires ont bougé ensemble**, et c'était obligatoire : une page chaude sous
des sous-surfaces lavande, c'est un écran qui se contredit. `card` reste le blanc pur — c'est la
surface la plus claire, et elle n'a pas de famille à porter.

### 2.6 Les deux surfaces de l'écran de séance

| Jeton | Valeur | Thèmes |
| --- | --- | --- |
| `seanceSurface` | `#0E0E14` | les deux |
| `seanceFond` | `#0A0A0E` | les deux |

**Fixes dans les deux thèmes, et ce n'est pas un oubli.** L'écran de course reste sombre même en
apparence claire : on le regarde dehors, en mouvement, à bout de bras, et un fond blanc y perdrait
le contraste que les chiffres demandent.

**Elles gardent la famille FROIDE quand le reste du clair est passé au chaud**, et c'est cohérent :
une famille suit la clarté de la surface, pas le thème choisi. Ces deux-là sont sombres, donc elles
appartiennent à la famille sombre. Même chose pour `traceBackground`, qui est le fond d'une image.

Les couleurs sémantiques — `azure`, `cyan`, `grape` — ne suivent aucune famille non plus : leur
teinte EST leur sens. Un bleu qui se réchaufferait cesserait de dire « fonctionnel ».

---

## 3. Les deux thèmes

**Décision D2 de Charlotte, 9 novembre 2026 : le fond clair est le défaut.** Le sombre l'était.
Le `#FBF9F7` chaud du brief **n'est pas imposé** — le fond froid actuel peut rester.

Trois règles, dans cet ordre.

**Une couleur de thème se déclare en deux branches, jamais une.** `isLight ? clair : sombre`, dans
`RUColor`. Une couleur écrite dans un fichier de vue est un défaut, même juste : personne ne la
trouve en ouvrant le système.

**Le texte est opaque, et dans la famille du fond — QUELLE QU'ELLE SOIT.** La règle ne nomme aucune
couleur. `check_jetons_de_texte.py` lit les fonds du thème, prend le signe de leur penchant, et
exige du texte le même signe. Une opacité est refusée : elle se mélange à ce qui passe dessous,
donc sa couleur serait décidée par la surface et non par le système.

Cette règle a été éprouvée le jour même où elle a été posée. Elle a été écrite quand les fonds
clairs étaient lavande, et elle exigeait alors du texte violet ; le fond clair est passé au chaud
quelques heures plus tard, et elle a exigé du texte chaud **sans qu'une ligne du garde change**.
Elle a même attrapé le jeton que j'avais oublié de faire suivre. Les jetons sombres, eux, restent
froids : leurs fonds le sont.

**Aucun fond ne perd de contraste.** Un gris violet se détache MOINS d'un fond lavande qu'un gris
neutre. Une valeur se règle donc sur le pire des fonds et pas sur le plus fréquent — calée sur la
carte blanche, `text3` tombait à 4,94:1 sur `bg2`. Les cinq fonds mesurés sont `bg`, `bg2`, `card`,
`card2`, et une borne du fond teinté.

Les rapports de contraste **ne sont écrits nulle part**, ni ici ni en commentaire :
`check_jetons_de_texte.py` les calcule et les imprime à chaque CI. Ils ont vécu dans un commentaire,
et c'est exactement comme ça que la branche sombre de `text3` avait pu rester sous le seuil pendant
qu'un commentaire d'à côté affirmait l'avoir corrigée.

---

## 4. La typographie

Une seule famille de texte : **Inter**, déclinée par taille et par graisse. Livrée dans les trois
cibles, vérifiée par `check_fonts.py`. Le titrage est Inter Medium, la même famille que le texte
courant, une graisse plus haut — pas une seconde famille.

**Les chiffres sont à chasse fixe partout.** `RUFont.display` applique `tnum` lui-même : trois
fichiers appelaient `.monospacedDigit()` à la main et tous les autres l'oubliaient, donc les
colonnes de l'app dansaient partout sauf à trois endroits.

### 4.1 Une seule échelle : 12 / 14 / 16 / 20 / 28 / 40

**Six nombres, et ce sont des POINTS RENDUS.** Jusqu'au 15 novembre, les valeurs écrites dans le
code passaient par deux facteurs de compensation — 1,25 pour le texte, 1,09 pour les chiffres —
hérités de tailles dessinées contre une police abandonnée. Aucun nombre du fichier n'était donc
la taille réelle : « corps = 12 » rendait 15 points. Les deux facteurs valent 1,0, et un nombre
est maintenant ce qu'on voit.

Le texte courant, `RUTextSize` — ces valeurs sont des tailles de base, que le réglage
d'accessibilité du système multiplie :

| Cran | Valeur | À quoi ça sert |
| --- | --- | --- |
| `micro` | 12 | méta : unités, micro-libellés, dates |
| `small` | 14 | légendes, valeurs secondaires, notes |
| `body` | 16 | le texte courant, et les libellés de carte sous l'alias `label` |
| `emphasis` | 20 | libellés qui priment, titres de carte et de section sous l'alias `title` |

Le titrage et les chiffres, `RUDisplaySize` — **l'échelle est fermée**, et `check_echelle.py` la
tient :

| Cran | Valeur | À quoi ça sert |
| --- | --- | --- |
| `caption` | 12 | micro-chiffres, valeurs de pastille |
| `label` | 16 | libellés de bouton, valeurs en ligne |
| `subtitle` | 20 | titres de ligne de liste, grille de mesures dense |
| `figure` | 28 | LE chiffre d'une carte, et les titres de page, de feuille et de carte sous l'alias `title` |
| `banner` | 40 | le chiffre unique d'un écran, une accroche, un record — **au plus un par écran** — et le titre d'écran sous l'alias `hero` |

**Quatre noms sont des ALIAS, pas des crans.** `label` est `body`, `title` est `emphasis`,
et côté chiffres `title` est `figure`, `hero` est `banner`. Swift refuse deux cas d'énumération
à la même valeur brute — le compilateur l'a dit en quatre lignes le 15 novembre — et l'échelle
unique fait tomber ces paires sur le même nombre.

Les garder en alias plutôt que de les supprimer, c'est garder ce qu'ils disent : un libellé de
carte n'est pas un corps de texte, même quand les deux font 16 points. Ce qui les sépare à taille
égale, c'est la graisse. Et le jour où l'un des deux rôles doit bouger, il bougera sans emporter
l'autre.

**Une conséquence à assumer** : `title`, côté chiffres, prend la graisse de `figure`. Un titre de
page passe donc du demi-gras au gras. Le brief le demande — « titres d'écran en 40 lourd ».

**La graisse suit le cran**, parce que la graisse perçue baisse quand la taille monte : `figure`,
`hero` et `banner` passent en grasse, les quatre crans du bas non.

Une taille hors échelle s'écrit `display(horsEchelle: 52)`, et l'étiquette est là pour que
l'exception se voie : un `grep horsEchelle` donne la liste complète. Il y en a dix, dans cinq
fichiers, et `check_echelle.py` tient le compte par fichier avec une raison par entrée.

### 4.2 La casse : pas de capitales, sauf sur un bouton

> « Supprimer les majuscules espacées ("TA JOURNÉE", "CE QU'IL REGARDE", "ALLURE CIBLE") : ce
> sont des labels en 12 gris, casse normale. » — brief du 15 novembre, point 1.

Les trois exemples sont des **labels**, et c'est ce que la règle vise. Un bouton en capitales est
autre chose : une convention assumée, que le brief ne nomme nulle part. **`check_majuscules.py`
le tient** — un libellé tout en capitales est refusé, sauf entrée comptée avec sa raison.

Il y en a 67, dans 30 fichiers : des boutons, deux affiches qu'on exporte (la carte de partage et
les images de la vidéo), l'onglet `RUN`, et une dette nommée — « EN PAUSE » et « EN COURS » sur
la montre, parce que la capture livrée à Apple est empreintée contre toute la cible `HaizoWatch`
et ne se refait pas sans machine macOS.

**Les capitales vivaient de trois façons**, et retirer l'une laissait les deux autres : un
`.textCase(.uppercase)` sur la vue, un `tracking` positif sur une chaîne déjà capitalisée, et les
capitales **dans la chaîne elle-même**, au catalogue, en trois langues — quarante-trois clés.
C'est la troisième qui demande un garde : les deux premières se voient en relisant une vue.

### 4.3 Le libellé d'un chiffre : `metaStyle`

12 points, gris, casse normale, **pas d'interlettrage**. L'interlettrage positif existe pour
rendre des capitales lisibles ; en casse normale il ne fait qu'écarter les lettres d'un mot qui
se lit très bien sans.

Il était écrit **cinq fois** — `.font(RUFont.sans(.micro, weight: .bold)).tracking(1.5)`, mot
pour mot, dans `LiveRunView` (trois fois), `RecapView`, `StatsView` et `RaceGoalView`. C'est ce
qui a permis à `eyebrowStyle` de perdre ses capitales le 15 novembre pendant que les cinq autres
gardaient les leurs.

`medium` et non `bold` : la graisse perçue monte quand la taille baisse, et le libellé doit
nommer le chiffre, pas le concurrencer — l'inverse exact de ce que fait `RUDisplaySize.grasse`
en haut de l'échelle.

### 4.4 Les sept crans d'icône

`RUIconSize`, relevés sur les 170 appels existants plutôt qu'inventés : 9, 11, 13, 15, puis les
trois crans hauts. Les deux plus employés — 13 et 15, 65 appels à eux deux — n'ont pas bougé.

**Décision de Charlotte, 11 novembre 2026 : les SF Symbols restent.** Le brief demande Phosphor ou
Lucide au trait 1,5 px. 200 appels, et les SF Symbols suivent seuls la ligne de base, le poids de
la fonte et les tailles d'accessibilité. Gain esthétique, coût structurel : non.

---

## 5. Les règles de l'écran de séance

C'est le seul écran qu'on regarde en courant : essoufflée, en mouvement, à bout de bras. Ses
règles ne sont pas celles des écrans de consultation.

**Il reste sombre dans les deux thèmes.** Voir § 2.6.

**La consigne d'abord, le chronomètre ensuite.** Le chrono est le chiffre le moins coaché de
l'écran — une montre à vingt euros le donne. Ce qu'une app de coaching a de plus à dire, c'est quoi
faire maintenant. La consigne est donc au-dessus, avec le segment en surtitre et l'allure visée en
gros ; le chrono descend de 64 à 52 points quand il y a une consigne, et retrouve ses 64 quand il
n'y en a pas (HYROX, course libre).

**L'allure cible est le plus grand corps de l'écran**, au cran `banner` — celui que l'échelle
réserve à « au plus un par écran ». Le chrono prend `hero` quand une consigne l'accompagne, et
retrouve son très grand corps hors échelle (64) quand il est le seul chiffre, en course libre ou
en HYROX.

Ça n'a pas toujours été vrai : l'allure était à `hero` sous un chrono à 52, donc 1,49 fois plus
petit que ce que le code appelait « la première chose lue de l'écran ». Les deux phrases étaient
écrites à soixante lignes l'une de l'autre.

**Le plafond de l'allure est 44, et c'est une mesure.** Sur l'iPhone le plus étroit il reste 284
points utiles. « CIBLE 10:30/km » — le pire cas, un coureur lent pendant son échauffement — occupe
261 points à 44 et 301 à 52. Au-delà de 44, la consigne se tronque en course.

**Tout grand chiffre tenu sur une ligne peut rétrécir.** `lineLimit(1)` sans `minimumScaleFactor`
tronque, et sur un nombre la troncature ment : « 1:23:45 » devient « 1:23… » sans que rien ne dise
que ce n'est pas l'heure complète. Ni le chrono ni l'allure n'en portaient, et la ligne débordait
dès 1,31× de taille de texte quand l'app en autorise 2,00×. `check_grands_chiffres.py` le tient.

**Les chiffres roulent, ils ne sautent pas.** `monospacedDigit` d'abord, et c'est le plus important
des deux : avec des chiffres de largeurs différentes, un chrono de 52 points se décale
horizontalement à chaque seconde — un tremblement permanent au centre de l'écran, sur le seul
objet qu'on fixe en courant.

**Rien ne s'invente quand il n'y a rien à dire.** Sans allure cible au plan, le bloc de consigne
disparaît. Pendant l'échauffement, la récupération et le retour au calme, l'allure cible perd
l'accent et gagne le mot CIBLE : l'écran affichait « ÉCHAUFFEMENT » suivi de l'allure des
répétitions dans le même accent, soit, lu à bout de souffle, la consigne de courir son
échauffement à l'allure de son travail. Même place, même taille, aucun saut de mise en page toutes
les quatre-vingt-dix secondes — l'accent seul dit « c'est maintenant ».

**Le chiffre lui-même est le bouton.** Pas une petite croix qu'on finit par détester.

---

## 6. Le mouvement

`RUMotion`. Sept valeurs nommées, et `RUMotion.respecting(reduceMotion, …)` rend `nil` quand le
système demande moins d'animation — une animation n'est jamais appelée directement.

| Jeton | Durée | Pour quoi |
| --- | --- | --- |
| `digit` | 180 ms | un chiffre qui change |
| `ecran` | 220 ms | une transition d'écran |
| `snap` | 260 ms | une réponse à un geste |
| `settle` | 280 ms | l'arrivée d'une carte, **et le changement d'onglet** |
| `glide` | 500 ms | le remplissage d'un anneau |
| `draw` | 700 ms | le tracé d'un itinéraire |

Plus `stagger` à 55 ms, plafonné à 6 éléments — au-delà, le dernier d'une liste arriverait une
demi-seconde après le premier.

**La fourchette du brief ne couvre pas tout, et c'est la distinction qui tranche.** Elle parle des
TRANSITIONS — ce qui remplace une chose par une autre. Une animation de VALEUR, un anneau qui se
remplit ou un tracé qui se dessine, ne remplace rien : elle montre une quantité en train d'être
parcourue. Sa contrainte est autre, et simple : **être finie avant qu'on ait besoin de lire ou
d'agir.**

`digit`, `ecran` et `settle` sont des transitions, et les trois tiennent la fourchette.

`settle` gouvernait le **changement d'onglet** — ce que son propre commentaire appelle
« l'animation la plus vue de l'app » — à 440 ms. Toute l'app paraissait lente de 160 ms, à chaque
passage d'un onglet à l'autre.

`glide` et `draw` sont des animations de valeur. Leurs bornes sont mesurées, pas choisies :
`glide` doit laisser le dévoilement de l'écran d'ouverture finir avant le fondu, `draw` joue sur
chaque carte du fil qui porte un tracé — ce n'est pas un moment rare qu'on regarde, c'est du
contenu qu'on attend.

**L'ouverture est finie avant que l'écran ne s'efface**, et ça ne l'était pas : le dévoilement
finissait à 1,38 s quand le fondu commençait à 1,15 — 29 % du mouvement d'ouverture de l'app se
jouait pendant qu'elle disparaissait. Chaque valeur était raisonnable toute seule ; le défaut ne
vivait que dans leur somme. `check_lancement.py` refait l'addition à chaque CI.

---

## 7. Ce que Charlotte a décidé, et qu'on ne rouvre pas

| Décision | Quand |
| --- | --- |
| **D1** — les huit nuanciers d'accent restent | 9 novembre 2026 |
| **D2** — fond clair par défaut, pas forcément chaud | 9 novembre 2026 |
| **D3** — la barre basse garde ses cinq entrées (le brief en demandait trois) | 9 novembre 2026 |
| **D4** — l'inscription reste longue, et vise le plan le plus sur mesure possible | 9 novembre 2026 |
| D1 à D4 tiennent, face au brief re-transmis | 11 novembre 2026 |
| Le Club reste sous l'onglet Profil — **ne pas y revenir** | 11 novembre 2026 |
| Les SF Symbols restent | 11 novembre 2026 |
| ~~Les sept teintes d'intensité actuelles restent~~ — **renversée le 15 novembre** | 11 novembre 2026 |
| La signature de la carte de nuit s'étend aux quatre écrans qui ne l'avaient pas | 13 novembre 2026 |
| **D1 amendée** — les huit nuanciers restent, et `#F0225F` devient le défaut | 15 novembre 2026 |
| Le thème sombre survit, et sera redessiné APRÈS le clair | 15 novembre 2026 |
| Les six teintes d'intensité du brief s'appliquent, ardoise `#44506B` comprise | 15 novembre 2026 |
| L'en-tête d'accueil ne porte pas de photo : c'est le tracé GPS en grand | 15 novembre 2026 |
| L'avatar et le récap de fin de course gardent leur dégradé, comme le logo | 15 novembre 2026 |
| **L'app s'appelle Haizo.** L'identifiant de l'app, le groupe applicatif, le domaine, le schéma d'URL, l'en-tête HTTP et les variables Vercel ne changent PAS : invisibles, et leur renommage coûte une panne. Le dépôt GitHub non plus, parce que l'adresse de confidentialité de la fiche App Store contient son nom. Le journal raconte l'avant ; `check_marque.py` tient l'après. | 16 novembre 2026 |
| **La graphie : en capitales au logo et à l'écran de lancement, en capitale initiale dans les phrases.** Dans une phrase, c'est un mot, pas un cri. | 16 novembre 2026 |
| **La refonte visuelle : le canvas fait foi.** « Le design est arrêté. Tu ne réinterprètes pas, tu reproduis. » Voir § 10 pour ce qu'elle renverse dans ce tableau, écran par écran. | 17 novembre 2026 |

---

## 8. Ce qui attend une décision de Charlotte

| Question | L'état mesuré |
| --- | --- |
| La chaleur du fond de consultation | Le brief demande `#FBF9F7`, blanc chaud ; l'app porte `#F4F3F8`, gris-lavande froid. **C'est le plus grand écart visible qui reste**, et D2 a explicitement laissé le chaud non imposé. |
| ~~La nuance de l'accent par défaut~~ | **Tranchée le 15 novembre** : `#F0225F` en clair, `#FF0A78` reste la valeur sombre tant que le thème sombre n'est pas redessiné. |
| La teinte des surfaces secondaires | Le brief du 15 novembre demande `#F3EEF4` pour les pastilles et les sous-surfaces — une lavande FROIDE. Les fonds clairs sont passés au CHAUD le 12 novembre, et les quatre jetons de texte ont suivi la famille du fond le même jour. Adopter `#F3EEF4` tel quel remet du froid sur une page chaude ; c'est la même question que la ligne au-dessus, et elle se tranche avec elle. |
| **L'app n'a de signature que sur deux écrans sur six** | Voir § 9. C'est la question qui reste après tout le reste. |


---

## 9. La signature : la carte de nuit

Le test final de la DA — « sorti de son cadre de téléphone et sans logo, l'écran doit être
reconnaissable comme Haizo » — ne tenait que sur deux écrans sur six. Charlotte a tranché le
13 novembre : l'étendre aux quatre autres.

### Ce que l'app avait d'authored

Une seule chose : **la carte sombre au tracé néon.** Un presque-noir plein cadre, un tracé GPS qui
s'y dessine en rose-violet lumineux, la date et les deux chiffres posés dessus. Elle a un point de
vue — la sortie comme un objet qui brille dans le noir — et elle ne ressemble à rien d'autre.

### Avant et après, mesurés

Part de l'image occupée par une surface sombre, **en thème clair** — donc là où le sombre est un
choix et non le thème. Même mesure des deux côtés : un pixel compte comme sombre quand la moyenne
de ses trois composantes est sous 70, sur un échantillon d'un pixel sur quatre.

| Écran | Avant | Après |
| --- | --- | --- |
| Club | 30,1 % | 30,1 % *(inchangé — il la portait déjà)* |
| Coach | 2,7 % | **20,3 %** |
| Stats | 1,9 % | **20,2 %** |
| Journée | 1,5 % | **19,4 %** |
| Accueil | 15,1 % | 15,0 % *(inchangé — c'est l'original)* |
| Plan | 1,3 % | **13,8 %** |

Les trois dessins qui suivent la journée — le ruban du Coach, l'anneau de la Journée, la courbe
des Stats — bougent de quelques dixièmes d'une campagne à l'autre, puisque leur contenu change
avec le jour. La colonne « après » est celle du 14 novembre.

Les six écrans tiennent maintenant entre 13,8 % et 30,1 %. Avant, quatre d'entre eux étaient sous
3 % : ils n'avaient aucun élément de signature, et étaient interchangeables avec ceux de n'importe
quelle app de course.

### LA RÈGLE

Elle est écrite dans `Haizo/Views/Components/CarteDeNuit.swift`, qui est le composant, pour qu'on
ne puisse pas la suivre sans la lire. Quatre choses ensemble, et il faut les quatre :

1. **Ce qui est mesuré devient le dessin.** Pas une illustration de la donnée : la donnée
   elle-même, tracée. Le tracé EST la sortie, les barres SONT le plan, la courbe EST l'allure, le
   ruban EST la semaine. Un écran qui n'a rien à dessiner n'a pas de carte de nuit.
2. **Le dessin occupe le cadre**, bord à bord à la marge près. Il n'est pas une vignette posée
   dans une carte : c'est le cadre qui lui est donné.
3. **La nuit, et rien d'autre d'allumé.** `RUColor.traceBackground` (`#14131E`) dans les deux
   thèmes, et l'accent y est à pleine force — ce qu'il n'est nulle part ailleurs sur page claire.
4. **Les chiffres se posent dessus.** Pas dessous, pas à côté : sur le dessin, sous un voile qui
   garantit la lecture quelle que soit la forme. Ils légendent une image, ils n'étiquettent pas un
   graphique.

Et une cinquième, négative : **une seule par écran.** Deux points de fixation n'en font aucun.

### Ce que chaque écran y met

| Écran | Le dessin | Ce qui est posé dessus |
| --- | --- | --- |
| Accueil | le tracé GPS de la dernière sortie | sa date, sa distance, son allure |
| Plan | seize semaines de volume, en couleurs de phase | le nombre de semaines, le plus gros volume |
| Coach | les sept jours de la semaine, famille et durée | forme, séance du jour, dernière sortie |
| Journée | l'anneau des trois objectifs | le compte, **au moyeu** et non en bas à gauche |
| Stats | la courbe d'allure et son point RECORD | l'allure moyenne et son écart |
| Club | le tracé GPS de chaque sortie du mur | *(inchangé — il la portait déjà)* |

La Journée est la seule où les chiffres sont DANS la forme plutôt que dessus : son compte est le
moyeu de l'anneau. C'est une exception à la règle 4, et elle est nommée ici pour ne pas être
imitée ailleurs sans raison.

### L'ENCRE DE LA NUIT

La nuit ne suit pas le thème. Ce qu'on y peint ne doit donc pas le suivre non plus — et c'était le
cas partout :

- l'anneau de départ du tracé était en `RUColor.textPrimary`, soit `#181511` en thème clair : du
  presque-noir à 85 % sur du presque-noir. Sur la capture de l'accueil, il ne se lit pas comme un
  repère mais comme un **trou** percé dans la lueur ;
- la trace fantôme, à 7 % de la même encre, disparaissait tout court ;
- le tracé lisait `RUColor.rose`, qui rend `primaryOnLight` en thème clair — une valeur descendue
  pour rester lisible **sur du blanc**, qu'il n'y a pas ici.

Mesuré sur les huit nuanciers, rapport de luminance de l'accent contre `#14131E` :

| nuancier | sombre | clair | perte |
| --- | --- | --- | --- |
| rose, violet, bleu, magenta | 4,23 à 5,55 | idem à 6 % près | ≤ 6 % |
| corail | 5,94 | 5,25 | 12 % |
| ambre | 10,10 | 5,26 | 48 % |
| cyan | 10,37 | 5,25 | 49 % |
| lime | 12,34 | 5,23 | 58 % |

Le nuancier par défaut ne perdait presque rien, ce qui explique que personne ne l'ait vu pendant
deux mois : trois nuanciers sur huit perdaient la moitié de l'éclat de leur tracé.

Sur la nuit, on lit donc : `surLaNuit`, `surLaNuit2` (0,72) et `surLaNuit3` (0,16) pour l'encre ;
`accentsDeLaNuit` ou `AccentTheme.current.*` pour l'accent ; `limeSombre`, `cyanSombre`,
`amberSombre`, `emberSombre`, `azureSombre`, `grapeSombre` pour le sens. **`check_nuit.py` le
tient** — il refuse un jeton de page dans le corps d'un appel à `CarteDeNuit`, et dans les
fichiers qui ne dessinent que sur la nuit.

**IL N'Y A PLUS QU'UNE CARTE DE NUIT DANS L'APP**, depuis le 16 novembre : le tracé de la
dernière sortie, sur l'accueil. Le brief du 15 novembre la borne à deux emplois — « les cartes
noires n'existent que pour un tracé GPS ou l'écran de séance » — et le dit une deuxième et une
troisième fois sur deux écrans nommés : la courbe des Stats « sur carte blanche et non noire »,
le bloc « Ce qu'il regarde » du Coach « passe en blanc ». Les quatre autres y sont donc
repassées, avec le graphique du Plan et l'anneau de la Journée.

Trois composants recevaient un booléen `surLaNuit` pour vivre sur les deux fonds —
`DailyGoalsBarsView`, `RubanDeSemaine`, la ligne d'allure des Stats. Les trois n'ont plus qu'un
fond, et le booléen est parti avec : **un paramètre qui ne prend plus qu'une valeur entretient
l'idée qu'il reste un choix.** `SessionFamily.tintSurLaNuit`, que seul le ruban lisait, est parti
de même.

### La Journée : tranché, et pourquoi

Un anneau de progression sur fond noir est le vocabulaire de l'app Activité d'Apple, reconnue
partout. La question 3 de la DA — « est-ce qu'on devine qu'il a été généré ? », et par extension
copié ? — se posait là, et seulement là. Posée à Charlotte le 14 novembre, elle m'a renvoyé la
décision. **L'anneau reste sur la nuit**, pour trois raisons, dans l'ordre de leur poids :

1. **La forme diffère vraiment.** Apple empile trois anneaux concentriques et ne met aucun chiffre
   au centre. Celui-ci est une piste UNIQUE coupée en trois arcs, avec le compte au moyeu. Apple
   montre trois efforts séparés ; nous montrons une journée dont on a bouclé deux tiers.
2. **L'anneau de progression n'appartient à personne.** C'est un objet de vocabulaire, comme une
   barre ou une courbe. Ce qui fait la signature, c'est la nuit sous le dessin et les chiffres
   posés dessus.
3. **L'alternative coûte plus qu'elle ne rapporte.** Revenir au fond clair ferait retomber la
   Journée à 1,5 % de surface sombre : le seul des six écrans sans signature, pour écarter une
   ressemblance qui ne tient qu'au premier coup d'œil.

**Le seul endroit où la réponse serait différente :** la grille de captures de l'App Store, où une
vignette est tout ce qu'on voit. Les six écrans de la fiche sont un choix séparé, et le changer ne
touche pas l'app.

### L'accueil ne répète pas ce qui vit ailleurs

Règle née le 14 novembre, d'une phrase de Charlotte devant la capture : « ça fait beaucoup d'infos
du coup ». Elle avait raison, et c'est moi qui l'avais densifié le matin même.

**L'accueil est un hub.** Tout ce qu'il pourrait dessiner appartient déjà à un autre écran — la
semaine au Plan, l'anneau à la Journée, les chiffres aux Stats. Son travail est d'orienter, pas de
résumer. Une carte qui raccourcit d'un tap un trajet déjà ouvert par la barre d'onglets ne gagne
pas sa place.

Ce qu'il garde, dans l'ordre des questions qu'on se pose en l'ouvrant : **qu'est-ce que je fais
aujourd'hui · qu'est-ce que je viens de faire · où j'en suis dans mon plan · suis-je à jour de ma
journée.** Quatre blocs. Ce qui a été retiré ce jour-là — les trente derniers jours, les trois
mesures du jour, le pied du programme — vit en entier à un tap de là.

---

## 10. La refonte du 17 novembre : le canvas fait foi

Charlotte a arrêté un design complet, dessiné hors de l'app, sur un canvas de dix écrans :
Accueil, Plan, Run, Resume, Coach, Stats, Club, Explorer, Profil, Reglages. Sa consigne tient en
deux phrases : « Ces fichiers sont la référence exacte : tailles, couleurs, rayons, espacements
et graisses y sont écrits en clair. Tu ne réinterprètes pas, tu reproduis. »

**Tant que la refonte est en cours, deux systèmes cohabitent.** Les §§ 1 à 9 décrivent l'app
livrée, écran par écran, jusqu'à ce que chacun bascule ; ce § décrit ce vers quoi elle va. Le
nouveau système vit dans `Haizo/DesignSystem/Refonte/` sous le préfixe `HZ`, les écrans refaits
dans `Haizo/Views/Refonte/`. Un écran bascule d'un bloc — refait à partir des composants, jamais
repeint par-dessus l'existant — et l'ancien système est retiré avec le dernier.

### Ce qui change

| | L'app livrée | Le canvas |
| --- | --- | --- |
| La fonte | Oswald pour l'affichage, Inter pour le texte | **Archivo variable**, seule. Affichage : graisse 800, largeur 125 %. Interface : largeur 100 %, graisses 500, 600, 700. Chiffres tabulaires. |
| L'accent | huit nuanciers, trois valeurs chacun | **quatre couleurs d'app**, une valeur chacune, un seul jeton d'accent |
| Les intensités | six teintes | **trois** : vert, bleu, violet |
| Les rayons | cinq, de 2 à 24 | **dix**, de 14 à 36 : cartes 36, feuilles 30, tuiles 24, groupes 22, boutons en pilule |
| La grille | un pas de 2 jusqu'à 14, puis 18, 24 | les mesures du canvas, écran par écran, chacune nommée |
| Les icônes | SF Symbols | les **vingt-neuf dessins du canvas**, trait pour trait |
| La navigation | barre d'onglets du système | **barre flottante noire** : Aujourd'hui, Explorer, Club, Stats, Coach. Le profil par l'avatar, le plan par les points de la semaine. |
| Les surfaces | cartes bordées, fond chaud | aplats : accent, noir, blanc, gris clair. **Aucun dégradé, aucune ombre, aucun trait décoratif.** |

### La règle du rose

**Jamais de petit texte blanc sur l'accent.** Sur le rose, un libellé s'écrit dans l'encre
sombre de l'accent ; le blanc y est réservé aux grands chiffres et aux titres. Les trois autres
couleurs d'app sont assez sombres pour porter du blanc à toutes les tailles : leur encre est le
blanc. C'est `HZAccent.encre`, et c'est la seule différence de traitement entre les quatre.

### Ce que la refonte renverse dans le § 7

Aucune de ces lignes n'est renversée tant que l'écran qui la porte n'a pas basculé.

| Décision du § 7 | Ce que le canvas en fait |
| --- | --- |
| **D1** — huit nuanciers | quatre couleurs. L'habillage « Teinté » disparaît. |
| **D3** — cinq entrées dans la barre | toujours cinq, mais pas les mêmes : le profil en sort, Explorer et Club y entrent. |
| Le Club reste sous l'onglet Profil | le Club est une entrée de la barre. |
| Les SF Symbols restent | remplacés par les dessins du canvas, là où le canvas en dessine un. |
| Les six teintes d'intensité | trois. |
| L'avatar garde son dégradé | l'avatar est un disque uni portant deux initiales. |
| La signature : la carte de nuit (§ 9) | la signature devient l'aplat d'accent et le très grand chiffre. |

### Ce que la refonte ne touche pas

Les données, la logique, le coach, le GPS, les calculs. Les contenus du canvas sont des
exemples : chaque écran branche les vraies données de l'app à leur place. Les cartes de Run et
de Resume sont dessinées à la main dans la maquette ; l'app garde sa vraie carte, avec le tracé
dans la couleur d'accent sur liseré blanc.

### Les écrans refaits

| Écran | Où | Commit |
| --- | --- | --- |
| **Accueil** | `Haizo/Views/Refonte/AccueilView.swift`, logique dans `Haizo/Models/AccueilModele.swift` | 17 novembre |

Les autres (Plan, Run, Resume, Stats, Coach, Club, Explorer, Profil, Reglages) gardent leur
ancien habillage et l'ancienne barre d'onglets jusqu'à leur tour. La barre flottante est posée par
`RootTabView` sur les écrans de cette liste, et seulement sur eux.

### Les gardes de la refonte

- `check_valeurs.py` — une vue de la refonte ne contient pas un nombre. Toute mesure porte un
  nom et se déclare dans le système de design.
- `check_grille.py` et `check_majuscules.py` continuent de tenir l'ancienne app ; le premier
  passe les deux dossiers de la refonte au garde ci-dessus, dont la règle est plus dure.
- La comparaison côte à côte : chaque écran est photographié sur un simulateur de 390 points de
  large — la largeur des planches du canvas — et posé à côté du rendu de sa référence. C'est
  elle, et aucun script, qui dit si une valeur nommée est la bonne.

