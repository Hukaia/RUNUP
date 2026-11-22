# Où en est Haizo

Tenu par l'équipe produit et technique, mis à jour à chaque chantier terminé. Un chantier n'est
« terminé » que quand la construction est verte, les tests sont verts, aucun avertissement nouveau
n'apparaît, l'avant/après est écrit ici, et les trois langues ont été vérifiées.

## Ce qui a été décidé

| Décision | Qui | Quand |
| --- | --- | --- |
| iOS seul pour l'instant ; Android plus tard | Charlotte | 7 novembre 2026 |
| Régler tout ce que l'audit a relevé, sans exception | Charlotte | 7 novembre 2026 |
| Surveillance des plantages : **maison**, pas Sentry — le rapport part sur notre serveur Vercel, aucune dépendance Swift tierce | Charlotte | 7 novembre 2026 |
| Et « maison » veut dire MetricKit, pas un gestionnaire de signal : Apple écrit que `backtrace` n'y est pas appelable, donc un rapport écrit là ne peut pas porter de pile d'appels. Voir le chantier 14. | l'équipe technique | 8 novembre 2026 |
| « ABONNÉ » → le libellé dit l'action (« SE DÉSABONNER ») | Charlotte | 7 novembre 2026 |
| « RETIRER » → une confirmation, pas un poids visuel différent | Charlotte | 7 novembre 2026 |
| `privacy.html` et `support.html` portés sur `main`, donc publiés : la politique dit maintenant ce que l'app collecte | Charlotte | 8 novembre 2026 |
| Fiche App Privacy d'App Store Connect corrigée et publiée : cinq types ajoutés, cinq passés de « non lié » à « lié », Product Interaction remis sur Analytics, Other Usage Data retiré | Charlotte | 9 novembre 2026 |
| Une carte de premiers jalons sur l'accueil, et des clubs proposés quand le champ de recherche est vide | Charlotte | 9 novembre 2026 |
| **D1 — les huit thèmes d'accent restent.** Le brief demandait une seule couleur d'accent ; l'app en propose huit au choix, et elles restent. Tout jeton dérivé doit donc être juste pour les huit, jamais écrit en dur. | Charlotte | 9 novembre 2026 |
| **D2 — fond clair par défaut, pas forcément chaud.** Le thème sombre était le défaut. Le `#FBF9F7` chaud du brief n'est pas imposé : le fond froid actuel peut rester. | Charlotte | 9 novembre 2026 |
| **D3 — la barre basse garde ses cinq entrées.** Le brief en demandait trois. | Charlotte | 9 novembre 2026 |
| **D4 — l'inscription reste longue, et vise le plan le plus sur mesure possible.** Le brief demandait trois questions ; la consigne est « fais au mieux pour quelque chose d'ultra sur mesure pour le plan ». La longueur du parcours n'est donc plus un défaut : sa qualité est le critère. | Charlotte | 9 novembre 2026 |
| **D1 à D4 tiennent, face au brief re-transmis.** Le brief d'origine demande une couleur d'accent unique, un fond blanc chaud, trois entrées de barre basse et une inscription en trois questions. Les quatre décisions du 9 novembre les emportent. | Charlotte | 11 novembre 2026 |
| **Le Club reste sous l'onglet Profil.** Mesuré : c'est le seul des trois différenciateurs annoncés qui soit à deux niveaux de profondeur, et le brief le voulait dans la barre. Proposé de le remonter à la place de Stats ; décision de ne pas le faire. Ne pas y revenir. | Charlotte | 11 novembre 2026 |
| **SF Symbols restent.** Le brief demande Phosphor ou Lucide au trait 1,5 px. 200 appels, et les SF Symbols suivent seuls la ligne de base, le poids de la fonte et les tailles d'accessibilité. Gain esthétique, coût structurel : non. | Charlotte | 11 novembre 2026 |
| ~~**Les sept teintes d'intensité actuelles restent.**~~ Le brief en donne cinq, en une seule valeur chacune ; l'app porte deux thèmes et huit accents, et `#F5A524` sur blanc donne 1,9:1. **Renversée le 15 novembre** — voir quatre lignes plus bas. | Charlotte | 11 novembre 2026 |
| **D1 tient, avec un défaut imposé.** Le brief de direction artistique du 15 novembre demande « un seul accent #F0225F » ; les huit thèmes restent, et #F0225F devient le défaut. C'est lui que montrent la fiche, les captures et l'identité ; qui veut en changer le peut encore. | Charlotte | 15 novembre 2026 |
| **Le thème sombre reste, et sera redessiné après le clair.** Le brief du 15 novembre ne décrit que le fond clair. Le sombre n'est pas abandonné : la même grammaire y sera déclinée une fois le clair refait. | Charlotte | 15 novembre 2026 |
| **Les six teintes d'intensité du brief s'appliquent, et renversent la décision du 11 novembre.** Le 11, la raison était mesurée : ces valeurs sont construites pour un fond sombre. Le brief du 15 les redemande en tête de ses cinq corrections obligatoires, et il redessine le clair autour d'elles — c'est la décision la plus récente, prise en connaissance du thème. Trois des six passent sous 3:1 sur blanc ; la famille est portée par le SYMBOLE, pas par la couleur, et c'est déjà la raison pour laquelle chaque famille en a un. Les chiffres sont dans DESIGN.md § 2.3. | Charlotte | 15 novembre 2026 |
| **La sixième teinte est l'ardoise `#44506B`**, pour le renforcement. Les cinq autres sont des couleurs de course ; celle-là n'en est pas une. | Charlotte | 15 novembre 2026 |
| **L'avatar et le récap de fin de course gardent leur dégradé**, comme le logo. Tous les autres dégradés d'interface partent. | Charlotte | 15 novembre 2026 |
| **L'en-tête d'accueil ne porte pas de photo** : c'est le tracé GPS en grand. | Charlotte | 15 novembre 2026 |
| **Pas d'image iPad sur la fiche App Store.** « L'app iPad doit être différente, on ne va pas courir avec son iPad. » Haizo est une app iPhone (`TARGETED_DEVICE_FAMILY` vaut 1) : Apple n'en demande aucune, et une mise en page iPhone étirée dans un cadre d'iPad n'est pas une app iPad. | Charlotte | 10 novembre 2026 |

## Ce qui attend une décision

| Question | Pourquoi ça bloque |
| --- | --- |
| Contenu des séances HYROX | Il faut quelqu'un qui a couru un HYROX. L'équipe n'a pas cette compétence et ne doit pas l'inventer. |
| Que faire des neuf commits de `claude/running-club-finance-wwuq46` | Mesurés le 9 novembre : ni sur `main` ni sur la branche de travail. Deux idées en ont été reprises (chantiers 16 et 17). Restent une direction artistique concurrente — **Oswald** en fonte d'affichage, quand la branche de travail a tranché pour Inter — et des retouches de profil dont l'équivalent existe. Rien ne presse ; la branche ne se supprime pas tant que ce n'est pas tranché. |
| Que faire de `ef3ad89`, sur `claude/new-session-otcd8z` | « La lecture des agrégats rentre dans `api/events.js` : douze fonctions, pas treize ». Quelqu'un s'est battu contre le même plafond Vercel, sur une autre branche, pour une autre fonctionnalité. Le code n'est nulle part ailleurs. |
| `main` et la branche de travail n'ont en commun que le commit initial | 853 commits d'un côté, 50 de l'autre, aucune fusion depuis le 13 juillet. Ça n'empêche rien, sauf pour `privacy.html` : la page dont l'adresse est sur la fiche App Store est servie par GitHub Pages **depuis `main`**, donc mise à jour à la main. `check_politique.py` compare la page publiée en ligne au dépôt. |
| Cette branche doit-elle rester la production ? | Elle l'est, confirmé dans les réglages Vercel le 7 novembre : `Settings → Environments → Production → Branch Tracking` porte `claude/runup-ios-swiftui-app-5b1yv6`. Donc aucune relecture, aucune préproduction. Les aperçus, eux, sont maintenant éprouvables — voir le chantier 11. |


## Au passage

**Une redondance en attente dans `privacy.html`.** « Aucun outil tiers de rapport de panne » y est
dit deux fois, à deux paragraphes d'écart — repéré le 8 novembre par Charlotte en cherchant la
phrase sur la page publiée. Ce n'est pas faux, c'est redondant, et ça ne valait pas un
aller-retour de plus sur `main` : cette page est servie par GitHub Pages depuis `main`, donc s'y
corriger demande de recopier le fichier à la main dans l'éditeur web. La consigne est écrite en
commentaire DANS le fichier, juste au-dessus du paragraphe concerné — c'est le seul endroit que
le prochain qui l'édite ouvrira forcément.


**La version monte dès qu'une version est publiée.** Apple ferme le train d'une version publiée :
depuis la sortie de la 3.3 le 3 novembre 2026, tout envoi à TestFlight en 3.3 est refusé (90186 et
90062). Le défaut ne se voit qu'au DERNIER pas de la chaîne — construction verte, tests verts,
archive signée, puis refus — donc après dix minutes de machine macOS. `project.yml` est passé en
3.4, aux trois cibles.

**Un attribut séparé de sa déclaration par une documentation change de propriétaire.** Swift
l'accepte sans rien dire, et l'attribut s'applique à la déclaration SUIVANTE. En extrayant
`viderLeStock` de `poser`, je l'ai posée entre les attributs de `poser` et sa déclaration :
`@MainActor` s'est recollé sur `viderLeStock`, `poser` a perdu son isolation, et la construction
des captures est morte — quarante minutes plus tard, parce qu'ici il n'y a pas de compilateur.
C'était la deuxième fois : `AdaptivePlanEngine.swift` porte déjà le récit d'un
`@discardableResult` resté douze fonctions plus haut. `ci_scripts/check_attributs.py` relit les
281 fichiers Swift du dépôt et refuse ce motif ; il a trouvé un TROISIÈME cas le jour où il a été
écrit (`ClubService.swift` : la documentation de `setRoutePhoto` avait glissé sur
`setActivityPhoto`, avec son attribut). Son premier jet listait « HaizoWidget » au singulier — un
dossier qui n'existe pas, et `rglob` sur un chemin absent ne rend rien, sans rien dire : le
contrôle couvrait le widget en apparence. Il exige maintenant que chaque dossier existe.

**Un garde-fou qui juge une image doit garder l'image.** Le contrôle de découpage du film
d'aperçu a dit « ce plan vise le coach et montre les stats » sur l'espagnol — une langue sur
trois, le français et l'anglais verts dans la même exécution. Il ne restait rien à regarder : le
dossier de travail est temporaire, l'enregistrement brut n'est plus publié, et la comparaison
porte sur un gris réduit à 258 pixels. Deux explications se calculent et tombent toutes les deux :
un décalage uniforme de +3,1 s mettrait aussi le plan du profil sur l'accueil (il est reconnu), et
une dérive d'horloge assez forte pour égarer le coach égarerait le profil davantage. Les quatre
témoins espagnols, eux, sont nets — le plus proche voisin est à 20,7 d'écart. Donc : non élucidé.
`bascules.py --preuves` garde désormais l'image de l'instant jugé, pleine taille et en couleurs,
et l'artefact la publie — seulement quand le verdict est mauvais.

**Suite, le lendemain : il s'est reproduit, en anglais, et avec ses images.** Deux plans sur
quatre tombaient sur l'écran du plan SUIVANT — le coach montrait les stats, le profil montrait
l'accueil — et `--preuves` a gardé les deux images, qui le montrent sans discussion (la barre
d'onglets y désigne l'onglet Stats sous un plan qui annonce le Coach).

**Donc le découpage ne peut pas reposer sur l'heure annoncée par la caméra.** `simctl` dit
« Recording started » avant d'écrire sa première image, et le reste de l'écart varie avec la
charge de la machine. Une horloge qu'on ne peut pas vérifier n'est pas une mesure.

`bascules.py --aligner` cherche donc le décalage par le CONTENU : les quatre écrans visés sont
photographiés par la passe claire, on essaie des décalages au quart de seconde sur ±4 s, et on
garde celui qui met les quatre plans sur leurs écrans. Le montage coupe sur ce décalage-là. Si
aucun ne les met tous les quatre, la mesure le dit et le film n'est pas fabriqué — ce qui reste
le bon comportement : à ce moment-là, ce n'est plus une horloge, c'est autre chose.

Éprouvé dans les deux sens sur un film fabriqué dont on connaît le découpage : on ment de trois
secondes, il retrouve zéro ; on dit la vérité, il ne déplace rien. (Et le premier jet de ce
test-là se trompait lui-même — deux de ses quatre écrans d'essai étaient identiques, parce que
leur motif était modulo 2.)

**Et cette recherche-là ne sait pas faire mieux qu'à une seconde près — c'est intrinsèque.** La
question « ce plan montre-t-il le bon écran ? » a la MÊME RÉPONSE sur deux secondes et demie :
le test appuie sur l'onglet 0,6 s avant le début du plan, et le plan dure deux secondes. Il n'y
a pas de minimum à trouver, il y a un plateau, et c'est le bruit de l'image qui y tranche. Elle
a rendu 0 pendant des semaines et −0,75 s le 8 novembre, sur le même harnais. Un décalage de
−0,75 est parfait pour l'identité et faux pour le découpage : la fenêtre de 0,9 s qui cherche
le changement d'écran tombe alors entièrement avant lui, et le garde-fou ne voit plus rien.

**J'ai écrit un affinage pour reprendre ce décalage sur le changement d'écran, et je l'ai
retiré.** Il a fait TROIS exécutions rouges — plus que le défaut qu'il visait — dont deux sur
des prises dont l'horloge était juste : −0,62 s une fois, −1,33 s une autre.

La cause n'est pas dans l'affinage, elle est dans `classer` : il reconnaît l'écran d'avant en
comparant chaque image à LA PREMIÈRE DE LA FENÊTRE. Ce choix n'est juste que pour une fenêtre
courte — le test laisse 0,6 s entre l'appui et le début du plan, donc sur 0,9 s le premier tiers
est encore l'écran précédent. Élargie à 2 s, la première image tombe n'importe où : au milieu
de la transition d'avant, ou sur un écran encore vide. « Avant » ne correspond alors presque à
rien, l'estimateur rend la longueur de la fenêtre, et l'affinage corrige d'autant. Les images
gardées par `--preuves` le montrent sans discussion : trois écrans VIDES, barre d'onglets seule.

Un affinage demanderait une autre référence pour « l'écran d'avant » — le témoin du plan
PRÉCÉDENT, que la passe claire photographie. C'est faisable, ce n'est pas écrit, et la note
au-dessus de `alignement` le dit. **En attendant, le défaut du plateau se solde par un film
REFUSÉ**, ce qui est le comportement sûr : les images partent, le film faux ne part pas.

**Trois erreurs de ma part sur ce seul sujet.** D'abord j'ai cru que l'instant où l'on regarde
était en cause, et l'exécution suivante a rendu le même −0,75. Ensuite une fenêtre d'affinage
qui ne couvrait pas le cas qui l'avait motivé. Enfin l'affinage lui-même, trois fois rouge.

**Ce qui reste de ces tentatives, et qui est bon.** `instant_du_changement` prend la DERNIÈRE
image de l'écran d'avant et non la première qui n'en est plus — même nombre sur une fenêtre
propre, ce qui explique que tous les cas fabriqués passaient, et immunisé contre un
clignotement.

**Et une question qui était mal posée depuis le début.** « À quel instant juger un plan » a eu
quatre réponses dans la journée, et les trois premières étaient fausses : `debut + 0,5 s`
tombait avant la pose des écrans lents (0,57 s mesuré) ; `fin − 0,25 s` dans l'action suivante,
car les plans sont CONTIGUS, et pour le dernier plan dans le démontage du test ; le MILIEU sur
l'écran des Stats DÉJÀ DÉFILÉ — le test fait défiler pendant le plan, et pas toujours au même
moment. Il n'existe pas d'instant unique qui soit sûr sur les quatre plans à chaque exécution.

Ce qu'on veut savoir n'est pas « quel écran y a-t-il à cet instant précis », c'est « le film,
coupé sur ce plan, montre-t-il le bon écran ». Le plan dure deux secondes et le film les montre
toutes : il suffit qu'il CONTIENNE le bon écran. On regarde donc trois instants répartis dans
le plan et on garde le meilleur. Un plan posé sur le MAUVAIS écran — le décalage de trois
secondes qui a sorti trois films faux — n'a aucun instant qui corresponde, et reste refusé ;
deux cas éprouvent les deux moitiés de la règle.

**Et un message disait l'inverse de sa condition.** « La fenêtre ne commence pas sur l'écran
d'avant » s'affichait quand AUCUNE image de la fenêtre ne quitte l'écran d'avant. Il m'a fait
raisonner une demi-heure sur la mauvaise cause.

**L'épisode précédent, lui, ne s'était pas reproduit sur le coup.** Deux exécutions complètes du harnais
ont suivi, et leur étape de film est verte dans les trois langues — `es-ES.mp4` existe et son
découpage tombe sur les bons écrans. C'était donc un accident de prise, pas un défaut de
l'alignement : un appui d'onglet qui n'a pas pris, très probablement. Ce qu'il faut en retenir
n'est pas la cause, qu'on ne connaîtra pas, mais le comportement : **le garde-fou a refusé de
publier un film faux**, ce que trois films sortis avant lui n'avaient pas eu pour les arrêter. Et
la prochaine fois, l'image sera dans l'artefact.

**CETTE BRANCHE DE TRAVAIL EST LA PRODUCTION.** Découvert le 7 novembre à 17 h 20, dans
l'incident ci-dessous. `main` n'a pas bougé depuis le 24 octobre et ne contient même pas
`api/races/`, pourtant les routes `api/races/*` répondaient normalement en production. La preuve
est dans les déploiements que Vercel enregistre sur GitHub : **douze déploiements
« Production » le 7 novembre, un par commit de cette branche**. Chaque poussée qui touche `api/`,
`lib/` ou `package.json` part donc EN LIGNE, tout de suite, chez les gens qui ont l'app. Il n'y a
pas d'étape de préproduction, et il n'y a pas de relecture. À décider : est-ce voulu ?

**La porte de sortie est écrite : [RELEASE.md](RELEASE.md).** Ce que les quatre chaînes
garantissent et ce qu'elles ne garantissent pas, les quatre questions qu'aucune machine ne pose,
les commandes à lancer dans l'ordre, et la liste honnête de ce qui n'est tenu par aucune barrière.

**Les chevrons sont des symboles, décision du 7 novembre.** Les deux boutons de retour
dessinaient le caractère « ‹ » là où cinq autres retours de l'app emploient déjà `chevron.left` ;
six indicateurs de ligne dessinaient « › » dans des fichiers qui, deux lignes plus loin,
employaient `chevron.right`. Huit caractères typographiques remplacés par les deux symboles, aux
crans de l'échelle d'icônes. Il ne reste aucun `Text("›")` ni `Text("‹")` dans l'app.

**Un contrôle qui cherche un motif dans un fichier finit par se trouver lui-même.** Trois fois
le 8 novembre. `check_cjs.py` refuse qu'un paquet livré en ESM seul soit chargé par `require` —
et le correctif qu'il venait de faire écrire cite `require('jose')` dans son commentaire, donc il
a signalé ce fichier-là. `check_filet.py` cite les deux formes qu'il refuse, dans sa propre
documentation. `check_cablage.py` cherchait `"from PIL" in texte`, et sa propre ligne de
recherche contenait ces mots : il s'est accusé lui-même de lire des images. Les deux premiers
blanchissent les commentaires ; le troisième ne pouvait pas, puisque c'était son code — il lit
les imports dans l'ARBRE syntaxique, qui ne contient que ce que Python exécute.

**Un garde-fou qu'on croit avoir est pire que pas de garde-fou**, et trois existaient sans
tourner : `test_session.py`, `test_accent.py`, et `test_comparer.py`, écrit le 8 novembre.
(Un quatrième, `check_profile.py`, a semblé en être un — et c'était le contrôle qui se
trompait : sa règle tourne à chaque build, appelée par `profils.py`, qui l'importe. Il suit
les imports depuis. Une dispense fausse est pire qu'une dispense manquante : elle dit qu'on
sait, et on ne sait pas.) `check_cablage.py` exige maintenant que tout
`check_*.py` et tout `test_*.py` de `ci_scripts/` soit nommé par un workflow, ou figure dans une
liste de dispenses AVEC sa raison — ou soit importé par un fichier qui, lui, est nommé. Il n'y
a aucune dispense aujourd'hui.

**Et câblé ne veut pas dire qu'il a de quoi tourner.** `test_comparer.py` était bien nommé par
un workflow, et il a échoué dix minutes plus tard sur `ModuleNotFoundError: No module named
'PIL'` : il était dans TestFlight, dont le python est celui du système. Les huit scripts du dépôt
qui lisent des images tournent dans un job qui installe Pillow dans un venv. `check_cablage.py`
pose donc la seconde question, et ne dépend lui-même de rien — c'est le job qui n'installe rien
qui le lance, et `pip install` nu est refusé sur les runners macOS.

**Le trait qui sépare deux lignes était écrit de deux façons, et une des deux était fausse.**
Trente endroits posaient `Divider().background(RUColor.line)` : le `Divider` de SwiftUI a sa
propre épaisseur — un pixel d'écran, un tiers de point sur un ×3 — et sa propre couleur, et
`.background` peint derrière lui au lieu de le recolorer. Douze autres dessinaient le bon filet à
la main. Aucun contrôle ne le voyait, aucune capture non plus : les écrans qui employaient
`Divider` ne sont pas photographiés. `RUFilet` les remplace tous les quarante-deux et nomme son
orientation au lieu de la deviner ; `check_filet.py` tient la porte.

**Le harnais de captures ne dit pas ce qu'il y a sur les images**, et découper un écran
photographié est par définition un changement qui ne doit rien changer à l'écran. `comparer.py`
prend les captures d'avant et celles d'après et dit ce qui a bougé : écart moyen, nombre de
pixels au-delà du bruit, et le CADRE qui les contient. Barre d'état masquée — elle porte l'heure,
et un outil qui compte ce pixel-là dit « tout a changé » à chaque fois. Le compte de pixels est
là à côté de la moyenne parce qu'un petit bloc changé du tout au tout ne pèse presque rien sur la
moyenne d'une image de 2 796 points, et que c'est exactement la forme d'un défaut de découpage.

**Découper une pile SwiftUI n'est pas neutre, et deux questions restent sans réponse sûre.**
Le classement est sorti de `ClubView` sans histoire : c'était un enfant unique d'un `Group`, le
sortir ne change rien à la mise en page, et TestFlight est vert dessus. Les trois sections de
pépites — ce que le club prépare, les séances tenues, les records — étaient au contraire trois
enfants DIRECTS d'une pile espacée de 24, et les regrouper en fait un seul enfant. Deux
comportements décident alors du résultat, et aucun des deux ne se lit dans la documentation :

1. **Une pile sans enfant est-elle espacée comme une vue vide ?** Quand les trois sections se
   taisent — un club tout neuf — chacune rendait une `EmptyView`, et une pile n'espace pas
   autour d'une `EmptyView`. Une pile vide est, elle, une vue de hauteur nulle mais présente.
   Quarante-huit points de blanc apparaîtraient là où l'aperçu a justement été retravaillé pour
   ne plus montrer de sections vides.
2. **`.task` part-il sur un `Group` dont le contenu est vide ?** La parade au point 1 est de ne
   rien rendre quand il n'y a rien — mais `highlights` vaut `nil` au premier rendu, toujours,
   donc la condition est fausse au moment même où le chargement doit partir. Les sources se
   contredisent : les unes disent que `.task` ne part jamais sur un `Group` vide, une autre
   qu'Apple l'a traité à part depuis iOS 26. Ce n'est pas une question à trancher par vote.

L'extraction a donc été annulée, et la bonne réponse est celle que le relevé indiquait déjà :
sortir les données et le réseau du club dans un magasin observable, et ne laisser aux vues que
de l'affichage. Six états sur trente sont partagés par trois régions ou plus, et ce sont
exactement ceux-là.

**`ClubStore` existe depuis, et il fait disparaître les deux questions au lieu d'y répondre.**
Les neuf états de données, les dix-huit fonctions de réseau, puis les quinze appels qui
traînaient au milieu des feuilles et des boutons : le mur, les sorties de groupe, les quatre
réglages du club, la suppression d'activité et `highlights`. `ClubView` ne garde que ce qui est
de l'écran — l'onglet affiché, les feuilles, les brouillons, les confirmations en attente — et
ne connaît plus `clubService` que pour le passer à une sous-vue. 2 721 → 1 799 lignes.

C'est `highlights` qui débloque les pépites : la donnée étant au magasin, la sous-vue n'en
recevra qu'une copie en lecture et le parent gardera son `.task`. Il n'y a plus de `Group` vide
dont il faudrait deviner le comportement.

L'état de l'application entre par le CONSTRUCTEUR et non par chaque appel : onze des dix-huit
fonctions le lisent, et le passer en paramètre aurait changé dix-huit corps — ce qui transforme
un déménagement vérifiable en réécriture. `@State` ne s'initialise pas depuis l'environnement,
mais il s'initialise depuis un paramètre, et c'est `SocialView` qui le passe.

Le magasin s'appelle `magasin` et non `club`, et ce n'est pas une préférence : le fichier est
plein de `if let club = board.club`, et le premier renommage a fait MASQUER le magasin par ces
liants locaux dans quatre blocs. Trouvé en lisant le diff, avec trois autres dégâts du même
renommage — les cases de l'énumération `Tab`, qui s'appellent `board` et `feed`, deux étiquettes
d'argument, et un `if let errorMessage` devenu `if let magasin.errorMessage`, qui n'est pas du
Swift.

**Et le découpage ne change rien à l'écran, c'est mesuré.** Vingt-quatre captures du Club —
trois langues, deux thèmes, quatre écrans — rendent `ÉCART MAXIMAL=0,000` et `PIXELS=0` entre
l'avant et l'après de la première extraction. C'est ce pour quoi `comparer.py` a été écrit avant
d'y toucher.

**Une feuille ne se présente que si la vue qui la porte est à l'écran, et deux ne l'étaient
pas.** Relevé pour chacune des douze feuilles de `ClubView` : la vue qui la PORTE, et celle qui
la DÉCLENCHE. « Modifier ce message » est sur le mur et sa feuille était sur l'Aperçu — les
onglets s'excluent, donc le bouton ne faisait RIEN, et la feuille surgissait plus tard sans
qu'on l'ait demandée. « Proposer une sortie » sur la carte qui propose de RÉVEILLER le club
avait le même défaut : `if clubEnSommeil { carteClubAReveiller } else { eventsCard }`, et la
feuille était sur la seconde. Sur un club endormi — le cas même où cette carte existe — le
bouton ne faisait rien. Les deux remontent au corps ; les dix autres étaient chez elles.

L'audit a ensuite été passé sur LES 111 FICHIERS DE VUES de l'app, pas seulement sur le
Club : cinq feuilles sont portées par une vue autre que celle qui les déclenche, et trois sont
des faux positifs — le déclencheur est dans la même branche, l'heuristique ne sait pas le voir.
Les deux du Club étaient les seules vraies. **Ce n'est pas devenu un contrôle** : trois faux
positifs sur cinq feraient un garde-fou qu'on contourne, et savoir si deux vues sont dans la
même branche demande l'arbre d'affichage, que rien ne lit sans exécuter l'app.

**Le chantier 13 s'est arrêté sur une mesure, pas sur une longueur.** Pour chacune des trois
régions qui restaient dans `ClubView`, j'ai compté ce qu'elle citerait de l'extérieur si on la
sortait :

| région | lignes | ports | lignes par port |
| --- | ---: | ---: | ---: |
| les sorties de groupe | 228 | 4 | 57 |
| le mur | 273 | 11 | 25 |
| l'entrée du club | 120 | 8 | 15 |

Les sorties sont parties. Les deux autres non : leurs actions — signaler, bloquer, commenter,
modifier, supprimer — sont PRÉSENTÉES par le parent, donc chaque bouton devient un port. Les
sortir échangerait de la longueur de fichier contre de la surface d'interface, ce qui n'est pas
un gain. `ClubView` reste donc le plus gros fichier de vues de l'app, 1 358 contre 1 172 pour
`HomeView`, et c'est assumé.

## Les chantiers de l'audit

Dans l'ordre d'exécution. « Effort » est l'estimation d'origine.

| # | Chantier | Effort | État |
| --- | --- | --- | --- |
| 1 | Cycle : ovulation mal placée, phase du jour appliquée à la semaine, messages qui affirment | 1 j | **fait** |
| 2 | Activité en direct : dire pourquoi elle ne démarre pas | 2 h | **fait** |
| 3 | `@MainActor` sur `LocationService` et `RunWeatherService` | 3 h | **fait** |
| 4 | Finitions design : 2 émojis dans l'interface, 2 dégradés, vert isolé du profil d'élévation, boutons gris en capitales, segment blanc sur blanc, contraste de la bulle du coach | 1 j | **fait** |
| 5 | Données de démonstration : FC 148 seize fois, « Sortie » seize fois, défi « octobre » affiché en novembre | 4 h | **fait** |
| 6 | Bilan de la semaine — l'écran noté 5,5/10 | 1,5 j | **fait** |
| 7 | États manquants : chargement de Stats et du Coach, erreurs d'inscription | 1 j | **fait** — l'item était faux |
| 8 | Harnais de captures : photographier l'inscription, le paywall, l'écran de course | 0,5 j | **fait** |
| 9 | Tests : `SubscriptionService` et `LocationService` d'abord | 2 j | **fait** |
| 10 | Valeurs en dur → jetons du design system, les 15 % restants | 1,5 j | **fait** — il en restait six, pas 15 % |
| 11 | Dépendances serveur : `jose` 6 et `bcryptjs` 3 | 0,5 j | **fait** — après une panne de onze minutes, une reproduction sur aperçu et un correctif éprouvé |
| 12 | Accessibilité : tailles de texte dynamiques, indices VoiceOver | 1,5 j | **fait** — sept écrans photographiés au deuxième cran, treize défauts vus et corrigés ; le reste mesuré et fermé, voir plus bas |
| 13 | `ClubView.swift`, 2 721 lignes, à découper | 2 j | **fait** — 2 721 → 1 358 lignes, en six fichiers ; zéro pixel d'écart |
| 14 | Rapport de plantage maison, posté sur notre serveur | 1,5 j | **fait** — par MetricKit, sans aucun gestionnaire de signal ; voir plus bas pourquoi |
| 15 | Les erreurs qu'on avale : audit des 275 `try?` et `catch` | 1 j | **fait** — un défaut qui perdait des courses, et du code mort qu'un test tenait en vie |

Le 14 est arrivé après coup, et il est passé devant les finitions de design : c'est le seul moyen
de savoir ce qui casse chez quelqu'un d'autre que nous. Le reste de l'ordre tient.

## La page publique d'un club, regardée pour la première fois

`public/club.html` est la seule surface de Haizo qu'un inconnu voit **avant** d'avoir l'app :
c'est le lien qu'un crew met dans sa bio. Les vingt-cinq écrans de l'app sont photographiés à
chaque commit, dans trois langues et deux thèmes. Celle-ci, jamais.

### Ce qu'on voyait en l'ouvrant

1. **Le bouton ne menait nulle part.** « Rejoindre sur Haizo » pointait sur `location.href`,
   c'est-à-dire sur la page elle-même. Sur un iPhone où l'app est installée, iOS ouvre le lien
   dans l'app AVANT que la page ne s'affiche — personne de ce côté-là ne voyait jamais ce bouton.
   Pour tous les autres, c'est-à-dire exactement le public de cette page, il rechargeait la page.
   Il mène à l'App Store (`id6790719663`, relevé par `itunes.apple.com/lookup` sur l'identifiant
   de l'app, pas recopié de mémoire).
2. **L'état d'erreur était un cul-de-sac** : une phrase grise sur fond noir, sans marque, sans
   issue. Un lien mort dans une bio tombait sur une page qui n'appartenait visiblement à rien.
3. **Tout était en français**, alors que l'app est livrée en trois langues. Les textes suivent
   maintenant le navigateur et reprennent mot pour mot ceux du catalogue de l'app : « %lld au
   départ » → « %lld going » / « %lld en la salida », « CHAQUE SEMAINE » → « EVERY WEEK » /
   « CADA SEMANA ».

La marque de l'app est maintenant en tête de page, dans les deux états — les quatre barres de
`AppMarkView`, mêmes coordonnées, mêmes graisses, mêmes opacités, recopiées en SVG depuis le
code et non à l'œil.

### Et l'échappement ne couvrait pas les attributs

`echappe` passait par `textContent` → `innerHTML`, qui n'échappe que `&`, `<` et `>`. Dans le
contenu d'un élément, c'est suffisant. Dans un **attribut** — le `src` de la couverture — une
valeur contenant un guillemet droit sort de l'attribut et en ouvre un autre : `onerror`, par
exemple. Rien n'était exploitable aujourd'hui (le serveur n'écrit dans `cover_url` que des URL de
stockage qu'il fabrique lui-même), et il suffisait d'une route acceptant une URL fournie par le
client pour que ça le devienne. Les guillemets sont échappés.

### Et deux autres, trouvés en regardant les images que la barrière venait de produire

**Une couverture qui ne charge pas laissait un cadre cassé** de 240 points — icône d'image
absente comprise — qui poussait le nom du club sous la ligne de flottaison. Vu sur la capture du
cas piégé, dont l'URL est volontairement morte. La page se passe très bien de couverture (c'est
le cas de tout club qui n'en a pas posé) : l'image se retire d'elle-même si elle échoue.

**Un club sans séance ne disait rien du tout.** Aucun titre, aucune phrase : un club qui n'a rien
annoncé et un club dont on cacherait les séances rendaient exactement la même page. Quelqu'un qui
décide s'il vient a besoin de la différence. « Aucune séance annoncée pour l'instant. », dans les
trois langues.

### Ce qui l'empêche de recommencer

`.github/workflows/page-club.yml` : huit cas — trois langues, l'état normal, l'état
« introuvable », un club d'une seule personne, une couverture morte et une couverture piégée — photographiés sur une
machine Linux en une minute. Il refuse une erreur JavaScript, une page sans bouton, un bouton qui
ne mène pas à l'App Store, et un échappement qui laisse une valeur sortir de son attribut.
Éprouvé dans les deux sens : sur la page corrigée il passe, sur une copie dont on a retiré
l'échappement des guillemets il échoue en nommant les deux symptômes.

Le reste ne se juge pas tout seul : les huit images partent dans l'artefact, et quelqu'un les
ouvre.

## La démonstration parlait français sur la fiche espagnole

Vu sur la capture n° 4 de la fiche App Store espagnole : sous un écran entièrement en espagnol —
« El Club », « Resumen · Clasificación · Actividad », « 18 miembros », « hace 3 h » — la
description du club s'affiche en français, en toutes lettres et sur trois lignes.

Le mécanisme existait déjà et était documenté : `echange()` et `commentaire()` choisissent la
langue à la main, avec la bonne raison — « c'est du texte libre, que rien dans l'app ne sait
retraduire ». Le reste du fil se refabrique à partir de `contentKey` (« a couru 6,0 km ·
Fractionné » devient « ran 6.0 km · VO2max intervals » tout seul), et c'est précisément ce qui
donnait l'impression que tout était traduit.

**Onze autres phrases ne passaient par rien** : la description du club, la bio de Charlotte, les
deux titres de séance hebdomadaire, les deux groupes d'allure de la séance de piste, les trois
annonces du mur et les trois messages de la page de course. Toutes passent maintenant par un
passeur unique, `libre(_:en:es:)`, plutôt que par onze `switch` recopiés.

Les noms propres n'y passent pas : « Les Foulées du Canal », « Bassin de la Villette », « Stade
Jules-Ladoumègue » et les prénoms restent ce qu'ils sont — un club parisien reste un club
parisien, et c'est une décision, pas un oubli.

Et les deux titres de séance sont désormais nommés **une seule fois** : ils paraissent aux
séances à venir ET à l'historique du club, qui rejoue les mêmes rendez-vous. Deux copies
auraient fini par diverger, et le club aurait annoncé une sortie qu'il n'a jamais tenue.

## Chantier 47 — un test qui affirmait sur une traduction

Le cas `testLaDechargeDitLaRegleDuMoteur` du chantier 45 vérifiait que la phrase contient
« quatre », pour garder la règle « une semaine sur quatre ». **La machine d'intégration lance les
tests en anglais.** Elle a reçu « one week in four », et le cas est tombé — à juste titre : il
n'éprouvait pas le moteur, il éprouvait la langue du simulateur.

Ce qui se vérifie sans dépendre d'une langue, c'est le **nombre** : il est le même dans les trois.
Que la phrase dise quelque chose de spécifique au bloc est tenu par
`testLesQuatreBlocsDisentQuatreChosesDifferentes` ; qu'elle dépende du plan, par
`testLaPhraseChangeAvecLaSemaine`. La formulation se relit, elle ne s'assert pas.

C'est le premier test du dépôt à avoir affirmé sur une traduction, et le défaut est doublement
instructif : l'app a passé des mois à parler français à tout le monde, et j'ai écrit un test qui
supposait que tout le monde lit le français.

### Et deux échecs qui n'étaient pas des défauts

**Les captures ont échoué sur `Failed to CreateArtifact`** — le service d'artefacts de GitHub a
répondu du HTML au lieu du JSON, cinq tentatives. Les captures avaient été prises et tous les
contrôles étaient passés ; seul l'envoi a cédé. Rien à corriger.

**Et la montre, elle, est verte du premier coup** : « Executed 3 tests, with 0 failures ». La
cible watchOS fonctionne, l'app se lance, et les assertions anglaise et espagnole passent.

## Chantier 46 — la montre est enfin pilotée, pas seulement photographiée (C2)

### Ce qui manquait

Aucune cible de test d'interface watchOS. La chaîne sait **photographier** la montre depuis le
chantier 33 — on construit, on installe, `simctl io screenshot`. Photographier n'est pas piloter :
une image dit à quoi l'écran ressemble, pas qu'on peut s'en servir.

La montre était donc la seule partie du produit qu'aucun test ne touchait. Et c'est celle qui
vient de passer des mois à parler français à tout le monde.

### Ce qui a été cherché avant d'écrire

La règle 8 s'applique en plein : je ne savais pas si XCUITest existe sur watchOS. Réponse :
**oui, depuis Xcode 12.5, et partiellement.** Pas d'enregistrement, et des retours publics
décrivent des éléments qui n'entrent dans l'arbre d'accessibilité qu'après un défilement.

Un piège, confirmé par un dépôt qui a fait la même chose en XcodeGen : **le schéma de test ne doit
pas lister l'app de la montre comme cible de build** — « doing so stopped Xcode auto-creating the
scheme the build command needs ». La dépendance déclarée sur la cible suffit à la faire
construire. `MontreTests` ne liste donc que la cible de test.

Et un avertissement qui ne nous concerne pas, vérifié plutôt que supposé : une construction non
signée ferait planter une **extension de widget** de montre au premier lancement. Notre
`HaizoWatch` n'en a pas.

### Les trois cas, et pourquoi ceux-là

- **L'écran s'ouvre et porte son bouton.** Le test de fumée : jusqu'ici, rien ne prouvait que
  l'app de poignet démarre.
- **Lancée en anglais, elle affiche « Today » et PAS « Aujourd'hui ».** C'est le défaut qui a
  vécu des mois — la cible ne portait pas le catalogue de traductions. Corrigé au chantier 18, et
  gardé jusqu'ici par rien d'autre qu'une relecture : **les captures de montre ne sont prises
  qu'en français**, donc aucune image ne pouvait le revoir.
- **Et en espagnol**, parce que deux langues qui s'accordent ne font pas trois — c'est la leçon
  de `comparer.py`, et elle vaut ici.

L'étape passe **avant** les captures dans `montre.yml` : une app qui ne démarre pas doit échouer
en deux minutes, pas après la séance photo.

### Ce que ce premier test ne fait pas

Il ne lance pas de séance. `workout.start()` ouvre une session HealthKit et la construction des
tests n'est pas signée ; piloter un démarrage de course demandera de traiter ce cas, et ce n'est
pas la première chose à écrire. Les délais sont à vingt secondes : un premier lancement sur un
simulateur watchOS neuf est lent, et un échec par impatience ressemble exactement à un échec par
défaut.

## Chantier 45 — dire pourquoi cette séance, aujourd'hui (C1)

### Ce qui existait, et ce qui manquait

L'app disait déjà pourquoi une séance avait été **allégée** : `adjustment` porte « Allégée · nuit
courte », `adaptationNote` porte « adapté à ta cheville sensible · impact réduit ». La carte
d'accueil les affiche en une ligne sous le titre, et son commentaire dit la bonne chose : « voici
la séance, voici pourquoi elle est ce qu'elle est ».

Mais ces lignes n'existent **que les jours où le moteur corrige**. Les autres — la grande
majorité — la carte affiche une séance et se tait sur la raison. Or le moteur en a une : il sait
dans quel bloc on est, qu'une semaine sur quatre est allégée, combien de semaines restent, et à
quelle distance est la course.

### La condition de l'item, et ce qui s'y conforme

`PHASE2.md` la pose en toutes lettres : « à condition que la phrase vienne du moteur et pas d'un
catalogue de phrases. Sinon c'est un texte générique, donc un défaut. »

Une phrase par bloc serait exactement ce catalogue. Ce qui l'en sépare : **chaque phrase porte un
nombre de CE plan.**

| bloc | ce que la phrase dit | d'où vient le nombre |
| --- | --- | --- |
| décharge | « Semaine 8 : une semaine sur quatre est allégée, pour que les trois suivantes tiennent. » | la règle est `week % 4 == 0` dans `trainingBlock` |
| affûtage | « Affûtage, J-12 : le volume baisse, l'intensité reste. C'est la fatigue qu'on enlève, pas la forme. » | la vraie date de course |
| spécifique | « Semaine 9 sur 14, bloc spécifique : les séances ressemblent de plus en plus à ta course. » | `weekNumber` et `shape.totalWeeks` |
| base | « Semaine 2 sur 14, bloc de base : on construit le volume avant de le spécialiser. » | les mêmes |

Deux coureuses dans le même bloc ne lisent pas la même phrase, parce qu'elles ne sont pas à la
même semaine. **Et là où le moteur n'a rien de chiffré à dire, la fonction rend `nil` et l'écran
se tait** — un programme ouvert (« rester en forme ») n'a pas de total de semaines, donc la
phrase de bloc deviendrait « on construit le volume », c'est-à-dire le texte générique interdit.

### Ce qu'elle ne fait jamais

**Parler par-dessus une correction.** Si le moteur a allégé la séance, c'est ça la raison du
jour : elle est plus précise que n'importe quelle phrase de bloc. La nouvelle ligne est en `else
if`, jamais en plus. Deux explications empilées sur la même carte, c'est une de trop.

Et rien un jour de repos : la carte affiche « REPOS » et porte déjà sa ligne.

### Ce qui le prouve

`PourquoiCetteSeanceTests`, **9 cas**. Un banc qui vérifierait seulement « il y a une phrase »
laisserait passer le catalogue ; ceux-ci vérifient l'inverse :

- **la phrase change avec la semaine** — si cette assertion tombe, c'est qu'une phrase a perdu son
  nombre et s'est mise à décrire le bloc au lieu du plan ;
- les quatre blocs disent quatre choses différentes ;
- une séance déjà expliquée n'en reçoit pas une deuxième, dans les quatre blocs ;
- sans total de semaines, et sans date de course, les blocs concernés se taisent.

### Et les trois langues

`check_strings.py` a refusé la première version : quatre chaînes affichées absentes du catalogue,
« chacune sortira EN FRANÇAIS en anglais et en espagnol ». Puis la deuxième : deux clés portaient
des marqueurs positionnels (`%1$lld`), et **une clé est calculée à l'exécution depuis la phrase
interpolée — elle ne porte jamais de position**. Une clé positionnelle n'est jamais trouvée, donc
l'app aurait affiché la clé, c'est-à-dire le français, à tout le monde. La traduction, elle, a le
droit d'en porter.

## Chantier 44 — la version 3.4, et l'élagage qui ne s'est pas fait tout seul

### Ce qui était attendu, et ce qui s'est passé

La note disait : « créer la version 3.4, la capture iPad s'élaguera d'elle-même ». C'était vrai
d'une seule façon de créer la version — le bouton `creer-la-version`, qui appelle
`asc.py create-version` et élague d'office les formats de `FORMATS_SANS_RAISON`.

La version a été créée depuis le site d'App Store Connect. Apple y recopie les captures de la
version précédente, **tous formats confondus**, et aucun élagage n'a eu lieu. L'inventaire de la
3.4 le disait noir sur blanc :

```
fr-FR · APP_IPAD_PRO_3GEN_129 · 1 image(s)
    1-accueil.png
```

Une image d'iPad fabriquée à partir d'une mise en page iPhone étirée, sur une app dont
`TARGETED_DEVICE_FAMILY` vaut 1, et que Charlotte avait décidé de retirer le 10 novembre.

### Ce qui a été fait

`nettoyer-les-captures`, format `APP_IPAD_PRO_3GEN_129`, après un essai à blanc qui a confirmé la
portée : **une seule image, et la capture Apple Watch pas touchée** — celle-là, Apple l'exige dès
que la build embarque une app watchOS, et une première version de l'élagage l'avait emportée.

Inventaire après : trois langues × six captures iPhone, plus la capture de la montre. Plus d'iPad.

### Ce que la note aurait dû dire

« La capture iPad s'élaguera d'elle-même **si la version est créée par le bouton**. » Une
instruction qui ne dit pas de quoi elle dépend n'est pas une instruction, c'est un pari — et ici
le pari se perdait en silence, parce que rien dans App Store Connect ne signale qu'une image
recopiée n'avait rien à faire là.

### Ce que le contrôle de soumission a trouvé au passage

`pourquoi-pas-soumettable` sur la 3.4, après l'élagage :

- état PREPARE_FOR_SUBMISSION, informations de vérification présentes, abonnement APPROVED ;
- six captures et un aperçu vidéo par langue, description présente ;
- **« nouveautés NON » dans les trois langues.**

Les notes de version existent dans `APP_STORE_LISTING.md` mais n'ont jamais été poussées vers la
3.4. Et surtout : leur dernière modification est le commit du 1er novembre, « Les nouveautés de la
3.3 parlent enfin de ce que la 3.3 contient ». **Ce sont les notes de la 3.3.** Les pousser telles
quelles afficherait aux gens, sous une mise à jour 3.4, la liste de ce qu'ils ont déjà reçu.

C'est le seul point qui reste entre la 3.4 et une soumission, et il demande un texte, pas une
commande.

### Suite, le même jour

Les notes ont été écrites dans les trois langues, poussées, et Apple les a reçues — `fr-FR mis à
jour, en-US mis à jour, es-ES mis à jour`, puis vérifié côté Apple plutôt que sur le message de
l'outil qui venait de les envoyer : « description oui, **nouveautés oui** » dans les trois langues.

`pourquoi-pas-soumettable` ne rend donc plus qu'une ligne :

```
CE QUI MANQUE :
  - aucune build n'est attachée
```

La fiche est complète. Ce qui manque est une build en 3.4, c'est-à-dire un passage de la chaîne
TestFlight — pas un texte.

### Un détail vu en passant, et qui répond à une question ouverte

Le `supportUrl` envoyé à Apple est `https://hicsuntco.github.io/Haizo/privacy.html`. Autrement
dit, le lien « Assistance » de la fiche App Store ouvre la politique de confidentialité. La
question « que faire de `support.html`, que personne ne peut atteindre » traînait depuis le
8 novembre : la réponse est qu'elle n'est pas seulement inatteignable, elle est **remplacée par la
mauvaise page** à l'endroit même où Apple la propose.

## Chantier 43 — Apple recevait un tracé à moitié dessiné, et c'était au hasard

### D'abord, ce que la comparaison a prouvé

Campagne 166 contre 165, **même jour**, 181 images : **169 identiques**. `fil` — l'écran que le
mur dessine — est identique dans les trois langues et les deux thèmes, comme les trois autres
écrans du Club. La découpe du chantier 42 n'a rien changé.

Huit des douze écarts sont `course-en-cours`, l'horloge. Restaient `4-club.png` en espagnol
(10 077 pixels) et en français (5 pixels), et une boîte de 24 pixels sur `grand-texte/accueil`.

### Ce que l'image montrait

Le tracé de la sortie, en bas de la carte. Dans la campagne 165 la ligne se termine net. Dans la
166, **une tête blanche lumineuse est posée au milieu du dernier segment, et la ligne s'arrête
avant sa fin**.

`SelfDrawingRoute` dessine le parcours en 1,45 s à l'apparition. La campagne 166 a pris la photo
pendant. La 165, six heures plus tôt, l'avait eu fini.

**`4-club.png` est une des six images livrées à Apple.** Ce n'est donc pas un défaut de
comparaison : c'est le minutage qui décidait de ce qu'Apple reçoit, et il pouvait tout aussi bien
tomber à 60 % du tracé.

### La règle, et pourquoi elle est posée là

**Une photo montre un écran posé. Un film garde son mouvement.** Les deux tournent dans le même
mode démonstration, et c'est pour ça que le défaut a vécu : « pas d'animation en démonstration »
aurait aplati le film d'aperçu, dont c'est tout l'intérêt.

La distinction tient à un argument de lancement, `--film`, posé par `ApercuUITests` et par lui
seul. **Le drapeau est sur le film, pas sur les photos**, et le sens compte : oublier de déclarer
un film donne un film sans mouvement, ça se voit en le regardant ; oublier de déclarer une photo
ramène le non-déterminisme EN SILENCE. C'est le sens où l'erreur se voit.

### Figer en un seul endroit

Une `transaction` à la racine des vues, qui vide l'animation de tout ce qui passe en dessous.

C'était le choix contre lequel il fallait se décider : corriger `SelfDrawingRoute` seul aurait
réglé le cas observé et laissé les autres. Mesuré : l'app compte **22 appels à `RUMotion`** et
**une cinquantaine d'animations écrites à la main** dans les vues — dont l'apparition en cascade
du fil et le ressort des anneaux de l'accueil, tous deux sur des écrans photographiés. Les
corriger une par une aurait laissé la cinquante et unième dehors sans que rien ne le dise.

### Ce qui le garde

`check_film.py` et ses **7 cas** vérifient les cinq faits lisibles dans le code : le film se
déclare, les photos ne se déclarent pas, l'app allume le mode film, la règle dit bien « en
démonstration ET pas en train de filmer », et la racine applique une `transaction`.

**Sa première version ne voyait rien.** Elle cherchait `--film` dans le fichier entier — or le
commentaire qui explique le drapeau contient le drapeau, et celui qui explique la `transaction`
contient `animationsFigees`. Retirer le vrai code laissait le contrôle vert : il relisait sa
propre explication. Deux cas du banc tiennent cette correction, et c'est exactement le piège que
`check_vides` avait rencontré en novembre.

### Ce qui le prouve

**Campagne 167, à 13 h 55, contre la 166 à 12 h 43 — même jour.** 171 images sur 181 identiques.
Neuf des dix écarts sont `course-en-cours`, le chronomètre d'une course en cours.

Le dixième est `4-club.png` en espagnol, et c'est le verdict : il est **identique à celui de la
campagne 165**, celle qui avait eu le tracé fini. Autrement dit, 167 est revenue à l'état posé, et
c'est bien la 166 qui était l'exception.

Sur les six variantes de `4-club.png`, cinq sont identiques au pixel entre 165 et 167. La sixième
diffère de **13 sur 255 au maximum, sur cinq pixels** — de l'anticrénelage sur le bout arrondi du
trait, sous le seuil de bruit de l'outil et invisible à l'œil.

**Et le film garde son mouvement** — vérifié plutôt que supposé, parce que « Filmer l'aperçu »
réussit même si le film ne bouge pas : aucune étape ne juge son contenu. Mesuré en extrayant les
images à 10 par seconde et en comparant chaque image à la précédente :

| | images qui bougent | écart moyen entre deux images |
| --- | --- | --- |
| campagne 166, avant | 16 % | 1,10 |
| campagne 167, après | **27 %** | **1,75** |

Plus de mouvement qu'avant, pas moins. Le drapeau est du bon côté.

### Ce qu'aucun script ne saura dire

Si l'image est effectivement posée. Aucun contrôle ne lit une animation. La preuve reste la
comparaison de deux campagnes prises à des heures différentes — ce qui est précisément comment
ce défaut a été trouvé, et pourquoi le chantier 40 valait la peine.

## Chantier 42 — le mur, et les onze fils qu'il fallait ne pas confondre (B5, dernier morceau)

### Pourquoi celui-ci n'était pas un déplacement

Les quatre cartes sorties avant lui demandaient zéro ou un état : c'est ce qui les rendait sûres,
et c'est pour ça qu'elles sont passées en premier. Le mur en touchait **onze sur les dix-huit** de
`ClubView`.

Onze n'est pas un signe de complexité, c'est un signe que **personne ne les possédait**. Ils
traînaient à plat dans la grande vue, et sortir le mur tel quel aurait voulu dire passer onze fils
à la main — chacun une occasion de brancher le mauvais, sans que rien ne le dise, dans un
remaniement qui ne doit RIEN changer.

### Ce qui a été fait

**`MurDuClub`** porte les huit qui sont vraiment du mur : le brouillon, l'envoi en cours, la
réponse en cours, les quatre feuilles qu'il ouvre et le drapeau de révélation du fil.

**Les deux autres restent dehors, et ce n'est pas un oubli.** `reportTarget` et `pendingBlock`
sont posés aussi par le classement et par la page du club ; les ranger dans le mur aurait fabriqué
un propriétaire faux. Ils passent en liaison, comme ils le faisaient déjà vers `ClubBoardSection`.
Deux liaisons au lieu de onze, et les deux qui restent sont celles qui le méritent.

**`ClubWallView`** prend le magasin, le mur et ces deux liaisons.

`ClubView` : **979 → 707 lignes**, 11 états au lieu de 18. Depuis le début de B5 : **1 425 → 707**.

### Le vrai gain : trois règles qui n'étaient vérifiables nulle part

Elles vivaient en propriétés privées d'une vue de 1 400 lignes, donc vérifiables seulement en
ouvrant l'écran avec les bonnes données — un message, sa réponse, une sortie du même jour —
c'est-à-dire jamais. Chacune porte une décision qui n'était écrite nulle part :

- **une réponse n'entre pas dans le fil**, elle s'affiche sous son message. C'est la moins visible
  des trois, et sa disparition ne casse rien : le fil se remplit simplement de répliques qui n'ont
  plus de question au-dessus d'elles ;
- **les sorties et les messages s'entrelacent par date**, ils ne s'empilent pas en deux listes. Un
  mur posé au-dessus des sorties se lit comme une annonce épinglée ;
- **les réponses se lisent dans l'ordre inverse du fil** — du plus ancien au plus récent. Un fil
  se lit du plus récent parce qu'on vient voir les nouvelles ; une conversation se lit dans
  l'ordre où elle s'est tenue. Deux tris opposés sur le même écran est exactement le genre
  d'écart qu'on « corrige » en croyant bien faire.

Et `peutPublier`, où `isEmpty` seul laisserait passer trois retours à la ligne.

`MurDuClubTests`, **11 cas**, avec des données **décodées depuis du JSON** plutôt que construites
à la main : `ClubPost` et `FeedItem` viennent du serveur, et une fixture écrite avec un `init`
mémberwise cesserait de ressembler à ce que l'app reçoit.

### Une troisième copie évitée de justesse

`seuleDansSonClub` était lue par le fil ET par l'Aperçu. Le chantier 37 avait déjà nommé cette
règle une fois après l'avoir trouvée écrite deux fois mot pour mot. En sortant le mur, le fil en
avait besoin dans un autre fichier : la recopier aurait refait exactement le défaut qu'on venait
de corriger. Elle descend donc sur `ClubStore` — c'est un fait sur le club, pas sur un écran.

### Le piège que le fichier portait déjà écrit

`MurDuClub` est `@MainActor`, et `ClubView.init` l'est explicitement avec sa raison en commentaire :
« construire un objet isolé au fil principal depuis un contexte qui ne l'est pas est une ERREUR DE
COMPILATION, pas un avertissement — et il n'y a pas de compilateur Swift ici pour la voir ». Le mur
est donc construit dans l'`init` comme le magasin, et non en valeur par défaut qui dépendrait de ce
que le compilateur déduit.

### Deux défauts de ma propre extraction, attrapés en relisant

Le renommage automatique en a produit deux que la chaîne ne pouvait pas voir :

- `if let reponseA = mur.reponseA { … Text(mur.reponseA.author…) }` — la variable déballée était
  redevenue optionnelle à l'intérieur de son propre bloc ;
- `reponses(a: message)` n'a pas été remplacé, parce que mon motif terminait par `\b` après une
  parenthèse fermante, où il ne peut pas s'accrocher.

Les deux sont des erreurs de compilation, donc sans danger pour la production — mais à quarante
minutes de machine d'ici. C'est la relecture du fichier produit qui les a trouvées, pas la chaîne.

## Chantier 41 — une bannière d'iOS ne coûte plus une heure

### Ce qui était faux

iOS pose parfois une notification en travers d'une capture. Deux fois en trois jours : le
8 novembre sur `1-accueil.png` — une des six images livrées à Apple — et le 10 sur
`club-classement.png`, 60,1 % de pixels clairs en haut pour un plafond à 25.

`check_banniere.py` l'attrape, et c'est l'essentiel : rien de fautif ne part chez Apple. Mais il
l'attrape **à la fin de la chaîne**, après les deux passes de prise de vue, la composition et les
contrôles d'image. La campagne échoue donc au bout d'une heure, et la relancer en coûte une autre.

### Ce qui a changé

La passe sombre se relit **langue par langue, juste après l'avoir prise**, et se reprend une fois
si une bannière est tombée dessus. Une langue à refaire, c'est deux ou trois minutes, et ça reste
dans la même exécution.

**Une seule reprise, volontairement.** Une bannière est une affaire de minutage ; si la seconde
prise la revoit, ce n'est plus le minutage, et le contrôle de fin doit échouer pour qu'on aille
regarder l'image. Deux essais qui échouent valent un signal, dix valent une boucle qui cache un
défaut.

L'environnement Python remonte avant les captures — il vivait dans « Composer les images
finales », c'est-à-dire après la prise de vue, et le contrôle qui se relit a besoin de Pillow.

### Ce qui n'est pas repris, et c'est écrit sur place

**La passe claire.** Le contrôle ne sait pas la lire : une bande claire sur un écran clair ne dit
rien, et il le déclare lui-même — « seules les captures SOMBRES sont regardées ». Reprendre une
passe qu'on ne sait pas juger serait un geste sans mesure derrière.

### Ce qui le prouve

La logique de reprise a été éprouvée ici, sur les **vrais dossiers** des campagnes 161 (celle qui
portait la bannière) et 163 (propre) :

| première prise | reprise | résultat |
| --- | --- | --- |
| propre | — | vert, **aucune** reprise |
| bannière | propre | vert, **une** reprise |
| bannière | bannière | **rouge**, une seule reprise |

Le troisième cas est celui qui compte : la boucle ne s'acharne pas, et l'échec reste visible.

### Ce qui n'a pas été fait, faute de source

Empêcher le simulateur de poser des bannières. Je n'ai trouvé aucune clé documentée pour ça, et
une recette inventée qui marche par hasard est pire qu'une reprise explicite.

## Chantier 40 — la capture héritait de l'heure de la machine

### D'abord, ce que la comparaison a prouvé

Campagne 162 contre campagne 160, 181 images. **Les quatre écrans du Club sont identiques au
pixel** — `club-apercu`, `club-apercu-bas`, `club-classement`, `fil`. Les trois découpes des
chantiers 36, 37 et 38 n'ont rien changé, et c'est prouvé par l'image.

### Et ce qu'elle a trouvé en passant

Vingt-six images diffèrent. `course-en-cours` est l'horloge, connue. Mais **`profil`,
`profil-bas` et `grand-texte/profil` diffèrent dans les trois langues et les deux thèmes** — neuf
images, systématiquement. Aucune de mes découpes ne touche cet écran.

En regardant les deux images : **« Badges · 6 sur 16 » est devenu « 7 sur 16 »**, « Course de
nuit » est allumé, et tous les badges suivants sont décalés d'une case. Et la carte des amies est
passée de « 2 sorties aujourd'hui » à « 3 ».

### La cause, vérifiée et non supposée

`ClubBadgeEngine` lit l'heure de chaque sortie : `heure < 7` donne « Lève-tôt », `heure >= 21`
donne « Course de nuit ». Or `CaptureSeed.historique` plantait chaque sortie à
`maintenant - N jours` — donc **à l'heure où la machine tourne**.

La campagne 160 a tourné à 18 h UTC, la 162 à 22 h. Le même code rend donc six badges ou sept
selon l'heure de la journée.

Deuxième manifestation, sur la même image : les trois activités d'amies sont posées 3 h, 9 h et
22 h en arrière, et `ProfileView` compte celles du jour. « Il y a 22 h » est HIER à 6 h du matin
et AUJOURD'HUI à 23 h.

**Et celle-là, `comparer.py` ne l'a pas vue.** Je l'ai vue à l'œil en ouvrant les deux images, et
j'ai d'abord cru qu'elle faisait partie de l'écart mesuré : c'est faux. La carte « Amis » vit dans
les 186 px du haut, que l'outil masque pour ignorer l'heure — iOS dessine l'heure par-dessus
l'app, et sur une capture prise au milieu d'un défilement cette bande porte du contenu. Un « = »
de cet outil veut donc dire « identique sous les 186 premiers pixels ». La limite est maintenant
écrite dans son en-tête.

**Et `4-club.png` est une des six images livrées à Apple.** Selon l'heure de la campagne, Apple
recevait un profil avec le badge « Course de nuit » ou sans.

### La troisième fois, dans le fichier qui porte déjà la leçon

`CaptureSeed.swift` contient, depuis un chantier précédent, cette phrase sur les sorties de
groupe : « un décalage en heures depuis l'instant de la capture donne “DEMAIN · 13:01” ou
“VEN. · 06:01” selon le moment où la machine a pris la photo ». La correction y est : l'heure est
posée, le jour calculé.

`CaptureSeedHeureTests.swift` porte la même leçon pour la conversation du coach, avec son
en-tête : « deux exécutions comparées, à 01 h 18 et 04 h 37, s'accordaient ; une troisième à
07 h 00 ne s'accordait plus ».

L'historique des sorties et les activités d'amies ne l'avaient pas. Trois cas frères, deux
corrigés, un oublié — le motif est exactement celui des chantiers 30 et 31.

### Ce qui a changé

- **L'heure de chaque sortie est posée**, et le jour continue de suivre la campagne : sortie
  longue à 9 h, fractionné à 19 h comme une séance de club, le reste à 8 h ou 18 h. Toutes dans
  `7..<21`, donc aucun des deux badges horaires ne s'allume par accident. La minute vient du rang,
  pas de l'horloge — seize sorties à l'heure pile sentiraient la donnée fabriquée.
- **Les trois activités d'amies sont bornées au jour**, exactement comme la conversation du coach :
  le recul est gardé tant qu'il tient dans la journée, raboté au début du jour sinon. Un recul ne
  peut pas être à la fois stable en affichage relatif et stable en jour ; c'est le jour qui porte
  un nombre à l'écran, donc c'est lui qu'on stabilise.

### Ce qui a été mesuré et ne pose pas de problème

Le JOUR DE LA SEMAINE des sorties dérive toujours avec la date de campagne, et le badge
« Guerrière du week-end » se lit dessus. Compté sur les sept jours possibles, le nombre de sorties
de week-end va de **0 à 6** — et le badge en exige **dix**. Il n'est donc jamais atteint, quelle
que soit la date. Vérifié, pas supposé.

### Ce qui reste instable, et pourquoi on ne le corrige pas

Les horodatages RELATIFS du fil du club — « il y a 3 h » — dépendent de l'heure de la campagne par
construction, et c'est ce qu'on veut : un fil doit dire depuis combien de temps. C'est ce qui fait
différer `4-club.png` dans une petite boîte d'une centaine de pixels. Un texte de largeur
différente n'est pas un défaut ; un badge qui apparaît en était un.

### Ce qui le prouve

La campagne **163 a tourné à 23 h** — plus tard encore que la 162, qui est celle qui avait allumé
le badge. `profil-bas.png` y est **identique à celui de la campagne 160**, qui avait tourné à
18 h, dans les trois langues et les deux thèmes. Deux campagnes de part et d'autre de l'heure qui
faisait basculer le badge rendent la même image.

Et le cas était plus dur qu'il n'y paraît : à 23 h l'ancien code allumait « Course de nuit », et à
00 h il aurait allumé « Lève-tôt ». La campagne 163 a photographié les deux côtés de minuit sans
que rien ne bouge sur cet écran.

**Ce qui ne se compare pas d'une campagne à l'autre quand elles ne tombent pas le même jour.** La
163 a commencé à 23 h 39 et fini après minuit : 73 images diffèrent de la 162, et c'est normal —
le plan, l'accueil et le bilan hebdomadaire parlent d'aujourd'hui. Une comparaison à cheval sur
minuit ne prouve rien sur une découpe. C'est pour ça que la preuve de B5 tient sur 160 → 162,
deux campagnes du même jour.

### Ce qui le garde

Six cas de plus dans `CaptureSeedHeureTests`, qui éprouvent **les vingt-quatre heures** plutôt
que d'attendre que l'heure qui casse tombe toute seule :

- aucune sortie de l'historique ne tombe avant 7 h ni après 21 h, à toute heure de campagne ;
- plus largement, l'heure de la campagne ne change **aucune** heure de l'historique — le cas
  précédent ne tient que les deux bornes, celui-ci tient la reproductibilité ;
- le JOUR, lui, suit toujours la campagne : la sortie la plus récente reste à deux jours ;
- chaque type de séance a une heure plausible — le jour où quelqu'un en ajoutera un, le cas lui
  rappellera que l'heure se décide ;
- les trois activités d'amies tombent aujourd'hui à toute heure ;
- et un recul qui tient dans la journée n'est PAS raboté, sans quoi le fil afficherait trois fois
  la même minute.

## Chantier 39 — une non-réponse était plus optimiste que la réponse la plus prudente

### Ce qui était faux

`PaceModel` portait trois VDOT écrits en dur pour le niveau déclaré : 36,34 / 43,61 / 53,94. Le
chantier 29 les avait laissés intacts exprès, en écrivant pourquoi : « un VDOT de 36 est un 10 km
en 54 minutes, ce qui n'est pas “débutante” mais “court déjà” », et « une constante devinée deux
fois ne vaut pas mieux qu'une fois ». La tâche a attendu une mesure.

La mesure n'était pas celle que j'attendais. Je cherchais ce que courent les gens qui cochent
« débutante » — donnée que personne n'a ici, et qui n'existe pas dans l'app. Ce qui se mesure,
c'est une **incohérence interne**, et elle se vérifie en trois lignes.

Converties à la fraction du footing, les trois constantes supposent des footings de :

| niveau | ce que la constante supposait | 5 km équivalent |
| --- | --- | --- |
| débutante — « je cours depuis moins de 6 mois » | **6:54/km** | 26:08 |
| intermédiaire — « je cours 2-3 fois par semaine » | **5:58/km** | 22:23 |
| confirmée — « je m'entraîne sérieusement depuis des années » | **5:02/km** | 18:40 |

Or l'app pose elle-même la question de l'allure de footing, et sa tranche la plus lente est
**« plus de 7 min/km »**. Donc quelqu'un qui se déclarait débutante et répondait « je ne sais pas »
— une vraie réponse, la première de la liste, prévue pour ça — recevait un plan calé sur
**6:54/km, plus rapide que la tranche la plus prudente qu'on lui proposait de cocher**.

Une non-réponse était plus optimiste que la réponse la plus prudente. Et c'est exactement au
niveau « débutante » que vivent les gens qui courent à plus de 7 min/km.

### Ce qui a changé

Les trois constantes ne sont plus des nombres : chaque niveau désigne **la tranche de footing
qu'elle aurait probablement cochée**, et les deux chemins passent ensuite par le même
`Vdot.depuisAllure(…, fraction: .footing)` sur la même valeur.

| niveau | tranche supposée | 5 km | 10 km | avant |
| --- | --- | --- | --- | --- |
| débutante | 7:30/km | 28:35 | 59:25 | 26:08 / 54:16 |
| intermédiaire | 6:30/km | 24:29 | 50:49 | 22:23 / 46:27 |
| confirmée | 5:30/km | 20:28 | 42:27 | 18:40 / 38:43 |

La quatrième tranche — « moins de 5 min/km » — ne s'atteint **que** si elle la coche. Un libellé
qu'on touche pour se décrire ne doit pas suffire à produire un footing sous les cinq minutes.

**Et il n'y a plus trois nombres à maintenir.** C'était le vrai risque : ce calcul a déjà connu un
aller-retour qui se trompait des deux côtés à la fois et dans des sens opposés — le `/ 1.20` du
chantier 29. Deux chemins pour une question, une seule valeur, un seul appel.

### Ce que ça change pour les gens

Pour tout le monde qui n'a donné ni chrono, ni perf récente, ni allure de footing : **les allures
de son plan ralentissent**, de 8 à 9 % selon le niveau. Personne ne perd son plan, et rien ne
change pour qui a donné un chrono ou une allure — leurs trois chemins passent avant celui-ci.

C'est une décision d'entraînement, et elle se discute : elle suppose que quelqu'un qui ne sait pas
dire son allure n'est pas en train de courir plus vite que la tranche médiane de sa catégorie.
L'inverse est possible pour une minorité, et le plan s'ajuste ensuite sur les sorties réellement
enregistrées. Dans le doute, le sens de l'erreur compte : un plan trop lent se corrige à la
première sortie loguée, un plan trop rapide se corrige à la blessure.

### Ce qui le garde

Cinq cas dans `PointDeDepartTests` :

- **le défaut lui-même** — le niveau débutante ne peut pas être plus rapide que la tranche la plus
  lente de la liste, et il doit viser précisément celle-là ;
- le niveau seul vaut **exactement** la tranche qu'il suppose, à 1 ms près : si l'un des deux
  chemins est retouché sans l'autre, le cas tombe ;
- aucun niveau n'atteint la tranche la plus rapide ;
- les trois niveaux restent ordonnés ;
- aucun niveau ne désigne « je ne sais pas », sans quoi le repli du repli — `Vdot.vdotMin` —
  deviendrait le plan de tout un niveau sans que rien ne le dise.

### Ce que l'image ne prouvera pas

**Les captures ne montreront aucune différence, et c'est normal.** Le profil de démonstration
donne `bestRecentPerf: "10 km en 49:12"` — le PREMIER des quatre chemins — donc il n'atteint
jamais la constante de niveau. Les 28 écrans photographiés sont rigoureusement identiques avant et
après.

Autrement dit : la seule preuve de ce chantier est ses cinq cas de test. Aucune capture ne montre
jamais cet écran-là, parce qu'aucun profil de démonstration ne laisse les trois premières questions
vides. C'est une limite réelle de la campagne de captures, et elle mérite d'être écrite plutôt que
découverte en comparant deux images identiques et en concluant que rien n'a changé.

### Ce qui n'a pas bougé, et pourquoi

Les quatre tranches de footing et leur milieu (7:30, 6:30, 5:30, 4:30). Leur commentaire porte un
raisonnement qui tient et qui va dans l'autre sens que l'intuition : pour une **allure**,
sous-estimer n'est pas prudent — ça donne des footings trop lents que personne ne tient et des
séances de qualité qui n'en sont plus. Le milieu de la tranche déclarée reste la réponse honnête.
Ce chantier ne touche qu'au cas où **rien** n'a été déclaré.

## Chantier 38 — l'écran « tu n'as pas encore de club » (B5, quatrième morceau)

### Ce qui est sorti

`ClubSetupCard` — 118 lignes de code, le magasin et **deux liaisons** : les deux champs de
saisie, `newClubName` et `clubQuery`. Tout le reste passe par le magasin, qui porte déjà
`createClub`, `joinClub`, `clubSearchEnCours`, `clubResultats`, `clubSuggestions` et
`chargerLesClubsSuggeres`. Le magasin faisait déjà le travail ; la vue n'avait qu'à le suivre.

Les deux lignes de résultat descendent avec elle — `ligneDUnClubARejoindre` et
`ligneDuClubTrouve` — parce qu'elles n'ont aucun autre appelant. Leur commentaire dit déjà
pourquoi elles sont uniques : « deux vues presque identiques auraient dérivé à la première
retouche, et l'écart se serait lu comme une différence de nature entre un club trouvé et un club
proposé ».

`ClubView` : **1 113 → 979 lignes.** Depuis le début de B5 : **1 425 → 979**, et six fichiers
nommés par ce qu'ils montrent.

### `signInPrompt` reste

14 lignes, une liaison. Un fichier pour quatorze lignes coûte plus à lire qu'il ne fait gagner :
on ouvre un fichier de plus pour voir un bouton « SE CONNECTER ». Le critère de la découpe n'a
jamais été le nombre de lignes du fichier d'origine, c'est qu'une section ait un nom et un état
propre. Celle-là a un nom et presque pas de corps.

### Une section `// MARK:` devenue vide

`// MARK: Signed in, no club yet` ne précédait plus rien. Un intertitre qui ne titre plus rien ne
casse pas la compilation et ne se voit pas en lisant le code autour : il se voit à la couture,
juste après avoir retiré ce qu'il annonçait. Retiré.

### Ce qui prouve les chantiers 37 et 38

**Une seule campagne de captures pour les deux.** Les deux découpes ont été poussées ensemble,
parce que pousser pendant qu'une campagne tourne l'annule — c'est ce qui a fait perdre le run 159.
La comparaison porte donc sur les deux d'un coup, contre la campagne du chantier 36. Pour une
découpe qui ne doit rien changer, c'est le même verdict : identique au pixel, ou pas.

## Chantier 37 — un seuil écrit deux fois, trouvé en découpant (B5, troisième morceau)

### Le plan était plus grossier que le code, pour la deuxième fois sur ce même fichier

Le chantier 35 annonçait « Rejoindre / réveiller : 231 lignes, 4 états ». Mesuré membre par
membre : **286 lignes et six états**. Et surtout, ce n'est pas un groupe. Les huit membres que
j'avais rangés ensemble font trois choses sans rapport :

| ce que ça fait | membres | états |
| --- | --- | --- |
| trouver ou créer un club quand on n'en a pas | `signInPrompt`, `clubSetupCard`, `ligneDUnClubARejoindre`, `ligneDuClubTrouve` | `clubQuery`, `newClubName`, `showSignIn`, `magasin` |
| réveiller un club endormi | `carteClubAReveiller` | `showCreateEvent`, `showManagement` |
| dire qu'on y est seule | `carteClubSeul` | `magasin` |

`banniere` n'appartenait à aucun des trois : elle est appelée depuis `body`, au-dessus de tout.

### Ce qui est sorti, et pourquoi ces deux-là d'abord

- `ClubAloneCard` — 53 lignes de corps, **zéro liaison**, le magasin seul. Elle était déjà
  appelée **depuis deux onglets** : l'Aperçu et le fil. Son commentaire disait pourquoi on ne
  l'avait pas recopiée — « un lien de partage dupliqué, c'est une des deux copies qui garde
  l'ancienne URL le jour où elle change ». La sortir du fichier ne change rien à ce partage ; ça
  le rend lisible depuis le nom du type.
- `ClubWakeCard` — 40 lignes, **deux liaisons et aucun magasin**. Elle n'affiche aucune donnée du
  club : deux boutons, c'est tout. C'est ce qui la rend bon marché malgré ses deux états.

`ClubView` : **1 193 → 1 113 lignes**, et le quatrième groupe du chantier 35 — « trouver ou créer
un club » — attend son tour.

### Le défaut trouvé en découpant : un seuil écrit deux fois

`magasin.board.club.map({ $0.memberCount <= 1 }) == true` était écrit **mot pour mot à deux
endroits** — une fois dans l'Aperçu, une fois dans le fil — chacun pour choisir entre la carte de
partage et autre chose. Les deux copies étaient à six cents lignes l'une de l'autre.

Ce n'est pas un bug : les deux disent la même chose aujourd'hui. C'est le jour où « seule » cesse
de vouloir dire « un membre » — un club où l'on compte les membres actifs, un invité qui n'a pas
encore accepté — que l'une des deux reste en arrière, et le club annonce deux états différents de
lui-même sur deux onglets. La règle est maintenant nommée une seule fois, `seuleDansSonClub`, à
côté de `clubEnSommeil` qui est de la même nature.

### Un renvoi qui ne survit pas à une découpe

`ClubWakeCard` portait un commentaire qui disait « voir la note sur le bouton Partager **plus
bas** ». Cette note est partie dans `ClubAloneCard.swift` avec sa carte. Un renvoi à une position
dans un fichier ne survit pas au découpage de ce fichier, et personne ne le remarque : le
commentaire reste grammaticalement correct, il désigne simplement le vide. Il est recopié en
entier — c'est la règle des 44 points qui s'empilent sous les marges du style, et elle vaut pour
les deux cartes.

De même, un commentaire de `ClubView` décrivait encore `if clubEnSommeil { carteClubAReveiller }`,
un membre qui n'existe plus sous ce nom.

### Ce que `check_prive.py` n'aurait pas rattrapé ici

`carteClubSeul` et `carteClubAReveiller` étaient des `private **var**`, pas des `func`. Le
contrôle écrit au chantier 36 ne regarde que les fonctions, et pour une raison mesurée : étendu
aux propriétés, il rendait 112 signalements faux. Les trois sites d'appel ont donc été vérifiés à
la main, par `grep`, avant la découpe — pas par la chaîne.

## Chantier 36 — la chaîne verte sur du code qui ne compile pas (B5, deuxième morceau)

### Ce qui est sorti

Le groupe « vue d'ensemble » du chantier 35, mesuré à 205 lignes et deux états. Il s'est découpé
en deux, parce que les deux cartes n'ont pas le même coût :

- `ClubWeekPulseCard` — 87 lignes, **zéro liaison**. Elle ne demande que le magasin.
- `ClubChallengeCard` — 83 lignes, **une** liaison : `showManagement`, parce que « créer un
  défi » ouvre la gestion du club.

`ClubView` : **1 338 → 1 193 lignes**, 43 membres, 19 états.

### Le défaut : chaîne verte, code qui ne compile pas

`ClubChallengeCard` appelait `daysLeft(until:)`, une `private func` restée dans `ClubView`. En
Swift, `private` sur un membre porte sur la déclaration englobante **et son fichier** : l'appel ne
se résout pas. Le projet ne compilait plus.

`sh ci_scripts/tout.sh` était vert. Tous les contrôles, tous leurs cas. C'est normal : aucun ne
résout un symbole Swift, et il n'y en aura pas un qui le fasse — ça demanderait un compilateur. Le
coût de ce défaut n'est pas le correctif, qui prend une minute : c'est que la seule machine qui
sait le dire est à quarante minutes d'ici, et qu'une découpe qui ne doit rien changer serait
partie rouge.

Ce qui l'a trouvé n'est pas un contrôle : c'est d'avoir relu les deux fichiers neufs en cherchant
quels membres de `ClubView` ils utilisaient encore. Treize identifiants à vérifier, un seul faux.

### Le contrôle, et ses deux premières versions fausses

`check_prive.py` ne compile rien. Il constate **une** impossibilité : un nom déclaré `private`
dans un seul fichier, appelé nu depuis un autre, ne peut pas se résoudre. Ce n'est pas un soupçon,
c'est une erreur de compilation certaine.

Les deux premières versions étaient fausses, chacune à sa manière, et c'est ce qui vaut d'être
écrit ici :

**La première signalait 112 défauts pour zéro défaut réel.** Elle regardait aussi les propriétés
et les types, sur une référence nue au nom. Or un identifiant nu en Swift n'est pas forcément une
référence : `RoundedRectangle(cornerRadius: 12)` contient `cornerRadius` nu, et c'est une
*étiquette d'argument*, pas la propriété privée du même nom déclarée ailleurs. Même chose pour
`opacity`, `filter`, `columns`, `password`. Un contrôle qui crie 112 fois dans le vide n'est pas
prudent : on apprend à ne plus le lire. D'où la forme étroite — les `func` seules, et seulement
la forme `nom(`.

**La seconde ne rattrapait pas le défaut pour lequel elle était écrite.** Elle vidait le contenu
des chaînes à la `re.sub`, comme les autres contrôles du dépôt — et l'appel vivait dans une
interpolation : `String(localized: "J-\(daysLeft(until: challenge.endDate))")`. La regex effaçait
le code avec le texte. J'ai remis `daysLeft` dans `ClubView` pour éprouver le contrôle sur le vrai
défaut, et il a rendu vert. Un contrôle qui rate le cas qui l'a fait naître est pire que pas de
contrôle : il rassure. Le lecteur de chaînes est maintenant un vrai parcours, qui jette le texte
et **garde le code des interpolations**, imbrications comprises.

C'est le même piège que `check_vides.py` avait rencontré en novembre, résolu là-bas en relisant la
ligne brute. Le dépôt a donc deux contrôles qui ont buté sur la même fonction ; les autres s'en
servent encore, et aucun ne regarde ce qui vit dans une interpolation.

### Ce qui le prouve

- `test_prive.py`, **21 cas**. Cinq sur ce qui doit être signalé, dont celui de l'interpolation et
  celui de l'interpolation imbriquée dans une chaîne imbriquée. Huit sur ce qui ne doit **pas**
  l'être — l'étiquette d'argument, l'appel de membre avec un point, le nom déclaré deux fois, le
  nom dans un texte, le nom en commentaire, un suffixe. Cinq sur le lecteur de chaînes seul.
- Mesuré sur les **301** fichiers Swift des quatre cibles, après correction : **zéro**.
- Et le contrôle rendait vert depuis `ci_scripts/` tant qu'il lisait `Haizo/` en relatif — « aucun
  fichier Swift trouvé ». Il est ancré sur la racine du dépôt, et un cas le tient.

### Ce que ce contrôle ne voit pas

Les propriétés et les types privés : le coût en faux positifs est prohibitif, mesuré à 112. Un nom
déclaré deux fois dans la cible : l'appel pourrait se résoudre sur l'autre, le script passe son
tour plutôt que d'accuser à tort. Et tout le reste de ce que fait un compilateur.

## Chantier 35 — ClubView, la découpe reprise par le bout le moins cher (B5, premier morceau)

### La mesure avant le découpage

1 425 lignes, 51 membres. **844 lignes** sont déplaçables en quatre groupes cohérents ; il
resterait 581, une taille raisonnable pour une vue-conteneur.

Mais le nombre de lignes n'est pas le bon critère de risque. La vue porte **vingt états**, et
chaque état qu'une section doit recevoir est un `@Binding` de plus — donc une chance de brancher
le mauvais, dans un remaniement qui ne doit RIEN changer.

| groupe | lignes | états à passer |
| --- | --- | --- |
| **Le niveau** | 101 | **0** |
| La vue d'ensemble | 205 | 2 |
| Rejoindre / réveiller | 231 | 4 |
| Le mur et le fil | 263 | **10** |

### Une erreur de plan, trouvée en lisant

Mon premier regroupement mettait `segment` avec le niveau, sur la foi de son nom. En ouvrant le
fichier : `segment` est le bouton d'un onglet, appelé par `clubTabs` quatre cents lignes plus
loin, et il a besoin de `tab`. Le groupe « niveau » ne porte donc **aucun** état, et c'est ce qui
en fait le premier morceau.

C'est la sixième fois dans cette session qu'un plan écrit depuis un résumé ne survit pas au
contact du code. Les mesures, elles, tiennent.

### Ce qui est sorti

- `NiveauDuClub` — le calcul du palier, pur et testé. Il vivait en propriété privée au milieu des
  1 425 lignes : vérifiable seulement en ouvrant l'écran avec un compte au bon nombre de points,
  c'est-à-dire jamais. Il porte pourtant trois décisions, dont une qui n'était écrite nulle part :
  **au-delà du septième titre, on ne s'arrête pas de monter.** Le comportement existait — un
  `min(max(…))` — et c'est exactement le bord qu'un remaniement transforme en plantage d'index ou
  en « Premiers pas » retrouvé au niveau 12.
- `ClubLevelCard` — la vue, qui ne connaît plus que son XP. Elle ne consulte plus `AuthService` :
  l'appelant lui donne le nombre, donc elle se dessine pour n'importe quelle valeur.

`ClubView` : **1 425 → 1 338 lignes.**

### Ce qui le prouve

`NiveauDuClubTests`, 9 cas : les deux bords du palier (où un `>=` mal placé décale tout le monde
d'un niveau sans rien casser), les sept titres dans l'ordre, le huitième niveau qui garde le
dernier titre, un XP négatif qui ne descend pas sous le niveau 1, et la monotonie.

Et surtout : **les quatre écrans du Club sont photographiés**, et `comparer.py` existe pour ça. Il
a été écrit pour la première découpe de ce fichier — son en-tête dit « `ClubView.swift` fait 2721
lignes » — et il compare pixel à pixel en masquant la barre d'état. Une découpe qui ne doit rien
changer se prouve par l'image, pas par une intention.

### Ce que je ne découperai pas comme les autres

**Le mur et le fil**, et ses dix `@Binding`. Dix états à faire passer n'est pas une section : c'est
le signe qu'il lui faut son propre objet d'état, comme `magasin` en est déjà un pour le reste du
Club. Le sortir en l'état transformerait une vue longue en une vue longue plus dix fils à ne pas
confondre.

## Chantier 34 — deux listes sans borne, pas soixante-trois fichiers (B6)

### L'item comptait la mauvaise chose

`PHASE2.md` disait : « 63 fichiers utilisent `ForEach`, **11 seulement** une liste paresseuse. »
Ce comptage ne mesure rien. Un `ForEach` sur les sept jours de la semaine n'a aucun besoin d'être
paresseux, et un fichier qui en porte trois ne compte pas pour trois défauts.

Le critère qui compte est la **position** : sous un `ScrollView`, sans `LazyVStack`, `LazyHStack`,
`LazyVGrid` ni `List` entre les deux.

| | |
| --- | --- |
| `ForEach` dans le dépôt | 133, dans 63 fichiers |
| conteneurs paresseux | 13 |
| **`ForEach` réellement construits d'un bloc sous un défilement** | **10** |
| dont la source est bornée dans le code (`allCases`, `0..<7`) | 7 |

### Et les deux écrans que l'item nommait étaient déjà réglés

« Le fil du club et l'historique ne sont pas courts », disait-il. Mesuré :

- **le fil du club** porte un `LazyVStack` depuis longtemps, avec son commentaire : « le serveur
  renvoie 50 activités, et un `VStack` les construisait TOUTES » ;
- **l'historique** est une `List` — paresseuse par construction, et choisie pour une autre raison
  écrite sur place : `.swipeActions` ne marche que là.

### Les deux qui restaient

| écran | collection | ce que porte chaque ligne |
| --- | --- | --- |
| `ActivityCommentsSheet` | les commentaires d'une activité | un avatar à décoder |
| `FriendsView` | la liste de personnes | un `AvatarView` |

Aucune borne, et une image par ligne. Les deux passent en `LazyVStack`, avec le même commentaire
que le fil du club — c'est le même cas.

### Les trois qui restent, et pourquoi

Bornées par une règle de produit que la syntaxe ne montre pas, donc **dispensées avec leur
raison** : les groupes d'allure d'une sortie (« le produit en propose huit au plus », dit le
commentaire de la vue), et les deux bandes de badges, bornées par `ClubBadgeCatalog.all`. Les
trois sont des bandes horizontales à tuiles de largeur fixe, pas des listes qui croissent.

### Ce qui le garde

`ci_scripts/check_listes.py`, **16 cas**. La règle : un `ForEach` sous un défilement, sans
conteneur paresseux, doit avoir une source dont la taille se lit DANS LE CODE — `X.allCases`, un
intervalle littéral — ou une dispense nommée avec sa raison.

Trois cas ne vérifient que les façons de passer vert à tort. Le plus utile : un `LazyVStack` posé
**ailleurs dans le fichier** ne doit pas couvrir une liste qui ne s'y trouve pas — c'est
l'imbrication qui décide, pas la présence du mot. Un autre fixe que `0..<items.count` n'est pas
une borne : c'est la même collection, écrite autrement.

Et le contrôle dit ce qu'il ne sait pas faire : il ne mesure aucune performance. Dix lignes de
texte nu ne valent pas dix lignes à avatar, et il ne connaît pas la différence. Il constate qu'une
liste sans borne est construite d'un bloc — une décision — et demande qu'elle soit prise exprès.

## Chantier 33 — la montre coupait sa seule phrase, et rien ne le disait (B4)

### Regardé, pas déduit

Sur la capture que la fiche App Store publie, dans les trois langues :

```
en-US  11 lignes de pixels encrées jusqu'à la toute dernière (495/496)
es-ES  11 lignes
fr-FR  11 lignes
```

« Cours à ta sensation — ta séance arrive de l'iPhone. » était **tranchée en deux par l'arête
basse**. L'écran est dans un `ScrollView`, donc la phrase était atteignable — en faisant défiler,
sur une montre, une phrase d'explication posée sous un bouton géant. Autant dire jamais.

### La cause, écrite dans le fichier lui-même

L'anneau pointillé faisait **118 points sur les 248** de l'écran, et le commentaire du fichier le
qualifiait : *« purely decorative since there's nothing to track yet »*. La moitié de l'écran pour
une décoration, qui pousse dehors la seule phrase.

| | avant | après |
| --- | --- | --- |
| anneau | 118 | 96 |
| bouton | 92 | **76** (minimum tactile d'Apple : 44) |
| écarts du `VStack` | 8 | 6 |

Vingt-huit points rendus. Et la phrase prend désormais la hauteur qu'il lui faut (`fixedSize`) au
lieu de celle qu'on lui laisse : une langue plus longue que les trois d'aujourd'hui repasserait
sinon sous le bord sans que la mise en page bouge d'un point.

### L'autre moitié de B4 était déjà tombée

`PHASE2.md` annonçait aussi « le dégradé sur le bouton principal ». Mesuré : la montre ne porte
**aucun** dégradé ni verre — ils sont partis avec le chantier 24. Restait le commentaire, qui
décrivait encore un « dashed gradient ring ». Un commentaire qui décrit ce qui n'est plus là est
la moitié d'un mensonge.

### Ce qui le garde

`check_captures_montre.py` savait dire que trois langues rendaient la même image. Il ne savait pas
dire que les trois étaient COUPÉES. Il le dit : la bande basse — 2 % de la hauteur, cinq points —
doit rester vierge.

Elle ne juge aucune mise en page. Elle constate qu'au REPOS rien n'est tranché par l'arête, ce à
quoi une image répond sans ambiguïté, contrairement à « est-ce joli ». **Éprouvée sur les vraies
captures d'avant : elle rougit pour les trois langues.** Cinq cas nouveaux, dont deux pour les
façons de passer vert à tort — un seuil d'encre à zéro accuserait toutes les captures réelles et
on apprendrait à ignorer le rouge ; et la coupe doit l'emporter sur la comparaison des langues,
parce que l'une se corrige dans la vue et l'autre dans la chaîne de capture.

### Et un rouge délibéré, pendant un build

Les trois captures livrées à Apple sont versionnées et portent l'empreinte du code de la montre.
Changer ce code les périme, et `check_requis.py` l'a dit tout de suite — il a refusé le commit.

Les réestampiller sur place aurait été lui mentir : déclarer à jour des images que personne n'a
refaites. Et je ne peux pas les refaire ici, il faut un simulateur watchOS. Le chemin honnête était
donc de pousser le code, laisser `montre.yml` refaire les captures, **les regarder**, et poser les
images fraîches au commit suivant. Un build rouge sur une étape, dix minutes, et le garde-fou a
fait exactement son travail.

## Chantier 32 — la mesure du lancement arrivait déjà, et une méthode vide la jetait (B7)

`PHASE2.md` disait : « Le temps de lancement n'a jamais été relevé. La phase 4 exige premier écran
en moins de 2 secondes. On ne peut pas tenir une promesse qu'on n'a pas mesurée. »

Il n'y avait rien à construire pour la relever.

### La moitié traitée, et la moitié jetée

MetricKit a deux canaux, et `Diagnostics` était abonné aux deux :

| | |
| --- | --- |
| `didReceive(_:[MXDiagnosticPayload])` | traité depuis longtemps — **cinq** listes, dont `appLaunchDiagnostics`, avec la durée dans la note. Chaque lancement anormalement lent arrive déjà, et `privacy.html` le décrit : « met trop longtemps à démarrer » |
| `didReceive(_:[MXMetricPayload])` | **`{}`** |

Une méthode vide. On avait donc les cas EXTRÊMES et pas la normale — et la promesse porte sur la
normale.

### Pourquoi iOS et pas un chronomètre dans l'app

`histogrammedTimeToFirstDraw` est « the time when the first CA commit is finished » : c'est bien
« premier écran ». Et c'est la seule mesure qui inclut ce qu'on ne peut pas voir depuis Swift —
le temps d'avant `main()`, le chargement dynamique, la mise en place du processus. Un chronomètre
posé dans l'app démarrerait trop tard et annoncerait donc des lancements **plus rapides** qu'ils ne
sont : il se tromperait dans le sens qui arrange, sur une promesse.

### Deux choses que je n'ai pas devinées

La documentation d'Apple n'était pas citable sur deux points, et le blog qui l'approche ne les dit
pas non plus :

1. **L'unité des paliers.** Le code de référence lit `bucketEnd.value` brut et traite le résultat
   comme des millisecondes, sans le dire. Un facteur mille ferait juger la promesse sur du vide.
   `Diagnostics` porte déjà `millisecondes(_:)`, qui **convertit** la `Measurement` au lieu de lire
   sa valeur — l'unité n'est donc pas une supposition.
2. **Le nom de la propriété de début de palier.** Non vérifié, et pas nécessaire : les paliers sont
   contigus, et les deux lectures utiles n'ont besoin que de la borne haute. Lire une propriété
   dont on n'est pas sûr, pour une donnée dont on n'a pas besoin, c'est deux risques pour rien.

### Les deux lectures se trompent exprès, et dans le même sens

Un histogramme ne donne aucune durée, seulement des paliers. `Histogramme` l'assume :

- `percentile(_:)` rend la **borne haute** du palier où le cumul franchit le seuil. « p90 =
  1 500 ms » veut dire « neuf sur dix ont fini avant 1 500 ms » ;
- `partAuDessusDe(ms:)` compte un palier **à cheval** sur le seuil comme étant au-dessus.

Les deux penchent vers le pessimisme. C'est le bon sens pour une promesse : on ne veut pas la
découvrir annoncée tenue parce qu'on arrondissait vers le bas. `HistogrammeTests`, **16 cas**,
dont un qui fixe `ceil` plutôt que `round` — à dix observations le p50 est la cinquième, pas la
cinq-et-demie, et `round` faisait sauter d'un palier, soit quatre fois plus de millisecondes
annoncées.

### Elle ne partait pas encore, et maintenant si

`Diagnostics.mesureDuLancementActive` est resté à **faux** le temps d'un chantier, pour une raison
qui n'était pas technique : la politique **publiée** ne décrivait pas cette mesure. Collecter une
donnée que la page liée depuis la fiche App Store ne mentionne pas est exactement le défaut que
`check_politique.py` existe pour empêcher, dans le sens qu'il qualifie de dangereux.

J'avais préparé le paragraphe et le push vers `main` m'a été refusé — un déploiement en
production, et l'autorisation d'alors portait sur un seul geste. Je ne l'ai pas contourné : j'ai
retiré le paragraphe de la branche de travail pour que les deux pages restent d'accord, et j'ai
posé un drapeau écrit en clair, avec sa raison et l'action qui le lève.

Charlotte a autorisé le geste le 10 novembre. **L'ordre a été tenu** : la page a été publiée sur
`main` d'abord, vérifiée servie par GitHub Pages — douze sections au lieu de onze, texte identique
au dépôt — et la constante n'est passée à vrai qu'après. Il n'a donc jamais existé d'instant où
l'app mesurait sans que la page le dise.

Le paragraphe publié :

> **Temps de lancement** — une fois par jour au plus, l'application envoie la mesure du temps que
> ton téléphone a mis à afficher le premier écran, telle qu'iOS l'établit. Elle arrive sous forme
> de *paliers* — « tant de lancements terminés avant 250 millisecondes, tant avant 500 » — et
> jamais sous forme de durées individuelles : aucun lancement en particulier n'est identifiable.
> Elle sert à une seule chose, vérifier que le premier écran s'affiche en moins de deux secondes.
> Elle relève du choix décrit ci-dessus : si tu refuses les statistiques d'usage, elle n'est ni
> enregistrée ni envoyée.

La constante reste en place plutôt que d'être retirée : elle est l'interrupteur par lequel on
arrête cette collecte sans toucher à rien d'autre.

Le manifeste, lui, n'a pas bougé : `PrivacyInfo.xcprivacy` déclare déjà `PerformanceData`, pour
les diagnostics de lancement. Même nature de donnée, même finalité.

Et cette mesure **obéit au consentement**, contrairement aux rapports de panne : elle passe par
`Analytics`, dont `enqueue` et `sendNextBatch` sont gardés par le choix fait à l'inscription. C'est
pour ça que le paragraphe le dit — les deux cas voisins ne se comportent pas pareil.

### Ce qu'on saura, et quand

Rien ce soir. MetricKit livre un lot par appareil et par jour, depuis un appareil RÉEL — un
simulateur n'en envoie pas. Les premiers chiffres arriveront dans la table `events`, événement
`launch_measured`, et la promesse se lira directement dans la propriété `part_au_dessus_de_2s`.

## Chantier 31 — l'état vide, écrit une fois pour de bon (A5, le reliquat)

`RUEmpty` existait depuis le chantier 25, et **six écrans l'utilisaient**. Seize endroits
continuaient d'écrire le leur.

### Ce que la mesure a donné

| | valeurs trouvées pour la même phrase |
| --- | --- |
| graisse du titre | `.bold`, `.semibold`, `.medium` |
| couleur du message | `text3`, `text2` |
| corps du texte | `.small`, `.body` |
| taille de l'icône | `.hero` (28), `.xlarge` (22) |

Deux couleurs et trois graisses pour dire « il n'y a rien ici ». « Aucun défi en cours » existait
dans deux fichiers, avec deux formulations et deux corps de texte.

### Et le composant partagé était le seul à ne pas suivre le système

`RUIconSize.hero` vaut 28, et sa documentation dit : *« l'icône d'un état vide, celle qu'on voit
avant même de lire »*. `RUEmpty` utilisait `.xlarge` (22). Les trois états vides écrits à la main,
eux, utilisaient bien `.hero`. La pièce censée mettre tout le monde d'accord était la seule à
ignorer le cran que le système nomme pour elle.

### Seize conversions, dans dix-sept fichiers

Six appels au départ, **24 maintenant**. Les cas intéressants :

- `FriendsView` recentrait une `.ligne`, alignée à gauche par construction — le site d'appel
  reprenait une décision du composant. La forme était en fait un `.bloc` : il n'y a aucun en-tête
  de section au-dessus, seulement un champ de recherche et une zone de résultats vide.
- `PublicProfileView` portait **deux** états vides à la main, dont un que je n'ai vu qu'en
  réparant l'accolade orpheline laissée par la première conversion.
- `MoveSessionSheet` et `ClubBoardSection` n'étaient dans aucune de mes listes : c'est la mesure
  qui les a sortis.

### Ce qui n'a pas été converti, et pourquoi

- **`StatsView.firstDayBanner`** — une carte héros avec en-tête, sous-titre et un paragraphe qui
  promet ce que l'écran affichera. Ce n'est pas « il n'y a rien », c'est une promesse de premier
  jour. La forcer dans `RUEmpty` aplatirait une intention.
- **`FriendsView`, « Personne à suivre pour l'instant »** — un bloc d'appel à l'action avec
  l'invitation par code, conçu comme tel et documenté sur huit lignes.
- **`PaywallView`** — un état de CHARGEMENT, avec sa roue. `RUEmpty` dit explicitement qu'il n'est
  ni une erreur ni un chargement.
- **`RaceDiscoveryView.message(…)`** reste, pour son unique autre usage : une erreur de
  chargement. « Rien à montrer » et « ça n'a pas marché » sont deux phrases différentes.

### Un trou trouvé en passant, et plus grave que le chantier

Le contrôle des symboles s'est mis à signaler « bell.slash » et « square.stack.3d.up » comme
**éprouvés mais plus employés**. Cause : il lit l'argument de `systemName:` et sait remonter un
membre calculé ou un paramètre de fonction — mais pas une **propriété stockée de structure**, qui
n'a pas de corps accoladé. En adoptant `RUEmpty(icone:)`, les écrans rendaient donc leurs icônes
invisibles à la vérification.

La résolution ajoutée a immédiatement découvert **trois symboles jamais éprouvés** : `shoe`
(`RUEmpty`), `clock` et `ruler` (`RUStatTile`, `RUCardHeader`). Trois familles de composants
passent un nom de symbole par propriété stockée, et aucune de leurs icônes exclusives n'était
vérifiée — depuis leur création. Un nom de symbole faux ne lève rien : il ne dessine rien.
108 symboles sont désormais éprouvés.

### Ce qui le garde — et ce qu'il avoue ne pas garder

`ci_scripts/check_vides.py`, **15 cas**. Trois règles : aucun bloc composé à la main (grande icône
teintée `text3` au-dessus d'un texte), aucun site d'appel qui restyle le composant, et le composant
qui garde `.hero` et `text3`.

**Et il dit ce qu'il ne sait pas faire.** La forme `.ligne` n'a aucune signature détectable : une
phrase sous un en-tête de section ressemble à n'importe quelle autre phrase secondaire. La règle la
plus large essayée — un `Text` teinté `text3` dans une branche qui teste `isEmpty` — a rendu
**35 endroits pour environ 6 vrais** : des `!x.isEmpty` qui testent une présence, des `isValid`,
des URL, des bios. Une règle à trente dispenses ne décrit pas un défaut, elle le noie, et on
apprend à ignorer son rouge. Les conversions ont donc été faites en lisant, et c'est écrit.

Un des quinze cas reproduit un défaut du garde-fou lui-même : il cherchait le nom du symbole de sa
dispense dans la source dont `sans_commentaires` a effacé le contenu des chaînes. La seule dispense
réelle ne s'appliquait jamais.

## Chantier 30 — huit boutons qui n'existaient pas, et une politique qui ne disait pas qu'on peut refuser

Deux demandes de Charlotte — retirer la capture iPad de la fiche, ajouter à `privacy.html` la
phrase sur le refus des statistiques. La première a buté sur un défaut que je n'avais pas vu.

### Le bouton que je lui avais indiqué n'existait pas

Je lui avais écrit : « workflow **App Store**, action **`nettoyer-les-captures`**, champ
« retirer » ». Au premier appel, l'API a répondu :

> Provided value 'lister-les-captures' for input 'action' not in the list of allowed values

**GitHub ne construit le formulaire « Run workflow » que depuis la branche par défaut.**
`appstore.yml` est le seul workflow du dépôt qui ne se déclenche qu'à la main — les six autres
tournent aussi au push — et sa liste d'actions sur `main` est la seule qu'on puisse choisir. Le
corps, lui, récupère explicitement la branche de travail pour y trouver `asc.py`.

Huit actions étaient déclarées dans le dépôt et absentes de `main` :

| | | |
| --- | --- | --- |
| `liberer-la-file` | `nettoyer-les-captures` | `pousser-l-apercu` |
| `lister-les-captures` | `nettoyer-les-captures-essai` | `pousser-l-apercu-essai` |
| `pourquoi-pas-soumettable` | `pousser-la-montre` | |

Dont **deux chantiers entiers** : l'envoi des captures de la montre et l'aperçu vidéo de la fiche.
Chacun écrit, testé, documenté — et impossible à lancer. L'entrée `retirer` manquait aussi, donc
même en atteignant l'action, le champ n'aurait pas été là.

C'est le défaut le plus discret rencontré jusqu'ici : le code existe, ses contrôles passent, sa
documentation le décrit, et il ne s'exécute jamais. Et `main` portait **déjà** un commit intitulé
« Le bouton qui envoie les captures doit vivre sur main, sinon il n'existe pas ». La leçon avait
été apprise une fois et n'a pas tenu, faute de quoi que ce soit qui la vérifie.

`ci_scripts/check_boutons.py` la vérifie maintenant, et **12 cas** le gardent. Deux d'entre eux
reproduisent un défaut du garde-fou lui-même : son premier jet lisait `origin/main` et ne
récupérait qu'en cas d'échec, or `git fetch origin main` ne met à jour que `FETCH_HEAD`. Il a donc
comparé le dépôt du jour à un `main` vieux de plusieurs semaines — et s'est trompé à son premier
essai réel. Il récupère d'abord, toujours, et échoue en le disant s'il ne peut pas regarder.

### Et la capture iPad ne peut pas être retirée de là où elle est

L'inventaire, une fois le bouton réparé, a donné l'état réel :

```
version 3.3      READY_FOR_SALE               plateforme IOS
version 3.2      READY_FOR_SALE               plateforme IOS
```

Il n'existe **aucune version 3.4** sur App Store Connect — les builds 1496-1499 sont en
TestFlight, c'est autre chose. La capture iPad est donc sur la **3.3, en vente, et Apple fige une
version en vente.** Personne ne peut l'en retirer, moi compris.

Ce qui se peut, en revanche, c'est qu'elle ne revienne pas. Créer une version recopie les captures
de la précédente, tous formats confondus : la retirer à la main une fois ne règle rien, il faut
s'en souvenir à chaque version. **`create-version` élague donc d'office**, sur une liste nommée
`FORMATS_SANS_RAISON` qui ne contient que l'iPad, et le geste à ne pas oublier devient une chose
qui arrive.

La capture Apple Watch n'y est pas et ne doit pas y venir : Apple l'exige dès que la build embarque
une app watchOS. Une première version de l'élagage, qui gardait l'iPhone et supprimait le reste,
l'avait emportée et la version était restée bloquée deux heures. Un cas de test l'interdit
nommément, avec cinq formats.

### La politique, et ce que le refus ne couvre pas

L'app pose la question à l'inscription — deux boutons, rien de coché d'avance — et le choix est
révocable dans Profil › Réglages › Plus de réglages. La page décrivait la collecte sans dire qu'on
peut la refuser.

**Et en vérifiant au lieu de supposer** : les rapports de panne n'obéissent PAS à ce consentement.
`Diagnostics.demarrer()` ne regarde que le mode démonstration, et `sendNextBatch` n'a aucune garde
de consentement. La phrase ajoutée le dit donc explicitement, au lieu de laisser quelqu'un déduire
de travers d'un paragraphe voisin.

Deux textes de l'app disaient aussi « rien n'est envoyé » — vrai pour les statistiques, ambigu à
côté d'un canal qui continue d'émettre. Ils disent maintenant « aucune statistique ». Et l'écran
d'inscription indiquait « Profil → Réglages » pour revenir sur son choix : **le réglage est dans
« Plus de réglages »**, une feuille à l'intérieur de Réglages. Quelqu'un qui suivait l'indication
ne trouvait rien. Corrigé dans les trois langues.

Enfin la redondance que la page signalait elle-même en commentaire depuis le 8 novembre est
retirée — « n'embarque aucun outil tiers de rapport de panne » apparaissait deux fois à deux
paragraphes d'écart. Le commentaire disait : « si tu modifies cette page, tu es cette prochaine
fois. »

### Ce qui reste à faire, et par qui

La capture iPad disparaîtra **à la création de la version 3.4**, sans que personne n'ait à y
penser. Créer cette version est une décision de sortie, pas une correction : elle attend
Charlotte.

## Chantier 29 — les allures du plan n'avaient aucune source (B1)

C'est l'item le plus lourd de la liste, et le fond du produit : un plan dont les allures ne se
défendent pas n'est pas un plan d'entraînement.

### Ce qu'il y avait

Quatre multiplications, dans `PaceModel.zones` :

```swift
easy:      paceText(thresholdSecPerKm * 1.20),
marathon:  paceText(thresholdSecPerKm * 1.08),
threshold: paceText(thresholdSecPerKm * 1.0),
interval:  paceText(thresholdSecPerKm * 0.87),
```

L'ancrage était l'allure du 10 km, projetée par Riegel depuis la meilleure performance. Le
commentaire du fichier avouait l'origine des quatre coefficients : *« deliberately simple […] in
the spirit of standard recreational running pace calculators »*. Autrement dit, aucune source.

### La méthode retenue

Jack Daniels et Jimmy Gilbert, *Oxygen Power* (1979), deux équations :

- le coût en oxygène d'une vitesse : `VO2 = −4,60 + 0,182258 v + 0,000104 v²`, v en m/min ;
- la fraction de VO2max soutenable sur une durée :
  `%VO2max = 0,8 + 0,1894393 e^(−0,012778 t) + 0,2989558 e^(−0,1932605 t)`, t en minutes.

Leur quotient sur une performance réelle donne le VDOT. En sens inverse, un VDOT et une fraction
donnent une allure.

**Les fractions ne sont pas recopiées, elles sont mesurées.** Trois sites donnent trois valeurs
différentes pour la même allure — pour le seuil, 83-88 %, 86-92 % et 88-92 %, et l'un des trois
confond %VO2max et %FCmax. Elles ont donc été *retrouvées* depuis la table publiée : pour chaque
allure et chaque VDOT, `coutEnOxygene(allure) / VDOT`. Le résultat est constant à un dixième de
point sur tout l'intervalle VDOT 30-60, ce qui n'arrive pas par hasard :

| Allure | Fraction mesurée | Étendue sur VDOT 30-60 |
| --- | --- | --- |
| footing, bord lent | 62,0 % | 61,9 – 62,1 |
| footing, bord rapide | 70,0 % | 69,9 – 70,1 |
| seuil | 88,0 % | 87,8 – 88,1 |
| intervalle | 97,5 % | 97,3 – 97,7 |
| marathon | **dérive de 80,5 à 82,5 %** | — |

L'allure marathon n'est donc pas une fraction : chez Daniels, c'est l'allure du marathon *prédit*.
Calculée comme telle, elle redonne la table à un demi-seconde près au lieu de trois.

### Ce que la mesure a dit des quatre coefficients

| | Haizo | Daniels (rapport à l'allure du 10 km) | Verdict |
| --- | --- | --- | --- |
| footing | × 1,20 | 1,199 → 1,376 selon le niveau | **faux** : au bord le plus rapide de la plage facile à VDOT 30, **devant** pour tout le monde au-dessus |
| marathon | × 1,08 | 1,076 → 1,094 | **juste** |
| seuil | × 1,00 | 1,003 → 1,037 | légèrement trop rapide, l'écart croît avec le niveau |
| VMA | × 0,87 | intervalle 0,925 → 0,957 ; **répétition 0,872 → 0,893** | **faux** : c'est l'allure du mile, prescrite pour des répétitions de 3 à 5 minutes |

En secondes par kilomètre, pour de vraies personnes :

| VDOT | 10 km | footing Daniels | footing Haizo | écart | VMA Daniels | VMA Haizo | écart |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 30 | 1:03:49 | 8:01 | 7:39 | **−22 s** | 5:54 | 5:33 | **−21 s** |
| 40 | 50:01 | 6:26 | 6:00 | **−25 s** | 4:41 | 4:21 | **−20 s** |
| 50 | 41:20 | 5:22 | 4:58 | **−25 s** | 3:55 | 3:36 | **−19 s** |
| 60 | 35:22 | 4:38 | 4:15 | **−24 s** | 3:23 | 3:05 | **−18 s** |

Le footing porte 70 à 80 % du volume d'une semaine. C'est l'erreur la plus répandue de
l'entraînement de loisir, et l'app la prescrivait.

**Et aucun coefficient fixe ne pouvait être juste.** Les rapports de Daniels varient avec le
niveau : footing/seuil passe de 1,2526 à 1,2659, VMA/10 km de 0,925 à 0,957. Un seul nombre se
trompe forcément à une extrémité.

### Le plus instructif : un test vert interdisait la bonne réponse

`testIntervalPaceIsAGenuineVO2maxStimulus` exigeait un écart seuil→VMA de **11 à 20 %**, sur la
foi de son propre commentaire : *« real vVO2max sits ~12-18% faster »*. Aucune source.

Mesuré sur la table, l'écart vaut **7,7 à 8,2 %**. Le code l'avait eu — × 0,92, soit 8 % — puis
l'a perdu pour satisfaire ce test. Le raisonnement du commentaire était juste sur le symptôme
(« à 8 %, la séance de VMA était un second tempo ») et faux sur le nombre, et il a sur-corrigé
dans la direction même qu'il voulait corriger.

Un chiffre d'entraînement sans source n'est pas une approximation, c'est une invention. Et une
invention sous test devient une invention protégée.

### Riegel sort de l'ancrage

L'exposant 1,06 a été ajusté par Peter Riegel sur des **records du monde** (« Athletic Records and
Human Endurance », *American Scientist* 69(3), 1981) : un travail descriptif, pas un prédicteur
individuel. Il n'est plus nécessaire ici — le VDOT se lit directement depuis n'importe quelle
distance, et les quatre distances d'une même ligne de la table rendent le même VDOT à cinq
centièmes près. Riegel reste le repli pour ce que Daniels ne couvre pas, en dessous de 1 500 m et
au-delà du marathon, où l'appelant affiche une prédiction et non une consigne.

### Deux autres faussetés trouvées en passant

1. **Les statistiques prédisaient depuis l'allure de seuil « sur 10 km ».** Deux propriétés
   séparées, l'une se repliant sur le seuil, l'autre sur dix. L'allure de seuil n'est pas celle
   d'un 10 km — c'est celle d'une course d'environ 67 minutes. Le couple ne tenait que parce que
   le plan se trompait de la même façon. La prédiction repart du VDOT du profil.
2. **Le tableau d'allure du jour J se repliait sur le seuil, quelle que soit la distance.** Sur un
   marathon, il proposait un rythme de course d'une heure sur quarante-deux kilomètres, et la
   ligne « Relance » cinq secondes plus vite encore. Il repart de la prédiction **pour cette
   distance-là**.

### Les deux erreurs de signe contraire

L'ancien code déduisait d'une allure de footing déclarée un seuil **14 s/km trop lent** (`/ 1.20`,
quand Daniels donne 1,25 à 1,27), pendant qu'il déduisait d'un chrono un footing **25 s/km trop
rapide**. Deux chemins d'entrée du questionnaire, deux erreurs opposées, et rien qui les
rapproche. Une seule méthode, maintenant, dans les deux sens.

### Ce qui ne change pas, délibérément

Les trois constantes de niveau — 330, 285, 240 s/km — sont converties en VDOT (36,34 / 43,61 /
53,94) de façon à rendre **exactement le même seuil** qu'avant. Seules les trois autres allures
bougent, ce qui est l'objet du chantier. Les redécider est un autre travail, et il se pose : un
VDOT de 36 est un 10 km en 54 minutes, ce qui n'est pas « débutante » mais « court déjà ». Personne
n'a mesuré ce que courent les gens qui cochent cette case, et une constante devinée deux fois ne
vaut pas mieux qu'une fois.

### La bascule

Rien n'est réécrit sous les pieds de personne. Une séance porte son allure en texte, posée à la
génération de la semaine : les nouvelles allures paraissent à la prochaine régénération — un
changement de réglage, ou le lundi suivant. La semaine commencée reste celle qu'on a sous les yeux,
et aucune séance ne change entre le moment où on la lit et le moment où on la court.

Conséquence attendue et correcte : à distance égale, une sortie longue dure environ 5 % plus
longtemps, puisqu'on la court plus lentement.

### Et le test rouge a trouvé un défaut que j'avais introduit

Une seule défaillance sur 764 : `testProjectionScalesWithTheReferencePace`, qui exigeait qu'une
référence deux fois plus lente donne une prédiction exactement deux fois plus lente. C'est vrai
d'une loi de puissance et faux de la course à pied — la fraction de VO2max soutenue dépend de la
durée, et la personne plus lente passe bien plus de temps sur la distance. Comme le test de la
VMA, celui-ci verrouillait l'algèbre d'une formule en croyant verrouiller une vérité. **Deuxième
fois dans le même chantier.**

Mais en l'examinant, le vrai défaut, et il était de moi : **j'avais borné le VDOT entre 25 et 85,
deux chiffres inventés** — exactement ce que ce chantier existe pour retirer.

| | Mon premier jet | Ce que ça coûtait |
| --- | --- | --- |
| plancher | 25 | Quelqu'un qui court son 10 km en **1 h 40** a un VDOT de 17,2. Ramené à 25, son plan lui prescrivait des footings à **9:11/km** — plus rapides que son allure de course — et lui prédisait un marathon à 7:55/km, soit **plus vite au kilomètre que son propre 10 km** |
| plafond | 85 | Le record du monde du marathon au moment où ces lignes sont écrites, **1 h 59 min 30 s** (Sabastian Sawe, Londres, 26 avril 2026), vaut **86,45**. Une performance humaine réelle était rabotée |

Les deux bornes se nomment maintenant :

- **plancher 13** — la frontière entre marcher et courir. Une marche rapide se tient vers
  12:00/km ; un 10 km à cette allure, deux heures, donne 13,45. Le plancher est juste en dessous
  pour que cette frontière reste dedans.
- **plafond 90** — bien au-dessus du record, et délibérément : son travail est d'écarter une faute
  de frappe, pas de suivre les records. Un 5 km tapé « 8 min » vaut 145, un marathon tapé « 1 h »
  vaut 197. L'écart est si large que la valeur exacte du plafond n'a aucune importance — et le
  dire est le seul argument qui la rende défendable.

Et le bornage est désormais **séparé de la lecture**, parce que les deux appelants ne veulent pas
la même chose : un plan a besoin d'un ancrage même pour une saisie extravagante — mieux un plan
borné qu'aucun plan —, une prédiction non. Une référence hors plage repasse donc par Riegel, qui
ne prétend à aucune physiologie, au lieu d'être ramenée au plancher et affichée avec aplomb.

Le test de proportionnalité est remplacé par les deux propriétés qui sont vraies et qui comptent :
plus lent reste plus lent, et **une plus longue distance n'est jamais prédite plus vite que la
référence** — la promesse qui blesse, que le test de proportionnalité cherchait à atteindre sans
y arriver.

### Ce qui le garde

`HaizoTests/VdotTests.swift`, 20 cas, et le premier ne teste pas notre code pour lui-même : il
vérifie que les deux équations d'*Oxygen Power* retrouvent le VDOT de chaque ligne depuis le temps
de 10 km de cette même ligne. Si ce n'était pas vrai, la table recopiée serait une paraphrase et
tous les autres cas vérifieraient une invention. Les suivants vérifient l'inversion, allure par
allure, à la seconde près — footing (deux bords), seuil, intervalle, marathon, et les quatre
colonnes de temps de course. Puis l'ordre des allures sur toute la plage, la monotonie que la
dichotomie suppose, l'aller-retour allure↔VDOT, le refus de l'ultra, et le bornage d'une saisie
absurde.

Deux cas existent uniquement pour empêcher le retour en arrière : l'un montre que le rapport
footing/seuil n'est pas constant, donc qu'aucune multiplication ne peut le remplacer ; l'autre
fixe l'écart seuil→VMA à celui de la table, avec sa source. Deux autres gardent les bornes : que
le bornage reste séparé de la lecture, et que les bornes séparent bien un record du monde et une
marche-course — dedans — d'une faute de frappe — dehors.

`ci_scripts/check_allures.py` et ses **16 cas**. Trois règles : `PaceModel.zones` ne contient
aucune arithmétique sur un littéral décimal — la forme exacte du défaut, et la seule qu'il puisse
reprendre ; les quatre allures passent par `Vdot`, le marathon par `allureDeCourse` et non par une
fraction ; chaque fraction de `Vdot.Fraction` est nommée dans les cas, qui doivent porter au moins
sept lignes de la table **et citer leur source**. Trois des seize cas ne vérifient que les façons
dont ce contrôle pourrait passer vert pour la mauvaise raison — une signature reformatée, une table
amputée, une source effacée.

## Chantier 28 — « L'achat n'a pas abouti. », dit à quelqu'un qu'Apple vient de débiter (A4)

### L'item était mal posé, pour la quatrième fois

`PHASE2.md` disait « `SubscriptionService` existe, aucun test de parcours d'achat », avec un risque
« moyen, les achats se testent mal sans compte sandbox ». Les trois décisions du parcours étaient
déjà **sorties de StoreKit et déjà sous test** : `Entitlement` (8 cas), `OfferCodeOutcome` (6 cas),
`RestoreOutcome` (7 cas). Il ne manquait que la frontière StoreKit elle-même, qui ne se teste pas
sans configuration `.storekit` et `StoreKitTest`.

Mais en lisant le fichier pour l'écrire, une asymétrie à trente lignes d'écart.

### Le défaut

`applyRedemption(sheetFailed:)` attendait le droit d'accès jusqu'à 3,2 secondes, avec un
commentaire qui disait pourquoi : poser la question une seule fois « répondrait “rien” à quelqu'un
qui vient d'entrer un code parfaitement valide ».

`purchase(_:)`, trente lignes plus haut, la posait **une fois** :

```swift
await transaction.finish()
await refreshEntitlement()
return isSubscribed == true ? .subscribed : .failed
```

Cette ligne tombe après une transaction **vérifiée** et terminée — Apple a signé, l'argent est
engagé — et `Transaction.currentEntitlements` publie le droit quelques centaines de millisecondes
plus tard. Le paywall en tirait les trois pires conséquences possibles d'un coup :

1. le message **« L'achat n'a pas abouti. »** affiché à quelqu'un qui vient d'être débité ;
2. un `purchaseFailed` enregistré — donc un taux d'échec faux, qui pousserait à corriger du code
   qui marche, et la statistique qui devrait signaler le défaut est celle qu'il corrompt ;
3. l'écran laissé ouvert, bouton d'achat toujours actif. C'est exactement le raisonnement que le
   cas `.subscribed` du même fichier tient déjà pour expliquer pourquoi il ferme : « rien ne dit
   que ça a marché, et le geste naturel est de retaper ». Ici, retaper veut dire payer une
   seconde fois.

Le piège était donc **déjà connu, déjà documenté et déjà contourné** dans le même fichier. Deux
chemins, un seul corrigé. Et il ne se voit nulle part ailleurs que chez l'utilisatrice : dans un
simulateur, l'entitlement arrive instantanément.

### Ce qui a changé

| | Avant | Après |
| --- | --- | --- |
| Après une transaction vérifiée | une seule lecture du droit | l'attente bornée d'`attendreLeDroit()`, celle des codes promo |
| Droit pas encore publié | `.failed` → « L'achat n'a pas abouti. » | `.purchasedAwaitingUnlock` → « Paiement validé. Ton accès s'ouvre dans un instant. » |
| Statistique dans ce cas | `purchase_failed` | `purchase_completed`, avec `unlock: deferred` pour compter les fois où 3,2 s n'ont pas suffi |
| Écran | reste ouvert, bouton actif | se referme |
| Signature non vérifiée | indistincte d'un échec réseau | `.unverified`, et le droit tranche s'il est là |
| Où la décision vit | une ligne dans `SubscriptionService` | `PurchaseOutcome.decide`, pur, sans `import StoreKit` |
| L'attente | deux boucles jumelles, une seule corrigée | une fonction, `attendreLeDroit()`, appelée par les deux |

Le droit d'accès n'est **pas** mis à vrai à l'achat, et ce n'est pas un oubli : `refreshEntitlement`
reste la seule source, relue de `currentEntitlements`, pour qu'un remboursement referme l'accès.
Seul le message change.

Une annulation reste une annulation, même chez quelqu'un d'abonné par ailleurs. La règle « le droit
d'abord » de `RestoreOutcome` et `OfferCodeOutcome` ne s'applique qu'aux cas où StoreKit doute :
là-bas on **cherche** un droit, ici StoreKit parle d'un achat précis et il est formel. Confondre les
deux ferait compter une annulation comme une vente — c'est-à-dire fausserait la seule mesure qui
dise si le prix est le problème.

### Ce qui le garde

`HaizoTests/PurchaseOutcomeTests.swift`, 10 cas, dont le premier est le défaut lui-même : une
transaction vérifiée sans droit n'est jamais un échec, et son message n'est jamais celui de
l'échec.

`ci_scripts/check_paiement.py` et ses **16 cas**. Trois règles : une fonction qui rend une issue de
paiement n'a droit qu'à **un seul `return`**, et il appelle `<Issue>.decide(` ; chaque issue vit
dans `Haizo/Models/`, sans `import StoreKit`, avec son fichier de cas ; et **chaque cas de chaque
issue est nommé dans ses cas de test** — ajouter une issue sans la vérifier rouvrirait le trou par
le haut.

Trois des seize cas ne vérifient qu'une chose : comment ce contrôle pourrait passer vert pour la
mauvaise raison. Une signature reformatée et il ne reconnaît plus rien ; un `case a, b, c` sur une
ligne et il laisse passer trois cas d'un coup ; une énumération déplacée et il félicite une liste
vide. Il le dit dans les trois cas. Le quatrième a servi tout de suite : il comptait les six
entrées de `StoreKitResult` parmi les issues, 17 au lieu de 11, et aurait exigé qu'on « teste » des
entrées comme si c'étaient des réponses.

La nouvelle phrase est au catalogue dans les trois langues.

## Chantier 27 — soixante secondes de roue qui tourne (A3)

### L'item était mal posé, pour la troisième fois

`PHASE2.md` disait « le mode hors ligne et la connexion lente ne sont pas éprouvés ». La moitié
était fausse :

- **`PanneReseau`** classe les pannes, rend la bonne phrase, et `check_reseau.py` interdit à un
  écran d'affirmer une panne de réseau de son propre chef. **7 tests.**
- **`ClubActivityOutbox`** garde une sortie publiée hors réseau, le serveur l'accepte sans doublon
  (`ON CONFLICT (client_id) DO NOTHING`), la file est **attachée au compte** — terminer une course
  en mode avion puis connecter un autre compte ne publie plus la course de la première sur le fil
  de la seconde — et son `Codable` survit à une clé manquante. **4 tests.**

Le hors-ligne est donc traité, et mieux que je ne l'avais écrit. **La latence, elle, ne l'était
pas du tout.**

### Ce que la mesure a donné

**Aucun délai d'expiration n'était déclaré nulle part.** Les douze requêtes du dépôt partaient sur
`URLSession.shared` avec les valeurs d'Apple : **soixante secondes** par requête.

Soixante secondes de roue qui tourne, c'est une app cassée. `PanneReseau` savait écrire la bonne
phrase — elle arrivait une minute après que la personne avait compris toute seule.

Et ça ne se voit **jamais** en développement. Aller-retour réel sur notre API, `GET /api/me`, cinq
fois depuis une machine filaire le 10 novembre 2026 : **0,17 à 0,51 seconde**. Le défaut n'existe
que chez quelqu'un dans un train.

### Les chiffres sont mesurés, pas choisis

| | | pourquoi |
| --- | --- | --- |
| `interactif` | **15 s** | Trente fois le temps mesuré, cinq fois un mauvais aller-retour mobile qui FONCTIONNE. Le quart du défaut d'Apple. |
| `coach` | **60 s** | Le seul appel où attendre est normal : on vient de poser une question et un modèle rédige. Le client n'a pas à renoncer avant le serveur. |
| `televersement` | **60 s** | Une photo de plusieurs méga-octets sur un réseau lent prend légitimement plus de quinze secondes, et l'abandonner oblige à tout recommencer. |
| `arrierePlan` | **20 s** | Personne ne regarde : événements d'usage, rapports de panne, inscription aux notifications. |

### Et ça ne perd rien — c'est pour ça qu'on peut être bref

Ce qui compte est **rejoué** : la sortie publiée attend dans l'outbox, les statistiques dans leur
tampon, les rapports de panne reviennent au lancement suivant. Abandonner vite ne jette rien — ça
remplace une minute de gel par une phrase honnête et un nouvel essai plus tard.

### Ce qui le garde

`ci_scripts/check_delais.py` : tout `URLRequest(` doit être suivi, dans les six lignes, d'un
`timeoutInterval` **pris dans `Delais`**. Un délai écrit en dur sonne aussi — douze requêtes,
douze occasions de diverger. 7 cas, dont celui du délai posé trop loin de l'appel : on le lit là
où on lit la requête, pas sept lignes plus bas.

## Chantier 26 — la voix dit enfin la séance (B2) — et elle la disait en français à tout le monde

### Ce que je cherchais

Face à Runna, le guidage vocal par intervalle est ce qui manquait : la voix ne disait que deux
choses — « accélère un peu », « ralentis légèrement ». Rien sur le départ d'une répétition, rien
sur sa fin.

### Ce que j'ai trouvé en ouvrant le fichier

**Les phrases existaient déjà.** `beginSegment` écrit depuis longtemps « Échauffement terminé.
Première répétition : vise 4:30/km, foulée relâchée », « Récupération — souffle, foulée
relâchée », « Dernière répétition faite, bien joué ». Elles étaient **affichées à l'écran**, et
jamais dites.

Une consigne de fractionné affichée sur un téléphone qu'on ne regarde pas — parce qu'on court —
n'a pas été donnée.

### Et un défaut plus grave, trouvé en passant

Ces quatre phrases étaient des **littéraux Swift nus** passés à `showCue(_ message: String)`. Un
`String` n'interroge jamais le catalogue : **elles sortaient en français chez tout le monde**, au
départ de chaque répétition, sur l'écran le plus important de l'app.

Et les quatre clés étaient au catalogue, **traduites dans les trois langues**, depuis longtemps.
Quelqu'un avait fait le travail, et le paramètre le jetait. Soixante lignes plus bas dans le même
fichier, la consigne de pause automatique passe correctement par `String(localized:)`.

C'est le même défaut que la montre, au même endroit du produit : une traduction qui existe et que
personne ne demande.

### Pourquoi aucun des six contrôles ne le voyait

`check_strings.py` porte **six** règles pour six angles morts, chacune avec son histoire. Aucune
ne couvrait celui-ci : `showCue("…")` n'est ni `String(localized:)`, ni `Text("…")`, ni un
initialiseur de composant, ni un paramètre déclaré `LocalizedStringKey`. C'est un `String` nu, et
le type ne dit rien.

**La septième règle est donc NOMMÉE, pas devinée.** On ne peut pas décider par le type qu'un
`String` finira à l'écran : il faut le savoir. `PUITS` liste les fonctions dont on sait que
l'argument est affiché. Y ajouter une fonction est une décision — une règle qui devinerait
signalerait la moitié du dépôt.

Elle lit l'argument complet, parenthèses équilibrées, donc **les deux branches d'un ternaire** :
c'est exactement la forme qu'avait le défaut. Cinq cas, dont celui qui dit qu'un littéral passé à
une autre fonction n'est pas concerné.

### Ce qui change pour quelqu'un qui court

| | Avant | Après |
| --- | --- | --- |
| Départ d'une répétition | écrit à l'écran, en français | **dit à voix haute**, dans sa langue |
| Récupération | idem | idem |
| Fin de la dernière répétition | idem | idem |
| Sur un vélo | les consignes de course s'affichaient quand même | silence — `suitLePlan` les coupe |
| Le réglage | « Alertes vocales d'allure » | « Consignes vocales » — une seule question : le coach parle-t-il ? |

Un seul interrupteur, et c'est voulu : deux réglages pour deux sortes de phrases auraient demandé
à quelqu'un de deviner laquelle il voulait taire.

### Et une tolérance qui a dérivé avec le texte

`check_pluriel.py` tolère `n == 1` dans ce fichier — « ce n'est pas un singulier contre un
pluriel, c'est la première répétition contre les suivantes ». La tolérance s'accroche au TEXTE de
la ligne, pour ne pas dériver avec les numéros ; la ligne a été réécrite, donc elle a dérivé avec
le texte. C'est le prix de ce choix, et c'est le bon : une tolérance qui survit à une réécriture
couvrirait une ligne que plus personne n'a relue.

## Chantier 25 — l'état vide, écrit une fois (A5)

Règle 3 : chaque écran a ses états vide, erreur et chargement. Règle 4 : rien ne s'écrit deux
fois. Ici la seconde perdait — « Aucun composant d'état vide partagé. Zéro fichier ne porte un
`RUEmpty`. Chaque écran écrit le sien. »

### Ils divergeaient, et pas qu'un peu

Trois écrans pris au hasard, pour la même phrase — « il n'y a rien ici » :

| | couleur | interligne | marges |
| --- | --- | --- | --- |
| `FriendsView` | `text3` | 3 | verticale 6, puis 18 ailleurs |
| `HistoryView` | **`text2`** | aucun | horizontale de page |
| `ShoesView` | **`text2`** | 3 | haute 4 |

Deux couleurs de texte différentes pour dire la même chose : c'est la définition d'un système de
design qui ne couvre pas un cas.

### `RUEmpty`, et deux formes dont le choix n'est pas esthétique

**`.bloc`** occupe la place d'un contenu absent : icône, titre, une phrase, éventuellement un
bouton. C'est la forme d'un **écran** vide — l'historique sans course, le carnet sans paire, la
carte sans parcours.

**`.ligne`** ne pose qu'une phrase, parce que la section a déjà son en-tête et que lui ajouter un
titre le redirait. C'est la forme d'une **section** vide dans un écran qui, lui, a du contenu.

Remplacer une ligne par un bloc change la mise en page d'un écran qui marchait : le bloc se
réserve aux endroits où il n'y a vraiment rien d'autre. C'est pourquoi le balayage n'a pas tout
converti d'un coup.

### Ce qui est converti

| écran | forme | ce qui change |
| --- | --- | --- |
| `HistoryView` | `.bloc` | icône + titre, et une phrase réécrite |
| `ShoesView` | `.bloc` | idem |
| `HeatmapView` | `.bloc` | idem |
| `FriendsView` ×2 | `.ligne` | la couleur et l'interligne deviennent ceux du système |
| `ClubEventsSection` | `.ligne` | idem |

### Ce qu'il n'est pas, et c'est écrit dans le fichier

Ni un état d'erreur, ni un état de chargement. « Rien à montrer » et « ça n'a pas marché » sont
deux phrases différentes, et les confondre fait dire « aucune course » à quelqu'un dont la
requête vient d'échouer.

### Ce qui reste

Sept écrans portent encore une phrase d'état vide écrite à la main, toutes dans des sections où
le `.ligne` conviendrait. Elles ne divergent plus que par leurs marges, et les convertir une à
une demande d'ouvrir chaque écran pour vérifier que la mise en page ne bouge pas. À finir.

## Chantier 24 — le consentement aux statistiques d'usage (A2)

Le point que l'audit appelait « le plus discutable du produit » : « Aucun écran ne présente un
consentement explicite et révocable aux statistiques d'usage. La politique les décrit ; l'app ne
les propose pas à refuser. »

### Le problème que le dessin devait résoudre

Les événements de l'inscription sont enregistrés **depuis le premier écran** — c'est l'entonnoir,
et il n'a de sens que complet. Poser la question à la première seconde, avant d'avoir dit ce que
l'app fait, serait impoli et inutile : personne ne décide de ça devant un écran vide. Mais tout
envoyer d'abord et demander ensuite n'est pas un consentement.

### La réponse : trois états, et un tampon

`Analytics` a maintenant un consentement à **trois** états, et c'est le troisième qui résout tout :

| état | on enregistre | on envoie |
| --- | --- | --- |
| `pasDemande` | oui, dans le tampon | **non** |
| `accepte` | oui | oui — et ce qui était gardé part |
| `refuse` | **non**, et le tampon est vidé | non |

Un oui expédie ce qui attendait ; un non le **jette**. Rien ne part avant la réponse, et
l'entonnoir reste mesurable pour qui accepte.

La garde tient en deux lignes parce que le fichier était bien fait : `track`, `trackOnce` et
`trackAppOpenedIfNewSession` passent **tous les trois** par `enqueue`, et `sendNextBatch` est le
seul point d'envoi. C'est là que vivait déjà la garde du mode démonstration.

**Un refus n'enregistre même plus.** Fermer l'envoi suffirait à tenir la promesse — mais accumuler
dans un tampon des événements qu'on s'est engagé à ne jamais envoyer, c'est garder la chose tout
en disant qu'on ne la prend pas.

### Où la question est posée

**Étape 8 de l'inscription**, juste avant la connexion à Santé — pour que « CRÉER MON PLAN » reste
le dernier geste : un bouton qui annonce la fin ne peut pas être suivi d'un écran de plus.

**Deux boutons, et aucun n'est le défaut.** Pas de case pré-cochée, pas de « Continuer » qui vaut
oui. L'écran dit ce qui est mesuré (douze moments du parcours), ce qui ne l'est jamais (ce qu'on
écrit, la position, Apple Santé), et qu'on peut changer d'avis.

**Et révocable** : Profil → Réglages → Confidentialité. Sans ça ce n'est pas un consentement.

### Ce que l'insertion a fait tomber, et c'était voulu

Deux tests Swift pinaient la longueur de l'inscription, avec ce commentaire : « Si ça tombe en
rouge, c'est qu'une étape a été ajoutée ou retirée. » Ils sont tombés en rouge. Mis à jour : neuf
écrans de questions deviennent dix, et la phrase « plus que N écrans » compte cinq au lieu de
quatre.

### Et un nombre recopié que rien ne surveillait

**Neuf écrans écrivent leur numéro d'étape EN DUR dans leur titre** — « Étape 6 · ton rythme ».
Rien ne les reliait à leur place réelle. En insérant le consentement, `HealthConnect` est passée
de 8 à 9 et son sourcil annonçait toujours « Étape 8 » : le numéro que lit la personne qui
s'inscrit.

C'est exactement le défaut que `check_etapes.py` existait pour empêcher — « c'est le propre d'un
nombre recopié », dit son en-tête — mais il ne regardait que la logique, pas l'écran. Il compare
maintenant le numéro du sourcil à celui du `switch`. Un écran qui n'annonce aucun numéro n'est pas
concerné : ne rien dire n'est pas se tromper. Quatre cas de plus, 14 au total.

### Ce qui reste, et qui ne peut pas se faire d'ici

`privacy.html` décrit les statistiques mais ne dit pas qu'on peut les refuser. L'ajouter ferait
rougir `check_politique.py --exiger` jusqu'à ce que la page soit portée sur `main` — et son
en-tête met en garde contre exactement ça : « une chaîne rouge pendant des jours pour une action
qu'elle ne peut pas faire apprend à ignorer un rouge ». La phrase est donc à ajouter **et** à
porter dans le même geste.

## Chantier 23 — les trois portes juridiques (A6, A7, A8)

### A6 — un commentaire faux dans une déclaration légale

`PrivacyInfo.xcprivacy` portait un `TODO(privacy)` affirmant que la phase du cycle « part sans que
le réglage correspondant ne mentionne aucune transmission ». C'était vrai quand la phrase a été
écrite ; ça a cessé de l'être, et personne n'est revenu — **exactement le défaut contre lequel
l'en-tête de ce même fichier met en garde**, et qu'il avait déjà commis sur la localisation.

Mesuré dans `MoreSettingsView` le 10 novembre : `shareCyclePhaseWithCoach` est un réglage
**distinct** du suivi du cycle, **à l'arrêt par défaut**, dont le texte affiché **nomme le
destinataire comme un service extérieur** et précise que refuser ne change rien au programme —
« le calcul se fait sur ton téléphone ». C'est un consentement explicite, spécifique, séparé et
révocable : l'article 9 est satisfait, et il l'était déjà.

L'entrée `NSPrivacyCollectedDataTypeHealth` reste, et elle doit rester : quand la case est cochée,
la donnée part réellement.

### A7 — le manifeste de la montre : mesuré, plus deviné

Je refusais de trancher faute de source. La documentation d'Apple ne traite pas le cas d'un paquet
watchOS imbriqué et les sources publiques se contredisent. **Mais la validation d'Apple répond
elle-même** — c'est elle qui émet ITMS-91053. Journal d'archive du 10 novembre, Xcode 26.6 :

```
ValidateEmbeddedBinary …/Haizo.app/Watch/HaizoWatch.app
"com.hicsuntco.runup.watchkitapp" => "Haizo CI montre"
No errors uploading archive at '…/Haizo.ipa'.
UPLOAD SUCCEEDED with no errors
```

Un paquet contenant la montre **sans manifeste** passe la validation sans une erreur. Et c'est
cohérent avec la règle : ITMS-91053 s'appelle « Missing API declaration » et se déclenche sur
l'**usage** d'une API à motif obligatoire. `HaizoWatch` n'en appelle aucune.

**Ce qui rendrait la réponse fausse tient en une ligne** : un `UserDefaults` écrit dans la montre
pour y garder un réglage. Elle compile, les tests passent, et le refus tombe **à l'envoi**, après
quinze minutes d'archive.

`ci_scripts/check_manifeste.py` ferme la porte : pour chaque cible livrée, il compare les API à
motif obligatoire qu'elle appelle — les cinq familles d'Apple — et le manifeste qu'elle embarque.
Éprouvé en vrai : une ligne `UserDefaults` ajoutée à `WatchViews.swift` le fait sonner, en nommant
la catégorie à déclarer et le fichier fautif. 10 cas.

### A8 — l'item était mal posé, et la moitié était déjà faite

`check_politique.py` **va chercher la page publiée EN LIGNE** et compare le texte de chaque
section, commentaires ignorés, avec `--exiger` dans `server.yml`. C'est mieux que le garde-fou que
j'avais proposé dans `PHASE2.md`, et ça existait avant.

Et l'item parlait des « deux pages qu'Apple affiche ». **Il n'y en a qu'une.** Mesuré :

| | |
| --- | --- |
| URL de politique sur la fiche | `https://hicsuntco.github.io/Haizo/privacy.html` |
| URL de support sur la fiche | `mailto:charlottegrudep@gmail.com` |
| Dans l'app, « nous contacter » | le même `mailto:`, à deux endroits |
| Ce qui pointe vers `support.html` | **rien** |

`support.html` est publiée sur GitHub Pages et personne ne l'atteint. Quatre documents du dépôt —
`AUDIT.md`, `RELEASE.md`, `PROGRESS.md`, `PHASE2.md` — affirmaient le contraire. Corrigés.

**Ce qui reste, et c'est une décision de fiche, pas de code** : en faire la vraie URL de support,
ou la supprimer. Une page se corrige sans passer par une revue ; un `mailto:` non.

### Et une règle 4 réparée au passage

`sans_commentaires` — la fonction qui décide ce qu'un contrôle VOIT dans du Swift — existait en
deux copies, et `check_manifeste.py` allait en écrire une troisième. Trois copies, trois façons de
diverger sur ce qui est vu. Elle vit maintenant dans `ci_scripts/swift.py`, et les trois
l'importent.

## Chantier 22 — le fond clair devient le défaut (D2)

### Le sombre n'avait jamais été choisi

`ThemeStore` lisait `UserDefaults.bool(forKey:)`, qui rend **`false` quand la clé est absente**.
Et `UserProfile.isLightMode` valait `false`, la valeur qu'une propriété booléenne prend quand
personne ne se prononce. Le thème sombre par défaut tombait donc de deux API, pas d'une décision.

### Quatre endroits décidaient, et il fallait les quatre

| Où | Quand ça décide | Avant | Après |
| --- | --- | --- | --- |
| `UserProfile.isLightMode` | un profil neuf | `false` | **`true`** |
| `ThemeStore.init` | tout premier lancement, avant qu'un profil existe | `d.bool(forKey:)` → `false` | `d.object(forKey:) as? Bool ?? true` |
| `DailyGoalsSnapshot.empty` | le widget avant que l'app ait jamais publié | `false` | **`true`** |
| L'aperçu de la galerie de widgets | la galerie | `false` | **`true`** |

N'en changer que deux aurait donné un widget sombre à côté d'une app claire — exactement la
famille de défauts que ce dépôt passe sa semaine à trouver.

### Le seul endroit qui reste à `false`, et c'est voulu

Le décodage d'un instantané de widget qui n'a pas la clé : `?? false`. Un instantané sans cette
clé a été écrit par une version de l'app ANTÉRIEURE à la clé, donc par quelqu'un qui a déjà un
profil — et un profil déjà enregistré reste en sombre. Mettre `true` là afficherait un widget
clair à côté d'une app sombre, le temps d'un lancement.

### CE QUE ÇA NE FAIT PAS, ET JE L'AI DIT TROP VITE LA PREMIÈRE FOIS

J'avais annoncé qu'on pourrait distinguer « n'a jamais touché le réglage » de « a choisi le
sombre », en regardant si la clé `apparence.clair.v1` existe dans les préférences. **C'est faux.**
`AppState` appelle `ThemeStore.appliquer(...)` à CHAQUE lancement pour synchroniser depuis le
profil, donc la clé est écrite pour tout le monde, dès la première ouverture.

Rien dans l'app n'enregistre si quelqu'un a choisi son thème. Les deux cas sont stockés à
l'identique, `isLightMode = false`. Il n'y a donc aucune façon honnête de retourner l'app de
quelqu'un sans risquer de retourner celle d'une personne qui avait décidé.

**Conséquence, et elle compte : les comptes existants ne changent pas.** Le clair est le défaut
des INSTALLATIONS NEUVES. Sur un téléphone qui a déjà l'app, rien ne bouge — il faut passer par
Profil → Apparence.

### Et la fiche App Store était déjà claire

`screenshots.py` compose à partir de `appstore/raw/<langue>/clair/` : **la passe claire livre la
fiche, la passe sombre sert au diagnostic.** Le magasin montrait donc du clair pendant que l'app
ouvrait en sombre. Cette décision referme cet écart au lieu d'en ouvrir un.

### Ce que la bascule a fait rougir, et pourquoi c'était juste

`check_banniere.py` a refusé la chaîne sur `diagnostic/inscription.png`, **88,7 % de pixels clairs
en haut dans les trois langues**, là où le plafond est à 25 %.

Ce n'était pas une bannière du système. Le contrôle mesure la clarté du haut de l'écran et suppose
que tout ce qui n'est pas dans `clair/` est sombre. Or l'écran d'inscription est photographié
**sans aucune graine** — `CapturesUITests` l'écrit : « aucune graine n'est posée : `onboarded`
vaut `false` à la création, donc l'app ouvre sur l'inscription d'elle-même ». Sans profil, il n'y
a pas d'`isLightMode` à appliquer : l'écran prend le défaut d'amorçage, désormais clair.

**L'app obéissait, et le garde-fou l'a accusée.** Il apprend donc que l'inscription précède le
profil, et la raison est écrite dans son en-tête.

Son message disait aussi « relancer la chaîne suffit : la bannière est une affaire de minutage ».
Ici, relancer n'aurait rien changé, et le tell était dans le relevé lui-même : **la même image, à
88,7 %, trois fois.** Une bannière ne tombe pas trois fois sur la même image au même pourcentage.
Le message le dit maintenant tout seul quand il voit ce motif.

Trois cas de plus dans `test_banniere.py` : l'inscription sort du relevé, une vraie bannière sur
un AUTRE écran sonne toujours, et le message reconnaît les trois langues. 11 cas.

### Et l'écran, regardé

L'inscription s'ouvre en clair — c'est le premier écran que voit quelqu'un, et c'est celui dont la
décision change le plus. La séance en cours, elle, reste sombre comme prévu : son jeu de jetons
`Ink` ne suit pas le thème, et c'est voulu.

## Chantier 21 — l'image iPad n'aurait jamais dû exister, et c'est moi qui l'avais fabriquée

### Ce que Charlotte a dit

« L'app iPad doit être différente, on ne va pas courir avec son iPad. »

### Ce que la mesure a donné

`TARGETED_DEVICE_FAMILY` vaut **1** dans les réglages de base comme dans ceux du widget ; seule la
montre porte 4. **Haizo est une app iPhone**, et Apple ne demande donc aucune image d'iPad.

Et le dépôt le savait. `RELEASE.md` portait déjà cette phrase, mot pour mot :

> « L'iPad, lui, ne pose pas la question — `TARGETED_DEVICE_FAMILY` vaut 1 […], donc Haizo est une
> app iPhone et Apple ne demande aucune image d'iPad. »

Et `asc.py` porte une commande écrite exprès pour la **retirer** de la fiche, dont le commentaire
dit : « une mise en page iPhone étirée dans un cadre d'iPad sur une app qui ne vise que l'iPhone.
Ces images ne se corrigent pas, elles se retirent. »

**J'ai passé deux jours à fabriquer, garder et rafraîchir une image que le dépôt avait déjà
décidé de supprimer.** Je l'ai régénérée deux fois, j'ai ajouté une exception au `.gitignore`
pour la nourrir, j'ai cassé un clone neuf en le faisant, et j'ai ouvert une tâche pour résoudre
structurellement un problème qui n'existait pas. Aucun de mes garde-fous ne pouvait l'attraper :
ils vérifient qu'une image est à jour, pas qu'elle a lieu d'être.

### Ce qui a changé

| | Avant | Après |
| --- | --- | --- |
| `requis.py` | composait une image iPad (fond, accroche, cadre d'appareil, filets) et posait la montre | pose la montre, c'est tout — **160 lignes de moins, et plus de dépendance à Pillow** |
| `appstore/requis/ipad/` | trois images versionnées | supprimé |
| `appstore/raw/*/1-accueil.png` | trois captures versionnées contre la règle du `.gitignore` | supprimées, la règle redevient simple |
| Exception du `.gitignore` | ajoutée la veille pour nourrir la composition | retirée, elle aura vécu vingt-quatre heures |
| `appstore.yml` | une action `pousser-l-ipad` | retirée |
| `captures.yml` | composait l'iPad à chaque passage | ne compose plus rien, vérifie la montre |
| `SOURCES.json` | 6 entrées | 3 |

### Ce qui reste à faire UNE FOIS, à la main

La fiche publiée porte encore la capture iPad d'août — App Store Connect recopie les captures de
la version précédente, tous formats confondus. Workflow **App Store**, action
**`nettoyer-les-captures`**, champ « retirer » : **`APP_IPAD_PRO_3GEN_129`**.

Et elle reviendra à chaque nouvelle version tant qu'on ne la retire pas. C'est écrit dans
`RELEASE.md`.

### La question produit, qui reste ouverte

S'il devait y avoir une app iPad un jour, ce ne serait pas la même app : pas d'écran de séance en
cours, mais le plan, les stats, le fil du club, le coach. C'est un chantier à part entière et il
n'est pas dans la liste de la phase 2 — à y ajouter si tu le veux.

## Chantier 20 — le verre dépoli sort de l'interface

La seconde moitié de la règle 7, et l'inverse du chantier 19 : **aucun jeton ne distribuait le
verre dépoli**. Chaque écran écrivait `.ultraThinMaterial` à la main. Douze emplois dans sept
fichiers, donc douze décisions, lues une par une.

### Ce que la lecture a montré

**Quatre d'entre eux ne floutaient presque rien.** La barre d'onglets empilait un
`.ultraThinMaterial` à 90 % **devant** une carte à 92 % en clair : le flou ne captait que **8 %**
de la page. Le sélecteur de discipline faisait pareil deux fois, devant une carte à 96 % — donc
4 %. Une couche de composition de plus sur l'écran le plus vu de l'app, pour un effet que personne
ne peut nommer.

**Trois autres étaient posés sur une carte MapKit**, et leur contraste dépendait donc de ce qui
défilait dessous. La bulle du coach portait **quinze lignes d'arithmétique** pour cette seule
raison : il avait fallu monter son fond à 92 % d'opacité pour que le sourcil « Coach · en direct »
tienne 4,5:1 au-dessus d'une carte claire.

### Ce qui a changé

| | Avant | Après |
| --- | --- | --- |
| Barre d'onglets | verre 90 % devant `card` 92 % | `card`, opaque |
| Sélecteur de discipline (libellé et rond inactif) | verre 90 % devant `card` 96 % | `card`, opaque |
| Décompte de départ | `.ultraThinMaterial` + un `colorScheme` posé à la main pour le forcer en sombre | `Ink.ecran`, opaque |
| Pastille d'état de la séance | teinte d'accent sur du verre — elle changeait de couleur selon la carte dessous | la même teinte sur `Ink.fond` |
| Bandeau de consigne | blanc 9 % sur du verre | blanc 9 % sur `Ink.fond` |
| **Bulle du coach** | `Ink.fond` à 92 % + verre, et quinze lignes pour justifier le 92 | `Ink.fond` opaque, et l'arithmétique disparaît |
| Bouton « agrandir le tracé » | verre sur le tracé | `card` |
| Tracé plein écran : carte d'infos et croix | verre sur MapKit | `card` |
| Retour posé sur une image | verre sous un noir à 45 % | un noir **opaque à 55 %**, calculé |
| Barre d'écriture des commentaires | verre | `card` |

### Deux chiffres, calculés et pas choisis

**La bulle du coach.** Avec un fond opaque, le contraste du sourcil ne dépend plus de la carte.
Les huit palettes, mesurées sur `Ink.fond` (#0E0E14) : rose **6,24:1**, violet 7,13, magenta 7,80,
corail 8,94, bleu 9,51, ambre 13,41, cyan 14,15, lime 17,24. La plus basse gagne **un point
entier** sur ce qu'elle valait à 92 % d'opacité, et aucune ne bouge plus quand la carte défile.

**Le retour posé sur une image.** Le pire cas est une image BLANCHE. À l'ancien noir de 45 %, le
fond composé vaut 0,55 et le chevron blanc n'y tient que **3,35:1** — au-dessus du seuil des
icônes, sous celui du texte courant, et c'est le verre qui rattrapait la différence. À **55 %**,
le fond vaut 0,45 et le chevron tient **4,76:1**. Sur une image sombre, le disque ne peut
qu'améliorer : jusqu'à 21:1.

### Deux noms qui mentaient

`FrostedBackButton` est devenu `OverImageBackButton` — il n'a plus rien de dépoli. Et l'en-tête de
`TabBarView` annonçait « Floating frosted-glass tab bar » : elle ne l'est plus.

### Ce qui le garde

`ci_scripts/check_verre.py`, même forme que `check_degrade.py` : un compte par fichier contre une
liste d'exceptions qui porte chacune sa raison. **La liste est vide, et c'est l'état qu'on veut.**
Elle existe pour qu'une exception future soit écrite avec sa raison plutôt que glissée dans un
écran — et la question à laquelle il faudra répondre est « qu'est-ce qu'un flou fait ici qu'un
aplat ne ferait pas ». Dans les douze cas de ce dépôt, la réponse était « rien ».

Sur le dépôt d'avant : **7 fichiers, 12 verres**. Après : zéro.

`test_verre.py`, 18 cas. Deux disent ce qui n'est PAS un verre dépoli — `chart.bar.fill` et
`RUSpacing.tabBarHeight` — parce que `.bar` EST un `Material` de SwiftUI et qu'une expression trop
large bloquerait le dépôt sur un nom d'icône. Un garde-fou qui refuse un nom de symbole finit par
être désactivé.

## Chantier 19 — le dégradé sort de l'interface

Premier chantier de la phase 3, et c'est le système de design — le brief l'impose, et la mesure
dit pourquoi il avait raison.

### Ce qui était faux

Vingt-quatre fichiers portaient un dégradé. **Personne n'avait mal travaillé** : `AccentTheme`
donne à chaque palette une couleur de queue (`tail`), et `RUColor` exposait `accentGradient`
(rose2 → rose), `violetRoseGradient` (violet → rose), `heroGradient` et `traceBackground`. Les
écrans appelaient le système de design, exactement comme il faut. **C'est le système qui
distribuait le dégradé.**

Corriger les écrans sans corriger les jetons aurait tenu une semaine.

### Ce qui a changé

| | Avant | Après |
| --- | --- | --- |
| `accentGradient` (rose2 → rose) | 7 appels : bouton principal, pastilles, sélecteurs, avatar, carte du fil, paywall | supprimé — `RUColor.rose`, un aplat |
| `violetRoseGradient` | pastille de niveau et jauge d'XP du club, bouton de l'abonnement | supprimé — `RUColor.violet` |
| `heroGradient` | lavis d'accent à 12 % descendant vers la carte, 11 cartes héros | `heroSurface`, un aplat à **6 %** — la moyenne du lavis qu'il remplace |
| `traceBackground` | vignette `#1A1926` → `#0E0D16` sous chaque tracé GPS | `#14131E`, le milieu exact des deux |
| `pageBackground` | un `LinearGradient` à deux arrêts identiques, « pour pouvoir y revenir un jour » | une `Color` — on n'y reviendra pas |
| Bouton RUN de la barre | dégradé rose2 → rose, au centre de tous les écrans | aplat d'accent |
| Bouton principal | dégradé en clair, aplat en sombre — **les deux thèmes ne montraient pas le même bouton** | aplat dans les deux |
| Nuancier de Profil → Apparence | pastilles `primary → tail` : on choisissait un dégradé et on recevait un aplat | la couleur qu'on choisit, et rien d'autre |
| Halo rose de l'onboarding | posé SOUS `pageBackground` dans le même `ZStack`, donc entièrement masqué — c'était noté, et laissé | parti |
| Panneau de commandes de la séance | dégradé `fond` 60 % → `fond` sur du verre dépoli | `Ink.fond`, la couleur que le jeu de jetons avait déjà pour ça |
| La montre | bouton de départ, anneau pointillé et deux anneaux de progression en rose → violet | aplat d'accent |
| `LinearBar.gradient` | un paramètre, trois appelants | supprimé |

**Le panneau de la séance est le seul endroit où je m'étais trompé en classant.** Je l'avais rangé
dans « voile de lisibilité », sans regarder. C'est le fond d'un panneau, et `Ink.fond` existait
depuis longtemps pour ça — « le fond des surfaces de cet écran », un cran au-dessus de `Ink.ecran`.
Le verre dépoli part avec : il n'était visible qu'à travers les 60 % du haut du dégradé.

### Ce qui reste, et pourquoi

Treize dégradés dans dix fichiers, chacun avec sa raison écrite dans `check_degrade.py`. La règle
appliquée n'est pas « aucun dégradé » mais celle-ci :

> Un dégradé est interdit comme **décoration** d'un écran. Il reste permis quand il **porte une
> information**, quand il **rend lisible**, ou quand il appartient à une **image produite**.

- **La marque** : `brandGradient`, l'icône, le splash et le logo. C'est ce que la DA autorise.
- **Une image produite** : les cartes de partage, les images de vidéo, l'avatar fabriqué pour
  quelqu'un qui n'a pas mis de photo.
- **Un voile qui sert à lire** : le noir sous le texte posé sur un tracé GPS, le fondu en bas du
  défilement du récap.
- **La couleur qui porte une information** : l'anneau des objectifs du jour, dont chaque arc vire
  vers la couleur de son **voisin** pour que les deux se rejoignent dans la même teinte et que
  l'anneau se lise comme un seul ruban ; et l'aire sous une courbe, qui s'efface vers le bas parce
  que c'est la convention de lecture d'un graphe.

### Ce qui le garde

`ci_scripts/check_degrade.py` compte les dégradés **par fichier**, contre une liste d'exceptions
qui porte chacune sa raison. Un de plus, un de moins, ou un fichier qui n'en porte plus aucun mais
reste dans la liste : il parle dans les trois cas. Sur le dépôt d'avant il sort **13 plaintes** ;
sur celui d'après, zéro.

`test_degrade.py`, 16 cas. Cinq disent qu'un dégradé **nommé dans un commentaire** ne compte pas —
sans eux, le garde-fou refuserait un fichier pour la phrase qui raconte sa correction, et la
moitié des fichiers de ce chantier en portent une. Un cas a trouvé une exception dont la raison
tenait en une ligne : c'était le panneau de la séance, mal classé.

Et l'expression de recherche avait une faute, trouvée en écrivant ses cas : une anti-recherche
arrière excluait `Color.rose.gradient`, c'est-à-dire exactement le raccourci qu'elle devait voir.

### Ce que ça invalide, et qui n'est pas encore refait

**Toutes les captures de l'App Store.** `check_requis.py` l'a dit tout seul dès que le code a
changé — « le code a changé : fa665226059b → 3dd86db7a0dc » sur les trois images de montre. Les six
captures iPhone montrent le même dégradé sur le bouton RUN, les pastilles et les boutons.

Ce chantier n'est donc **pas terminé** tant que les deux chaînes n'ont pas rephotographié l'app et
que les images ne sont pas versées. C'est la seule raison pour laquelle `tout.sh` n'est pas vert
à ce commit, et c'est un garde-fou qui fait son travail, pas un défaut.

### Ce que la chaîne a rendu, et ce qu'elle a fait trouver

Les trois chaînes sur `e594cae`. « Capture de la montre » verte, « Captures App Store » verte —
**donc l'app iPhone compile**, puisque cette chaîne la construit et la pilote sur simulateur. Et
« TestFlight » rouge, arrêtée AVANT la compilation par le garde-fou des captures périmées, ce qui
est exactement son travail.

Les six captures iPhone, la montre et l'iPad sont refaites et versées. Le bouton RUN de la barre
d'onglets, photographié avant et après : un dégradé vertical avec un halo, puis un aplat d'accent.

**Et en vérifiant d'où venaient ces images, j'ai trouvé plus gros que le chantier.**

### L'image iPad de l'App Store était composée d'une capture du 30 août

`appstore/raw/fr-FR/1-accueil.png` porte la mention `36ed586 — 2026-08-30 — « Add files via
upload »` : quatre captures déposées à la main, en français seulement, jamais revues depuis.
`requis.py` compose l'image iPad À PARTIR DE CE FICHIER, et `appstore.yml` la pousse chez Apple
DEPUIS LE DÉPÔT (`--dir appstore/requis/ipad`), pas depuis l'artéfact.

Donc la fiche App Store montrait, sur iPad, l'app telle qu'elle était il y a trois mois.

**Et le garde-fou écrit ce matin ne pouvait pas le voir.** `check_requis.py` vérifie que l'image
livrée est cohérente AVEC SA SOURCE — pas que la source est fraîche. L'entrée iPad n'avait même
pas d'`empreinte_code`, contrairement aux trois de la montre : un changement de code ne
l'invalidait donc pas. L'image était parfaitement conforme à une capture périmée.

Les captures iPhone, elles, n'ont jamais eu ce problème : `appstore.yml` va les chercher dans
l'artéfact de la dernière exécution réussie de `captures.yml`. C'est le bon mécanisme — et c'est
celui que l'iPad n'avait pas.

**Corrigé ici** : les trois `1-accueil.png` de l'artéfact d'aujourd'hui remplacent la capture
d'août, les trois autres fichiers d'août sont supprimés (rien ne les lisait, et ils avaient déjà
provoqué un `file exists` à l'extraction — c'est écrit dans `appstore.yml`), et l'image iPad existe
pour la première fois **dans les trois langues** au lieu du seul français.

### Ce qui reste ouvert, et que je n'ai pas fait

- **L'image iPad reste une copie versionnée**, donc elle redeviendra périmée au prochain chantier
  qui touche l'accueil. Le bon correctif est structurel : que `appstore.yml` aille la chercher dans
  l'artéfact, comme il le fait déjà pour les six captures iPhone. Un garde-fou de plus ne ferait
  que signaler plus tôt une copie qui n'a pas à exister.
- **Le verre dépoli.** Six fichiers portent encore un `Material`, dont la barre d'onglets
  (`.ultraThinMaterial`). La règle 7 l'interdit aussi. Celui-ci traitait le dégradé, et un
  chantier à la fois.
- **La phrase du bas de la montre n'est pas « coupée », elle est sous la ligne de flottaison.**
  L'écran est un `ScrollView` : le texte s'affiche entier si on fait défiler. Je l'avais annoncé
  comme une troncature, c'était faux, et ça change le correctif — ce n'est pas une réparation de
  mise en page mais un arbitrage de hiérarchie sur un écran de 46 mm.

## Chantier 18 — la montre et le widget parlaient français à tout le monde

### Ce qui était faux

`project.yml` déclarait, sur **trois cibles**, les polices et le catalogue de traductions sous une
clé `resources:`. **Cette clé n'existe pas dans XcodeGen.** `Docs/ProjectSpec.md` § Target ne la
liste pas parmi les clés d'une cible, `Target.init(jsonDictionary:)` n'a aucune branche pour elle,
et `SourceGenerator.getAllSourceFiles` ne regarde que `target.sources`. La valeur est lue puis
jetée, sans erreur ni avertissement — ticket XcodeGen #1645, ouvert (XcodeGen 2.46.0).

### Ce que ça coûtait, mesuré dans le paquet construit

Sonde de `HaizoWatch.app` (workflow « Capture de la montre », commit `5cadd52`) :

| attendu | présent |
| --- | --- |
| `fr.lproj`, `en.lproj`, `es.lproj` | oui |
| `Localizable.strings` dans chacun | **non, aucun** |
| `Inter-Medium/Bold/SemiBold.ttf` | **non, aucun** |

Donc, pour tout le monde et depuis le premier jour de la cible montre : **la montre parlait
français quelle que soit la langue du téléphone** — chaque `Text("Courir")` retombait sur sa clé,
qui est française et parfaitement lisible — et **elle s'affichait dans la police système, pas en
Inter**, malgré les trois fichiers enregistrés dans son `UIAppFonts`.

**Le widget de l'écran d'accueil avait le même défaut**, pour la même raison : ses deux ressources
partagées sont hors de `HaizoWidgets/`. « BOUCLÉS », « SÉANCE », « KCAL » en français chez une
anglophone, dans la police système, à côté d'une app correctement traduite. Celui-là n'était pas
cherché : c'est le garde-fou écrit pour la montre qui l'a nommé.

L'app iPhone n'a jamais été touchée : son unique entrée `sources: - path: Haizo` contient
`Haizo/Resources/`. Sa clé `resources:` ne faisait rien non plus, elle redéclarait ce qui entrait
déjà — **retirer cette clé ne peut donc pas changer le binaire iPhone**.

### Pourquoi rien ne l'a signalé

Le build était vert : aucune ressource ne manque à la compilation. `check_fonts.py` était vert, et
il avait raison de l'être — il compare le code, l'`UIAppFonts` et les noms PostScript des fichiers ;
« livrée » y veut dire « le fichier existe dans `Haizo/Resources/Fonts` », jamais « la cible
l'embarque ». Les captures de la montre montraient un écran français, qu'on prenait pour la capture
française. Et le commentaire de `project.yml` disait la chose **au passé** : « sans lui, la montre
restait entièrement en français » — une correction qui n'avait jamais eu lieu.

**Ma première sonde m'a fait annoncer le contraire.** Elle vérifiait que les trois dossiers `.lproj`
existaient. Ils existaient. J'ai conclu que le paquet allait bien, et je l'ai écrit. La seconde a
regardé dedans : rien. J'avais mesuré le contenant.

### Ce qui a changé

| | Avant | Après |
| --- | --- | --- |
| Ressources partagées | sous `resources:`, jetées en silence | sous `sources:` avec `buildPhase: resources` |
| Clé `resources:` | sur 3 cibles | nulle part |
| Langue de la montre | français pour tout le monde | celle du téléphone |
| Police de la montre et du widget | police système | Inter |
| Clé de cible inconnue | acceptée sans un mot | refusée par `check_spec.py` |
| Police enregistrée non embarquée | invisible | refusée |
| Cible affichant du texte sans catalogue | invisible | refusée |

### Ce qui le garde

**`ci_scripts/check_spec.py`** (nouveau) refuse toute clé de cible ou d'entrée `sources:` absente
des listes documentées, toute valeur inconnue de `buildPhase` et de `type`, toute police enregistrée
dans un `UIAppFonts` que sa cible n'embarque pas, et toute cible qui affiche du texte sans embarquer
de catalogue de chaînes. Sur le `project.yml` d'avant il sort **11 plaintes** ; sur celui d'après,
zéro. Lancé dans `testflight.yml` avant la construction, parce qu'il lit un fichier et coûte une
seconde.

Il lit le YAML **à la main** : le python du runner macOS n'a pas PyYAML et ce job n'installe rien —
la décision est déjà écrite dans `check_cablage.py`, et ce script l'avait d'abord enfreinte. Un
lecteur maison qui se trompe en silence serait pire que pas de contrôle du tout, donc il **refuse**
tout ce qu'il ne comprend pas (tabulation, bloc littéral, ancre, accolade, ligne inclassable), et
`test_spec.py` **compare sa lecture du vrai `project.yml` à celle de PyYAML** partout où PyYAML
existe. Cette comparaison a trouvé une faute dans mon lecteur au premier essai :
`- applinks:runup-nu.vercel.app`, sans espace après le deux-points, était lu comme une table au
lieu d'une chaîne.

**`.github/workflows/montre.yml`** : la sonde est devenue un garde-fou. Elle exige un
`Localizable.strings` dans chacune des trois langues, exige que « Courir » rende **trois valeurs
différentes** — un catalogue compilé peut très bien produire trois fichiers qui rendent tous la clé
française, et c'est exactement le symptôme qu'on vient de passer une journée à ne pas voir — et
exige que chaque police de l'`UIAppFonts` soit présente dans le paquet.

**`ci_scripts/test_spec.py`** : 29 cas. Les deux premiers sont le défaut d'origine reconstitué ; six
disent qu'une déclaration VALIDE ne sonne pas, parce qu'un garde-fou qui refuse tout est aussi
inutile qu'un garde-fou qui accepte tout.

### Ce que la chaîne a rendu, une fois corrigé

Run 5 de « Capture de la montre », commit `a0d27d0`, vert de bout en bout. Le paquet construit :

```
fr : « Courir » → Courir      ✓ Inter-Medium.ttf
en : « Courir » → Run         ✓ Inter-Bold.ttf
es : « Courir » → Correr      ✓ Inter-SemiBold.ttf
```

Les trois captures ouvertes une par une : « Aujourd'hui / Course libre / Courir », « Today / Free
run / Run », « Hoy / Carrera libre / Correr ». Comparées à celles d'avant sous la barre d'état,
**23,6 % des pixels ont changé** et la graisse d'« Aujourd'hui » n'est plus la même : ce n'est pas
seulement la langue qui a bougé, c'est le rendu.

`appstore/requis/montre/` porte désormais **trois** images au lieu d'une, chacune avec l'empreinte
de sa source ET l'empreinte du code qui l'a dessinée. L'entrée `source: null` de `SOURCES.json` —
celle qui portait le constat « faite à la main, et ne montre pas l'app » — a disparu.

### Ce que ça invalide

Toutes les captures de montre prises jusqu'ici montrent une app dans la mauvaise police et dans la
mauvaise langue. La note donnée à l'écran de course au poignet dans `AUDIT.md` § 9 a été mise sur
une image qui n'était pas celle de l'app. **Elle est à refaire.**

### Deux écarts avec la DA, vus sur l'image d'aujourd'hui et NON corrigés

Ce chantier-ci était la livraison des ressources. Ces deux-là sont des décisions de design, donc
ils attendent la phase 2 :

1. **Le bouton « Courir » est un dégradé rose → violet, en plein milieu de l'interface.** La règle
   7 dit « pas de dégradés dans l'interface », et la DA réserve le dégradé rose-violet à l'icône,
   au splash et au logo. L'accent d'action est `#F0225F`, plat. C'est l'élément le plus important
   de l'écran, et c'est l'infraction la plus visible du produit.
2. **La phrase du bas est coupée par le bord de l'écran, dans les trois langues** : « Cours à ta
   sensation — ta séance », « Run by feel — your session is on its », « Corre a tu ritmo; tu sesión
   llega ». Aucune des trois ne finit.

### Ce qui reste ouvert

- **`HaizoWatch` n'embarque aucun `PrivacyInfo.xcprivacy`**, là où l'app et le widget ont le leur.
  La cible montre n'appelle aucune API « à motif obligatoire » (vérifié : ni `UserDefaults`, ni
  `FileManager`) et n'envoie rien au serveur elle-même, donc l'absence se défend. Mais je n'ai pas
  de source Apple qui tranche pour un paquet de montre embarqué. **À décider avant le prochain
  envoi, pas à deviner.**
- **Le widget ne déclare pas de `CFBundleLocalizations`.** Avec le catalogue désormais livré, ses
  `.lproj` devraient suffire à faire découvrir ses langues. *Devraient* : ça se mesure sur un
  appareil, et ça ne l'a pas été.

## Chantier 17 — rejoindre un club sans en connaître un seul

### Ce qui était faux

La carte « Rejoindre un club » demandait un code à six lettres. Le code a été retiré, avec cette
raison écrite dans `db/schema.sql` :

> « Un code suppose qu'on l'ait reçu de quelqu'un, donc qu'on sache déjà que le club existe —
> c'est-à-dire tout ce qu'une recherche rend inutile. »

Le raisonnement était juste et il n'a pas été poussé jusqu'au bout. La recherche qui l'a remplacé
exige **deux caractères du nom**, et le serveur refuse en dessous (`handleSearchClubs` rend une
liste vide pour `q.length < 2`). Elle suppose donc elle aussi qu'on sache déjà qu'un club existe
et comment il s'appelle. Quelqu'un qui ouvre cette carte sans connaître un seul nom voyait un
champ vide et rien d'autre : la même porte fermée, deux crans plus loin.

### Ce qui a changé

Champ vide, cinq clubs ouverts. **Pas un annuaire** : une liste qu'on fait défiler demande de
choisir, cinq lignes demandent d'en essayer une.

L'ordre les choisit pour qu'on arrive dans un club **vivant** plutôt que dans le plus gros — une
séance à venir d'abord, puis un mur qui a parlé dans les quatorze derniers jours, puis le nombre
de membres. Quatorze jours et pas sept : sept ferait disparaître la mention pendant les vacances
scolaires, c'est-à-dire au moment où quelqu'un cherche justement avec qui courir.

Et chaque ligne porte **sa raison** — « Une séance prévue », « Actif ces jours-ci ». C'est la
règle déjà écrite pour les suggestions de personnes : une liste de noms sans explication
ressemble à un annuaire, et on ne suit pas un annuaire. Une séance à venir passe devant un mur
actif, parce que l'une dit où se présenter samedi et l'autre seulement que le club n'est pas
mort.

### Ce qui a été refusé

**Classer par proximité.** C'était la version la plus utile, et elle demandait d'envoyer la ville
ou les coordonnées de quelqu'un pour obtenir une liste de suggestions : une collecte de plus, à
déclarer au manifeste, dans la politique et chez Apple — le jour même où la fiche App Privacy
venait d'être remise d'équerre. Pour cinq lignes, non.

### Ce qui le garde

`lib/clubsSuggeres.js` porte ce qui se calcule sans base de données, donc ce qui s'éprouve sans
elle — même découpage que `lib/recherche.js` et `lib/pannes.js`, et `lib/` ne compte pas dans les
douze fonctions Vercel. Neuf cas, dont les deux qui comptent :

  · **une date illisible ne rend pas « actif » par accident.** `new Date('n'importe quoi')` rend
    NaN, et NaN comparé à quoi que ce soit rend `false` — mais la comparaison écrite dans l'autre
    sens aurait rendu `true` ;
  · **un message daté dans le futur non plus.** Une horloge en avance, et « il y a -3 jours » est
    bien inférieur à quatorze jours.

Côté Swift, les deux booléens sont **optionnels**, parce que `api/clubs/search` ne les renvoie
pas. Un `Bool` non optionnel ferait échouer le décodage de toute la recherche le jour où les deux
routes cesseraient d'être d'accord — et une recherche qui ne rend rien ressemble exactement à
« aucun club ne porte ce nom ».

La **même vue de ligne** sert aux deux listes. Deux vues presque identiques auraient dérivé à la
première retouche, et l'écart se serait lu comme une différence de nature entre un club trouvé et
un club proposé. Il n'y en a pas.

### Une erreur de ma part, en chemin

J'ai annoncé à Charlotte que « parcourir les clubs, ça n'existe pas » après avoir regardé
`api/clubs/public` — qui sert **une** page de club ouverte depuis un lien profond. La recherche
existait, de bout en bout, dans un fichier que je n'avais pas ouvert. Le chantier s'est rétréci
d'un annuaire complet à l'état vide d'un champ, ce qui était le vrai défaut.

## Chantier 16 — la fenêtre entre la 3e et la 10e sortie

### Ce qui était faux

Le catalogue de badges marque la toute première course, puis la dixième. Entre les deux, rien qui
compte les sorties — c'est-à-dire rien dans la fenêtre où l'on arrête.

Mais la fenêtre n'était pas vide : elle était **mal remplie**. La carte des trente derniers jours
s'affiche dès la première sortie et montre une **allure moyenne**. Au cinquième jour d'une
reprise, c'était le seul chiffre de l'écran capable de donner tort à quelqu'un qui hésitait déjà.
Et sa fenêtre **glisse** : elle redescend quand on ralentit, au moment précis où une redescente
coûte le plus cher.

### Ce qui a changé

De la 3e à la 9e sortie, c'est une autre carte, et elle n'affiche **que des grandeurs qui ne
peuvent pas baisser** : nombre de sorties, kilomètres cumulés, plus longue sortie.

Les deux cartes ne coexistent pas. Avec moins de dix sorties, la fenêtre de trente jours contient
à peu près tout ce qu'on a couru, et les afficher ensemble dirait deux fois la même chose.

Elle s'arrête d'elle-même à la dixième, quand le badge prend le relais — pas de réglage, pas de
croix à fermer, et elle ne revient jamais. Elle commence à la troisième : en dessous, « 1 sortie ·
3 km · plus longue 3 km » dit trois fois la même chose.

### Le chiffre écarté

Le **nombre de jours** depuis la première sortie disait quelque chose de vrai sur la régularité —
« 3 sorties en 9 jours » n'est pas « 3 sorties ». Il a été écarté pour la raison même qui fonde la
carte : il grandit qu'on coure ou non. « 3 sorties en 40 jours » est un reproche déguisé en
mesure.

### Ce qui le garde

Trois colonnes, **deux aux tailles d'accessibilité** — même règle que la grille de mesures
d'`ActivityDetailView` : « PLUS LONGUE » en capitales espacées dans un tiers d'écran rétrécit
déjà à 0,7 au corps normal.

### D'où vient l'idée

De `3477d46`, sur `claude/running-club-finance-wwuq46`, une branche d'août jamais fusionnée. Le
code n'en est pas repris : ni le système de couleurs ni les contrôles de ce dépôt n'existaient
alors. Seul le raisonnement l'a été — et corrigé sur un point, le compte des jours.

## Chantier 15 — les erreurs qu'on avale

Annoncé à la fin du chantier 14 : MetricKit ne voit que ce que le système appelle une panne. Les
erreurs rattrapées par l'app lui sont invisibles — de son point de vue, rien n'a mal tourné. Donc
un audit, et un audit commence par compter.

### LE RELEVÉ

**275 sites** : 143 `try?`, 132 `catch`, et **zéro `try!`** — pas un seul point d'exclamation
forcé dans toute l'app.

Les `catch`, par ce que leur corps FAIT :

| | |
|---:|---|
| **97** | montrent quelque chose à l'utilisatrice (`toast`, `errorMessage`, bannière) |
| 8 | relancent l'erreur à l'appelant |
| 5 | rendent un cas d'échec nommé (`.baseNonVide`, `.fichierIllisible`…) |
| 4 | posent un état que l'écran lit (`loadFailed`, `storeState`…) |
| 4 | annulent un changement optimiste |
| 4 | sont VIDES |
| 3 | rendent `nil` ou `[]` en silence |
| 2 | arrêtent l'app en débogage |

Les `try?` : 37 replis sur une valeur, 29 attentes (`Task.sleep`, qui n'échoue qu'à
l'annulation), 26 encodages/décodages avec repli, 6 enregistrements SwiftData, 5 nettoyages de
fichiers temporaires, 2 audio, 1 Santé, 37 divers.

**Les quatre `catch` vides sont tous délibérés et tous commentés** — la photo de profil réessayée
au prochain rafraîchissement, la montre non appairée, une suppression qui n'a rien bougé à
l'écran, une page de fil qui reste juste. J'ai lu les douze candidats au silence un par un ; onze
sont corrects.

### LE DOUZIÈME : UNE COURSE DE MONTRE PERDUE POUR DE BON

`WatchSessionService.handleCompletedRun` finissait par `try? appState.modelContext.save()`. Si
cet enregistrement échouait, **tout le reste se déroulait quand même** :

- l'identifiant de livraison entrait dans `seen`, donc la montre ne redélivrait plus jamais ;
- la feuille de ressenti s'ouvrait ;
- l'app annonçait « Course reçue de ta montre ⌚ ».

Elle affirmait donc avoir reçu une course qui n'existait que dans la mémoire du processus, et qui
disparaissait au lancement suivant sans que rien ne puisse la ramener.

Ce qui rend ce défaut remarquable, c'est que **le commentaire juste au-dessus le décrivait déjà** :
il raconte que le marqueur était autrefois posé avant l'enregistrement, qu'un processus tué entre
les deux perdait la course, et il énonce la règle — « une livraison interrompue doit pouvoir
recommencer ». Un échec d'enregistrement EST une interruption. La branche n'était simplement pas
couverte.

Corrigé avec l'idiome que les deux réparations de données d'`AppState` emploient déjà
(`guard (try? save()) != nil else { return }`), plus deux choses : l'insertion est défaite, et
l'app le DIT — « La course de ta montre n'a pas pu être enregistrée. Elle sera renvoyée », ce qui
est vrai puisqu'on ne consomme pas l'identifiant.

### ET DU CODE MORT QU'UN TEST TENAIT EN VIE

`SauvegardeService.ecrire` était appelée par exactement un endroit : un test. Elle avait été
écrite pour un `ShareLink(item:)`, remplacé depuis par un `fileExporter` — l'app encode, pose les
octets dans un `SauvegardeDocument`, et laisse le système écrire.

Le coût n'était pas la fonction, c'était son test. Son commentaire affirmait : « un vrai fichier
sur un vrai disque, écrit puis relu, parce que c'est le seul trajet que la sauvegarde empruntera
jamais. » Faux — et c'est le genre de phrase qui fait croire que l'export est couvert. Il
emprunte maintenant le chemin réel, et la fonction est sortie du binaire.

### CE QUI A ÉTÉ REGARDÉ ET LAISSÉ

`GPXExporter.fileURL` rend `nil` si l'écriture échoue, et ses deux appelants font
`if let url { ShareLink… }` : le bouton « Exporter en GPX » disparaît sans explication. Ça
confond « pas applicable » et « cassé ». Laissé tel quel : l'écriture est un petit fichier dans
le dossier temporaire, son seul échec réaliste est un disque plein — auquel cas bien d'autres
choses cassent d'abord — et le corriger demanderait de rendre l'export paresseux (`Transferable`
au lieu d'une URL) aux deux endroits. Le seuil où ça change : le jour où cette écriture grossit
ou sort du dossier temporaire.

### CE QUE L'AUDIT DIT DE L'APP

Quatre-vingt-dix-sept `catch` sur cent trente-deux parlent à l'utilisatrice, aucun `try!` nulle
part, et les silences sont presque tous écrits et justifiés. **Un seul défaut sur 275 sites.**
C'était la bonne nouvelle possible, et c'est la raison pour laquelle ce chantier ne se termine
PAS par « on rapporte toutes les erreurs rattrapées au serveur » : il n'y a pas de gisement
d'erreurs avalées à instrumenter, il y en avait une.

## Chantier 14 — le rapport de panne, et la façon de le faire qui ne marche pas

Commencé par chercher comment on fait, et la recherche a renversé le plan.

### LE PLAN D'ORIGINE, ET POURQUOI IL EST MORT

La façon dont presque tous les rapporteurs de panne fonctionnent : poser un
`NSSetUncaughtExceptionHandler` et des `sigaction` sur SIGSEGV, SIGABRT, SIGBUS, SIGILL, relever
la pile d'appels depuis le gestionnaire, l'écrire dans un fichier, l'envoyer au lancement suivant.
C'est ce qu'il fallait écrire. Ce n'est pas ce qui a été écrit, et la raison est une phrase.

Quinn « The Eskimo! », de l'assistance aux développeurs d'Apple, dans « Implementing Your Own
Crash Reporter » (developer.apple.com/forums/thread/113742) :

> `backtrace` is not an async signal safe function.

Un gestionnaire de signal ne peut appeler que des fonctions dites *async signal safe*, et cette
liste ne contient ni `malloc` — donc « a crash reporter's signal handler cannot use Objective-C or
Swift » — ni `backtrace`. Sans `backtrace`, pas de pile d'appels ; sans pile d'appels, un rapport
de panne ne sert à rien. Le reste du texte ferme les autres portes :

> On iOS […] your crash reporter must run inside the crashed process. That means it can never be
> 100% reliable.

> You must ensure that your crash reporter doesn't disrupt the Apple crash reporter.

Et il nomme la sortie :

> I recommend that you lean in to Apple's crash reporter. […] iOS 14 and macOS 12 report crashes
> in MetricKit. This is a *very* cool feature, and I'm surprised by how few people use it
> effectively.

C'est exactement la règle 8 — chercher et citer avant d'écrire. Une journée de C contraint,
impossible à relire et impossible à éprouver ici, a été remplacée par un abonnement.

### CE QUI EST FAIT

`Haizo/Services/Diagnostics.swift` s'abonne à MetricKit. iOS collecte la panne **hors** du
processus mort — le même mécanisme que les rapports de l'organiseur Xcode — et la rend au
lancement suivant. Jumeau volontaire d'`Analytics` : même file privée, même tampon sur disque,
même discipline d'endpoint. Ce n'est pas de la copie, c'est la même forme pour le même problème.

**Cinq genres arrivent, et quatre ne sont pas des plantages.** Un gel de plusieurs secondes, un
dépassement de processeur, une écriture disque excessive, un lancement trop lent. Ce sont les
pannes où l'app ne meurt pas : elle devient mauvaise. Un rapporteur de panne classique ne les voit
JAMAIS, et c'est pourtant ce qu'une utilisatrice appelle « ça plante ».

| Pièce | Rôle |
| --- | --- |
| `Haizo/Services/Diagnostics.swift` | l'abonnement, la traduction d'un lot MetricKit en lignes, le tampon sur disque |
| `lib/pannes.js` | ce qu'on accepte d'un rapport, seul et testé — 19 cas dans `tests/crashes.test.js` |
| `api/crashes.js` | l'endpoint : jeton facultatif, lot borné, genre inconnu jeté ligne par ligne |
| `crash_reports` dans `db/schema.sql` | la table, avec sa charge `jsonb` et ses deux index |
| `ci_scripts/check_pannes.py` | les trois accords, 14 cas dans `test_pannes.py` |

### Ce qui a été VÉRIFIÉ en production, et les deux lignes que ça laisse

Le déploiement réussi prouve que le schéma a été appliqué — `appliquer_schema.js` est la commande
de construction, et « si ce script échoue, la construction échoue, donc RIEN n'est déployé ». Il
ne prouve PAS que l'`INSERT` est juste : il a été écrit à la main contre un schéma écrit à la
main, et une colonne mal nommée rendrait un 500 à chaque panne. Silencieusement : le client garde
son tampon sur un 5xx et réessaie, donc rien ne se perd et rien n'arrive jamais non plus.

Deux sondes envoyées à la production :

| Ce qui est éprouvé | Réponse |
| --- | --- |
| un genre inconnu est jeté ligne par ligne, sans rien écrire | `accepted:0, rejected:1` |
| l'`INSERT` passe, toutes colonnes nommées | `accepted:1` |
| la colonne `payload` accepte du vrai JSON en `jsonb` | `accepted:1` |
| un lot de six est refusé | `payload_too_large` |
| `GET` est refusé | `405` |
| `/api/events` répond toujours, non réécrit | `200` |

Elles laissent **deux lignes** dans `crash_reports`, de genre `app_launch` et non `crash` — pour
qu'aucun compte de plantages ne soit faussé — et dont la note dit en toutes lettres « SONDE DE
DÉPLOIEMENT, pas une vraie panne ». C'est le prix assumé de la vérification : sans elles, la
première preuve que la table marche aurait été la première panne de quelqu'un.

### LA DÉGRADATION, QUI EST LA DÉCISION DE CONCEPTION

Un rapport dont la charge JSON est abîmée ou trop grosse **perd sa pile d'appels et garde sa
ligne**. « Combien de plantages sur la 2.9 » reste une information sans la pile ; refuser tout le
rapport ferait disparaître le plantage au lieu de la pile. Et ce serait invisible, parce qu'une
table de pannes vide ressemble trait pour trait à une app qui ne plante pas.

C'est le même raisonnement partout : un champ trop long devient `NULL` plutôt que tronqué
(tronquer fabriquerait une version qui n'existe pas, et elle serait agrégée comme telle), une date
plus vieille qu'un mois cède à l'heure du serveur, un `isTestflight` qui n'est pas un vrai booléen
devient `NULL` au lieu d'être coercé en `true`.

### LE CONTRÔLE, ET SA TROISIÈME RÈGLE

`check_pannes.py` compare `Diagnostics.Genre` et `KNOWN_KINDS` dans les deux sens, comme
`check_events.py` le fait pour l'analytique. La raison est la même, l'enjeu est plus mauvais : un
rapport de panne n'arrive que quand ça va mal, donc il n'y a aucun volume quotidien dont la chute
sauterait aux yeux. La divergence qui a jeté onze événements d'analytique pendant des mois aurait
ici **zéro symptôme**.

Sa troisième règle n'est pas de la même nature. Tant que l'app s'abonne à MetricKit, le manifeste
`PrivacyInfo.xcprivacy` doit déclarer `NSPrivacyCollectedDataTypeCrashData` **et**
`NSPrivacyCollectedDataTypePerformanceData` — déclarer les plantages et oublier les gels est le
piège exact, et il a son cas de test. Une déclaration incomplète fait refuser le binaire à
l'**envoi**, avant toute revue humaine. Cette règle existe parce que la dérive s'est déjà produite
ici : le manifeste a affirmé pendant des mois que le tracé GPS ne partait jamais, ce qui a cessé
d'être vrai le jour où la table `routes` est apparue. Son propre en-tête mettait en garde contre
exactement ça. Ça n'a pas suffi — c'est la définition d'un travail de machine.

### CE QUI EST ÉCRIT NOIR SUR BLANC COMME NON COUVERT

- **Les erreurs rattrapées.** Les 160 `try?` et 132 `catch` de l'app avalent des erreurs dont
  MetricKit n'entendra jamais parler : de son point de vue, rien n'a mal tourné. C'est le chantier
  suivant, et il commence par un audit de ces sites — pas par du code.
- **Pas de regroupement.** Aucune colonne « signature », aucun compteur d'occurrences : regrouper
  demanderait de symboliser côté serveur. À cette échelle on lit les lignes. Le seuil où ça
  devient faux s'énonce : le jour où une requête rend plus de lignes qu'on n'en lit à l'œil.
- **Rien sur le simulateur.** MetricKit ne collecte que sur un appareil réel, donc ce chemin ne
  sera jamais éprouvé par le harnais. Ce qui est éprouvé, c'est tout ce qui est en dessous : les
  règles d'acceptation (19 cas), les trois accords (14 cas), le découpage du schéma.
- **Pas d'alerte.** Une panne arrive au lancement suivant, et personne n'est prévenu. Il faut
  aller regarder la table.

### L'API UTILISÉE EST DÉPRÉCIÉE EN iOS 27, ET C'EST LE BON CHOIX QUAND MÊME

`MXMetricManager` et les classes `MX*` sont remplacées en iOS 27 par `MetricManager` et sa suite
asynchrone `diagnosticReports`. Haizo vise iOS 17 : la nouvelle API n'existe pas pour la
quasi-totalité du parc, et les classes `MX*` sont là depuis iOS 14. Le jour où le plancher passe à
27, la migration est dans un seul fichier.

### LA POLITIQUE PUBLIÉE A RATTRAPÉ, LE JOUR MÊME

Le constat était que la page lue par Apple et les utilisatrices — servie par GitHub Pages depuis
`main`, pas depuis cette branche — ne mentionnait pas les rapports de panne, alors que
`testflight.yml` ENVOIE à chaque push (`xcrun altool --upload-app`) : des builds qui les
collectent étaient déjà distribués. Pas une fuite, un manquement de déclaration, et sur une
donnée qui ne contient ni texte écrit, ni santé, ni position.

Charlotte a porté `privacy.html` et `support.html` sur `main` le 8 novembre. Vérifié octet pour
octet : les deux pages publiées sont identiques à celles du dépôt. *(Relevé le 10 novembre :
`support.html` est publiée mais n'est l'adresse de personne — la fiche et l'app emploient un
`mailto:`.)* `check_politique.py` est passé
en `--exiger` dans la foulée — toute nouvelle section ajoutée ici fera désormais rougir la chaîne
tant qu'elle n'est pas publiée.

### CE QUI RESTE À FAIRE À LA MAIN

La fiche App Store Connect doit déclarer **Crash Data** et **Performance Data** en *App
Functionality*, pour concorder avec le manifeste — une divergence entre les deux est un motif de
rejet à part entière. Le détail est dans `APP_STORE_LISTING.md` § Confidentialité.

## Chantier 12 — l'app en grand texte, enfin photographiée

Commencé par la mesure, et la mesure a corrigé l'item de l'audit.

### Ce que l'audit disait, et ce que le code dit

« Tailles de texte dynamiques » : c'est **déjà fait pour le texte**. `RUFont` fait passer chaque
taille dessinée par `scaled(_:)`, qui lit le réglage iOS et plafonne à 2,0 ×. Sur les 174 appels
à `.font(.system(size:))` du dépôt — le seul chemin qui contourne ce système — **167 portent une
icône** et **4 portent du texte** : les deux chevrons « ‹ » des boutons de retour, le repli qui
affiche l'emoji d'une notification déjà enregistrée, et la coche typographique de l'assistant
d'objectif. Les trois derniers sont des glyphes dans un cadre, et c'est justifié.

### Ce qui est fait : l'échelle d'icônes

`RUIconSize`, sept crans — 9, 11, 13, 15, 18, 22, 28 — et `RUFont.icone(_:weight:)`. Les 170
appels sont convertis, et `ci_scripts/check_icones.py` refuse désormais une taille écrite à la
main dans `Haizo/Views` : il en reste **deux** depuis que les chevrons « ‹ » sont devenus
`chevron.left`, toutes deux listées avec leur raison, et aucune n'est une icône (le repli qui
affiche l'emoji d'une notification déjà en base, la coche typographique de l'assistant
d'objectif). Le test, lui, RÉPÉTAIT le nombre quatre au lieu de le dériver de la liste : il est
resté rouge dix minutes après le commit qui ramenait quatre à deux, parce que j'avais lancé les
contrôles sans lancer leurs cas. D'où `ci_scripts/tout.sh`, qui lance les deux en une commande.

Les crans sont relevés, pas inventés : **13 et 15 — les deux tailles les plus employées, 65
appels à elles deux — sont des crans**, donc ces 65 appels rendent exactement ce qu'ils
rendaient. Les autres se déplacent d'un point, deux au plus. Quatre sorties d'échelle restent,
toutes des illustrations : 72 points pour un état vide, 52 pour une carte de badge partagée, 42
et 40 pour deux hexagones dont la taille suit leur médaillon.

### Ce qui n'est PAS fait, et pourquoi c'est écrit dans le code

**Les icônes ne suivent toujours pas le réglage de taille du texte.** C'est un vrai défaut
d'accessibilité et il reste ouvert. La raison est celle qui a tenu le plafond de titrage à 1,6 ×
pendant des mois : une icône qui double dans un cadre qui ne double pas déborde. La barre
d'onglets enferme ses symboles dans 22 points de haut, calculés pour qu'un symbole de 18 y tienne
sans déborder — et sa hauteur sert d'encart au bas de chaque écran. Une dizaine de colonnes
d'alignement (`.frame(width: 26)`, `.frame(width: 30)`) sont dans le même cas.

Ouvrir la croissance sans reprendre ces cadres ne rendrait pas l'app accessible : **ça la
casserait à AX2 pour exactement les gens qui en dépendent**. Ce qu'il faut est ce qui a permis de
lever le plafond de titrage : reprendre les cadres un par un, et regarder. Les captures en grand
texte existent maintenant pour ça.

### Le relevé qui a mené là

**170 icônes à taille figée, sur 22 valeurs différentes de 8 à 72 points** — dont 13, 14 et 15 pt
voisinant sur 76 appels. C'est le même défaut que l'échelle de titrage avant `RUDisplaySize` :
personne n'a décidé ces tailles, chaque écran a été réglé à l'œil puis recopié. Et aucune ne suit
le réglage de taille du texte : à AX2, le texte grandit de 94 % et les icônes qui l'accompagnent
restent où elles sont.

Classées par ce qui les contient : **97 à côté d'un texte** (elles doivent grandir avec lui),
**60 dans un cadre chiffré** (les faire grandir les ferait déborder), 15 ni l'un ni l'autre.

### Ce que les quatre captures ont trouvé, et ce qui est corrigé

Douze mesures d'écart entre chaque capture en grand texte et son ordinaire : **17,3 à 31,3**. Le
réglage a donc bien pris partout, et ce qu'on voit est l'app.

**L'écran de course — celui qu'on lit à bout de bras — cassait en trois endroits.**

| Défaut | Correctif |
| --- | --- |
| « Recherche du signal **GP…** » | le bandeau est posé en `.overlay` sur une rangée haute d'un bouton : la hauteur proposée était celle d'une ligne. `fixedSize(vertical:)` lui rend sa hauteur. |
| le panneau de mesures s'effondrait — les tirets d'allure passaient à la ligne et « ALLURE » ne s'alignait plus | `ViewThatFits` : trois de front quand ça tient, l'une sous l'autre sinon. Le patron de `RUMetricRow`. |
| le bouton d'arrêt affichait « **ST…** » | le mot rétrécit, le cercle non. Faire grandir les trois commandes ferait déborder la rangée (52 + 70 + 52 à 1,94 ×), et leur taille est une sécurité quand on les vise en courant. |

**L'accueil.** « TA JOURNÉE » chevauchait l'anneau : l'anneau fait 186 points, son trait 15 × 0,74
sur un canevas de 100, donc un carré inscrit de ≈ 102 points — le mot en demandait plus du
double. Les deux lignes rétrécissent pour y tenir ; l'anneau, lui, ne grandit pas (il déborderait
de l'écran). Et le tracé de la dernière sortie passait par-dessus les chiffres : le bandeau était
haut de 150 points fixes, il suit maintenant le texte, plafonné à 2,0 × comme la typographie —
c'est la proportion pour laquelle le voile dégradé a été réglé.

**Le bilan de la semaine.** La pastille d'écart chevauchait le chiffre qu'elle commente. Elle
rejoint le flux aux tailles d'accessibilité. Et l'écran Stats montrait déjà le MÊME écart dans le
flux ET avec son unité — « ▼ 16,6 km » — là où le bilan affichait « ▼ 16,6 » tout court : un
nombre sans unité à côté d'un total en kilomètres se lit comme un pourcentage. Les deux écrans
disent maintenant la même chose de la même façon.

**Stats.** « prochain palier : 30 jours » s'affichait « prochain palier :… » — exactement le
défaut que le commentaire de ce bloc existe pour empêcher : « une barre aux deux tiers sans son
palier est un pourcentage de rien ». Deux lignes plutôt qu'une.

### Trois écrans de plus, et trois défauts de plus (8 novembre, deuxième passe)

Quatre écrans sur les vingt et un photographiés, c'était la couverture. Les trois ajoutés sont les
plus denses de ceux qu'on n'avait jamais vus en grand texte : la sortie dépliée (l'écran le plus
chiffré de l'app), l'aperçu du club (redécoupé en quatre fichiers la veille, donc jamais revu
depuis), et le profil (une grille de tuiles). Les trois ont rendu un défaut chacun.

| Écran | Défaut | Correctif |
| --- | --- | --- |
| Aperçu du club | **une coupure de mot, pas une troncature** : « Classe / ment » en français, et les TROIS à la fois en espagnol — « Resume / n », « Clasific / ación », « Activida / d ». Un onglet dont le nom est coupé en deux ne se lit plus comme un nom. | les trois segments s'empilent au cran d'accessibilité (`AnyLayout`). Chacun a la largeur entière, rien ne rétrécit. |
| Profil | « jours de suite » passait à la ligne et tombait sous le chiffre du milieu, centré sous rien — une quatrième ligne orpheline qui casse le lien entre un chiffre et son unité. | la rangée de chiffres devient une colonne, comme `RUCardHeader` et `WeeklyRecapView` le font déjà. |
| Sortie dépliée | « bpm m… » : `bpm moyen` ne tient pas dans un tiers de largeur, et le `lineLimit(1)` du libellé le coupait. Sans son libellé, « 154 » n'est rien. | deux colonnes au lieu de trois, ET deux lignes autorisées. Aucune des deux ne suffit seule. Le chiffre, lui, garde son `lineLimit(1)` : un chiffre coupé serait pire qu'un chiffre rétréci. |

Le compte de la méthode est donc de **treize défauts sur sept écrans**, tous invisibles aux
tailles ordinaires et tous vus sur une image.

Ce qui a été REGARDÉ et laissé : les textes libres tronqués en fin de ligne — la bio du profil,
le sous-titre « Ton club, tes abonnements et tes c… », le nom d'un club long. Ce sont des limites
de lignes posées exprès sur du contenu de longueur inconnue, pas des mises en page qui cassent, et
la coupure se fait proprement sur un caractère de suite.

### Le calage de l'heure du coach, qui attendait une exécution de nuit

Une dette plus petite, et fermée le même jour. La fausse conversation du coach est plantée cinq
heures en arrière, bornée au début du jour courant : sans cette borne, une chaîne qui tourne à
03 h 00 pose le message à 22 h 00 la VEILLE, et `3-coach` — une des six images livrées à Apple —
affiche un séparateur « HIER ». Le défaut est passé une fois, et n'a été vu qu'à la troisième
exécution comparée.

La borne était écrite, et **impossible à vérifier autrement qu'en attendant qu'une exécution
tombe entre minuit et 05 h 00** — c'est-à-dire en confiant la vérification au hasard de l'heure
à laquelle quelqu'un pousse. Elle est sortie dans `CaptureSeed.poseDeLaConversation`, et
`CaptureSeedHeureTests` éprouve les vingt-quatre heures en une seconde : la pose tombe toujours
le jour courant, le recul de cinq heures reste intact passé 05 h 00, et la réponse du coach —
posée quarante secondes après la question — ne bascule pas au jour suivant non plus.

### Ce qui restait du chantier 12, et pourquoi il est fermé

« Indices VoiceOver » était la seconde moitié de l'item d'audit. Elle est fermée sur une mesure,
pas sur une opinion.

**Les commandes ont toutes un nom.** `check_a11y.py` existe déjà et le garantit : il refuse toute
commande dont le libellé est une icône seule et qui n'a ni `accessibilityLabel`, ni
`accessibilityHidden`, ni `accessibilityElement`. Il est vert. J'ai voulu le vérifier à part et
j'ai écrit deux mesures fausses coup sur coup — la première a rendu trois défauts, tous faux
positifs d'une fenêtre de lecture trop courte ; la seconde en a rendu un, faux lui aussi, parce
que le texte du bouton était passé en ARGUMENT à `RUCardHeader` et non écrit dans un `Text`. La
bonne réponse est zéro, et elle était déjà tenue par une machine.

**Ce qui est DESSINÉ ne parle pas, et c'est délibéré partout.** Quinze fichiers dessinent de
l'information (`Canvas`, `Path`, des rectangles dans un `GeometryReader`). Six ne portent aucune
annotation, et aucun n'est un défaut :

| Fichier | Pourquoi il se tait |
| --- | --- |
| `AppMarkView` | le logo : décoratif |
| `HexagonBadgeShape` | une `Shape`, de la géométrie sans contenu |
| `RunShareCardView` | rendu en image pour le partage, jamais à l'écran |
| `DrawnRoute` | employé par le seul `RunVideoFrameView`, qui fabrique des images de vidéo |
| `ProgressBars` | un `Rectangle` n'est pas un élément d'accessibilité : VoiceOver ne s'y arrête pas. Et aux six endroits où `LinearBar` sert, le nombre qu'elle dessine est ÉCRIT en toutes lettres juste à côté — « 180 / 250 XP », « 212 / 300 km — 71 % », « 245 km / 800 km », « Semaine 7/16 ». L'annoncer en plus ferait lire deux fois la même chose |
| `ElevationProfileView` | son `RUCardHeader` le nomme, et `RecapView` porte déjà le commentaire qui le dit : « the min/max/gain numbers below it are combined into this card's own label instead » |

**Les six indices restent six.** Le relevé : 127 `accessibilityLabel`, 58
`accessibilityElement`, 29 `accessibilityAddTraits`, 25 `accessibilityHidden`, 15
`accessibilityValue`, 6 `accessibilityHint`.

Et la raison de ne pas en ajourer cent vingt d'un coup doit être dite correctement, parce que je
l'ai d'abord dite faux. J'ai écrit que c'était « contre la recommandation d'Apple » : je n'ai pas
pu sourcer cette phrase. La page de `accessibilityHint(_:)` dit ce qu'un indice EST —
« Communicates to the user what happens after performing the view's action », avec pour exemples
« Purchases the item », « Downloads the attachment » — et ne dit rien sur la parcimonie.

La vraie raison tient en une distinction : **un libellé calculé depuis la donnée qu'il décrit ne
peut pas mentir ; un indice est une affirmation sur un COMPORTEMENT.** « Ouvre la sortie en
détail » est vrai ou faux selon ce que fait le bouton, et rien ici ne peut le vérifier — ni le
compilateur, ni une capture, ni un contrôle. En écrire cent vingt reviendrait à poser cent vingt
phrases sur le fonctionnement de l'app que personne n'aurait éprouvées. C'est la règle « rien de
faux » appliquée aux textes de l'interface. Les six qui existent ont été écrits un par un, en
regardant ce que la commande fait.

### Une bannière d'iOS sur une image livrée à Apple

Trouvée par accident, en comparant une dernière fois deux exécutions pour vérifier qu'un
refactorisage de `CaptureSeed` n'avait bougé aucun pixel. Une image avait bougé : `1-accueil.png`
en français, 13,4 de moyenne dans la bande du haut.

C'était une notification du système — « Ready for Apple Intelligence », émise par Réglages — posée
en travers du haut de l'écran. Sur cette image, on ne voit ni le prénom, ni la date, ni la série :
on voit une bannière grise qui parle d'autre chose, par-dessus l'app. Et c'est une des SIX images
livrées à Apple.

Rien ne pouvait l'attraper. Le test de capture était vert, parce qu'il dit deux choses et deux
seulement : l'app n'a pas planté, un fichier a été écrit. Aucun contrôle ne regardait ces six
images. Rien n'a été envoyé — `appstore.yml` ne part qu'au bouton — donc c'est une alerte, pas un
dégât. La prochaine fois, c'est une question de minutage.

`check_banniere.py` mesure la part de pixels clairs dans la bande où iOS pose ses bannières, sur
les captures SOMBRES uniquement. Le relevé de quatre-vingt-quatre captures saines va de 1,3 % à
8,0 % — les plus claires étant les écrans en grand texte, dont les titres occupent légitimement le
haut — contre **59,7 %** pour celle qui portait la bannière. Le plafond est à 25 %, trois fois la
plus claire observée, et il n'y a rien entre 8 et 60 à départager.

**Et la chaîne qui PUBLIE le vérifie aussi.** `captures.yml` refusait déjà une bannière, mais
c'est `appstore.yml` qui parle à Apple — et il télécharge l'artefact d'une exécution qu'on peut
DÉSIGNER par son numéro, y compris une ancienne, antérieure au contrôle. Il relance donc la
mesure sur les images qu'il s'apprête à pousser, avant de toucher à App Store Connect. Sur
`raw/` et non `out/` : le plafond est calibré sur des captures en thème sombre, et les images
composées portent un fond de fiche clair où la mesure ne voudrait rien dire — une bannière dans
une brute se retrouve de toute façon dans la composée. C'est le principe que ce workflow applique
déjà pour l'aperçu : ce que la commande décide sans parler à Apple est éprouvé juste avant.

Il ne l'empêche pas, il la voit — et cette limite doit être dite honnêtement : **je n'ai pas
trouvé comment l'empêcher.** La recherche n'a rien rendu sur une option de `simctl` qui
musellerait les notifications du système, ce qui ne prouve pas qu'elle n'existe pas. Ce qui est
documenté et voisin en ENVOIE (`simctl push`), fige la barre d'état (`status_bar override`) ou
calme les journaux (`spawn log config`) ; aucun ne touche aux bannières. Ce qu'on peut faire sans
rien supposer, c'est refuser de livrer l'image.

### Et la question inverse : est-ce que les écrans ORDINAIRES ont bougé ?

Les trois correctifs ne devaient toucher que le cran d'accessibilité. `comparer.py` entre les
captures d'avant et d'après, sur les quarante-deux images d'une langue : **trente-quatre
identiques au pixel près**, et huit qui diffèrent — toutes expliquées.

| Image | Écart | Explication |
| --- | --- | --- |
| les trois en grand texte corrigés | 11,6 à 17,7 | c'est le correctif |
| `course-en-cours` (×3, dont la version claire et la version grand texte) | 0,17 à 1,12 | écran non reproductible, documenté : chronomètre, calories, tuiles qui n'arrivent pas au même moment |
| `clair/diagnostic/profil` | 0,19 sur une bande de 38 points | écran non reproductible, documenté : la tuile « Amis » dépend de l'heure |
| `diagnostic/club-apercu-bas` | **16,3 et 813 202 pixels** | TROISIÈME écran non reproductible, trouvé ce jour-là |

Le dernier a coûté une demi-heure. Seize de moyenne, c'est cinq fois ce que rend un changement de
LANGUE complet sur ce même écran — le plus gros chiffre que cet outil ait jamais rendu. Et ce
n'était rien : le contenu est identique, le défilement s'est arrêté 105 pixels plus loin. Le
harnais donne un nombre de glissements, pas une destination.

D'où `comparer.py --decalage`, qui cherche désormais si un décalage vertical explique l'écart et
le dit en toutes lettres. Sur cette image : « le contenu d'après est 105 px plus bas (défilement
moins loin) ; la moyenne passe de 19,904 à 1,435 → un défilement, pas une régression. »

Et un écho du même défaut, un cran plus loin : modifier `comparer.py` n'a relancé que TestFlight.
Quatre scripts — `comparer.py` et ses cas, ceux des bascules, le contrôle du grand texte et les
siens — étaient lancés par `captures.yml` sans être dans son filtre de chemins. Câblés sur le
papier, débranchés en pratique. `check_cablage.py` ne pouvait pas le voir : il vérifie qu'un
script est NOMMÉ par un workflow, pas que ce workflow PARTE quand le script change.
`check_declencheur.py` porte maintenant les deux règles.

Deux défauts trouvés en ÉPROUVANT l'option, qui méritent d'être notés parce qu'aucun ne se voyait
à la relecture : le gabarit de test posait une barre toutes les 24 lignes, donc un décalage de 48
retombait exactement sur lui-même et l'écart tombait à zéro des deux côtés ; et la recherche
sautait silencieusement tout décalage qui faisait sortir la bande de l'image — invisible sur une
capture de 2 868 pixels, fatal sur un gabarit de 600. Les deux sont corrigés et écrits dans le
code.

### Mais d'abord : regarder l'app en grand texte

Le plafond de `RUFont` est passé de 1,6 × à 2,0 × sur la foi d'un travail de réorganisation —
rangées de mesures qui passent en colonne, bande des sept jours qui laisse tomber le quantième,
barre d'onglets qui laisse tomber ses libellés. Tout cela est **écrit, commenté, et n'a jamais été
photographié**. C'est exactement la forme de défaut que cette journée a trouvée quatre fois.

Quatre captures nouvelles, au deuxième cran d'accessibilité (AX2, ≈1,94 ×, le plus grand que le
plafond couvre en entier) : l'accueil, les statistiques, la course en cours, le bilan de la
semaine — les quatre endroits où un texte deux fois plus grand n'a nulle part où aller. Le
réglage arrive par `-UIPreferredContentSizeCategoryName`, le même chemin que la langue.

Et `check_grand_texte.py` mesure l'écart entre chaque capture et son ordinaire : si le drapeau
cessait d'être lu, les quatre images seraient des copies, le harnais resterait vert, et on
croirait avoir vu l'app en grand texte. **Le plancher vaut 10 depuis le 8 novembre**, et il vient
de trente-six mesures — trois exécutions, trois langues, quatre écrans — qui vont de 16,2 à 31,3.
Deux copies du même écran ne diffèrent que par l'heure, soit une fraction de point : il n'y a rien
entre 0,x et 17 à départager, donc rien à régler finement.

### Ce que les quatre captures ont montré, le 8 novembre

Regardées, pas supposées. L'écart au texte ordinaire va de **19,1 à 27,4** sur les douze mesures
— trois langues, quatre écrans : le réglage prend partout, et les images ne sont pas des copies.

Trois des sept correctifs posés la veille tiennent, et la capture les montre : la pastille
d'écart du bilan rejoint le flux au lieu de flotter, la barre d'onglets laisse tomber ses
libellés, le bandeau GPS passe sur deux lignes. Restaient trois choses.

1. **Les trois mesures de la course ne basculaient pas en colonne.** « --:-- » se cassait en deux
   DANS sa cellule, et le libellé ALLURE descendait d'un cran sans plus s'aligner avec FC ni
   KCAL — exactement le défaut que le `ViewThatFits` posé la veille existait pour corriger,
   photographié une deuxième fois. `ViewThatFits` compare la taille IDÉALE de chaque candidat à
   la place offerte, et la taille idéale d'un `Text` qui a le droit de revenir à la ligne est
   toute petite : la rangée « tenait » toujours. Les cellules disent maintenant leur vraie
   largeur — `lineLimit(1)` et `fixedSize(horizontal:)`. C'est le même raisonnement que le
   `Spacer(minLength: 0)` de `RUMetricRow`, commenté depuis longtemps dans `ChipView.swift` :
   un élément élastique rend la rangée inextensible à la mesure.

2. **« Allure moy… » — un titre de section tronqué, deux fois**, sur les Stats et sur le bilan.
   Le titre de `RUCardHeader` porte `lineLimit(1)` et `minimumScaleFactor(0.8)` : à côté d'un
   accessoire il rétrécit d'un cinquième, puis se coupe — et c'est le seul mot qui dise de quoi
   parle la carte. Corrigé dans le composant et non aux deux appels : au deuxième cran
   d'accessibilité l'accessoire passe SOUS le titre, poussé à droite pour rester la valeur de cet
   en-tête. Rien ne bouge aux tailles ordinaires, ni pour les soixante-douze en-têtes sans
   accessoire.

3. **La carte de trace n'était PAS rognée**, et j'avais commencé par la « corriger ». J'ai lu
   « 8,1 km 5:18/km » coupé net et changé `height:` en `minHeight:`. Puis j'ai mis les deux
   captures côte à côte : en taille ordinaire, « À faire / 612 / 9 240 » passe exactement pareil
   derrière la barre d'onglets, qui est translucide et flottante. Modification annulée. On ne
   change pas la mise en page d'un écran photographié pour un défaut qu'on n'a pas vu.

### Et le film espagnol, qui n'avait pas le défaut qu'il annonçait

La chaîne Captures est passée au rouge : « ce plan vise stats et montre profil (écart 24,4 contre
25,0) ». Un quasi-ex æquo — là où un plan posé rend 6,4 contre 24,6 — et les trois autres plans du
même film étaient reconnus sans hésitation. Le découpage était donc juste. C'est l'INSTANT du
jugement qui ne l'était pas : l'image était prise à `debut + 0,5 s`, et « stats » a mis 0,57 s à
se poser ce jour-là — dix-sept images sur vingt. On jugeait un mélange de l'écran qui part et de
celui qui arrive.

Le jugement se prend maintenant un quart de seconde avant la FIN du plan, qui dure deux secondes.
La référence de transition, elle, reste à 0,5 s : c'est l'état vers lequel la fenêtre précédente
converge, c'est son rôle. Et c'est `--preuves` qui a permis de le voir — le garde-fou a refusé le
film ET gardé l'image jugée, ce pour quoi il avait été écrit la veille.

## Chantier 11 — `jose` 6 : onze minutes de panne, puis la cause, trouvée sur un aperçu

**Fait.** `jose` 5.9.6 → 6.2.15 et `bcryptjs` 2.4.3 → 3.0.3, après une panne, une reproduction
hors production et un correctif éprouvé avant d'être poussé.

### La panne

| Heure (UTC) | |
| --- | --- |
| 17 h 00 | les 83 adresses : 69 × 401, 13 × 405, 1 × 400 |
| 17 h 09 min 48 | `jose` 6 + `bcryptjs` 3 déployés **en production**, construction verte |
| 17 h 15 → 17 h 19 | toutes les routes en 500, `FUNCTION_INVOCATION_FAILED`, quatre sondages |
| 17 h 20 min 50 | retour arrière déployé |
| 17 h 20 min 59 | tout revient |

### Les deux explications fausses, dans l'ordre où je les ai eues

**« Le Node du projet est trop vieux. »** `jose` 6 n'est livré qu'en ESM, et `require` d'un module
ESM n'est actif par défaut que sur Node ^20.19, ^22.12 ou ≥ 23. J'avais vérifié ce que Vercel
*propose* et conclu que le plancher était tenu. Charlotte a ouvert le réglage : **le projet est
sur Node 24.x**. L'explication tombe.

**« Alors c'est le code. »** Node 24.22 installé ici, les quatre points d'entrée du serveur
chargés avec `jose` 6.2.15 et `bcryptjs` 3.0.3 : **les quatre chargent sans broncher**.
L'explication tombe aussi.

### La reproduction, sur un déploiement d'aperçu

Quatre aperçus sur une branche jetable, même code à chaque fois sauf la ligne testée. Il a fallu
couper `Vercel Authentication` le temps de l'essai : sans ça, un aperçu répond 302 vers une page
de connexion et ne se sonde pas.

| Aperçu | Ce qui change | Résultat |
| --- | --- | --- |
| témoin | rien | 405 / 401 — sain, donc les variables d'environnement sont partagées |
| épreuve | `jose` 6 + `bcryptjs` 3 par `require` | **500 partout** — la panne, rejouée |
| bissection | `bcryptjs` 3 seul | 405 / 401 — sain |
| correctif | `jose` 6 par `import()` | 405 / 401 — sain |

**La cause : l'empaquetage des fonctions par Vercel ne sait pas charger par `require` un paquet
livré en ESM seul.** Ni le code, ni la version de Node. Rien dans le dépôt ne pouvait le dire —
construction verte, 133 tests verts, Node au-dessus du plancher. Seule une requête à un
déploiement réel le disait. `bcryptjs` 3 est innocent : il garde une condition `require` vers une
livraison UMD, et c'est toute la différence entre les deux montées.

### Le correctif

`lib/auth.js` et `lib/apns.js` chargent `jose` par `await import('jose')`. C'est un import ESM
ordinaire, qu'aucun empaqueteur n'a à interpréter. Le module est chargé une fois et gardé ; le jeu
de clés d'Apple est construit à la première vérification au lieu de l'ouverture du fichier.

### `bcryptjs` 3, mesuré

Les empreintes déjà en base doivent continuer de se vérifier. Les deux versions installées côte à
côte : la 2.4.3 écrit `$2a$`, la 3.0.3 écrit `$2b$`, et **chacune vérifie l'empreinte de l'autre**.
Les mots de passe existants passent, et un retour en arrière reste possible. Coût 12 : 317 ms. La
licence passe de MIT à BSD-3-Clause.

### Les deux barrières

`ci_scripts/check_cjs.py` refuse un paquet livré en ESM seul chargé par `require`. Il a d'abord
signalé le fichier qu'il venait de faire corriger : le commentaire du correctif CITE
`require('jose')` pour expliquer pourquoi il n'est plus là, et le contrôle lisait ses propres
commentaires. Il les blanchit désormais, en suivant les chaînes pour ne pas couper sur le `//`
d'une URL.

`check_deploiement.py` refuse un 5xx depuis ce matin — c'est lui qui a vu la panne, vingt minutes
après avoir été écrit.

## Chantier 10 — les valeurs en dur : six, pas 15 %

Trois barrières en gardent déjà une partie (`check_grille.py`, `check_teintes.py`,
`check_contraste.py`), donc j'ai mesuré les deux classes qu'elles ne couvrent pas.

### Les couleurs écrites à la main

Vingt-et-une occurrences dans les vues, dont la plupart sont des palettes locales **assumées et
documentées** : `Ink` (l'écran de course reste sombre dans les deux thèmes), la carte de partage et
le cadre vidéo (de l'identité de marque, pas de l'interface), l'orange de Strava, et une variable.

Quatre étaient de vrais défauts :

1. **Le dégradé du tracé était écrit deux fois** — dont une dans `RUColor.traceBackground`. Et le
   commentaire de ce jeton **prédit le défaut mot pour mot** : « il vivait en privé dans
   `ActivityFeedRow`, parce qu'un seul écran en avait besoin […] une deuxième copie aurait divergé
   au premier réglage — c'est exactement ce qui est arrivé aux dix rayons et aux dix-neuf écarts ».
   `ActivityDetailView` **était** cette deuxième copie, trois lignes sous un commentaire qui
   renvoie au fil.
2. **`0x0A0A0E`**, le fond de l'écran de course, écrit en dur à son unique point d'usage — à quatre
   centièmes de bleu près de `Ink.fond`. Deux noirs presque identiques écrits à la main sont la
   façon exacte dont on obtient, un jour, deux noirs visiblement différents. Il s'appelle
   `Ink.ecran`.
3. **`0xFFD79A`**, l'ambre lisible des bandeaux. La raison de l'épingler est écrite depuis
   longtemps en tête du fichier ; seule la valeur traînait en dur, soixante lignes plus loin que
   son explication. Elle s'appelle `Ink.amberTexte`.
4. **`0x0A0A0A`** contre `0x0A0A0E` : l'encre des commandes posées sur un disque blanc, à quatre
   centièmes du fond de l'écran. L'écart n'a aucune raison d'être, et c'est tout l'argument pour
   le nommer. `Ink.surBlanc`.

### Les tailles de police

178 emplois de `.font(.system(size:))`, et **162 sont du dimensionnement de symboles** — ce qui est
légitime : un symbole SF se mesure en points, `RUFont` est une échelle de TEXTE. Des quinze autres,
treize sont des icônes que mon premier classifieur avait manquées, et deux sont des glyphes
typographiques assumés (la coche, l'emoji d'une notification déjà posée sur l'appareil).

### La trouvaille que je n'ai pas changée

`BackChevronButton` et `FrostedBackButton` — les deux boutons « retour » de l'app — dessinent leur
chevron avec le **caractère** `‹` (U+2039, un guillemet simple) sizé en points, là où tout le reste
de l'app utilise `chevron.left`. Un caractère tiré de la police système ne suit ni la graisse ni la
couleur comme un symbole, et il ne s'accordera jamais avec les `chevron.right` des lignes voisines :
l'app a donc un chevron gauche dessiné d'une façon et un chevron droit d'une autre. C'est le même
argument que celui qui a fait retirer les émojis.

Je ne l'ai pas changé parce que ça touche le bouton retour de **chaque** écran et que je ne peux pas
voir le résultat avant de pousser. Le harnais photographie vingt-et-un écrans : la bonne façon de le
faire est de le changer et de regarder.

## Chantier 9 — les tests qui manquaient vraiment

`SubscriptionService` était **déjà couvert, et bien** : sa décision vit dans `Entitlement`, sous
test, avec une table de vérité complète et un commentaire qui dit de quel côté la règle penche
quand elle ne sait pas. Ses deux autres sorties ont leurs fichiers. Le reste est de la plomberie
StoreKit — un test unitaire n'y vérifierait pas notre code, il vérifierait Apple.

Le vrai trou était **`LocationService.consomme`**, qui décide la distance de chaque course. Trois
règles longuement expliquées dans le code et éprouvées par rien, parce qu'elles étaient
inatteignables depuis l'extérieur du fichier : le plancher de bruit (né d'un défaut mesuré : **+2 km
sur une course de 4 km**), le saut à plus de 12 m/s, le seuil de confiance à 65 mètres. Les trois se
trompent **en silence**.

Treize tests. Et l'un d'eux m'a pris en flagrant délit : j'avais écrit l'invariant juste dans un
test et **son contraire huit lignes plus bas**. Le plancher de bruit ne met pas à jour
`lastLocation`, donc les pas écartés s'additionnent — un signal flou perd une fenêtre de
comparaison, pas le trajet. Douze tests sur treize passaient ; c'est la construction qui m'a dit
lequel des deux mentait, et c'était le mien.

## Chantier 8 — les trois écrans que personne ne revoit

**Terminé, et vérifié en regardant les images.** Les trois captures neuves — inscription, mur
d'abonnement, course en cours — montrent bien ce qu'elles annoncent. Deux d'entre elles ne le
faisaient pas au premier essai, et le harnais était vert : l'inscription montrait l'accueil de
Charlotte (le stock SwiftData survit d'un lancement à l'autre, et sauter la graine ne l'efface
pas), la course en cours montrait le décompte de trois secondes (deux secondes d'attente ne
suffisaient pas). Les deux correctifs sont posés et les deux images sont justes.

Ce que la course en cours montre, maintenant qu'on la voit : la carte au niveau du continent
tant que le signal n'est pas pris — c'est l'état du simulateur, pas un défaut —, le bandeau
« Recherche du signal GPS… », le panneau de mesures avec ses tirets d'absence, et les trois
commandes. Elle se tient.


L'inscription, parce qu'on ne s'inscrit qu'une fois. Le mur d'abonnement, parce qu'on est abonné et
qu'`introShown` s'en souvient pour toujours. L'écran de course, parce qu'on le regarde en courant.
Les trois écrans les plus décisifs de l'app, et les trois qu'aucune capture n'avait jamais montrés
— donc les trois qu'on jugeait de mémoire. Le dépôt écrit cette phrase trois fois déjà.

- **`--inscription`** est le seul des trois à demander un drapeau **de moins** : `onboarded` vaut
  `false` à la création, donc il suffit de ne pas poser la graine. Le mode démonstration reste
  allumé — c'est lui qui coupe le réseau et Santé.
- **`--paywall`** contourne `introShown` sans y toucher, donc il ne consomme pas la présentation
  réelle.
- **`--encours`** démarre une vraie course.

### Le piège de l'écran de course

`demarrer()` appelle `location.requestAuthorization()` : une **boîte de dialogue système** se
serait posée sur la capture — au mieux une image de la boîte, au pire trente secondes d'attente
suivies d'un écran qu'on n'a pas vu. La demande est maintenant gardée par `Demonstration.enCours`,
comme huit autres endroits du dépôt, et c'est juste au-delà du harnais : une construction dont le
profil et le club sont inventés et dont le réseau est coupé n'a aucune raison de réclamer la
position de quelqu'un.

Le micro et les notifications, vérifiés aussi, ne se demandent qu'au **geste** — pas à l'apparition.

### Ce que la capture montrera, et ce qu'elle ne montrera pas

**Pas de distance.** Le simulateur n'a pas de signal GPS : 0,00 km et le bandeau « Recherche du
signal GPS… ». C'est l'état des premières secondes de chaque vraie course, et c'est tout ce qu'on
vient regarder — la disposition, le panneau de mesures, les commandes, la place de la bulle du
coach, et le bandeau lui-même. Attendre d'avoir un GPS simulé pour photographier cet écran
reviendrait à ne jamais le photographier.

## Chantier 7 — les états manquants, qui ne manquaient pas

Les **trois** affirmations de l'item sont fausses, et je les ai vérifiées une par une.

- **Chargement de Stats** : l'écran n'a aucun appel réseau. Son `@Query` SwiftData est synchrone,
  et son unique `.task` compte des tracés en mémoire. Il n'y a rien à attendre, donc rien à
  annoncer.
- **Chargement du Coach** : l'indicateur de frappe existe, animé, avec son `reduceMotion`.
- **Erreurs d'inscription** : `SignInView` distingue **deux 409 différents** (« cette adresse a
  déjà un compte avec mot de passe » et « un compte existe déjà »), le 401, le 422, et retombe sur
  `PanneReseau.phrase` pour le reste. Le Coach fait pareil : un refus du modèle et une panne réseau
  demandent deux choses différentes, et il les dit différemment.

### Le balayage que l'item aurait dû faire

Quinze écrans appellent le réseau. Pour chacun : annonce-t-il qu'il charge, dit-il quand il échoue,
dit-il quand il est vide ? **Les quinze ont leurs états.** Mon scan en a d'abord signalé quatre
comme incomplets, et les quatre étaient des faux positifs : il cherchait `isLoading` alors que ce
dépôt écrit `saving`, `isPublishing`, `enCours`. Quatre sur quatre — la même erreur de clé de
recherche que trois fois aujourd'hui.

**Pas de barrière d'intégration continue pour cette règle**, et c'est un choix : un contrôle dont le
premier jet produit 100 % de faux positifs finirait désactivé, et on perdrait les barrières qui
marchent avec celle qui ne marche pas. C'est l'argument que `check_strings.py` écrit lui-même au
sujet de sa cinquième zone aveugle.

### Le seul vrai trou, et il n'était pas dans la liste

Les deux feuilles qui joignent une photo. Après avoir choisi l'image, le bouton affichait toujours
« Ajouter une photo » pendant tout le décodage, le redimensionnement et l'encodage — une à deux
secondes sur une photo de douze mégapixels, pendant lesquelles l'écran ne bouge pas. Le geste
naturel est alors d'appuyer une seconde fois.

Et les trois `guard` sortaient **en silence** : une photo restée sur iCloud, un format que `UIImage`
ne sait pas lire, un encodage qui échoue — rien ne se passait et rien ne le disait. Exactement le
défaut du chantier 2, sur un autre écran. Le bouton annonce la préparation et se désactive pendant,
et chaque échec a sa phrase.

## Chantier 6 — le bilan de la semaine

Mon audit avait noté cet écran 5,5/10 sans dire pourquoi. En le lisant, la raison est nette et
elle est unique : **cinq définitions différentes de « la semaine »**, dans cinq propriétés privées
d'une vue SwiftUI — donc aucune vérifiable, et deux qui se contredisaient sur le même écran.

| Ce qui était affiché | Ce qui était compté | Ce qui aurait dû l'être |
| --- | --- | --- |
| « Parcourus » | à pied | à pied |
| « Volume par jour (km) » | **toutes disciplines** | à pied |
| « Ta meilleure semaine » | à pied cette semaine **vs toutes** les autres | à pied des deux côtés |
| « Nouveau record d'allure » | **toutes** cette semaine vs course avant | course des deux côtés |
| « Temps actif » | **à pied seulement** | toutes disciplines |
| « Séances » | toutes, sans que ce soit écrit | toutes, écrit |

### Le plus grave

`avgPace` est stocké en secondes au kilomètre pour **toutes** les disciplines. Une sortie à vélo à
20 km/h vaut donc 180 s/km, ce qui bat n'importe quelle allure de course à pied. L'écran annonçait
**« Nouveau record d'allure · 3:00/km sur 20,0 km »** après une sortie à vélo : un record de course
inventé par une discipline qui n'en est pas une.

### La règle qui tranche les six cas

**Les kilomètres ne s'additionnent pas entre disciplines, le temps si.** Vingt kilomètres à vélo ne
sont pas vingt kilomètres en courant — les mettre dans le même total ne mesure rien. Une heure, en
revanche, est une heure, et c'est précisément ce que « temps actif » veut dire à côté d'un compteur
de kilomètres.

`RunRecordDiscipline` portait déjà la doctrine, commentaire compris : `.allDisciplines` existe pour
que « toutes » soit **une décision écrite, pas l'absence de décision**. Les cinq agrégations
l'ignoraient ; plus aucune n'utilise `weekRuns` nu.

### Et un sixième cas, dans la liste des séances

La ligne écrivait `avgPace + "/km"` pour toutes les disciplines — donc **« 3:00/km » sous une sortie
vélo**. `TimeFormat.rythme(_:secondesParKm:)` existe et relit le champ dans l'unité que la
discipline *affiche* : au kilomètre à pied, aux cent mètres en bassin, en km/h à vélo.

### Ce qui le garde

Le calcul est sorti de la vue dans `BilanDeLaSemaine` — même raison que `PlanRecap`, et son
en-tête l'explique : une vue SwiftUI ne se teste pas, une structure qui prend un historique et rend
des nombres, oui. `HaizoTests/BilanDeLaSemaineTests.swift`, onze tests, dont « une sortie à vélo ne
bat pas un record d'allure de course » et « la somme des barres est exactement le total affiché ».

## Chantier 5 — les données de démonstration

Premier point de l'audit dont les **trois** affirmations étaient exactes au chiffre près : seize
sorties portant `avgHeartRate: 148`, seize portant `title: "Sortie"`, et un défi de club dont le
mois est écrit en dur.

### La fréquence cardiaque, et pourquoi le fractionné n'est pas le plus haut

Ces valeurs sont des **moyennes de séance** — échauffement, récupérations et retour au calme
compris — pas des pics. Un fractionné VMA touche Z5 pendant ses répétitions, mais ses
trottinements de récupération tirent la moyenne vers le bas : elle finit **sous** celle d'un tempo,
qui est un effort continu au seuil. Écrire 175 en moyenne sur un fractionné aurait été un chiffre
faux sur une capture de l'App Store.

Pour une coureuse intermédiaire (FC max ≈ 190) : footing facile 136, endurance 146, sortie longue
144 (un peu au-dessus du footing facile à cause de la dérive cardiaque sur une heure et demie),
tempo 158 — la plus haute des cinq — et fractionné 152. Une graine décale de quelques battements
d'une sortie à l'autre : **8 valeurs distinctes au lieu d'une**.

### Le titre, dont le vrai défaut était ailleurs

Le seize fois « Sortie » avait **deux causes**, et la seconde touche de vraies utilisatrices :
`HistoryView` affichait `run.title` — le libellé **français** de l'archétype, écrit à
l'enregistrement — au lieu de `run.titreAffiche`. L'écran qui porte toute l'histoire de quelqu'un
sortait donc en français pour une anglophone.

L'accesseur existait, documenté, et était déjà utilisé par le bilan de course, la vidéo partagée et
la carte du parcours. Il avait été oublié dans `HistoryView` (la ligne **et** son libellé VoiceOver)
et dans `WeeklyRecapView`. Et il est strictement meilleur que ce qu'il remplace : il retombe sur le
texte enregistré quand la sortie n'a pas de `sessionKind`, ce qui est exactement le cas que le
commentaire d'`AddRunSheet` protège — une sortie importée de Strava avec son titre libre.

### Le mois du défi

Les captures de la 3.3 ont été prises en novembre : la fiche annonçait un défi **d'octobre**, avec
six jours restants, à côté d'un historique daté de novembre. Le mois vient maintenant du
calendrier, dans la langue de la capture, avec sa clé dans les trois langues.

## Chantier 4 — les finitions de design (émojis faits)

### Ce que l'audit avait mal compté

L'audit disait « 2 émojis UI ». Il y en avait **57**, et « 2 dégradés » là où il y en a une
trentaine dont quatre violets. L'audit avait compté ce qui se voyait sur dix-huit captures, pas ce
qui est dans le code. La coche `✓` n'entre pas dans le compte : c'est un signe typographique, pas
un emoji, et le widget s'en sert exprès.

### Les deux moitiés du travail

**Trente-cinq occurrences** étaient des émojis posés dans une phrase : aucune décision à prendre,
juste à retirer. Un emoji qui tenait lieu de ponctuation rend le signe qu'il remplaçait. Vingt-huit
clés du catalogue renommées, anglais et espagnol nettoyés de la même façon.

**Vingt-deux** étaient des émojis utilisés comme **icône** — un glyphe seul, donc un remplaçant à
trouver. Les neuf objectifs de l'inscription, les quatre visages du ressenti, trois pictogrammes de
la fiche de débriefing, la série, la coupe, deux cibles, une feuille et la pastille Strava.

### Ce qui a été décidé, écran par écran

Sept des neuf symboles d'objectif étaient **déjà employés ailleurs dans le dépôt** — donc déjà
éprouvés : `dumbbell.fill` est le symbole du renforcement, `mountain.2.fill` celui d'une course de
trail, `leaf.fill` celui de la récupération. Les faire se répondre d'un écran à l'autre vaut mieux
que d'en inventer neuf nouveaux. Chaque symbole prend la **teinte de son objectif**, qui existait
déjà dans le système de design et que l'emoji ne pouvait pas porter.

Deux changements de **sens**, pas de dessin :

- la perte de poids portait 🔥, qui parle de dépense. Elle porte une **balance**, qui est ce qu'on
  regarde. Le feu revient à la série en cours, où il veut dire ce qu'il dit.
- « Rester en forme » portait ⚡, qui parle d'intensité — l'inverse de ce que cet objectif propose.
  Il porte un **cœur**.

Le **ressenti** perd ses quatre visages et garde ses quatre mots. Un visage ne dit rien de plus que
le mot qu'il surmonte, et il dit moins bien : il n'est pas ordonné. L'échelle l'est déjà, par la
position des boutons.

La carte « semaine prochaine » passe de 📈 👍 🧘 à une **flèche qui monte, un signe égal, une
flèche qui descend**. Les trois états sont ordonnés ; un bonhomme en lotus ne se compare pas à un
pouce levé.

La **pastille Strava** reste une pastille, dans l'orange de Strava écrit en dur. Le 🟠 n'était pas
de la décoration : il identifiait la marque par sa couleur. Aucune teinte de notre palette ne
convient, et poser `0xFC4C02` dans `RUColor` laisserait croire qu'il nous appartient.

### La barrière posée avant le remplacement

Un nom de symbole SF faux **ne dessine rien** : pas d'erreur, pas de journal, un cadre vide de la
bonne taille. Écrire neuf noms d'un coup sur le premier écran de l'app, c'était neuf occasions
d'expédier une icône invisible.

`HaizoTests/SymbolesTests.swift` demande donc à `UIImage(systemName:)` de résoudre chaque nom — la
seule façon de poser la question, le catalogue appartenant au système. `check_symboles.py` est le
pont qui garantit que la liste éprouvée est exactement celle que le code emploie.

**En l'écrivant, elle a trouvé que 33 noms déjà en production n'avaient jamais été éprouvés** :
les sept familles de séance, la main qui n'applaudit pas encore dans un ternaire, et
`lock.rectangle` / `lock.slash` que j'avais écrits moi-même au chantier 2 deux heures plus tôt. Mon
premier jet d'extraction les manquait tous — il ne lisait que le littéral collé à `systemName:`.
La lecture est maintenant pilotée par le site d'appel, avec deux précautions contre la collision de
noms entre fichiers : la même erreur que dans mon inventaire d'émojis, qui annonçait 21 défauts
dont 17 appartenaient à l'écran d'à côté.

102 noms, zéro émoji restant dans l'interface, et c'est le simulateur qui valide chaque nom à
chaque construction.

### Les cinq autres points, mesurés un par un

L'audit s'étant trompé d'un facteur 25 sur les émojis, chaque point a été **mesuré** avant d'être
touché. Deux se sont révélés faux, deux étaient réels, et un était une décision déjà documentée.

**Le vert du profil d'élévation : à moitié vrai.** Sur l'écran de bilan le vert tient, parce que le
« +123 m D+ » posé juste sous le graphe est vert aussi — la couleur y est le nom de la mesure. Sur
la page d'activité du club, le D+ existe mais dans la grille générique, en `textPrimary`, à six
cases du graphe : le vert ne désignait rien et c'était la seule tache de couleur d'une page rose et
neutre. Repeindre le graphe aurait été pire — la même donnée en deux couleurs selon l'écran. C'est
le D+ qui prend la couleur de sa courbe.

**La bulle du coach : vrai, et le chiffre le dit.** La bulle est posée sur la carte MapKit, donc son
`.ultraThinMaterial` capte un fond clair en apparence claire. À 0,85 d'opacité le fond effectif vaut
`0x303036`, et le sourcil écrit dans la variante claire de l'accent y tombe à **4,25:1** pour
l'accent par défaut — sous le seuil de 4,5:1 d'un petit texte. Le violet n'était qu'à 4,86. À 0,92,
le rose monte à 5,25 et le violet à 6,00 : sept centièmes d'opacité que l'œil ne distingue pas.

**Le segment blanc sur blanc : vrai, et pire que ce que l'audit disait.** La pastille active est
`card` sur un rail `bg2` : **1,25:1 en clair, 1,04:1 en sombre**. Du blanc sur du blanc et du noir
sur du noir, là où WCAG 1.4.11 demande 3:1 pour un élément qui porte un état. L'état était lisible,
mais par le TEXTE seul. Elle porte maintenant un filet d'accent — 4,97:1 en sombre, 3,03:1 en clair
— et non un remplissage : la raison écrite dans le code tient toujours (deux barres roses empilées
ne se hiérarchisent plus), et le filet est la règle du dépôt.

**Les boutons gris en capitales : faux.** `SecondaryButtonStyle` donne **16,27:1** en sombre et
**15,39:1** en clair. Le reproche ne pouvait pas être le contraste. Ce que j'ai trouvé en regardant
ce qu'ils FONT est autre chose, et je ne l'ai pas changé seul — voir ci-dessous.

**Les dégradés violets : une décision déjà prise.** Quatre sites, dont deux sur les surfaces de
partage (carte et vidéo) qui sont de l'identité de marque, pas de l'interface. Des deux autres, la
pastille du niveau garde son dégradé : le commentaire du code montre qu'une passe précédente l'a
décidé exprès (« un point de couleur, pas un aplat plein cadre »), et repasser par-dessus une
décision documentée sans la poser serait exactement ce qu'il ne faut pas faire.

Le FOND de cette carte, lui, était un vrai défaut : le même commentaire affirme « c'est maintenant
une carte comme les autres » alors que seul le mode CLAIR avait été corrigé. En sombre elle gardait
un dégradé de deux teintes écrites en dur qui n'existent nulle part ailleurs, un contour violet à
30 % — un accent dilué, ce que le dépôt refuse partout — et des textes figés en blanc pour
compenser ce fond. Trois symptômes, une cause, et un commentaire qui annonçait la correction des
trois. C'est une carte, dans les deux thèmes.

### Deux trouvailles d'affordance, tranchées par Charlotte

Toutes deux sur `SecondaryButtonStyle`, et toutes deux de l'**affordance**, pas du contraste — le
style est à 16:1.

1. **« ABONNÉ » était une bascule déguisée en état.** Le bouton affichait l'état et son appui
   désabonnait : on croyait lire un statut, on agissait. Décision du 7 novembre : **le libellé dit
   l'action**. « SE DÉSABONNER » et « ANNULER LA DEMANDE ». L'état ne se perd pas — « se
   désabonner » implique qu'on est abonnée.
2. **« RETIRER » était visuellement identique à « MODIFIER »** et partait sans confirmation, alors
   qu'il fait disparaître de la page et des groupes d'allure. Décision : **une confirmation**,
   plutôt qu'un poids visuel différent. Le texte dit ce qu'on perd **et** que c'est réversible —
   sans la seconde phrase, une confirmation fait hésiter sur un geste qui ne coûte rien à défaire.

## Chantier 3 — les délégués CoreLocation

### Ce qui était faux

L'audit en nommait deux, il y en avait **trois** : `LocationService`, `RunWeatherService`, et
`LocationPermission` dans `RouteDiscoveryView`. Les trois publient de l'état lu par une vue à
chaque image et l'écrivent depuis un rappel système, sans aucune garantie du compilateur. La
promesse tenait sur un fait vrai mais invérifiable : `CLLocationManager` livre ses rappels sur la
boucle d'exécution du fil où il a été créé, et les trois créations sont `@MainActor`.

`RunWeatherService` est le cas le plus net. `enAttente` est un emplacement unique, écrit depuis
`position(fallback:)` et depuis deux rappels, et **une continuation reprise deux fois fait tomber
le processus**. Le fichier raconte déjà une course qu'il a fallu voir pour la croire — deux
demandes qui se chevauchent — et la parade écrite à l'époque reste juste ; ce qu'elle n'avait pas,
c'est une garantie que les deux demandes ne s'exécutent pas en même temps.

### Pourquoi pas `Task { @MainActor in … }`

C'est le patron déjà présent deux fois dans le dépôt (`WatchSessionService`,
`VoiceCoachController`), et il est juste **là-bas** : WatchConnectivity et `AVSpeechSynthesizer`
appellent leur délégué depuis leur propre file, donc le saut est obligatoire, et il s'agit d'un
état à poser — pas d'une mesure à accumuler.

`LocationService.didUpdateLocations` accumule : il compare chaque point au précédent, additionne
une distance, alimente un lissage d'altitude. Or **deux `Task` non structurées n'ont aucun ordre
garanti entre elles**. Deux lots de fixes traités à l'envers ne donnent pas un retard : ils
donnent une distance fausse et un dénivelé faux, sur la mesure qui est tout le produit.

`surLActeurPrincipal` fait donc le travail **tout de suite** quand on est déjà sur le fil principal
(`MainActor.assumeIsolated`) : même ordre, même image, aucune ligne ne change de moment
d'exécution, et l'isolation devient vérifiée. Le repli par `Task` existe parce que
`assumeIsolated` seul fait tomber le processus si l'hypothèse est fausse — ce code tourne pendant
quatre-vingt-dix minutes écran éteint, et un plantage au trentième kilomètre serait un prix absurde
pour une vérification de type.

### Le détail qui a demandé deux essais

`NSObject.init()` n'est pas isolé, et un remplacement ne peut pas l'être plus : les trois
initialiseurs sont donc `nonisolated`. Ça, c'était juste du premier coup.

Ce qui était faux, c'est ce que j'ai cru qu'un tel `init` avait le droit de faire ensuite. J'avais
retiré leur valeur par défaut à `manager` et `authorizationStatus`, en pensant que leur affectation
compterait alors comme de l'**initialisation**, qui n'a pas besoin d'isolation, plutôt que comme
une **mutation**, qui en a besoin. Le compilateur dit non, et il l'a dit en trois lignes dont une
erreur franche :

```
RouteDiscoveryView.swift:355: error: main actor-isolated property 'status'
can not be mutated from a nonisolated context
```

Les propriétés gardent donc leur valeur par défaut, et tout le réglage part dans un
`reglageInitial()` isolé appelé par `surLActeurPrincipal` — qui l'exécute **tout de suite**, avant
que l'`init` ne rende la main, puisque les trois constructions sont `@MainActor`.

J'avais hésité entre deux formes et j'ai poussé la moins sûre sans le dire. La construction est le
seul compilateur de ce projet : quand il y a un doute, la bonne méthode est de pousser la forme
dont on est sûr.

### Ce qui le garde

Le compilateur. L'isolation est une propriété de compilation : une construction verte EST la
vérification, et inventer un test unitaire pour en faire semblant serait pire que rien.
L'algorithme de distance de `LocationService` — plancher de bruit, saut à 12 m/s — n'a toujours
aucun test ; c'est le chantier 9, qui le nomme.

## Les treize avertissements du dépôt, et leur cause unique

Onze des treize venaient d'UNE insertion. `markSessionDone` avait été écrit **entre** le
`@discardableResult` de `applyDebrief` et `applyDebrief` elle-même. L'attribut s'est recollé sur
`markSessionDone`, qui ne rend rien — « declared on a function returning 'Void' is unnecessary » —
et les dix appels à `applyDebrief` se sont mis à avertir « result of call is unused ». La
documentation, elle aussi restée en haut, décrivait une fonction qui n'était pas celle qu'elle
surplombait.

Et l'avertissement avait raison : `applyDebrief` rendait « Programme mis à jour · +120 XP » que
**personne ne lisait**. Son unique appelant, `DebriefSheet`, jetait la valeur et affichait la même
phrase écrite une seconde fois chez lui — les deux copies avaient déjà divergé. La fonction ne rend
donc plus rien ; la phrase appartient à l'écran qui l'affiche.

Les deux derniers : un `try? await auth.refreshMe()` dont on ne voulait que l'effet de bord, et un
`let today` devenu inutile quand la pastille du jour du widget est passée au calcul chez le widget.

**Zéro avertissement.** C'est ce qui rend la règle « aucun avertissement nouveau » vérifiable : un
treizième se perdait dans douze.

## Chantier 2 — l'activité en direct

### Ce qui était faux

`startLiveActivity` avait **deux sorties muettes** : un `guard` sur l'interrupteur du système et
un `try?` sur la demande. Les deux rendaient exactement le même écran — l'écran de course
ordinaire — et la coureuse qui verrouillait son téléphone n'y trouvait rien. Ni elle ni nous ne
pouvions distinguer « l'interrupteur des Réglages est éteint » de « ActivityKit a refusé » de
« tout va bien ». Le défaut a coûté une recherche entière : l'absence d'affichage sur l'écran
verrouillé a été prise pour un bug de l'app alors que la case « Activités en direct » était
simplement décochée dans les Réglages du téléphone.

### Ce qui a changé

| | Avant | Après |
| --- | --- | --- |
| Interrupteur éteint | rien | bandeau sur l'écran de course, 45 s, qui ouvre les Réglages |
| Refus d'ActivityKit | rien | bandeau qui dit ce qui est perdu, sans envoyer nulle part |
| Trace durable | aucune | une ligne d'état dans Réglages → Course, suivie en continu |

Les deux causes restent **distinctes** et non un seul « indisponible » : l'une se répare en deux
touches, l'autre ne se répare pas. Les confondre enverrait la coureuse chercher une case qui
n'existe pas. Le bandeau du GPS passe devant celui-ci : il parle de la course, qui est en train de
ne pas être enregistrée.

### Trouvé en travaillant dessus

`bannerBody(icon:text:)` prenait un `String`, donc `Text(text)` **ne consultait jamais le
catalogue**. Les trois avertissements GPS de l'écran de course sortaient en français en anglais et
en espagnol — alors qu'ils y sont, traduits, depuis le début. Quelqu'un avait fait le travail de
traduction et le paramètre le jetait. Dont « Localisation refusée — ouvrir les Réglages » : la
phrase qu'on lit au moment précis où l'app a l'air cassée.

Mesuré ensuite sur tout le dépôt, pour savoir si c'était un cas ou une classe : 48 méthodes
rendent un paramètre `String` par `Text(…)`, et **4 seulement** reçoivent un littéral — `min`,
`km`, des symboles d'unité identiques dans les trois langues. La classe est fermée, le bandeau en
était le seul vrai cas.

Un premier jet de ce scan indexait les méthodes par NOM seulement et a rapporté 21 défauts, dont
17 appartenaient à la méthode d'un autre écran : `HomeView.statTile` fait déjà
`Text(LocalizedStringKey(label))`. Il a fallu ouvrir le fichier pour le voir.

### Ce qui le garde

`check_strings.py` gagne une sixième règle : tout littéral confié à un paramètre de **méthode**
typé `LocalizedStringKey` est réclamé au catalogue. Les cinq rangs précédents ne regardaient que
les initialiseurs de composants, alors que la méthode privée est la forme la plus courante du
dépôt. Aucun faux positif possible — c'est le type du paramètre, pas son nom, qui le dit — et la
règle est scellée au fichier, pour la raison qu'on vient de voir. Trois cas de plus dans
`test_strings.py` (28/28).

## Chantier 1 — le suivi du cycle

### Ce qui était faux

1. **L'ovulation était posée au milieu du cycle** (`length / 2`). C'est la phase lutéale — de
   l'ovulation aux règles suivantes — qui dure à peu près toujours quatorze jours ; c'est la phase
   folliculaire qui varie. Le milieu tombe juste pour vingt-huit jours et faux partout ailleurs :
   trois jours trop tard sur un cycle de 21 jours, quatre jours trop tôt sur un cycle de 35.
   L'erreur grandissait en s'éloignant de vingt-huit jours, donc elle frappait exactement celles
   dont le cycle n'est pas celui du manuel.
2. **La phase du jour était recopiée sur les sept jours de la semaine** — et sur toutes les
   semaines suivantes du plan, que l'écran du plan prévisualise. Une semaine entière pouvait
   s'annoncer « phase menstruelle » alors que les règles finissaient le mardi.
3. **L'heure de la saisie décalait le cycle d'un jour.** `dateComponents([.day])` tronque : des
   règles enregistrées à 23 h et un jour de séance qui vaut minuit étaient séparés de « −1 jour »,
   donc aucune adaptation le jour même de la saisie.
4. **Quatre messages affirmaient des effets que la littérature ne soutient pas** : « bon moment
   pour pousser » en phase folliculaire, « pic de forme estimé » à l'ovulation, un ressenti plus
   dur en phase lutéale, et 15 % de durée en moins sur **toute** la semaine menstruelle — footing
   et sortie longue comprises.
5. La note de phase **écrasait** celle de la blessure : une séance raccourcie de 30 % pour un genou
   sensible s'annonçait « phase lutéale estimée ».

### La source

McNulty KL, Elliott-Sale KJ, Dolan E, Swinton PA, Ansdell P, Goodall S, Thomas K, Hicks KM.
« The Effects of Menstrual Cycle Phase on Exercise Performance in Eumenorrheic Women: A Systematic
Review and Meta-Analysis. » *Sports Medicine* 50(10) : 1813-1827, 2020.

Soixante-dix-huit études. Effet de groupe **trivial** (taille d'effet de l'ordre de −0,06), qualité
de preuve **faible**, recommandation explicite d'une **approche individuelle**. Le seul effet retenu
est une légère baisse de performance en phase folliculaire précoce — c'est-à-dire autour des règles.

### Ce qui a changé

| | Avant | Après |
| --- | --- | --- |
| Jour de l'ovulation | `durée / 2` | `durée − 14` |
| Phase lue | une fois, le jour d'ouverture de l'app | pour chaque jour de séance, à sa vraie date |
| Semaine menstruelle | −15 % sur les sept jours, sortie longue comprise | −10 % sur la seule séance de qualité |
| Phase lutéale | −8 % sur la séance de qualité | rien |
| Folliculaire, ovulation | « bon moment pour pousser », « pic de forme estimé » | la phase estimée, et le renvoi au ressenti |
| Note de blessure | écrasée par la phase | conservée ; le cycle se tait |

Les quatre nouvelles notes sont au catalogue dans les trois langues. Les quatre anciennes y restent
volontairement : une semaine déjà enregistrée les porte encore, et les retirer les ferait ressortir
en français chez une anglophone jusqu'à la régénération du lundi suivant.

### Ce qui le garde

`HaizoTests/CycleTrackingTests.swift`, sept nouveaux tests : le jour d'ovulation sur des cycles de
21, 28 et 35 jours ; la phase calculée pour un autre jour qu'aujourd'hui ; l'heure de saisie qui ne
décale plus rien ; chaque note qui correspond à la phase de son propre jour ; la sortie longue qui
ne dépend plus de la phase ; une semaine hors règles identique à celle de quelqu'un qui ne suit pas
son cycle ; la note de blessure qui survit.

---

## 12 novembre 2026 — la continuité d'un changement demandé

Point soulevé par Charlotte : « il faut faire très attention à la dégradation de la continuité.
TOUTES les informations doivent être prises en compte lorsqu'un utilisateur demande un changement ».
Audit en lecture seule des six chemins par lesquels un changement entre dans le programme, puis
correction.

### Le jeu de référence

`generateWeekSessions` applique neuf règles. **Trois dépendent du jour où la séance tombe** : le
plafond de temps (`TempsDisponible.plafond`, le week-end commence au jour 5), la phase du cycle
(lue par jour), et le jumelage de l'enchaînement d'ultra (le lendemain calendaire de la sortie
longue).

### Les cinq écarts mesurés

1. **La régénération inversait la demande.** `applyProgramSettingsChange` reconstruit la semaine de
   zéro et ne préservait que les jours faits. Nuit de cinq heures à 8 h : le fractionné du jour
   passait de 60 à 42 minutes, en souple. Elle écrivait au coach à 10 h « j'ai mal au genou,
   allège » : la semaine était régénérée, la séance revenait à 45 minutes **avec ses intervalles**.
   Elle demandait moins et obtenait plus dur qu'une minute avant — sans recours, le garde du jour
   étant déjà consommé. Le même effacement se produisait **sans qu'elle demande rien** : l'allègement
   du coach expire tout seul au lancement et déclenche la régénération, donc un déplacement posé
   mardi n'existait plus jeudi matin.
2. **Le plafond de temps du jour d'arrivée n'était jamais relu.** Sa sortie longue du dimanche
   déplacée au mardi gardait ses 95 minutes chez quelqu'un qui avait répondu « 45 minutes en
   semaine ». L'information était dans son profil ; le chemin ne l'ouvrait pas.
3. **La note de phase voyageait avec la séance.** Déplacée de quatre jours, une séance de qualité
   annonçait « phase lutéale estimée » un jour en phase menstruelle. Pas une mention inutile : une
   mention fausse.
4. **Deux implémentations du déplacement.** `moveTodaySessionToTomorrow` ne passait pas par
   `SessionMove` : ni l'avertissement sur les jours durs enchaînés, ni le refus d'écraser un jour
   déjà fait. La même règle d'entraînement, appliquée dans un écran et pas dans l'autre.
5. **Le contrôle du jour consommé sans donnée.** `lastSameDayAdjustmentCheckDay` est posé avant le
   garde du signal : une ouverture avant que Santé ait écrit la nuit brûle le contrôle de la
   journée. Le plus faible des cinq, laissé au chantier #17.

Vérifié et **écarté** : `adaptationNote` et `adjustment` sont bien localisés à l'affichage
(`Session.swift:549`, `ChipView.swift:70`) et les trois chaînes sont au catalogue. Pas de défaut de
langue ici.

### Ce qui a changé

Le principe était déjà écrit dans le dépôt, en tête de `TrainingEase.swift` : « une séance éditée à
la main serait effacée au passage suivant ; ce qui survit, ce sont les ENTRÉES du générateur ». Les
deux changements qui ne le suivaient pas en sont devenus des entrées (`ChangementDemande.swift`) :

- `DeplacementDeSeance` — un échange de deux jours, **rejoué** sur la semaine fraîchement générée.
  Il porte son numéro de semaine et **la forme de semaine contre laquelle il a été demandé**, parce
  que « déplace ma séance du jeudi » ne veut plus rien dire quand le jeudi n'est plus un jour de
  course : rejoué quand même, l'échange reposerait une séance sur le jour qu'elle vient de déclarer
  impossible.
- `AllegementDuJour` — le jour et la mention. Le facteur et le passage en souple ne sont **pas**
  stockés : ils se déduisent de la séance qui occupe vraiment ce jour-là, sans quoi un footing se
  verrait raccourci de 30 % parce que la séance qui était là ce matin était un fractionné.

`generateWeekSessions` se construit maintenant en **trois étapes** : quel archétype sur quel jour,
sans aucune règle du jour ; les déplacements rejoués ; puis les règles du jour, calculées sur le
jour **final**. C'est l'ordre qui est le fond du sujet — une seule étape rendait les écarts 2 et 3
inévitables.

La bande de jours de l'accueil se lit désormais sur **ce que la semaine porte** et non sur les jours
de course : `moveSession` la rapiéçait de son côté, la même règle écrite deux fois dont la version
du générateur reprenait le dessus à la régénération suivante.

Deux conséquences que la modification elle-même a ouvertes, trouvées et fermées :

- l'instantané d'annulation du coach ne capturait pas la liste des déplacements, donc « Annuler »
  rendait la semaine d'avant en laissant le déplacement — que la régénération suivante rejouait.
  L'annulation se défaisait toute seule ;
- `deplacementsDeLaSemaine` devait entrer dans la sauvegarde, puisque `weekSessions` y est : sans
  elle, une restauration ramenait la semaine déplacée puis l'annulait une heure plus tard.
  `allegementDuJour` reste volontairement dehors, comme son propre repère — après une restauration
  le contrôle se rejoue et relit la vraie nuit.

### Ce qui le garde

`ci_scripts/check_entrees.py` et ses **17 cas** : la semaine du plan ne s'écrit qu'à la génération.
Les deux premiers cas sont les défauts réels recopiés tels quels — un garde qui ne les rattrape pas
ne sert à rien, et c'est la seule façon de le savoir. Deux faux positifs sont tenus explicitement :
lire la séance du jour dans un `guard let` n'est pas l'écrire, et une ligne commentée ne satisfait ni
ne viole la règle. Une première version ne regardait que le **premier** `=` de la ligne et laissait
donc passer `if let v = p.weekSessions { profil.weekSessions = v }` — précisément la forme du fichier
de restauration, donc une forme qu'on recopie.

`HaizoTests/ContinuiteDuPlanTests.swift`, **12 cas** : le rejeu en entiers (échange, jour vide,
composition, réversibilité), le refus d'un déplacement portant sur une autre forme de semaine, le
plafond de temps du jour d'arrivée, la note de phase du jour d'arrivée, la survie à une régénération,
la non-inversion d'un allègement, l'oubli au passage de semaine, l'annulation du coach, et la bande
de jours. Deux d'entre eux dépendaient du jour où la CI tourne — un test qui n'échoue que le vendredi
n'est pas un test : ils choisissent désormais leurs jours à partir d'aujourd'hui.

Deux cas ajoutés à `DecodageTolerantTests` : un déplacement illisible ne concerne aucune semaine
(rejoué, il tirerait une séance vers une case hors semaine, c'est-à-dire l'effacerait), et un
allègement sans jour est un allègement expiré.

---

## 12 novembre 2026 — un `nil` qui disait deux choses à la fois

Cinquième écart de l'audit de continuité, traité à part parce qu'il change une sémantique et non
une structure.

`applySameDayAdjustmentIfNeeded` posait son repère de journée (`lastSameDayAdjustmentCheckDay`)
**juste après le garde de date, avant de regarder le signal**. Et il recevait le sommeil sous la
forme d'un `Double?`, dont le vide voulait dire deux choses opposées : « aucune source de sommeil
connectée » — une réponse définitive, il n'y a rien à attendre — et « une source est connectée mais
la nuit n'y est pas encore écrite » — une absence provisoire.

Conséquence : quelqu'un qui ouvrait l'app à 6 h 30, avant que sa montre ait versé la nuit dans
Santé, brûlait le contrôle de la journée sans qu'il ait rien lu. À 9 h la donnée était là, et le
garde refusait. L'information existait, elle est arrivée dix minutes trop tard.

### Ce qui a changé

Un type à trois cas, `AdaptivePlanEngine.SommeilDeLaNuit` — `lu(Double)`, `pasEncoreEcrit`,
`aucuneSource` — qualifié par l'appelant, qui est le seul à savoir lequel. Le repère ne se pose plus
que lorsqu'il y a de quoi conclure : le sommeil a été lu, il n'y a aucune source à attendre, ou le
ressenti d'hier suffit à lui seul.

**Ce que ce choix coûte, dit ici plutôt que passé sous silence.** Une séance jugée trop dure hier,
sur une ouverture où la nuit n'est pas encore versée, s'allège sur ce seul motif et clôt la journée :
la mention composée « nuit courte + séance dure » est alors perdue. L'autre conduite serait
d'attendre le tableau complet, c'est-à-dire de laisser une séance intacte sous les yeux de quelqu'un
qui part courir à 6 h 30, et d'envoyer deux notifications pour la même séance si on repassait
ensuite. Un allègement sur un motif juste mais incomplet vaut mieux que ces deux-là.

### Ce qui le garde

Trois cas dans `HaizoTests/ContinuiteDuPlanTests.swift` : une nuit pas encore écrite ne consomme pas
la journée et la décision se prend bien une fois la donnée versée ; une bonne nuit n'allège rien mais
clôt la journée ; aucune source de sommeil clôt la journée tout de suite, pour que ce contrôle ne se
relance pas à chaque ouverture chez quelqu'un qui n'a jamais connecté Apple Santé.

---

## 12 novembre 2026 — une notification qui promettait ce que l'écran ne montrait pas

Trouvé en auditant la continuité, antérieur au chantier précédent, et traité à part.

Le mécanisme d'allègement du jour accepte la phase « course libre » et posait son allègement ;
l'accueil envoyait la notification « Séance allégée aujourd'hui ». Mais la carte de course libre
**recalcule sa séance à chaque affichage** par `CourseLibre.duJour`, qui ne lisait pas l'allègement.
La notification promettait donc quelque chose que l'écran ne montrait jamais. Une notification qui
ment est pire qu'une notification absente.

### Ce qui a changé

La règle — une séance de qualité perd sa structure et 30 %, une séance déjà souple perd 15 % —
vivait dans le générateur de programme. Elle est devenue **une seule fonction**,
`AllegementDuJour.appliquee(a:)`, appliquée sur la séance **construite** plutôt que sur l'archétype.
Le générateur l'appelle en dernier, la course libre l'appelle aussi : c'est la même nuit courte, elle
ne peut pas vouloir dire deux choses selon l'écran.

C'est aussi une simplification de ce que le chantier précédent avait livré : la variable
`facteurAllegement` qui traversait tout le calcul de durée disparaît, et le test « est-ce une séance
de qualité » se pose une fois, sur la séance, avec `isIntervalSession` — c'est-à-dire exactement le
test d'origine, que ma version sur l'archétype avait rétréci à `kind.isIntervalWorkout`.

Un invariant ajouté avec la règle : **un jour de repos ne s'allège pas.** La course libre en propose
de vrais, à zéro minute ; il n'y a rien à raccourcir, et poser la mention dessus annoncerait une
séance allégée là où il n'y a pas de séance.

### Et la carte le dit

Maintenant que l'allègement l'atteint, se taire serait pire qu'avant : la séance maigrirait de 15 ou
30 % sans un mot, sur la carte dont l'en-tête dit justement qu'une suggestion sans raison est un
ordre. Les deux phrases tiennent ensemble — la première explique la **suggestion**, la seconde la
**réduction**.

La ligne d'explication était écrite trois fois (l'ajustement du moteur, la phrase « pourquoi cette
séance », et maintenant la course libre), chacune avec son `HStack`, sa fonte et sa couleur. Elle
devient `LigneDExplication`, avec **deux initialiseurs** qui ne sont pas une commodité :
`adjustment` est une clé française enregistrée que le catalogue traduit à l'affichage, tandis que la
phrase de `PourquoiCetteSeance` est composée à l'exécution et déjà traduite. Confondre les deux la
traduit deux fois — ce qui marche en français par identité et casse partout ailleurs.

### Ce qui le garde

Trois cas sur la règle pure dans `ContinuiteDuPlanTests` (la qualité perd sa structure, la souple est
seulement raccourcie, le repos ne s'allège pas) et deux dans `CourseLibreTests` (l'allègement du jour
raccourcit bien la séance de course libre et la carte peut le dire ; un allègement d'hier ne
raccourcit rien aujourd'hui).

---

## 12 novembre 2026 — HYROX : un plafond de sécurité qui ne tenait que pour quatre familles sur cinq

Audit de C3 (le contenu HYROX), en lecture seule d'abord. Le format annoncé est juste et sourcé :
l'app dit « 8 × 1 km de course, 8 stations fonctionnelles », ce que confirme
[hyrox.com](https://hyrox.com/the-fitness-race/), et elle n'affirme **aucune charge** — seulement
« charge standard » et « charge renforcée ». C'est prudent : les poids changent par saison et par
division ([rulebook Singles 26/27](https://hyrox.com/wp-content/uploads/2025/07/25_26_HYROX_RulebookSingles_EN.pdf)).

Mais l'audit a trouvé plus grave qu'un manque de contenu.

### Le bloc spécifique HYROX était le seul des vingt blocs du moteur sans séance facile

Les rôles produits par chaque bloc des cinq familles, mesurés :

| Famille | base | spécifique | affûtage | décharge |
| --- | --- | --- | --- | --- |
| Course | easy, speed, longRun | speed, speed, **easy**, longRun | easy… | easy… |
| Ultra | easy, speed, easy, longRun | speed, **easy**, easy, longRun… | easy… | easy… |
| Triathlon | longRun, easy, easy, speed | longRun, speed, **easy**, speed, easy | easy… | easy… |
| Duathlon | longRun, easy, speed, easy | longRun, speed, speed, **easy** | easy… | easy… |
| **HYROX** | easy, speed, longRun | **speed, speed, longRun** | easy, speed, longRun | easy, speed, longRun |

Le plafond de deux séances de qualité par semaine s'applique en REMPLAÇANT la troisième par
l'archétype `.easy` du bloc. Sans archétype `.easy`, il n'y a rien à mettre à la place, et
`generateWeekSessions` garde la séance dure. **Avec six jours de course, le bloc spécifique HYROX
posait cinq séances dures dans la même semaine** — dans le bloc déjà le plus chargé, pour une
épreuve qui compte huit kilomètres de course.

### Et le garde qui aurait dû le voir était vert pour la mauvaise raison

`testNeverMoreThanTwoQualitySessionsInAWeek` cherchait « Fractionné », « Tempo » et « Rappel
d'allure » **dans le titre**, et ne tournait que sur l'objectif course. « Fonctionnel HYROX ·
Circuit intense » ne contient aucun de ces trois mots. Son voisin
`testBuildWeeksAlwaysIncludeAnEasyRun` cherchait « Footing » dans le titre, et ne tournait que sur
l'objectif course lui aussi — l'invariant qu'il tient est précisément celui que HYROX violait.

Compter sur le titre est le défaut que `SessionKind` a été introduit pour réparer ailleurs dans ce
dépôt : un titre se traduit et se reformule, un type non.

### Ce qui a changé

Décision de Charlotte, option recommandée : le bloc spécifique HYROX reçoit **le footing du bloc de
base** — même type, même libellé, même entrée au catalogue. Son objet ne change pas d'un bloc à
l'autre, et inventer une séance quasi identique aurait coûté trois traductions pour dire la même
chose. Placé **en deuxième position**, parce que les archétypes hors sortie longue sont distribués
dans l'ordre des jours de course : en dernier, il laissait les deux séances dures dos à dos, ce que
le moteur interdit justement par ailleurs.

Les deux invariants de sécurité sont réécrits : comptés sur `SessionFamily.isDemanding` et
`Discipline.wearsShoes` — la règle que le moteur applique vraiment (`peseSurLesJambes`) et celle que
l'avertissement de déplacement lit déjà — et exécutés sur **les cinq familles**, six jours de course,
toutes les semaines du plan. La sortie longue est exclue par son JOUR et non par sa famille : en
HYROX la course compromise porte le rôle de sortie longue mais la famille « fonctionnel », et
l'exclure par la famille ne l'exclurait pas.

### La portée du plan est dite, au lieu d'être devinée

Open et Pro ne sont pas les seules divisions officielles : Doubles, Relay et Adaptive ont chacune
leur règlement, et elles ne se préparent pas pareil — en Doubles les équipiers alternent les
stations, en Relay ils se partagent les kilomètres. Décision de Charlotte : garder Open et Pro, et le
dire. L'écran de division porte donc une ligne, dans les trois langues : « Plan écrit pour le format
individuel. Doubles et Relay se préparent autrement. »

### Ce qui reste, et qui est un chantier à part

Charlotte a demandé **un programme d'entraînement spécifique pour HYROX** plutôt que d'ajouter les
deux stations manquantes aux sous-titres existants. `burpee`, `sandbag` et `lunge` apparaissent
aujourd'hui **zéro fois** dans tout le dépôt : six stations sur huit sont nommées, et les deux
absentes sont les deux schémas de mouvement qu'une coureuse n'a aucune autre raison de travailler.
C'est un chantier de contenu, avec une source par station.

Observation non corrigée, parce qu'elle n'est pas une affirmation d'entraînement : le sous-titre de
la division Open dit « le format le plus couru », ce qui est une affirmation sur la participation
pour laquelle je n'ai pas de source. La source officielle dit « the standard HYROX ».

### Et le test élargi a d'abord échoué sur deux faux positifs — les miens

La première version du compte a été refusée par la CI sur l'ultra et le duathlon, et c'est le TEST
qui avait tort, pas le moteur :

- **ultra** : « Sortie de nuit » et « Enchaînement · jour 1 » comptés. J'avais gardé
  `isDemanding`, qui inclut la famille `.longRun`, en croyant que l'exclusion par jour suffirait —
  mais une semaine d'ultra porte PLUSIEURS séances de famille `.longRun`, et n'exclure que le jour
  de sortie longue préféré en laissait deux dans le compte ;
- **duathlon** : « Transitions · T1 et T2 » comptée. Elle porte le rôle `.easy` et le moteur ne l'a
  jamais comptée — son propre commentaire dit pourquoi : « hors de l'axe d'effort […] ce qu'on y
  travaille n'est pas une filière énergétique, c'est un geste ».

Correspondance type → rôle extraite mécaniquement du moteur pour trancher : **aucun type ne porte
deux rôles différents**. La distinction est donc nette, et elle est maintenant écrite là où vivent
les types — `SessionKind.estUnGeste`, qui dit aussi pourquoi `SessionFamily.isDemanding` ne peut pas
y répondre : il sert l'avertissement de déplacement, où avertir en trop ne coûte rien, et il réunit
donc le circuit intense HYROX avec des transitions qui s'apprennent à allure de promenade.

Après correction, les deux semaines mises en cause comptent exactement deux séances dures — le
plafond, pas au-dessus. Il n'y avait donc qu'un seul défaut de moteur, celui de HYROX.

---

## 12 novembre 2026 — « cette séance est-elle dure ? » avait trois réponses

Demandé par Charlotte après le chantier HYROX. Le défaut du bloc spécifique n'est pas passé par une
ligne manquante : il est passé par l'écart entre trois réponses à la même question.

| Qui demandait | Par quoi il répondait | Ce que ça valait |
| --- | --- | --- |
| Le générateur, pour son plafond | le **rôle** de l'archétype (`.speed`) | juste, mais `private` et perdu à la génération |
| L'avertissement de déplacement | la **famille** (`isDemanding`) | délibérément plus large |
| Le test de sécurité | une **sous-chaîne de titre** | ne survit pas à une traduction — et c'est lui qui est resté vert |

### Ce qui a changé

`SessionRole` quitte le `private enum` du moteur et devient un type du modèle, `Codable`, porté par
la séance produite. C'est maintenant la **seule** réponse à « est-ce que ça compte contre le plafond
de deux séances de qualité par semaine ».

Il est **optionnel exprès**, et ce n'est pas une commodité de migration : « on ne sait pas » doit
être représentable. Une séance enregistrée avant ce champ, ou construite ailleurs que par le
générateur — course libre, graine de captures, saisie manuelle — n'a pas de rôle, et la faire passer
par défaut pour une séance facile serait exactement le genre de valeur fausse mais plausible qui ne
casse rien et rend les comptes faux.

Le test de sécurité y gagne en même temps qu'il devient juste : la version intermédiaire approchait
la règle avec **quatre** conditions — famille exigeante, pas de famille `.longRun`, pas un geste,
chaussée — et la CI l'avait refusée deux fois. Il en a maintenant **deux** : le rôle et les
chaussures. La sortie longue est écartée par définition, puisque c'est un rôle à elle. Et il exige
que **chaque séance générée porte un rôle** : sans ce cas, un chemin de génération qui l'oublierait
ferait simplement baisser le compte, et le plafond redeviendrait vérifié pour la mauvaise raison.

`SessionKind.estUnGeste`, écrit une heure plus tôt, est **supprimé** : il n'existait que parce que le
rôle n'était pas observable.

### Ce que l'unification ne fait PAS, et pourquoi

Elle ne réduit pas tout à une seule notion, parce qu'il y a bien **trois questions voisines et
distinctes**, et que les confondre est précisément ce qui a produit les faux positifs de la CI :

1. « Est-ce que ça compte au budget de la semaine ? » → `WorkoutSession.role`.
2. « Faut-il un jour de récupération derrière ? » → `SessionFamily.isDemanding`, plus large exprès :
   pour l'avertissement de déplacement, avertir en trop coûte un haussement d'épaules là où avertir
   en moins coûte une semaine d'arrêt.
3. « Y a-t-il de l'intensité à retirer ? » → le contenu de la séance, dans
   `AllegementDuJour.appliquee`. Elle ne peut pas lire le rôle : l'allègement du jour s'applique
   aussi en course libre, où la séance n'en porte pas, et le lire y rendrait l'allègement muet sur
   un fractionné.

Chacune est désormais répondue **une fois**, à un endroit nommé, avec un renvoi vers ses deux
voisines. C'est l'absence de ces renvois qui avait laissé une sous-chaîne de titre tenir le rôle de
garde de sécurité.

---

## 12 novembre 2026 — HYROX, étape 1 : les quatre divisions et leurs charges

Premier des deux temps du programme HYROX demandé par Charlotte. Celui-ci pose la fondation ; les
séances qui s'en serviront viennent ensuite.

### Ce que le règlement dit, et que l'app ignorait

Le PDF officiel a été lu — `pdftotext` sur le règlement Single 26/27, section 4.1 — et il est
explicite : **« HYROX offers four divisions. The divisions differ in gender and/or weight. »** Les
quatre sont WOMEN, WOMEN PRO, MEN, MEN PRO. C'est le genre autant que le niveau qui décide des
charges, et **Men Open et Women Pro partagent exactement la même colonne**.

| Épreuve | Femmes | Hommes / Femmes Pro | Hommes Pro |
| --- | --- | --- | --- |
| Sled push 4 × 12,5 m | 102 kg | 152 kg | 202 kg |
| Sled pull 4 × 12,5 m | 78 kg | 103 kg | 153 kg |
| Farmers carry 200 m | 2 × 16 kg | 2 × 24 kg | 2 × 32 kg |
| Sandbag lunges 100 m | 10 kg | 20 kg | 30 kg |
| Wall balls | 100 × 4 kg | 6 kg | 9 kg |
| Hauteur de cible | 2,70 m | **2,70 / 3,00 m** | 3,00 m |

SkiErg et rameur font 1000 m, le burpee broad jump 80 m, dans les quatre divisions. Et une
correction de ce que donnait la recherche web : **le sled fait quatre allers de 12,5 m, pas deux de
25**.

L'app ne proposait qu'Open et Pro, et ne stockait aucun genre. Elle ne pouvait donc pas savoir si
une coureuse affrontait 102 ou 202 kg — c'est pour ça, et c'était juste, qu'elle ne nommait aucun
kilo.

### La décision d'avant était bonne ; sa prémisse a changé

L'ancien commentaire de `HyroxDivision` disait : « this app has no verified current-season rulebook
weights to assert as fact, and a wrong "real" number would be exactly the kind of fake precision
this codebase has been fixing everywhere else ». La première moitié n'est plus vraie. **La seconde
l'est toujours** : les charges changent de saison.

Elles sont donc **datées** — `ChargesHyrox.saison` s'affiche avec elles, et l'écran de division dit
« Charges du règlement 26/27 » — et elles vivent à **un seul endroit**, pour qu'une mise à jour soit
une édition et pas une chasse. Un nombre sourcé et daté n'est pas de la fausse précision ; un nombre
sans date en serait.

### Ce que la question demande, et ce qu'elle ne demande pas

Elle ne demande pas un genre comme donnée de santé. Elle demande dans quelle **catégorie** on s'est
inscrit — ce que l'écran demandait déjà — et une seule réponse remplace deux questions. La règle des
données de santé minimales est tenue : rien d'autre dans l'app ne lit cette valeur.

Le sous-titre des cartes annonce maintenant deux charges concrètes — « Sled 102 kg · wall balls
4 kg » — au lieu de « le format le plus couru », qui était une affirmation sur la participation que
rien ne sourçait.

### Le piège du tableau : deux découpages qui ne se superposent pas

Trouvé en relisant le règlement pour préparer l'étape 2, et corrigé avant la fin de la barrière. Les
**poids** groupent « WOMEN », puis « WOMEN PRO / MEN », puis « MEN PRO ». La **hauteur de cible** des
wall balls groupe autrement, deux pages plus loin : « WOMEN / WOMEN PRO 2.70M » et « MEN / MEN PRO
3.00M ».

Hommes et Femmes Pro portent donc exactement les mêmes kilos et **ne lancent pas à la même
hauteur**. La première version de ce fichier leur donnait une seule valeur partagée, parce que leurs
cinq charges sont identiques — ce qui faisait s'entraîner trente centimètres trop bas, cent fois de
suite. Les quatre divisions ont maintenant quatre valeurs distinctes, et les deux colonnes de poids
identiques sont écrites deux fois exprès ; le test tient leur égalité pour que la duplication ne
dérive pas.

### Les profils déjà enregistrés

`open` et `pro` restent décodables mais ne sont plus proposées, et elles ne portent **aucune
charge** : « Open » ne dit pas si elle pousse 102 ou 152 kg, et l'inventer ferait prescrire une
charge fausse à quelqu'un qui s'entraîne dessus. Le plan se tait sur les kilos jusqu'à ce que la
division soit rechoisie. `estPro` remplace un `== .pro` qui ne pouvait pas survivre au passage à
quatre divisions.

### Ce qui le garde

`HaizoTests/ChargesHyroxTests.swift`, onze cas. Ils **recopient le tableau**, et c'est leur intérêt :
ce sont des charges qu'une coureuse va pousser et soulever cent fois, et une faute de frappe — 120
au lieu de 102 — ne casserait rien et ne se verrait pas à l'écran. Les nombres sont écrits à deux
endroits qu'on ne modifie pas d'un même geste, ce qui force à rouvrir la source le jour où le
règlement change. Plus les cas qui tiennent la colonne partagée, la montée monotone des cinq charges
(une transposition de deux colonnes ne se verrait sur aucun nombre isolé), l'absence de charges sur
les divisions héritées, et leur décodage.

---

## 12 novembre 2026 — HYROX, étape 2a : les huit stations, et leurs charges à l'écran

Décision de Charlotte : nommer la vraie station et sa vraie charge, plutôt que de demander le
matériel ou de proposer des équivalences. Le coût est dit plutôt que caché — sans sled, une séance
par semaine devient inapplicable telle quelle, et l'app ne proposera pas de remplaçante, parce
qu'« un sac à dos vaut un sandbag de 20 kg » est une affirmation d'entraînement que rien ne source.

### Le sous-titre d'une séance ne pouvait pas porter la charge

`WorkoutSession.displaySubtitle` lit `kind.subtitleKey`, une clé **statique** du catalogue, et jette
le sous-titre composé par l'archétype. Les archétypes HYROX interpolaient pourtant « charge
standard » / « charge renforcée » dans le leur **depuis le début** — du texte qui n'a jamais atteint
un écran. C'est le défaut exact que l'en-tête d'`adaptationNote` raconte pour les notes
d'adaptation, reconduit pour la charge. Le code mort est retiré.

Les charges s'affichent donc dans la **fiche détail**, seul écran qui a le profil, donc la division,
donc les kilos : les huit stations dans l'ordre de l'épreuve, avec leur distance, leur charge et —
pour les deux qui n'existaient nulle part — leur standard de mouvement.

### Deux défauts trouvés dans la foulée

**`hyroxSteps` aiguillait sur des sous-chaînes de titre** — « compromise », « simulation »,
« tempo » — alors que son voisin `ultraSteps` lit le `kind`, et que le commentaire de l'appelant
disait déjà pourquoi : « Classer par sous-chaîne française quand un champ dédié existe, c'est
reconduire une faiblesse qu'on n'est plus obligé de porter. »

Cette faiblesse avait une conséquence vivante : **un footing HYROX ne contient aucun des trois mots
cherchés.** Il tombait dans le repli et s'affichait « Circuit fonctionnel · stations enchaînées,
technique avant charge » — la description d'un circuit de musculation sur une sortie en endurance.
Rien ne plantait, et l'écran disait le contraire de la séance. L'aiguillage se fait maintenant sur
le `kind`, et les footings sont décrits comme des courses.

### La hauteur de cible passe en centimètres

Le règlement écrit « 2.70M ». Un nombre à virgule doit se formater avec la locale sous peine
d'afficher un point à quelqu'un qui attend une virgule — `ci_scripts/check_decimales.py` le tient.
270 cm dit le même fait sans machinerie, et se lit mieux pour une hauteur de cible. Le sled est
donné en « 50 m en 4 allers » pour la même raison, ce qui est aussi la formulation du règlement :
« 50 METERS [4 X 12.5M] ».

### Ce qui le garde, et un défaut que j'ai failli réexpédier

Trois cas de plus dans `ChargesHyroxTests` : les huit stations existent, aucune n'est nommée deux
fois, chacune porte une dose, et les prescriptions portent les charges de SA division — y compris
la cible des wall balls, qui distingue Hommes de Femmes Pro à kilos égaux.

La première version de ces cas cherchait les **noms français** des stations. L'intégration continue
lance les tests en anglais, où « Fentes sandbag » devient « Sandbag lunges » : ils seraient tombés.
C'est le défaut qu'un cas de `PourquoiCetteSeance` a déjà commis dans ce dépôt, et je l'ai écrit une
seconde fois. Les assertions portent maintenant sur le **rang** dans l'ordre de l'épreuve et sur les
nombres — ce qui ne se traduit pas.

Et la CI a refusé la version suivante, pour une raison plus intéressante : **un entier interpolé dans
une chaîne localisée est groupé par la locale.** La prescription des ergomètres dit « 1,000 m » en
anglais et « 1 000 m » en français, et ne contient « 1000 » dans aucune des deux. L'affichage est
juste — un séparateur de milliers est ce qu'on attend d'une distance — c'est l'assertion qui était
naïve. Elle lit maintenant les chiffres de la phrase, séparateur retiré. Les autres nombres du
tableau sont sous mille et ne sont donc pas groupés, ce qui explique que seules ces deux lignes
soient tombées.

Deux pièges de langue en deux versions du même test. Le premier se voyait en relisant, le second
non : il fallait que la machine le dise.

---

## 12 novembre 2026 — HYROX, étape 2b : une famille de stations par semaine

Décision de Charlotte : une famille à charge réelle par semaine, **plus une séance de qualité en
courant**. Les quatre familles tournent sur quatre semaines, soit trois passages chacune sur un bloc
de douze.

### Les quatre familles viennent du format, pas d'une méthode

L'épreuve groupe elle-même ses stations par ses propres chiffres : deux ergomètres de 1000 m qui ne
portent pas le corps, deux sleds de 50 m aux charges les plus lourdes, deux stations de port sur 200
et 100 m, et deux stations qui font passer du sol à debout — dont une cent fois.

| Famille | Stations | Rangs dans la course |
| --- | --- | --- |
| Pousser-tirer | sled push, sled pull | 1, 2 |
| Porter | farmers carry, fentes sandbag | 5, 6 |
| Sol-debout | burpee broad jumps, wall balls | 3, 7 |
| Ergomètres | SkiErg, rameur | 0, 4 |

C'est une organisation lisible du travail que l'épreuve exige, et rien de plus. **Aucune affirmation
physiologique n'est portée** : le règlement donne un format, pas une méthode, et ce que la source ne
dit pas, le code ne l'invente pas.

### Pourquoi une seule famille par semaine

Le plafond du moteur autorise deux séances de qualité par semaine, et toutes les séances HYROX
comptent comme chaussées. Quatre familles ne peuvent donc pas être dures la même semaine. Une
famille prend **une** place ; la seconde reste à une séance de qualité en courant — parce que
l'épreuve fait huit kilomètres de course, soit la moitié du temps de course pour la plupart des gens,
et que préparer les stations en abandonnant la vitesse à pied serait préparer la moitié de l'épreuve.

### Le piège était dans la distribution, pas dans la liste

Les archétypes hors sortie longue sont distribués dans l'ordre des jours de course, **en bouclant
sur la liste**. Avec deux entrées seulement, quatre jours de course donnent famille, footing,
famille — soit **deux** séances de station dans la semaine, ce que la rotation est censée exclure.
Le bloc de base porte donc **deux footings** dans sa liste, ce qui n'est pas une faute de copie :
trois entrées suffisent à ce que la famille ne tombe qu'une fois jusqu'à cinq jours de course.

Et en spécifique, le footing est placé **entre** la famille et le tempo, pas en fin de liste : en
dernier, les deux séances dures tomberaient sur deux jours de course consécutifs — ce que le moteur
interdit par ailleurs.

### Un défaut reconduit le jour même, et rattrapé

Le tempo du bloc spécifique utilise le type générique `tempoRun`. `hyroxSteps` l'aurait décrit comme
un « circuit fonctionnel » par son repli — exactement le défaut que les footings venaient de subir,
reproduit à l'heure près par la séance que je venais d'ajouter. La liste des séances de course du
découpage le nomme explicitement.

### Ce qui le garde

Cinq cas dans `ChargesHyroxTests` : les quatre familles couvrent les huit stations **chacune une
fois** (une station oubliée ne serait jamais travaillée et rien ne le dirait ; une station comptée
deux fois serait travaillée deux fois plus que les autres), chaque famille a son type distinct et on
retrouve la famille depuis le type, la rotation passe par les quatre en quatre semaines puis
recommence, deux appels pour la même semaine rendent la même famille, et une semaine aberrante ne
fait pas sortir de l'index.

Un cas dans `AdaptivePlanEngineSafetyTests` : **au plus une séance de stations par semaine**, sur
toutes les semaines du plan, avec quatre jours de course — et le bloc spécifique garde bien une
qualité à pied à côté de la famille. C'est la distribution qu'il éprouve, pas la liste.

---

## 12 novembre 2026 — #15 : neuf copies d'une adresse, et un renommage qui les a toutes cassées

Le chantier était noté « le lien Assistance de la fiche ouvre la politique de confidentialité ». Il y
avait deux défauts dans cette seule ligne, et le second est plus grave.

### Le lien d'assistance était la politique de confidentialité

`ci_scripts/asc.py` envoyait à Apple `"supportUrl": ".../privacy.html"`. Or `support.html` existe
dans le dépôt **depuis le 8 novembre** : une vraie page d'assistance, avec une adresse à qui écrire.
La fiche envoyait donc les gens lire ce que l'app collecte quand ils cherchaient à qui s'adresser.

### Et cette adresse est morte

Le dépôt a changé de propriétaire. GitHub Pages suit le propriétaire, pas le nom. Mesuré :

| Adresse | Réponse |
| --- | --- |
| `hicsuntco.github.io/Haizo/privacy.html` | **404** |
| `hicsuntco.github.io/Haizo/support.html` | **404** |
| `hukaia.github.io/RUNUP/privacy.html` | 200 |
| `hukaia.github.io/RUNUP/support.html` | 200 |

L'ancienne adresse était écrite en dur à **neuf endroits** : la fiche App Store dans ses trois
langues, le script qui l'envoie à Apple, la page d'assistance, la page de club, et
`PaywallView.swift`. Aucune conséquence bruyante, et deux graves : la fiche annonçait une politique
de confidentialité **introuvable**, ce qu'Apple exige de fournir ; et le lien du paywall, dans l'app
livrée, ouvrait une page d'erreur au moment précis où quelqu'un s'apprête à payer.

### Ce qui a changé

Une déclaration par langage — `Haizo/Models/Liens.swift` et `ci_scripts/liens.py` — et tous les
porteurs corrigés. Un renommage est maintenant **une ligne de chaque côté**.

`asc.py push-metadata` **vérifie que les deux pages répondent** juste avant d'envoyer la fiche. Cette
question-là appartient au réseau, et c'est le moment où elle compte : la commande passe déjà par le
réseau, donc la vérifier là ne la rend pas plus fragile qu'elle n'est.

### Ce qui le garde

`ci_scripts/check_liens.py` et ses **neuf cas**, hors ligne : toute adresse visant une page de ce
projet est l'une des deux déclarées, les deux déclarations s'accordent, et chaque page annoncée
existe comme fichier. Les deux premiers cas sont l'ancienne adresse recopiée telle quelle.

La première version du contrôle lisait **tout**, `node_modules` compris, et signalait **cinquante et
un** liens de spécification des dépendances — « https://w3c.github.io/FileAPI/ » n'est pas une page
de Haizo mal adressée. Le motif vise maintenant le segment de projet, pris dans la déclaration : un
renommage le suit, et aucune liste d'exceptions n'est à tenir. Les journaux — PROGRESS, AUDIT,
PHASE2 — gardent leurs anciennes adresses, parce qu'ils racontent ce qui a été fait.

---

## 12 novembre 2026 — B8, premier morceau : ce qui n'était pas atteignable

La règle écrite au regard de ce chantier est « à faire par morceaux, jamais d'un bloc, et seulement
là où ça paie ». J'ai donc mesuré les coutures avant de découper, et deux blocs sont restés en place
avec leur raison.

### Deux blocs examinés et laissés

**La sauvegarde.** Ses parties pures sont déjà dans `SauvegardeService`. Ce qui reste dans
`AppState` est l'orchestration : récupérer trois collections du contexte, puis, après une
restauration, relancer le programme, la course libre, l'accord de genre, le thème et les rappels, et
revenir à l'accueil. C'est exactement le travail d'`AppState`. L'extraire aurait été du brassage.

**`recoverInterruptedRunIfNeeded`.** Elle lit le profil et surtout elle **notifie** : elle touche
l'état vivant. La déplacer aurait voulu dire lui faire rendre ce qu'elle voulait annoncer pour que
l'appelant l'annonce à sa place — sans qu'aucun test n'y gagne.

### Le morceau qui paie

Les deux **réparations de données** — renommer les sorties titrées « Repos » et recalculer un
dénivelé positif gonflé — ne dépendaient que du contexte de données. Mesuré avant de bouger : zéro
référence à la navigation, aux feuilles, à la course en direct.

Elles sont sorties dans `Haizo/Services/ReparationsAuLancement.swift`. `AppState` passe de **1 255 à
1 155 lignes**, mais le compteur n'est pas le point : c'étaient deux méthodes **`private`** d'un
objet qu'un test ne peut pas construire sans toute l'app derrière. C'est la même histoire que
`LocationService.majDeLaDistance`, dont le commentaire raconte qu'une règle corrigeant une erreur de
cinquante pour cent n'avait aucun test pour cette seule raison.

### Ce que les sept nouveaux cas tiennent, et que rien ne tenait

`RestDayRunTitleTests` tenait la RÈGLE — `buildRunRecord` refuse d'écrire un nouveau titre de jour de
repos — et `ElevationGainTests` le CALCUL. Personne ne tenait la **réparation** : le marqueur qui la
fait tourner une seule fois, la sélection des lignes à toucher, et le fait qu'elle ne touche pas les
autres.

Les sept cas : un titre « Repos » est renommé ; une course d'avant `sessionKind`, reconnue par son
texte, l'est aussi ; une vraie séance n'est pas touchée — une réparation qui renomme trop efface ce
que quelqu'un a couru ; elle ne tourne qu'une fois, et ce cas **fixe ce que ça coûte** (une ligne
arrivée après, par une restauration, ne sera pas réparée) ; un dénivelé gonflé descend ; il ne monte
jamais, parce que le défaut d'origine ne pouvait que gonfler ; et une course sans tracé garde son
chiffre plutôt que de recevoir un zéro inventé.

Les deux marqueurs `UserDefaults` sont devenus des constantes nommées, pour que les tests les
**lisent** au lieu de les recopier : une clé recopiée qui dérive donne un test qui passe sur une
réparation qui ne tourne plus. Et la suite partage `UserDefaults`, donc les cas les effacent avant et
après — sans quoi le premier poserait le marqueur et les suivants passeraient en n'éprouvant rien.

## 12 novembre 2026 — premier chantier esthétique : le texte entre dans la famille du fond

Charlotte, après une journée de moteur et de gardes : « l'esthétique on a rien changé ». C'est
vrai, et ce chantier ouvre la refonte par le système de design, comme la phase 3 le demande.

### Le défaut, mesuré sur la capture et non déduit du source

Les quatre fonds de l'app penchent tous vers le violet de l'accent — `#F4F3F8` porte le bleu
4 points au-dessus du rouge, `#EDEBF4` 7 points, `#E7E5F0` 9 points. Le texte, lui, sortait en gris
neutre pur.

Sonde sur `raw/fr-FR/clair/1-accueil.png` de la campagne de captures du 12 novembre, avant
changement. Les deux couleurs intermédiaires les plus présentes de l'écran :

| Couleur | Part de l'image | bleu − rouge | Ce que c'est |
| --- | --- | --- | --- |
| `#616161` | 0,362 % | **0** | `text3` sur une carte blanche |
| `#474747` | 0,059 % | **0** | `text2` sur une carte blanche |
| `#5D5C5E` | 0,071 % | +1 | `text3` sur le fond de page |

Et le commentaire de `RUColor.bg` énonce la règle cent cinquante lignes plus haut : « un gris pur à
côté d'un rose vif prend l'air sale, un gris qui partage sa famille non ». Elle était appliquée aux
fonds, et pas aux 835 emplois de texte posés dessus — `textPrimary` 265, `text2` 244, `text3` 318,
`text4` 8.

Défaut mineur du même coup : les trois jetons secondaires étaient des opacités, donc leur couleur
était décidée par la surface derrière et non par le système de design. `text3` sortait à `#616161`
sur une carte et `#5A595D` sur une sous-surface.

### La teinte vient du brief, pas sa luminosité

Le brief demande `#6B6473` en secondaire. Même signature de famille que nos fonds (bleu +8,
vert −7), mais mesuré sur NOS surfaces il donne 4,56:1 sur `bg2` et 4,81 sur `card2` — au-dessus du
seuil, et en dessous des 5,76 et 5,89 que `text3` rendait déjà. L'adopter tel quel aurait reculé la
lisibilité pour gagner une teinte.

On garde donc la direction — vert −6, bleu +8 en clair ; vert −5, bleu +8 en sombre — et on résout
la luminosité sous une contrainte : **aucun fond ne perd de contraste.**

### Avant / après

| Jeton | Clair : avant → après | Sombre : avant → après |
| --- | --- | --- |
| `textPrimary` | `#15151C` — inchangé | blanc pur — inchangé |
| `text2` | noir 72 % → `#443E4C` | blanc 68 % → `#BBB6C3` |
| `text3` | noir 62 % → `#5B5563` | blanc 52 % → `#9893A0` |
| `text4` | noir 22 % → `#B7B1BF` | blanc 20 % → `#514C59` |

Le primaire n'a pas bougé, et c'est une mesure : `#15151C` porte déjà le bleu 7 points au-dessus du
rouge, et le `#15121A` du brief donne 18,53:1 sur une carte blanche contre 18,17 pour le nôtre — un
écart qu'aucun œil ne relève. En sombre il reste le blanc pur, hors famille et volontairement : le
primaire sombre est le seul jeton dont on veut le maximum.

### Fond par fond, et c'est ce qui m'a rattrapé

Ma première résolution était calée sur le **minimum** des quatre surfaces. Elle tenait ce minimum,
et perdait 0,17 de contraste sur `card2` en particulier, 0,18 sur le fond teinté. Le garde l'a
refusée avant la CI ; le cas est dans les tests, nommément, parce que c'est l'erreur qu'on ne voit
pas à l'œil et qu'une prochaine résolution refera.

Les valeurs finales montent sur les cinq fonds dans les deux thèmes — par exemple `text3` clair
passe de 6,02 / 5,76 / 6,19 / 5,89 à 6,50 / 5,77 / 7,18 / 6,08.

### Ce qui le garde

`ci_scripts/check_jetons_de_texte.py`, 16 cas dans `test_jetons_de_texte.py`. Il vérifie trois
choses : aucun jeton de texte n'est une opacité ; chaque jeton secondaire est dans la famille du
fond ; et sur chacun des cinq fonds, aucun ne rend un contraste plus faible que celui que son
opacité d'origine rendait. **Le plancher est donc calculé, jamais recopié.**

Et aucun chiffre de contraste n'est écrit dans un commentaire. Ils y vivaient jusqu'ici, et c'est
exactement comme ça que la branche sombre de `text3` avait pu rester sous le seuil pendant qu'un
commentaire d'à côté affirmait l'avoir corrigée. Le garde les calcule et imprime le tableau.

La borne du fond teinté évite de rejouer la recherche dichotomique d'`AccentTheme` — ce serait
écrire sa règle une deuxième fois. Mélanger 3,5 % de n'importe quelle couleur dans le neutre ne peut
pas l'assombrir plus que 3,5 % de noir pur ; un cas le vérifie sur 4 096 teintes, pour les huit
nuanciers d'un coup.

### La barrière, franchie — et ce que les images disent vraiment

**Construction** : run 538, job `success`, build 1538 parti sur TestFlight.
**Tests** : 874, zéro échec. Le compte ne monte pas — les 16 nouveaux cas sont des gardes Python.
**Avertissements** : le seul `warning:` du journal entier est celui d'Apple,
`Metadata extraction skipped. No AppIntents.framework dependency found.` Zéro du compilateur Swift.

**Captures** : campagne 179, trois langues, deux thèmes, 36 écrans comparés à la campagne 178.

En clair, 18 écrans sur 18 : `#616161` passe de 0,362 % de l'image à **0,000 %**, `#5B5563` le
remplace. En sombre, quatre écrans gardaient une trace de `#8F8F93` — et c'est là que le
pourcentage ne suffisait plus.

| Écran Coach, thème sombre | Pixels `#8F8F93` | Plus grosse composante connexe |
| --- | --- | --- |
| Avant | 840 | **282 px** — un corps de glyphe |
| Après | 172 | **1 px**, et 100 % des composantes font un pixel |

Ce qui reste est de l'anticrénelage : des pixels isolés où un bord de glyphe passe par cette
valeur exacte. Aucun glyphe ne subsiste. Les 36 écrans sont donc conformes, et c'est le critère de
comparaison qui était faux, pas le changement qui était incomplet — `comparer.py` mesure maintenant
la plus grosse composante connexe et non un pourcentage.

### Et la chose honnête à écrire : ça ne se voit pas

J'ai regardé les planches avant/après à l'échelle 1:1, en clair et en sombre. **L'écart n'est pas
perceptible à l'œil.** « mar. 10 nov. », « km », « prochain palier : 30 jours », « Face à la
semaine passée » : identiques. C'était prévisible — six points sur une seule voie — mais il faut
l'écrire, parce que ce chantier répondait à « l'esthétique on a rien changé » et qu'il n'y répond
pas.

Ce qu'il fait : il retire une valeur que le système de design ne décidait pas, il fait monter le
contraste sur les cinq fonds dans les deux thèmes, et il pose la règle de famille avec sa
barrière. C'est du système, pas de la surface. Les chantiers visibles sont les suivants.

## 12 novembre 2026 — deuxième chantier esthétique : le fond devient du papier

Charlotte, après le premier chantier : « Go ». Le levier qu'elle avait laissé ouvert avec D2 — le
`#FBF9F7` chaud du brief, non imposé — est celui qui change tous les écrans d'un coup.

### Le raisonnement qu'il a fallu reprendre

Le fond clair penchait vers le violet de l'accent, et `Colors.swift` en donnait la raison : « un
gris pur à côté d'un rose vif prend l'air sale, un gris qui partage sa famille non ».

**L'argument est bon et il ne tient pas, parce qu'il suppose UN accent.** L'app en propose huit
(décision D1), dont le cyan, le lime et le bleu. Un fond lavande ne partageait la famille que de
deux nuanciers sur huit, et se trouvait en désaccord avec les six autres. Le fond prend donc la
position du papier — un blanc cassé chaud sur lequel n'importe quelle encre se pose.

### La teinte du brief, pas sa luminosité — pour la deuxième fois

| | Séparation page / carte |
| --- | --- |
| Froid actuel `#F4F3F8` | 1,104:1 |
| **Le brief `#FBF9F7`** | **1,050:1** |
| Retenu `#F5F4F1` | 1,100:1 |

`#FBF9F7` est presque blanc : la page ne reculerait plus que de moitié sous la carte, et ce recul
est exactement ce qui empêche une carte à image pleine de se lire comme un trou — c'est écrit en
tête de `bg` depuis des semaines. La valeur retenue garde la luminance de l'ancienne et retourne
sa famille.

### Ce qui a bougé

| Jeton | Avant (froid) | Après (chaud) |
| --- | --- | --- |
| neutre de `bg` | `#F4F3F8` | `#F5F4F1` |
| `card2` | `#EDEBF4` | `#EEECE7` |
| `bg2` | `#E7E5F0` | `#E8E6DF` |
| `textPrimary` clair | `#15151C` | `#181511` |
| `text2` clair | `#443E4C` | `#443F3A` |
| `text3` clair | `#5B5563` | `#5B5651` |
| `text4` clair | `#B7B1BF` | `#B7B2AD` |

`card` reste le blanc pur : c'est la surface la plus claire, elle n'a pas de famille à porter. Le
thème sombre ne bouge pas — ses fonds sont froids, donc ses jetons de texte le restent.

**Les trois surfaces devaient bouger ensemble.** Une page chaude sous des sous-surfaces lavande,
c'est un écran qui se contredit.

### La règle a passé son épreuve, et elle m'a corrigé

Le garde du premier chantier exigeait « bleu au-dessus du rouge ». C'était la famille du moment,
pas la règle. Il lit maintenant les fonds du thème et exige du texte le même penchant, sans nommer
aucune couleur.

Résultat à la première exécution : **il a refusé `textPrimary`.** J'avais écrit la veille « le
primaire n'a pas bougé, il est déjà dans la famille », ce qui était vrai des fonds lavande et
devenu faux sans que rien ne l'écrive. Le primaire clair était resté seul, froid, sur cinq fonds
chauds. `#181511` garde sa luminance — 18,19:1 sur une carte contre 18,17.

C'est la meilleure preuve que la règle est la bonne : **elle a survécu au retournement de ce
qu'elle décrivait, et elle a attrapé ce que son auteur avait oublié.**

### Une quatrième copie du fond, trouvée en cherchant

`ci_scripts/montage.py` portait `--fond` à `0xF4F3F8` en dur : les planches de la fiche App Store
auraient continué à composer sur l'ancien gris-lavande pendant que l'app passait au chaud — une
fiche qui ne montre plus l'app qu'elle vend. Le défaut lit maintenant `couleurs.fond_neutre`.

Les gardes lisent eux aussi les fonds dans la source au lieu d'en porter une copie.

### Deux cas qui ne testaient plus rien

`test_design.py` remplaçait `#5B5563` par une valeur fausse pour vérifier que le garde l'attrape.
La valeur du dépôt est devenue `#5B5651` quelques heures plus tard : la substitution est devenue
sans effet, et **le cas a continué d'afficher « ok » en ne vérifiant plus rien.** Toutes les
substitutions de ce fichier passent maintenant par `_fausse()`, qui refuse de continuer si le
texte cherché n'est plus là.

Même nature dans `test_jetons_de_texte.py` : un cas cherchait une phrase de `Colors.swift` à la
lettre, et mon remaniement l'avait repliée sur deux lignes. La prose est cherchée après
normalisation.

### Les couleurs sémantiques, vérifiées et inchangées

Elles avaient été réglées contre un fond froid. Mesuré sur les nouveaux fonds : elles perdent au
plus 0,02 — le fond chaud a la même luminance. Sur `card`, où `Colors.swift` situe son affirmation,
tout tient : ember 5,47 — azure 5,83 — grape 6,72 — lime 3,22 — cyan 3,41 — amber 4,12.

### L'encre de la page, et une copie de formule qui traînait

Le fond n'était pas seul à porter la famille. `cardShadow` et `cardBorder` étaient teintés de
`#1A162E`, et le commentaire de `cardBorder` citait nommément le raisonnement qu'on venait de
renverser : « le gris de la page poussé vers le violet de l'accent — le même raisonnement que
`bg`, qui penche déjà de ce côté ». `bg` ne penchait plus de ce côté.

La valeur est devenue `RUColor.encreDeLaPage`, un jeton nommé, chaud (`#20180C`) et de même
luminance — 17,54:1 sur une carte blanche contre 17,53. Un noir PUR reste exclu, et c'est le vrai
sujet : sur une page teintée il se lit comme un trait tracé par-dessus le dessin, là où la même
valeur dans l'encre de la page se lit comme son bord.

**Et `SettingsView` recopiait la formule de l'ombre** — encre, accent et part de mélange — pour
son aperçu des habillages, avec sa propre opacité. C'est exactement ce que `fond(pour:)` raconte
avoir déjà coûté une fois : « l'aperçu recopiait la formule, et la copie a fait ce que font les
copies ». La formule devient `RUColor.ombreDeCarte(_:)`, une fonction qui prend l'opacité ; il
reste zéro occurrence de l'encre hors du système de design.

### Deux encres recopiées hors du système, et restées froides

Trouvées en cherchant l'ancienne valeur dans tout le dépôt après coup — c'est-à-dire par chance,
et c'est bien le problème.

**`DailyGoalsWidget.textPrimary`** portait sa propre copie, `#15151C`. La cible du widget ne
compile pas `Haizo/DesignSystem` — frontière de processus, la raison est en tête de
`WidgetAccentPalette` — donc la copie est inévitable. Ce qui ne l'était pas : rien ne la tenait
d'accord avec l'originale. **Le widget aurait porté l'ancienne encre violette sur l'écran d'accueil
du téléphone, à côté d'une app chaude.**

**`RUColor.onAccent`** écrivait la même valeur en dur, et ne peut pas lire `textPrimary` non plus :
ce jeton suit le thème, alors que l'encre sur un aplat d'accent dépend de l'aplat et de rien
d'autre — un bouton rose vif porte la même encre dans les deux apparences.

`check_encres.py` et ses 8 cas tiennent maintenant les deux. Il n'interdit pas la copie, ce qui
serait faux : il refuse une copie **sans correspondance déclarée**, chaque entrée disant quelle
valeur locale doit égaler quel jeton et pourquoi elle ne peut pas l'appeler. Un cas vérifie aussi
qu'une correspondance qui ne trouve plus sa valeur CRIE au lieu de dormir.

### Ce qui garde légitimement l'ancienne famille

Balayage de tous les jetons à valeur littérale, branche claire. Six restent froids, et chacun a sa
raison :

| Jeton | Pourquoi il ne se réchauffe pas |
| --- | --- |
| `azure`, `cyan`, `grape` | Couleurs sémantiques : leur teinte EST leur sens. Un bleu réchauffé cesse de dire « fonctionnel ». |
| `seanceSurface`, `seanceFond` | Surfaces SOMBRES. Une famille suit la clarté de la surface, pas le thème choisi. |
| `traceBackground` | Le fond d'une image, sombre lui aussi. |

`card` reste le blanc pur : c'est la surface la plus claire, elle n'a pas de famille à porter.

## 13 novembre 2026 — l'écran de séance tient enfin la hiérarchie qu'il annonçait

### Deux phrases écrites à soixante lignes l'une de l'autre

`targetPaceLine` : « gros, en accent, c'est la **première chose lue** de l'écran ».
`metricsPanel` : le chrono « **cesse d'être la première chose lue** ».

Mesuré : l'allure était à `hero`, soit 35, et le chrono à 52. **Le chrono faisait 1,49 fois la
taille de ce qui devait être lu en premier.** Une passe précédente l'avait descendu de 64 à 52 et
avait écrit la seconde phrase ; elle n'avait pas été assez loin pour changer l'ordre.

### Ce qui change

| | Avant | Après |
| --- | --- | --- |
| Allure cible | `hero` (35) | **`banner` (44)** |
| Chrono avec consigne | 52, hors échelle | **`hero` (35)** |
| Chrono sans consigne | 64, hors échelle | 64, inchangé |

`banner` est le cran que l'échelle réserve à « une accroche, un record : au plus un par écran ».
L'allure cible est exactement ça. Et le 52 disparaît : une valeur inventée pour un rang qui ne
tenait pas.

Sans consigne — course libre, HYROX — le chrono reste à 64 : il est alors le seul chiffre de
l'écran, il en prend tout le poids, et c'est là que le très grand corps demandé par la direction
artistique se pose.

### Pourquoi 44 et pas plus : une mesure qui a tranché

Largeurs réelles calculées avec les fichiers Inter du dépôt, facteur 1,09 et tracking −3 %
compris, sur l'iPhone le plus étroit (320 − 2×18 = **284 points utiles**) :

| Ligne | à 44 | à 52 |
| --- | --- | --- |
| « 4:45/km » | 193 pt | 229 pt |
| « CIBLE 10:30/km » — coureur lent, échauffement | 261 pt | **301 pt, déborde** |

Le préfixe CIBLE n'apparaît qu'à l'échauffement, en récupération et au retour au calme. À 52, la
consigne se serait tronquée en course, pour les coureurs les plus lents, et aucun test n'aurait pu
le voir.

### Un défaut plus grave trouvé en mesurant autre chose

**Ni le chrono ni l'allure ne portaient de `minimumScaleFactor`.** `lineLimit(1)` sans réduction
tronque, et sur une phrase la troncature se voit — les points de suspension disent qu'il manque
quelque chose. Sur un NOMBRE elle ment : « 1:23:45 » devient « 1:23… », et rien à l'écran ne dit
que ce n'est pas l'heure complète.

Mesuré : la ligne cédait dès **1,31×** de taille de texte système, quand l'app en autorise
**2,00×**. C'était vrai avant ce chantier, et mon passage à 44 l'aurait fait céder dès 1,09×.

### Ce qui le garde, et le trou qu'il avait

`check_grands_chiffres.py`, 10 cas. Un grand corps — `hero`, `banner`, ou `horsEchelle` à partir
de 35 — tenu sur une seule ligne doit pouvoir rétrécir.

**La règle a été corrigée avant d'être écrite.** Sa première formulation exigeait une réduction de
TOUT grand corps, ce qui refusait deux cas légitimes : le titre d'accueil sur trois lignes avec ses
`\\n` explicites dans un `ScrollView`, et le titre du paywall qui porte
`fixedSize(horizontal: false, vertical: true)` pour grandir en hauteur. Passer à la ligne est
l'autre bonne réponse.

**Et le garde était aveugle à son propre cas d'origine.** Sa première version n'acceptait qu'un
nombre littéral après `horsEchelle:`, donc elle ne voyait pas
`horsEchelle: hasInstruction ? RUDisplaySize.hero.rawValue : 64` — la ligne même qui a fait écrire
ce contrôle. Il comptait 8 grands corps ; il en voit 13. Un `horsEchelle:` calculé est désormais
contrôlé dans le doute : exiger une réduction d'un corps finalement petit ne coûte rien, la
manquer sur un grand coûte un chiffre faux à l'écran.

### La barrière de ce chantier n'était pas franchissable, et je ne l'ai su qu'en regardant

L'écran de course EST photographié — en diagnostic, et même à deux fois la taille de texte. J'avais
d'abord écrit l'inverse ; c'était faux, et la correction vient d'avoir ouvert les images.

Les deux montrent la même chose : **une course libre, quatre secondes après le départ, sans
consigne.** Pas d'allure cible, pas de nom de segment, pas de barre de progression. Le chrono est
sur sa branche 64, celle que ce chantier ne touche pas.

**La modification n'apparaissait donc sur aucune image que le projet sait prendre.** Et le trou
dépasse ce chantier : tout ce qu'une app de coaching ajoute à un chronomètre n'avait jamais été
photographié.

Pire qu'une absence. `todaySession` est la séance DU JOUR DE LA SEMAINE où la campagne tourne : un
dimanche de repos, l'allure vaut « — » et le bloc disparaît. Deux campagnes lancées à deux jours
d'écart ne photographiaient pas le même écran — **tout avant/après sur cet écran était faux sans
prévenir.**

`CaptureSeed.seanceDeDemonstration` pose une séance déterministe avant le départ : 6 × 800 m,
allure 4:45, Z4, récupération 400 m. Une séance à RÉPÉTITIONS parce que c'est le cas le plus
chargé — elle seule porte un nom de segment, un restant et une barre. Un footing continu
afficherait la consigne sans ses trois accessoires, donc il éprouverait moins.

Deux erreurs attrapées avant compilation, en vérifiant plutôt qu'en supposant : l'ordre des
paramètres de l'initialiseur de `WorkoutSession`, et `.intervals`, qui n'existe pas comme genre de
séance — c'est `.vo2maxIntervals`.

## 13 novembre 2026 — le cycle a sa teinte, et le mouvement ses raisons

### Le cycle empruntait ses quatre couleurs

`.menstrual` prenait `RUColor.rose`, **c'est-à-dire l'accent choisi par la coureuse** : la phase
menstruelle était rose pour l'une et vert lime pour celle qui a pris le nuancier Lime. C'est
exactement ce que le commentaire de `SessionFamily.tint` interdit vingt lignes plus bas — une
information qui emprunte l'accent change de couleur quand on change de goût.

Les trois autres prenaient `lime`, `cyan` et `amber`, les teintes des **familles de séance**. Un
point lime disait « endurance » sur un écran et « phase folliculaire » sur l'autre.

**Une seule teinte pour les quatre phases, et c'est une mesure.** L'app n'affiche jamais deux
phases à la fois, et celle du moment est nommée en toutes lettres à côté du point. Quatre couleurs
distinguaient donc des choses qu'on ne voit jamais ensemble.

| Jeton | Clair | Sombre |
| --- | --- | --- |
| `cycle` | `#80462E` | `#F2B8A0` |
| `cycleSurface` | `#F6EAE5` | `#130702` |

`#F2B8A0` est la valeur de la DA, ici telle quelle en sombre. En clair elle donne 1,73:1 sur une
carte blanche — la branche claire descend à la même teinte jusqu'à 5,93:1 au pire des cinq fonds.

**Et la surface a repris la teinte de la DA, pas sa luminosité — pour la troisième fois.**
`#FDF1EC` a été dessiné contre le `#FBF9F7` du brief ; sur notre page chaude il donne **1,006:1**,
c'est-à-dire rien. La valeur retenue reprend la séparation de `card2` : 1,179:1 sous une carte.

La phase est maintenant posée SUR cette surface. Elle flottait jusqu'ici au milieu
d'interrupteurs, et rien ne disait qu'elle appartenait à autre chose.

### Les trois durées n'avaient pas de raison — mon audit disait l'inverse

`ecran` et `digit` portent chacune une mesure : 0,10 s de fond vide à couvrir, un plafond de
200 ms avant que le chrono ne tremble. `settle`, `glide` et `draw` n'avaient qu'une étiquette.
J'avais écrit « chacune a une raison écrite » : c'était faux.

**La fourchette du brief ne couvre pas tout**, et c'est la distinction qui tranche. Elle parle des
TRANSITIONS. Une animation de VALEUR — un anneau qui se remplit, un tracé qui se dessine — ne
remplace rien : sa contrainte est d'être finie avant qu'on ait besoin de lire ou d'agir.

| Jeton | Avant | Après | Ce qui le borne |
| --- | --- | --- | --- |
| `settle` | 440 ms | **280 ms** | C'est une transition, et elle gouverne le CHANGEMENT D'ONGLET |
| `glide` | 800 ms | **500 ms** | Le dévoilement de l'ouverture doit finir avant le fondu |
| `draw` | 1 450 ms | **700 ms** | Joue sur chaque carte du fil qui porte un tracé |

`settle` gouverne ce que son propre commentaire appelle « l'animation la plus vue de l'app ».
**Toute l'app paraissait lente de 160 ms, à chaque passage d'un onglet à l'autre.**

### 29 % de l'ouverture se jouait après le début du fondu

Trouvé par addition, pas par l'œil. L'écran de lancement décale trois mouvements puis s'efface
après un délai fixe :

| | Démarre | Finit |
| --- | --- | --- |
| le tracé | 0,00 s | 0,75 s |
| la tuile | 0,42 s | 0,86 s |
| **le dévoilement** | 0,58 s | **1,38 s** |
| *le fondu commence* | | *1,15 s* |

**Personne n'a jamais vu la fin de l'animation d'ouverture de Haizo.** Chaque valeur était
raisonnable toute seule ; le défaut ne vivait que dans leur somme. Avec `glide` à 500 ms, le
dernier mouvement finit à 1,08 s, 70 ms avant le fondu.

### Ce qui le garde, et trois versions ratées

`check_lancement.py`, 7 cas. Il refait l'addition à chaque CI, avec les durées réelles de
`RUMotion` — donc raccourcir un jeton du système ne peut plus désaccorder l'ouverture en silence.

**Mes trois premières versions lisaient le mauvais nombre.** La première prenait le `Task.sleep`
de la branche « réduire les animations », qui sort tout de suite. La deuxième prenait celui
d'APRÈS le fondu, parce que le fondu est lui-même un `withAnimation`. La troisième butait sur une
parenthèse interne. La cause était la même à chaque fois : **j'analysais à l'expression régulière
une fonction à deux branches.**

Le problème n'était pas la regex, c'étaient les nombres — anonymes et dispersés dans les appels.
Ils vivent maintenant dans un `enum Tempo` nommé, qu'on lit d'un coup d'œil et que le garde lit
sans rien deviner. L'addition est devenue évidente à l'œil nu, ce qu'elle aurait dû être depuis
le début.

## 13 novembre 2026 — la pastille hebdo comparait deux choses de nature différente

### Le défaut

`WeekKmSummary` affichait `cetteSemaine − semainePassée`, où la première est la semaine EN COURS,
donc partielle, et la seconde une semaine ENTIÈRE.

**Le lundi matin, tout le monde était « en retard ».** Quelqu'un parfaitement à jour de son plan,
qui n'avait simplement pas encore couru cette semaine-là, lisait « ▼ 19,6 km » **en ambre, la
couleur d'alerte du système**. Une semaine d'allègement, de maladie ou de vacances était peinte
comme une faute.

Aucun symptôme technique : les deux nombres étaient justes et la soustraction correcte. C'est ce
qu'ils MESURAIENT qui ne se comparait pas.

Quelqu'un avait déjà vu la moitié symétrique du problème, écrite juste à côté : « une semaine
passée à zéro ne produit pas une pastille +5,0, qui ferait passer un début pour un progrès ». Le
cas partiel-contre-complet n'avait pas été posé.

### Ce qui change, et ce qui ne change pas

`SemaineComparable.kilometres` coupe la semaine passée **au même point** : lundi à midi, elle
compare le lundi-midi d'il y a sept jours. L'écart redevient une information — « à ce moment-là de
la semaine dernière, j'en étais là ».

**Au même POINT, pas au même jour** : reculer de sept jours exactement conserve l'heure. Comparer
« jeudi 12 h » à tout le jeudi fausserait l'écart d'une demi-journée, et toujours dans le même
sens. Un cas le tient.

**Ce que ce calcul ne décide pas**, et c'est volontaire : qu'un écart négatif s'affiche en ambre,
c'est-à-dire comme une alerte, reste une question de ton de voix. Elle appartient à Charlotte.

### Une troisième copie retirée, et une fonction née morte

Le calcul était écrit deux fois — `HomeView` et `StatsView` — chacune avec sa propre façon de
borner la semaine. Deux copies d'une comparaison, c'est deux occasions de la réparer à moitié.

Et j'ai failli en laisser une de plus : ma première version portait un
`kilometresEntiers(semainesAvant:)` « pour les usages qui voudraient un total de semaine entière ».
Aucun ne le voulait. **Une fonction gardée au cas où est du code mort qui a l'air d'une
intention** — elle est partie, avec le `weeklyKm` de `HomeView` qui n'avait plus d'appelant.

Six cas dans `HaizoTests/SemaineComparableTests.swift`, dont le défaut lui-même : un lundi midi,
avec vingt kilomètres courus la semaine passée mais tous après le mercredi, l'écart doit valoir
zéro — l'ancien calcul rendait vingt.

## 13 novembre 2026 — ce que les captures ont dit, et ce qu'elles ne pouvaient pas dire

### Trois vérifications sur quatre

**L'écran de course porte enfin sa consigne.** « ALLURE CIBLE » et l'allure en accent : cet état
n'avait jamais été photographié depuis que l'app existe. L'allure domine visiblement le chrono —
c'était 35 contre 52, c'est 44 contre 35. Et à deux fois la taille de texte, elle tient
entièrement, sans troncature.

**La pastille hebdo affiche « ▼ 2,4 km » au lieu de « ▼ 19,6 km ».** L'écart est redevenu une
information. L'ambre reste, et c'est la décision de Charlotte.

### La quatrième : mon correctif de déterminisme n'a rien fait

La capture montre une séance continue à 6:18, pas les 6 × 800 m à 4:45 que `CaptureSeed` posait.
`todaySession` est EXTRAITE de `weekSessions` par la génération : y écrire à la main juste avant
une régénération se perd — ce que `check_entrees.py` avertit mot pour mot, dans un paragraphe que
j'avais écrit deux jours plus tôt pour l'autre champ.

L'écriture est retirée. Un code qui ne fait rien mais qui a l'air d'une intention est pire que son
absence.

**Et j'ai failli commettre la même faute en la corrigeant.** J'ai voulu étendre le garde à
`todaySession`. Il a signalé quatre sites, et les quatre sont légitimes : l'initialiseur du profil,
le décodeur de sauvegarde, la substitution par la course libre qui tourne juste APRÈS le moteur par
conception, et une constante locale `let todaySession = profile.todaySession` que mon motif prenait
pour une affectation. La règle n'a pas été ajoutée — ce qui m'a piégé est l'ORDRE d'exécution, et
une expression régulière ne le voit pas.

### Le cycle n'apparaissait sur aucune des 147 images

Cherché pixel par pixel dans toute la campagne : **zéro occurrence** de `cycle` et de
`cycleSurface`. Deux raisons, toutes deux corrigées :

Le profil de démonstration portait `cycleTrackingEnabled: false`, donc `cyclePhase` rendait nil et
la ligne ne se dessinait jamais. Il l'allume maintenant, avec une date **relative** — huit jours
avant minuit, soit le neuvième jour du cycle, à trois jours de chaque borne de la phase
folliculaire, pour qu'aucune dérive d'heure ne la fasse basculer. C'est une ENTRÉE, contrairement à
la séance du jour.

Et la feuille des réglages n'était photographiée nulle part. Elle n'est pas un `AppScreen` : c'est
une feuille présentée depuis le profil, que le harnais ne sait pas atteindre en demandant un écran.
`--reglages` l'ouvre, exactement comme `--paywall` ouvre le mur d'abonnement — le fichier portait
déjà ce patron, et sa raison écrite.

## 13 novembre 2026 — une baisse programmée n'est plus une alerte

Charlotte a tranché : option 2. L'ambre ne sort que si la baisse n'était **pas** prévue.

### Ce que l'app se disait à elle-même

Le fil des phases du plan annonce, mot pour mot : « En gris, les semaines de décharge : le volume
baisse **exprès**, c'est là que les progrès se fixent. » Et la pastille peignait cette même baisse
en `amber`, que DESIGN.md § 2.2 définit comme « attention ». **L'app prescrivait une baisse, puis
l'affichait comme une faute.**

### Ce qui change

| Semaine | Écart négatif |
| --- | --- |
| Base, Spécifique | ambre — la baisse n'était pas prévue |
| **Décharge, Affûtage** | **neutre (`text3`)** — le plan l'a demandée |

**L'affûtage compte pour la même raison**, et ce n'est pas une extension de confort : son
commentaire dans `trainingBlock` dit qu'il « déleste par construction ». Une semaine d'affûtage où
l'on court moins fait exactement ce qu'on lui demande.

**La baisse reste affichée.** La masquer rendrait l'app moins honnête, pas plus douce — elle cesse
seulement d'être criée.

### La question se répond une fois

`AdaptivePlanEngine.baisseProgrammee(forWeek:shape:)`, dans le moteur et non dans les vues :
l'accueil et les statistiques affichent la même carte de semaine, et deux lectures d'une même
question sont deux occasions d'en changer une seule. C'est la quatrième copie retirée de cette
carte en deux jours.

Quatre cas dans `BaisseProgrammeeTests`, dont celui qui exige que **les quatre blocs soient
classés** : un bloc oublié prendrait silencieusement le comportement par défaut.

## 13 novembre 2026 — la signature s'étend aux cinq écrans, et son encre était fausse

Charlotte : « Étends la signature aux quatre autres écrans. » DESIGN.md § 9 mesurait l'état :
part d'image sombre en thème clair, Club 30,1 % · Accueil 15,0 % · Coach 2,6 % · Stats 1,9 % ·
Journée 1,6 % · Plan 1,3 %. Deux écrans sur six portaient la direction artistique.

### D'abord dire ce qu'est la signature

Avant de peindre, il fallait la définir — sinon on applique un fond sombre et on produit
exactement le rendu générique qu'on fuit. Elle est écrite dans `CarteDeNuit.swift`, qui est le
composant, pour qu'on ne puisse pas la suivre sans la lire. Quatre règles, et il faut les quatre :
**ce qui est mesuré devient le dessin** ; **le dessin occupe le cadre** ; **la nuit, et rien
d'autre d'allumé** ; **les chiffres se posent dessus**. Et une cinquième, négative : **une seule
par écran.**

La règle 1 est celle qui tranche le plus : les états vides des Stats n'ont pas de carte de nuit,
parce qu'il n'y a rien à dessiner. Une nuit vide avec un chiffre dessus serait un fond sombre
pour faire signature, c'est-à-dire ce que la règle refuse.

### Ce que chaque écran y met

| Écran | Le dessin | Posé dessus |
| --- | --- | --- |
| Plan | seize semaines de volume, en couleurs de phase | le nombre de semaines, le plus gros volume |
| Stats | la courbe d'allure et son point RECORD | l'allure moyenne et son écart |
| Coach | les sept jours de la semaine, famille et durée | forme, séance du jour, dernière sortie |
| Journée | l'anneau des trois objectifs | le compte, au moyeu de l'anneau |
| Accueil | *(inchangé)* le tracé GPS, repassé sur le composant | sa date, sa distance, son allure |

Le ruban du Coach est un objet nouveau, et il parle la langue du graphique du Plan : des hauteurs
côte à côte. L'un montre seize semaines de volume, l'autre sept jours de séance. Ce n'est pas une
répétition, c'est une grammaire — la forme d'un entraînement se lit en hauteurs, qu'on regarde un
bloc ou une semaine.

### CE QUE J'AI TROUVÉ EN CHEMIN, ET QUI COMPTE PLUS

La nuit vaut `#14131E` dans les deux thèmes — c'est écrit, et c'est juste. Mais **tout ce qu'on y
peignait suivait le thème de la page.**

- L'anneau de départ du tracé GPS était en `RUColor.textPrimary`, soit `#181511` en thème clair :
  du presque-noir à 85 % sur du presque-noir. En recadrant la capture de l'accueil, il ne se lit
  pas comme un repère mais comme un **trou** percé dans la lueur. Le thème clair est le défaut
  depuis la décision D2 : c'était le cas normal, pas un cas limite.
- La trace fantôme, à 7 % de la même encre, disparaissait.
- Le tracé lisait `RUColor.rose`, qui rend `primaryOnLight` en thème clair — une valeur descendue
  par `meetingContrastOnWhite` pour rester lisible **sur du blanc**, qu'il n'y a pas ici.

Mesuré, rapport de luminance de l'accent contre `#14131E` :

| nuancier | sombre | clair | perte |
| --- | --- | --- | --- |
| rose, violet, bleu, magenta | 4,23 à 5,55 | idem à 6 % près | ≤ 6 % |
| corail | 5,94 | 5,25 | 12 % |
| ambre | 10,10 | 5,26 | 48 % |
| cyan | 10,37 | 5,25 | 49 % |
| lime | 12,34 | 5,23 | 58 % |

Le nuancier par défaut ne perd rien, ce qui explique les deux mois : **trois nuanciers sur huit
perdaient la moitié de l'éclat de leur tracé**, et personne ne les regarde en premier.

D'où la famille `surLaNuit` / `surLaNuit2` / `surLaNuit3`, `accentsDeLaNuit`, et les six couleurs
sémantiques en `*Sombre`. `check_nuit.py` la tient : il refuse un jeton de page dans le corps d'un
appel à `CarteDeNuit` et dans les fichiers qui ne dessinent que sur la nuit. **Il a trouvé un
quatrième cas à sa première exécution** — le repli de la lueur de tête, `colors.last ?? RUColor.rose`,
que j'avais lu trois fois sans le voir.

### Une divergence réparée au passage

Le Club peignait le tracé en DEUX teintes, l'accueil en TROIS. La même course, deux dessins selon
l'écran. Le commentaire du jeton `traceBackground` prévoyait exactement ça — « une deuxième copie
aurait divergé au premier réglage » — à propos du fond ; c'est la nuance qui avait divergé. Les
deux appels du Club n'imposent plus de palette.

### Ce qui a échoué, et pourquoi

**Deux fois de suite, un fichier de test Swift que rien n'exécutait avant CI.** `tout.sh` lit le
texte des fichiers, il ne compile pas Swift.

1. `BaisseProgrammeeTests` passait la chaîne « forme » à un paramètre `GoalType`. Aucun cas ne
   porte ce nom. La compilation est tombée, et les deux workflows avec elle.
2. `SemaineComparableTests` affirmait que « dix jours en arrière, c'est l'avant-dernière semaine ».
   Depuis un jeudi, dix jours en arrière tombent sur le **lundi de la semaine passée**, premier
   jour de la fenêtre comparable. Le code comptait les 42 km, et il avait raison. Le cas est
   réécrit sur la borne elle-même — une seconde avant, une seconde après — au lieu d'un nombre de
   jours compté de tête.

Je n'en fais pas un garde. Un contrôle qui vérifierait les littéraux d'énumération rendrait un
faux positif à chaque chaîne qui ressemble à un cas, et `check_entrees` a déjà appris ce que vaut
un garde bâti sur une prémisse non vérifiée. Le compilateur est le bon outil ; il tourne sur CI.

### Trois gardes existants ont attrapé mon propre travail

`check_degrade` (le voile de la carte de nuit, exception déplacée de `HomeView` vers le composant
qui le porte maintenant), `check_grille` (trois écarts hors grille dans le ruban et le Coach),
`check_strings` (deux chaînes neuves absentes du catalogue, donc françaises en anglais et en
espagnol). Et `check_design` a refusé la table de DESIGN.md dès que j'ai nommé les valeurs
sombres : `couleurs.declarations()` ne savait pas suivre un jeton qui en nomme un autre. Il le
sait, sur une seule indirection — au-delà, une couleur se lirait par chaînage et le lecteur de
palette redeviendrait un interpréteur.

### Ce qui attend Charlotte

**La Journée.** Un anneau de progression sur fond noir est le vocabulaire de l'app Activité
d'Apple. Celui de Haizo en diffère réellement — une seule piste segmentée en trois arcs, et non
trois anneaux concentriques, avec le compte au centre — mais la question 3 de la DA se pose là, et
seulement là. C'est un jugement sur une image rendue, pas une mesure.

## 13 novembre 2026 — trois campagnes mortes sur une erreur que le build ne pouvait pas voir

`CapturesUITests.swift` écrivait `prendre(…, reglages: true, defilements: 2)`. Swift exige que les
arguments d'un appel suivent l'ordre des paramètres, et `defilements` est déclaré avant `reglages`.
La cible ne compilait plus depuis `c6e1821`.

**Pourquoi personne ne l'a vu.** `HaizoUITests` n'appartient qu'au schéma `Captures`. Le workflow
de build lance `xcodebuild test -scheme Haizo` : il ne l'a jamais compilée. Pendant trois
campagnes — une heure chacune — le build restait vert et annonçait 886 tests passés, pendant que
la chaîne qui produit les images mourait à sa troisième étape.

J'avais écrit la barrière qui prévenait de regarder là en premier : « si le build échoue, regarder
d'abord si `reglages:` manque dans un appel de `prendre(...)` ». Je ne l'ai pas suivie, parce que
les deux premières campagnes s'étaient arrêtées sur une annulation de plateforme à quinze minutes,
sans aucun log récupérable — et que j'ai cru à un aléa de machine. La troisième a enfin rendu la
ligne d'erreur.

**Le trou est bouché à la racine, pas au cas.** Le workflow de build compile désormais le schéma
`Captures` en `build-for-testing` : on construit le bundle de test, on ne lance rien. Les
vingt-six tests de capture prendraient l'heure que ce workflow existe pour éviter ; les compiler
coûte deux minutes et déplace la découverte d'une erreur de soixante minutes à quatorze.

## 13 novembre 2026 — ce que les deux autres langues et le thème sombre ont dit

La campagne photographie trois langues et deux thèmes. Les trois défauts ci-dessous ne se voient
sur aucune des images françaises en thème clair.

### Le voile éteignait le dessin qu'il devait protéger

La carte de nuit pose un voile noir dégradé sous ses chiffres, pour qu'ils se lisent quelle que
soit la forme derrière. Posé EN HAUT — le cas du Plan et du Coach, dont le dessin est collé au bas
du cadre — il partait du bas de la carte : le dégradé couvrait donc toute la hauteur, et à
mi-chemin il valait encore un tiers de noir.

Sur la capture espagnole, chaque barre du Plan s'assombrit visiblement vers son sommet. On y lit
un dégradé décoratif, c'est-à-dire exactement ce que la règle 7 interdit — alors que c'est un
voile de lecture mal borné. Il part maintenant du MILIEU des deux côtés, et ne touche plus la
moitié du cadre où aucun texte n'est posé.

### « km au plus fort » sortait en français chez les hispanophones

À côté d'un « 7 semanas » correctement traduit. La carte de nuit du Plan porte deux chiffres, et
un seul des deux libellés était au catalogue.

**Pourquoi le garde ne l'a pas vu.** `LegendeDeNuit` recevait ses chiffres dans un tableau de
TUPLES. `check_strings.py` suit une étiquette d'un type à l'autre quand c'est un `String` déclaré
— c'est son « relais » — mais un champ de tuple n'en est pas un, et le suivre demanderait
d'interpréter l'accès à un élément de collection. Ce fichier refuse de deviner, et il a raison.

**Ce que j'ai essayé d'abord, et pourquoi je l'ai retiré.** Inscrire `LegendeDeNuit` dans la liste
des puits d'affichage. Il a aussitôt signalé CINQ littéraux dont quatre vont très bien : ils
descendent jusqu'à `RUChiffre`, qui les passe au catalogue. Un garde qui refuse du code juste est
pire qu'aucun garde — c'est la leçon de `check_entrees`, et elle a servi dans l'heure.

**Ce qui est fait à la place.** Le tuple anonyme devient un composant nommé, `ChiffreDeNuit`. Son
`unite` est alors une étiquette ordinaire, que le relais suit comme celle de n'importe quel type.
Vérifié en retirant la clé du catalogue : le garde refuse, en nommant le fichier et la ligne.

### Le thème sombre, lui, va bien

La carte de nuit y est plus sombre que les cartes voisines et plus claire que la page : elle se
lit comme un panneau en retrait plutôt que comme un objet posé. C'est la conséquence assumée de
`traceBackground`, qui ne suit pas le thème — en thème sombre, la nuit EST la page, et la
signature passe par le dessin, pas par le fond.

### La mesure

Part d'image sombre en thème clair, même définition qu'au 12 novembre (moyenne des composantes
sous 70, un pixel sur quatre) :

| Écran | Avant | Après |
| --- | --- | --- |
| Club | 30,1 % | 30,1 % |
| Coach | 2,7 % | **20,3 %** |
| Stats | 1,9 % | **20,2 %** |
| Journée | 1,5 % | **19,4 %** |
| Accueil | 15,1 % | 15,0 % |
| Plan | 1,3 % | **13,8 %** |

Les trois dessins qui suivent la journée — le ruban du Coach, l'anneau de la Journée, la courbe
des Stats — bougent de quelques dixièmes d'une campagne à l'autre, puisque leur contenu change
avec le jour. Les valeurs ci-dessus sont celles du 14 novembre.

Quatre écrans étaient sous 3 %. Les six tiennent maintenant entre 13,9 % et 30,1 %.

## 14 novembre 2026 — le film d'aperçu refusé, et une explication que j'avais inventée

### Le garde du film a fait son travail

La campagne espagnole a refusé son aperçu : au plan « première-coach », l'image montrait le
Profil. `bascules.py` existe pour ça — il compare chaque plan aux écrans réellement photographiés
par la même campagne, et non à des horloges. Un film coupé sur le mauvais onglet serait parti sur
l'App Store.

La mesure dit où regarder : « changement d'écran à 0,13 s avant le plan (attendu 0,60) ». La
bascule avait bien eu lieu, trop tard pour que l'écran soit posé. Les trois suivantes tenaient
leurs 0,60 s : c'est la PREMIÈRE bascule de la campagne qui est lente, celle qui suit le
lancement — le français et l'anglais l'avaient passée de justesse.

La pose de la passe à blanc monte de 1,4 à 2,0 s. Quatre onglets, trois langues : sept secondes
sur une campagne d'une heure.

### J'avais écrit une explication fausse, et je la retire

Hier, l'encre de la ligne de phase du cycle mesurait `#834C33` là où `RUColor.cycle` déclare
`#80462E`. J'en ai conclu un fondu saisi en cours, parce que `#834C33` est exactement `#80462E`
à 97 % sur du blanc, et j'ai porté l'attente de deux à quatre secondes.

**C'était faux.** La campagne suivante rend EXACTEMENT le même compte de pixels — 33 020, au pixel
près. Une image saisie pendant un fondu ne se reproduit pas à l'identique.

Ce qui est établi, en revanche :

- tous les autres jetons de la même image ressortent exacts : `textPrimary`, `text2`, `text3`,
  `card2`, la page, la carte, et `cycleSurface` ;
- le rose de marque y compte **142 223 pixels exacts** — donc le rendu n'altère pas les teintes
  saturées ;
- en thème **sombre**, le même jeton `cycle` rend exactement `#F2B8A0`.

Donc ni la capture, ni un fondu, ni la saturation. La cause reste ouverte, et elle est notée comme
telle plutôt que devinée — c'est une tâche, pas un commentaire qui rassure.

Ce qui protège la lectrice, lui, est mesuré : le contraste réellement rendu vaut **5,85:1** contre
6,29 attendus, au-dessus du seuil de 4,5.

### Vérifié sur la campagne

Les barres du Plan espagnol sont redevenues des aplats — le voile ne les éteint plus. Et
« 31 km en su pico » est traduit.

## 14 novembre 2026 — la capture du cycle était tirée au sort

Hier j'ai écrit que l'encre de la ligne de phase rendait `#834C33` au lieu de `#80462E`, et que
la cause restait ouverte. Elle est fermée, et la réponse était dans la campagne elle-même :
**l'image ESPAGNOLE du même écran contient 6 315 pixels exactement `#80462E`.** Le jeton rend
juste. C'est l'image française qui ne valait rien comme mesure.

Pourquoi : le bloc du cycle est la cinquième carte de `MoreSettingsView`, et la capture y arrivait
par trois glissements comptés en coordonnées. La campagne du 14 a donné **trois résultats
différents pour la même capture** — l'espagnol tombait sur le bloc, le français et l'anglais le
dépassaient, parce que les quatre cartes qui le précèdent sont plus courtes dans ces deux langues.

Une fonctionnalité dont l'unique image dépend de la longueur des textes qui la précèdent n'est pas
photographiée, elle est tirée au sort.

### Ce qui change

`--cycle` pose la vue sur le bloc par son ancre, et la capture ne défile plus. `ScrollViewReader`
ne rouvre pas le piège que `CapturesUITests` documente depuis septembre : ce qui avait tué le
premier essai de ces captures, c'était d'interroger l'arbre d'accessibilité **depuis le test**.
Ici le défilement se décide dans l'app, qui connaît ses propres vues, et le test ne demande rien.
Le défilement en coordonnées reste la règle partout ailleurs.

### Deux explications fausses, dans l'ordre

1. **Un fondu saisi en cours.** `#834C33` est exactement `#80462E` à 97 % sur du blanc, ce qui
   rendait l'hypothèse séduisante. Réfutée : deux campagnes aux attentes différentes — deux
   secondes, puis quatre — rendaient le même compte de pixels, au pixel près. Une image prise
   pendant un fondu ne se reproduit pas à l'identique.
2. **Le rendu des teintes saturées.** Réfutée dans la même image : le rose de marque y comptait
   142 223 pixels exacts, et le jeton `cycle` rend exactement `#F2B8A0` en thème sombre.

La troisième tentative a été la bonne parce qu'elle a cessé de chercher une cause dans le rendu
pour aller chercher **une autre image du même écran**. La leçon tient en une ligne : une couleur
ne se juge pas sur une image dont on n'a pas vérifié qu'elle était stable.

## 14 novembre 2026 — l'accueil : une seule semaine, et le programme au-dessus de la ligne

Charlotte : « tu peux faire l'écran d'accueil comme tu veux. » J'ai commencé par chercher un
dessin propre à cet écran, et j'ai trouvé l'inverse : **l'accueil est un hub, et tout ce qu'il
pourrait dessiner appartient déjà à un autre écran.** Le profil d'effort d'une séance aurait été
le seul objet vraiment neuf — la règle 2 l'interdit : `IntervalStructure` connaît `reps`,
`repMeters` et `recoveryMeters`, rien sur l'échauffement ni le retour au calme. Dessiner le profil
aurait inventé son début et sa fin, et la plupart des jours il n'aurait montré qu'un rectangle,
puisqu'un footing n'a qu'une zone.

Trois défauts constatés sur la capture, trois corrections.

### L'app avait DEUX semaines

L'accueil portait sa propre bande : sept lettres, sept quantièmes, une pastille rose cochée.
Elle dit quel jour on est et ce qui est fait — un calendrier. Le ruban que j'ai ajouté au Coach
**la veille** dit en plus quoi et combien de temps, par la couleur et la hauteur.

Deux objets « semaine » dessinés dans deux langages, dans la même app. C'est exactement la
divergence que le jeton `traceBackground` décrit depuis septembre, et celle-ci était de moi : je
n'avais pas regardé si l'accueil en avait déjà une.

Le ruban devient donc la semaine de l'app. Il reprend les quantièmes — la seule chose que la
bande faisait de plus — et reçoit `surLaNuit`, comme l'anneau des objectifs, parce qu'il vit
maintenant sur les deux fonds. `check_nuit.py` l'a signalé de lui-même à la première exécution
qui a suivi : il était inscrit comme fichier de nuit, il ne l'est plus, et sa note prévoyait ce
cas mot pour mot.

**Ce qui est perdu, et dit plutôt que caché :** la pastille cochée. Une séance faite recule
maintenant à 0,3 d'opacité, comme les semaines faites du graphique du Plan — le geste que l'app
emploie déjà pour dire « c'est derrière toi ».

**Ce qui a failli l'être :** la bande donnait à VoiceOver un élément par jour, avec son libellé.
Le ruban n'en donnait qu'un, résumé. Il en donne maintenant un par jour, et reprend mot pour mot
les quatre tournures déjà au catalogue — le Coach y gagne aussi, sa semaine se parcourt.

### Le programme était sous la ligne de flottaison

« Ton programme · 10 km · 47:30 » n'apparaissait qu'en bas de l'écran, à moitié caché par la barre
d'onglets. C'est la promesse que l'app vend — un plan qui s'adapte — et c'était la seule chose
qu'on ne voyait pas en ouvrant. Il passe avant les objectifs du jour.

### L'anneau des objectifs faisait trois cents points de haut

Pour un objet que l'écran Journée porte désormais en grand, sur sa carte de nuit. Il passe de 186
à 72 points et se range À CÔTÉ de son compte au lieu de l'entourer : la carte tient en moitié
moins de hauteur. Rien n'est retiré — le compte, le libellé et les trois mesures sont tous là.

### L'ordre, maintenant

Séance du jour · dernière sortie · programme et semaine · objectifs du jour · chiffres. C'est
l'ordre des questions qu'on se pose en ouvrant l'app.

### Ce que la campagne a montré, et ce qu'elle ne pouvait pas montrer

**L'anneau va bien.** Sur la vignette au tiers, il semblait n'être rempli qu'aux deux tiers alors
que sa légende dit « 2/2 ». À pleine résolution, il est complet : deux arcs qui couvrent tout le
cercle, avec les deux écarts de segment. Ce que je prenais pour la piste grise était
l'anticrénelage de la réduction. Vérifié avant d'accuser.

**Le ruban débordait au grand texte, et aucune image ne pouvait le dire.** La bande que j'ai
remplacée avait deux adaptations que j'avais perdues : un `ViewThatFits` qui laissait tomber les
quantièmes quand la place manquait, et une pastille d'état en `@ScaledMetric`. Je lui avais donné
un cadre de hauteur fixe. `micro` vaut 9 points, le système plafonne l'agrandissement à 2× : une
initiale et un quantième l'un sous l'autre font donc quarante points, au-dessus d'une barre qui
peut déjà en faire soixante-seize.

Le ruban se mesure maintenant lui-même, et les quantièmes s'effacent aux tailles accessibles —
ils disent « aujourd'hui, c'est le 14 », un confort ; la forme de la semaine est l'information.

**Et le bas de l'accueil n'était photographié nulle part.** Ni en taille normale, ni en grand
texte. L'écran le plus ouvert de l'app, et sa moitié basse — le programme, la semaine, les
objectifs — n'apparaissait sur aucune des 193 images. On la jugeait de mémoire, et c'est
exactement ce qui a failli laisser passer le débordement. Deux captures de plus.

## 14 novembre 2026 — un jour de repos pesait trois fois plus sur la page que sur la nuit

Le ruban dit la semaine sur deux fonds. Un jour sans séance y garde un trait court — un creux, pas
un trou. Sur la nuit, c'est du blanc à 28 % : **2,50:1**, il recule. Sur la carte, `SessionFamily.tint`
rend `RUColor.text3` : **7,25:1** en thème clair, **6,00:1** en sombre. Le même creux avançait donc
sur un fond et reculait sur l'autre, et les premières captures du bas de l'accueil le montrent
sans discussion — trois blocs gris qui se lisent comme « quelque chose ».

`text4` donne **2,10:1** et **2,16:1**. Le repos pèse maintenant pareil sur les trois fonds.

**Le jeton partagé ne bouge pas**, et c'est le point : `SessionFamily.tint` colore aussi le
croissant de lune des lignes de jour du Plan, un glyphe de quinze points qu'il faut pouvoir lire.
Une barre qui dit « creux » et un symbole qui dit « repos » ne demandent pas le même poids. La
correction vit donc dans le ruban, avec sa mesure à côté.

### Et les deux captures neuves ont servi tout de suite

Le bas de l'accueil au plus grand texte montre ce qu'on venait de corriger : les quantièmes
s'effacent, le ruban se mesure lui-même, rien ne déborde. C'est la première image de cette moitié
d'écran, et elle a confirmé un correctif le jour de sa prise.

## 14 novembre 2026 — la règle 7 interdisait les emojis, et rien ne la tenait

Les dégradés ont leur garde, le verre dépoli aussi. L'emoji n'avait personne, et DESIGN.md le
notait depuis la veille : « aucun garde ne tient l'emoji ». `check_strings.py` ne pouvait pas s'en
charger — il ignore explicitement les chaînes sans lettre, puisque son sujet est la traduction.

### Ce qu'est un emoji, précisément

Pas « tout ce qui n'est pas une lettre ». Le dépôt emploie `✓`, `▲`, `▼`, `·`, `—`, `″`. **Ma
première version prenait la plage U+2600–U+27BF en bloc et signalait les huit `✓` du catalogue.**
Un garde qui refuse du code juste est pire qu'aucun garde — celui-là aurait été désactivé dans la
semaine.

La règle d'Unicode est nette : un caractère est un emoji s'il a la présentation emoji **par
défaut**, ou si on la lui demande avec U+FE0F derrière. `✓` (U+2713) ne l'a pas ; `✅` (U+2705) l'a ;
`☀` est typographique et `☀️` est un emoji — même lettre, deux intentions. C'est cette règle-là qui
est écrite, avec la liste des caractères du plan de base nommés un par un plutôt que devinés.

### Ce qu'il a trouvé

**« Course reçue de ta montre ⌚ »** — un toast, dans les trois langues, plus son littéral Swift.
U+231A a bien la présentation emoji par défaut. Il doublait la notification juste au-dessus, qui
porte déjà le symbole `applewatch` : l'emoji n'ajoutait rien qu'une décoration, ce que la règle 7
vise exactement.

Le garde lit le code ET les trois langues du catalogue, parce qu'une traduction est précisément
l'endroit par où un 🔥 revient « pour faire vivant », et que personne ne relit 2 117 clés à l'œil.

## 14 novembre 2026 — trois consignes disaient comment la course se passait, sans rien mesurer

Le dernier marqueur de la « Claude touch » que DESIGN.md donne pour tenu par aucun garde : le
texte générique. Il ne se mesure pas, il se relit. J'ai relu les 2 117 clés du catalogue en
cherchant les signatures de l'encouragement creux — l'exclamation, l'éloge, la formule.

La plupart tiennent. « Meilleur temps sur ce parcours ! », « Nouveau record personnel ! »,
« Personne n'a encore couru cette semaine — lance-toi ! » : ce sont des faits ou des états vides
avec une action. Un coach qui encourage fait son travail ; ce qui est interdit, c'est l'éloge qui
ne repose sur rien.

### Les trois qui ne reposaient sur rien

- « Mi-séance, tu gères **parfaitement**. Garde ta cadence. »
- « Mi-séance, tu gères. Garde ta cadence sur les prochaines répétitions. »
- « **Beau rythme**, reste régulière — c'est la constance qui paie »

Elles partent sur un MINUTEUR, à 360 et 720 secondes, quelle que soit l'allure réelle. Quelqu'un à
quarante secondes au kilomètre de sa cible s'entendait dire qu'il gérait parfaitement. C'est la
règle 2 autant que la 7 : rien de faux sur l'entraînement.

Le commentaire juste au-dessus de ces lignes disait déjà la règle, pour une consigne retirée
avant elles : « claimed "FC bien maîtrisée" with no real heart-rate reading behind it, **the exact
kind of fabricated claim the rest of the app already scrubbed out** ». Trois étaient restées.

Elles sont remplacées par ce qu'un entraîneur dit vraiment à ce moment-là, et qui est vrai sans
rien mesurer : une sortie continue se court en deux moitiés égales, et sur du fractionné c'est la
qualité de la récupération qui décide des dernières répétitions.

### Et le palier de série

« Tu enchaînes les séances sans lâcher — **continue comme ça !** » Le fait était vrai — la série
est réelle — mais la phrase tient dans n'importe quelle app, et le titre disait déjà « Série de 7
jours ». Elle nomme maintenant le palier SUIVANT, calculé depuis la liste des paliers : la seule
chose qu'on veut savoir à ce moment-là, et un fait plutôt qu'un encouragement.

**Pas de garde.** Un contrôle du « texte générique » serait une liste de mots interdits, et il
signalerait « bien joué » dans « Dernière répétition faite, bien joué » — qui est juste, parce
qu'une répétition FINIE est un fait. DESIGN.md dit que cette règle-là se tient à l'œil ; elle se
tient à l'œil.

## 14 novembre 2026 — l'accueil portait trop d'informations, et c'est moi qui l'avais densifié

Charlotte, en voyant la capture : « ça fait beaucoup d'infos du coup ». Compté sur l'image :
**une trentaine de nombres sur un seul écran.** Et c'est bien moi qui l'ai densifié le matin même,
en remontant le programme — la carte la plus chargée de l'app — au-dessus de la ligne de
flottaison.

Trois coupes, et ce que chacune ne perd pas.

### La carte « 30 derniers jours »

Quatre chiffres — distance, sorties, temps, allure — et un bouton vers l'onglet Stats, **qui est
dans la barre du bas, en permanence, à un doigt**. Une carte entière pour raccourcir un trajet
d'un tap.

La carte des PREMIERS JALONS reste. Elle ne double rien : elle s'affiche tant qu'on n'a pas assez
couru pour que les statistiques veuillent dire quelque chose. C'est de l'accueil pour une
débutante, pas un résumé.

### Les trois mesures du jour

Séance, calories, pas — six éléments pour dire ce que l'anneau dit déjà au-dessus d'eux : deux
objectifs sur deux. Elles vivent en entier sur l'écran Journée, que la carte ouvre d'un tap et qui
les porte avec leurs barres. L'anneau reste : il est l'entrée, et il se lit sans se lire.

### Le pied du programme

« 7 semaines · voir le plan complet ». Les deux moitiés étaient ailleurs : l'en-tête annonce
« Semaine 1/7 », donc le total y est, et la carte entière est un bouton vers le plan, donc
l'invitation aussi. Seul le programme SANS date de course garde une ligne — son « Semaine 1 » n'a
pas de total, et « Programme ouvert » est la seule façon de le dire.

### Ce qui reste

Séance du jour · dernière sortie · programme et semaine · objectifs du jour. Quatre blocs au lieu
de six, et une vingtaine de nombres au lieu d'une trentaine.

## 14 novembre 2026 — le ménage de l'accueil avait laissé un trou dans la carte Journée

Vérification de la coupe précédente sur la campagne 198, en regardant les images plutôt qu'en
relisant le code.

**Ce que la capture dit de bon.** L'accueil tient en un écran : le bas de page, photographié
séparément, est décalé de 122 pixels sur une image de 2 868, soit **41 points de défilement** —
la hauteur d'une ligne de texte. Avant la coupe il fallait faire défiler pour atteindre l'anneau.
Quatre blocs au lieu de six, une vingtaine de nombres au lieu d'une trentaine.

**Ce qu'elle dit de mauvais, et que je n'avais pas vu.** En retirant les trois mesures du jour de
la carte Journée, j'avais vidé sa moitié droite sans retoucher sa mise en page. Mesuré sur
l'image, à l'intérieur de la carte : le contenu s'arrête à 241 points sur 388, puis **160 points
de vide** avant le chevron.

La même grammaire existe ailleurs dans l'app — « Le fil », sur le profil : icône, titre,
sous-titre, chevron. Mesuré sur la même campagne : **50 points de vide**. Trois fois moins. Ce
n'est donc pas la respiration d'une ligne de liste, c'est une place laissée libre par ce qui
vient d'en partir : un composant sans intention, au sens de la troisième question de la DA.

**Ce qui est fait.** Rien ne revient pour combler. Le compte et son libellé, qui étaient empilés,
se rangent côte à côte — « 2/2 · TA JOURNÉE » en une lecture. Un `ViewThatFits` repasse à la pile
en grand texte, plutôt que de réduire un nombre de 44 points à la moitié de sa taille.

**Ce que le garde a attrapé au passage.** En sortant les deux `Text` dans des vues nommées — pour
ne pas les écrire deux fois, une par branche du `ViewThatFits` — le bouton n'a plus porté, aux
yeux de `check_a11y.py`, qu'une icône de chevron. Refus. Le garde avait tort sur la lettre et
raison sur le fond : VoiceOver lisait bien quelque chose, mais il lisait « deux barre oblique
deux, T A J O U R N É E » — un libellé en capitales s'épelle. La carte porte maintenant le nom
prononçable de l'anneau dont elle est l'entrée, **mot pour mot celui de `RingsView`** :
« %lld sur %lld objectifs bouclés ». Une clé déjà au catalogue, dans les trois langues.

**Mesuré sur la campagne 199.**

| | avant | après |
| --- | --- | --- |
| Vide à droite dans la carte Journée, en français | 160 pt | **73 pt** |
| — en anglais | — | 96 pt |
| — en espagnol | — | 130 pt |
| Vide de la ligne comparable (« Le fil », profil) | 50 pt | 50 pt |
| Hauteur de la carte | 109 pt | **96 pt**, identique dans les trois langues |
| Défilement restant sur l'accueil | 41 pt | **31 pt** |
| Nom lu par VoiceOver | « 2/2, T A J O U R N É E » | « 2 sur 2 objectifs bouclés » |

L'espagnol garde 130 points parce que « Tu día » fait six caractères contre dix à « Ta journée ».
Ce n'est pas rattrapable sans faire dépendre la mise en page de la longueur d'un mot, ce qui
serait pire ; l'image, elle, se tient.

Le repli en grand texte est vérifié sur la capture d'accessibilité : la carte repasse à la pile,
rien n'est tronqué, rien n'est réduit.

Build 561 vert, **zéro avertissement du compilateur Swift** — compté dans le journal complet du
build, pas déduit.

**Au passage, relevé dans ce même journal.** `check_strings.py` levait six `SyntaxWarning` Python
à chaque build : « `\(` is an invalid escape sequence », lignes 35 et 69, deux docstrings
ordinaires qui contiennent des exemples d'interpolation Swift. Python avertit aujourd'hui,
refusera demain : un garde de la barrière qui se serait cassé tout seul à la prochaine montée de
version. Les deux docstrings sont maintenant brutes. Vérifié sur les 142 scripts de `ci_scripts`,
en compilant chacun avec les avertissements promus en erreurs : aucun autre.

## 15 novembre 2026 — un titre de section se faisait encore couper en grand texte

Trouvé en regardant la capture d'accessibilité de la campagne 199, à pleine résolution :
l'en-tête de la carte du programme affiche **« Ton programme · 10… »**. L'objectif de la
coureuse — sa distance et son chrono cible — disparaît de l'en-tête au deuxième cran
d'accessibilité.

`CardHeaderView.swift` porte depuis le 8 novembre un mécanisme écrit exactement contre ça :
l'accessoire d'un en-tête descend SOUS le titre en grand texte, pour que le titre récupère toute
la largeur. Son commentaire le dit mot pour mot — « un titre de section tronqué est le seul mot
qui dise de quoi parle la carte ».

**Il ne s'appliquait pas, pour deux raisons.**

La première : le « J-41 » n'était pas l'accessoire de l'en-tête. Il était posé À CÔTÉ de
`RUCardHeader`, dans un `HStack` écrit sur place. Vu de l'en-tête, il n'existait pas. Compté dans
l'app : sur 68 appels, deux passent par le paramètre `accessory`, trois posent leur voisin dans
un `HStack` — et deux de ces trois sont des `Spacer`, donc légitimes. Le programme était le
troisième.

La seconde, et c'est elle qui compte : même seul sur toute la largeur,
« Ton programme · 10 km · 47:30 » ne tient pas sur une ligne à 35 points. Le titre portait
`lineLimit(1)`. Il en prend deux — **uniquement aux tailles d'accessibilité**. Aux tailles
ordinaires, rien ne change : une ligne, réduction d'un cinquième au besoin, exactement comme
avant. Le sous-titre suit la même règle.

C'est la correction qui compte, parce qu'elle vaut pour les 68 en-têtes et pour le prochain,
sans que personne ait à se souvenir de passer par `accessory`.

**Pas de garde.** La règle vérifiable serait « un `RUCardHeader` ne se pose pas à côté d'une autre
vue dans un `HStack` » — elle refuserait les deux `Spacer`, qui sont justes, et la feuille de
séance, dont la pastille ne tronque plus rien depuis la correction ci-dessus. Un garde qui refuse
du code juste est pire qu'aucun garde.

**Relevé au passage, et noté comme tâche :** `SessionDetailSheet`, la feuille qui s'ouvre sur une
séance du plan, n'apparaît dans AUCUNE capture. « sortie » photographie la page d'une course
passée, pas celle-ci. C'est l'écran qu'on ouvre avant de courir.

### Vérifié sur la campagne 200

**L'en-tête est entier.** Sur la capture d'accessibilité : « Ton programme · 10 km · 47:30 » sur
deux lignes, et le « J-41 » descendu sur sa propre ligne, poussé à droite — le mécanisme de
`RUCardHeader` s'applique enfin, parce que le compte à rebours est passé par son paramètre.

**Les sept autres écrans en grand texte n'ont rien perdu.** Regardés : stats, profil, bilan de la
semaine, aperçu du club, sortie, course en cours, accueil. Rien n'est poussé hors de l'écran,
rien ne se chevauche. Deux sous-titres gagnent leur deuxième ligne au passage — « Cette semaine ·
Face à la semaine passée » sur les stats, « Le fil · Ton club, tes abonnements… » sur le profil.

Les coupures qui restent en grand texte ne viennent pas des en-têtes : la biographie du profil,
le nom du club sur l'aperçu. Chacune a son propre composant et sa propre limite.

**La comparaison au pixel près des captures ORDINAIRES n'a pas pu se faire**, et c'est une limite
qu'il faut écrire plutôt que contourner : la campagne 199 a tourné un samedi de repos, la 200 un
dimanche de sortie longue. Le jeu de données de capture suit la date, donc les deux accueils ne
montrent pas la même app — carte de séance de 290 points là où il y avait trois lignes de repos,
28,3 km au lieu de 14,1. Ce qui est vérifié à la place : aux tailles ordinaires, l'expression
`tailleDuTexte.isAccessibilitySize ? 2 : 1` vaut littéralement 1, donc le code emprunté est le
même qu'avant ; et les en-têtes des quatre écrans ordinaires regardés tiennent bien sur une
ligne.

**Une chose regardée et laissée telle quelle.** À côté d'un titre sur deux lignes, le glyphe de
l'en-tête se centre verticalement, donc il se pose entre les deux lignes. L'aligner sur la
première demanderait de changer l'alignement des 68 en-têtes à TOUTES les tailles pour un gain
qui n'existe qu'en accessibilité. Centrer est aussi ce que font les rangées de liste d'iOS.

## 15 novembre 2026 — la feuille de séance n'était photographiée nulle part

C'est l'écran qu'on ouvre AVANT de courir : le détail de la séance du jour, son découpage en
échauffement, bloc et retour au calme, ses allures cibles, son bouton de départ. Il n'apparaissait
sur **aucune** des images de la campagne. « sortie » photographie la page d'une course PASSÉE,
pas celle-ci.

Relevé le 15 novembre en cherchant où regarder le troisième en-tête qui pose son accessoire à
côté de `RUCardHeader` au lieu de passer par son paramètre : il est dans cette feuille, et il n'y
avait aucune image pour décider s'il fallait y toucher. La correction a donc été faite au bon
endroit — dans le composant, pour les 68 en-têtes — et celle-ci est restée en attente d'une
image.

**Deux captures : la feuille, et la feuille en grand texte.** Une feuille a moins de hauteur qu'un
écran, et celle-ci porte trois étapes avec chacune son titre, sa durée, son allure et sa zone.

`--seance` ouvre la feuille par le même chemin que `--reglages` ouvre celle des réglages : l'app
la présente elle-même au lancement. Rien à choisir dedans — elle lit `profile.todaySession`.

**Ce que l'image montrera suit le jour de la campagne** : une sortie longue un dimanche, trois
lignes de repos un jour de repos. Les deux sont des états réels de l'app, et c'est la même
dépendance au jour que l'accueil. Ce n'est pas le défaut du bloc du cycle, où un seul et même
écran était tantôt atteint tantôt manqué selon la langue des textes qui le précédaient : ici, deux
états différents alternent et chacun vaut d'être vu.

Contrôles et cas locaux verts. L'image dira le reste.

### Ce que la première image de la feuille a montré

**La feuille existe, elle est photographiée, dans les trois langues et en grand texte.** Vérifié
avant de regarder quoi que ce soit : l'image EST la feuille et non l'accueil — 59,5 d'écart moyen
entre les deux, dans les trois langues.

En grand texte, elle tient : l'en-tête « Séance clé » et sa pastille « Niveau 2 » restent sur une
ligne, rien n'est tronqué. C'est le troisième en-tête qui pose son accessoire à côté de
`RUCardHeader` ; l'image dit qu'il n'y a rien à y corriger, et c'était la raison d'attendre une
image.

**Et elle a montré un défaut, celui-là réel.** La phrase du coach s'affichait :

> Le coach a ajusté cette semaine à "Niveau 2" d'après ta forme la semaine dernière.

Le guillemet droit `"` est celui de la machine à écrire. L'app savait déjà faire : à deux
centimètres de là, la notification qui annonce LE MÊME ajustement écrit
« On lève un peu le pied sur « %@ » », et sa version anglaise « Easing off on “%@” ». La règle
existait, en trois langues, et cette phrase-là ne la suivait pas — la forme de défaut la plus
fréquente de ce dépôt.

Corrigé dans les trois langues, selon la convention déjà en place : « %@ » en français, “%@” en
anglais, «%@» en espagnol. Deux valeurs anglaises de la nutrition d'ultra portaient la même faute
alors que leurs versions française et espagnole étaient justes : corrigées aussi.

**Un garde, parce qu'une relecture ne tient pas.** `check_guillemets.py` + `test_guillemets.py`,
douze cas. Il ne regarde que le catalogue, qui est en JSON : un guillemet droit à l'intérieur
d'une chaîne y apparaît échappé, donc la recherche est exacte et ne peut pas se tromper sur du
code. Et elle suffit — `check_strings.py` refuse déjà toute chaîne affichée absente du catalogue,
il n'y a pas de second chemin. Éprouvé en réintroduisant le défaut : le garde refuse, et le
dépôt tel qu'il est passe.

Ce qu'il NE regarde pas, et c'est écrit dans son en-tête : quel guillemet courbe employer — une
chaîne française a le droit de citer de l'anglais. Et l'apostrophe : le catalogue en porte 827,
toutes droites, zéro courbe. C'est un choix uniforme, pas un oubli, et le changer serait une
décision de direction artistique sur 827 chaînes.

**Deux captures en grand texte n'étaient surveillées par aucun garde.** `grand-texte/seance`
(nouvelle) et `grand-texte/accueil-bas` (depuis sa création) manquaient aux `PAIRES` de
`check_grand_texte.py` : si le réglage de taille cessait d'être lu, elles deviendraient des
copies des captures ordinaires sans que rien ne le dise. Ajoutées, après mesure sur la campagne
201 dans les trois langues — la séance entre 19,4 et 20,2, le bas de l'accueil entre 21,7 et
23,4, pour un plancher à 10.

### Deux questions de direction, pas des défauts à corriger seul

**La feuille s'appelle « Séance clé », la carte qui l'ouvre « Séance du jour ».** Deux noms pour
la même chose, à deux centimètres l'un de l'autre.

**Et elle dit trois fois les mêmes trois nombres.** La rangée du haut donne 39′ · 6:18 · Z2 ;
« Structure de la séance » les redonne dans son unique ligne, « Course continue · 39′ · 6:18/km ·
Z2 » ; et la carte dont on vient les portait déjà. Pour une sortie continue il n'y a qu'un bloc,
donc la section annonce un découpage et rend une répétition. C'est le même reproche que Charlotte
a fait à l'accueil le 14 novembre.

## 15 novembre 2026 — l'accueil sans programme n'était photographié nulle part

Charlotte, en regardant l'app : « maintenant l'accueil fait vide lorsqu'il n'y a pas de programme
en cours, mais c'est peut-être fait exprès ? »

**Ce n'est pas fait exprès, et personne ne pouvait répondre.** Toutes les captures de l'accueil,
depuis qu'elles existent, montrent un programme ACTIF. Cet état-là n'a jamais été vu.

Et la question tombe juste. En course libre, `programWeekCard` ne rend que le ruban des sept
jours : pas d'en-tête, pas de « Semaine 1/7 », pas de volume, pas de barre, pas de pastille
d'écart. La carte passe d'environ 290 points à la hauteur d'un ruban. Or la carte
« 30 derniers jours », retirée le 14 novembre parce qu'elle doublait l'onglet Stats, était aussi
ce qui remplissait cet écran-là — et cette coupe a été mesurée sur un jour AVEC programme. Le
vide qu'elle décrit est donc vraisemblablement de mon fait, et je ne l'ai pas vérifié.

**On regarde avant de redessiner.** `--libre` pose `programPhase = .freerun` après l'inscription
et rappelle `refreshProgramForCurrentDate` pour que la bande de la semaine soit celle de la
course libre. C'est un état stable de l'app, pas un montage : le moteur, en `.freerun`,
reconstruit la bande et s'arrête là.

Deux captures : le haut et après un défilement. Si les deux images sont identiques, l'écran tient
en moins d'une hauteur — et c'est la mesure du « vide », au lieu d'une impression.

**Un état voisin reste non photographié**, et il est noté plutôt que traité ici : l'accueil de
quelqu'un qui n'a PAS souscrit (`planUnlocked == false`), où la carte du programme disparaît
aussi et où `PlusLockCard` prend sa place. `--paywall` ouvre la feuille d'abonnement, pas cet
accueil-là.

### Ce que la première image de l'accueil sans programme a montré

**Un mensonge sur l'entraînement, et c'est la règle 2.** Le bandeau annonce « Mode course libre ».
Deux lignes dessous, la carte de séance écrit :

> Semaine 1 sur 7, bloc de base : on construit le volume avant de le spécialiser.

Il n'y a pas de semaine 1 sur 7 : il n'y a pas de programme. Le profil garde son objectif et sa
date de course après la fin d'un programme, donc `ProgramShape` recalculait une forme de plan
pour un plan qui ne tourne plus, et `PourquoiCetteSeance` la commentait.

Le fichier qui porte cette phrase dit pourtant la règle dans son en-tête : « là où le moteur n'a
rien de chiffré à dire, cette fonction rend `nil` et l'écran se tait ». Il manquait le cas où le
moteur n'a rien à dire du tout.

`Contexte` gagne `estEnCourseLibre`, sans valeur par défaut — il n'y a qu'un appelant, et un
défaut à `false` laisserait le prochain l'oublier en silence. Deux cas de test : les QUATRE blocs
se taisent en course libre, et le même contexte hors course libre parle — sans quoi le premier
passerait aussi avec une fonction qui ne dit jamais rien.

Ici plutôt qu'en passant `semainesEnTout: nil` depuis l'appelant : ça suffirait à taire le bloc de
base et le spécifique, mais `.deload` n'a besoin d'aucun total et `.affutage` se contente de la
date de course, qui survit elle aussi.

**Et le vide, mesuré.** L'écran défile de 129 points en course libre contre 200 points avec
programme, le même jour. Il n'est donc pas plus court d'une hauteur d'écran — il est moins
rempli : la carte du programme, qui porte en-tête, semaine, bloc, volume, barre et pastille,
devient un ruban de sept barres **dans une carte blanche sans titre**. C'est ça que Charlotte
voit, et ce n'est pas une impression : une carte dont tout le contenu est un graphique muet.

### Le film d'aperçu est rouge depuis deux campagnes, et je ne l'avais pas vu

La campagne 202 a échoué et je ne l'ai pas regardée : j'ai poussé le chantier suivant avant de
vérifier le précédent. Le chantier des guillemets a donc été annoncé terminé sur une campagne que
je n'avais pas ouverte. C'est une faute de méthode, pas de code.

Les deux échecs sont au même endroit : le découpage du film d'aperçu, en anglais. Le plan qui vise
l'onglet Stats montre le Profil — vérifié sur l'image de preuve que le harnais garde,
`stats-montre-profil.png` : c'est sans ambiguïté l'écran Profil, onglet Profil allumé. Le garde a
raison.

**Les captures, elles, sont toutes bonnes** : l'échec est dans l'étape qui suit, et l'artefact est
publié. C'est pourquoi ce chantier-ci a pu être mesuré malgré le rouge.

Ce qui est su et ce qui ne l'est pas : le journal donne « changement d'écran à 0,64 s du plan en
moyenne (attendu 0,60, étendue 0,40 → 0,90) » pour des fenêtres de 0,90 s. La marge est donc
mince, et la campagne 201 est peut-être passée par chance. Ce n'est pas une conclusion, c'est ce
qu'il y a à instruire — et ça devient le chantier suivant.

## 15 novembre 2026 — le film d'aperçu : instruire avant de corriger

Les campagnes 202 et 203 sont refusées au même endroit : « ce plan vise *stats* et montre
*profil* », en anglais. L'image de preuve ne laisse aucun doute — c'est l'écran Profil, onglet
Profil allumé. Le garde a raison sur ce qu'il affirme.

**Mais le journal porte une contradiction, et c'est elle qu'il faut instruire.** Trois lignes plus
haut, la recherche d'alignement conclut « chaque plan sur son écran », au même décalage et sur le
même enregistrement. Deux mesures du même film, deux réponses.

**Lecture du code : elles ne posent pas la même question.**

| | ce qu'elle regarde |
| --- | --- |
| `alignement()` | UNE image par plan, à `debut + 0,5 s` |
| le verdict | TROIS images, à 25 %, 50 % et 75 % du plan |

Et le verdict garde, des trois, **celle dont la distance au plus proche écran est la plus
faible** — pas celle qui montre l'écran visé. Un instant net sur le mauvais écran l'emporte donc
sur un instant correct mais encore en train de se poser. Or son propre en-tête dit l'inverse :
« il suffit qu'il CONTIENNE le bon écran », « un plan qui se pose lentement ou qui défile en
chemin en a au moins un, et passe ». La règle écrite et la règle appliquée divergent.

**Je ne touche pas à la règle, et c'est délibéré.** Desserrer un garde pour que la barrière
repasse au vert est la façon ordinaire de tuer un garde. Tant que je ne sais pas ce que montrent
les DEUX AUTRES instants, je ne peux pas dire si le film est juste ou faux — et je ne peux pas le
savoir, parce que `brut.mov` ne part pas dans l'artefact (trop lourd) et qu'une seule image sur
trois était gardée.

**Ce qui est fait, donc : de quoi diagnoser la prochaine fois.** Les trois instants sont
désormais gardés en PNG pleine taille quand un plan est refusé, et le journal dit pour chacun
l'écran vu, sa distance, et la distance à l'écran visé — plus une marque sur celui que le verdict
a retenu. Trois images par plan fautif, uniquement en cas d'échec.

Et le message de la recherche dit maintenant ce qu'il a regardé : « chaque plan sur son écran **au
premier instant** ». On ne lira plus une contradiction là où il y a deux questions.

La prochaine campagne tranchera : si les trois instants montrent l'écran visé à l'un d'eux, la
règle écrite est la bonne et c'est le code qui doit la suivre. Si aucun ne le montre, le film est
vraiment coupé au mauvais endroit et c'est le découpage qu'il faut corriger.

## 15 novembre 2026 — la fiche App Store annonçait une politique de confidentialité morte

Charlotte : « remets la page privacy html elle a sauté ».

**La page, elle, n'avait pas bougé.** Mesuré avant de toucher à quoi que ce soit : l'adresse
déclarée répond **200**, son contenu est identique octet pour octet à `main` et à la branche de
travail, sa dernière modification est le 11 novembre, `check_politique.py` dit « 12 sections,
texte compris, les mêmes que dans le dépôt », et la page s'ouvre et se rend sans une requête
échouée. `support.html` aussi.

**C'est la fiche en vente qui pointait ailleurs.** Relevé sur la page publique de l'App Store,
téléchargée telle qu'un visiteur la reçoit : l'ancienne adresse, celle d'avant le renommage du
dépôt, **dix-sept fois dans le HTML**. Elle répond 404. Charlotte a donc cliqué depuis le
magasin, et elle est tombée sur une erreur — comme tout le monde, et comme un examinateur
d'Apple, qui EXIGE que ce lien réponde.

**Pourquoi le renommage ne l'avait pas emportée avec lui.** Le 10 novembre, neuf copies de
l'ancienne adresse ont été corrigées, une déclaration posée par langage, et `check_liens.py`
écrit pour les tenir. Mais cette URL-ci n'est écrite **nulle part dans le dépôt** : elle vit sur
l'`appInfoLocalization` d'App Store Connect, personne ne l'écrivait, et `push-metadata` ne
poussait que `supportUrl`. La valeur posée à la main des mois plus tôt est restée.

**Et le diagnostic la regardait.** `asc.py pret` imprimait « confidentialité oui » : il vérifiait
qu'une valeur EXISTE, pas qu'elle réponde. **Une URL morte est une valeur.**

### Ce qui change

`push-metadata` pousse désormais l'URL de confidentialité depuis `liens.py`, pour toutes les
langues de la fiche, juste après les textes — et `verifier_les_pages_publiees`, qui tourne au
début de la même commande, a déjà éprouvé que la page répond. On ne pousse jamais une adresse
qu'on n'a pas vérifiée.

`pret` compare maintenant ce qu'Apple annonce à ce que `liens.py` déclare, au lieu de se
contenter d'une valeur non vide : « oui », « AUTRE » ou « NON ».

Un prochain renommage ne demande toujours qu'une ligne de chaque côté — et celle-ci suivra, au
lieu d'attendre que quelqu'un clique.

**Le garde m'a attrapé au passage.** La première version de ce commentaire recopiait l'ancienne
adresse en toutes lettres pour l'expliquer : `check_liens.py` l'a refusée. Il a raison — une
adresse publiée écrite en dur est exactement ce qu'il existe pour empêcher, commentaire compris.
Ce sont les journaux qui gardent les anciennes.

### Ce qui reste à faire, et qui n'est pas de moi

Cette session n'a pas les clés d'API d'Apple — elles vivent dans les secrets de la CI. La
commande est prête ; c'est `asc.py push-metadata` qui la portera. **Le plus rapide reste de poser
l'adresse à la main dans App Store Connect** (App Information → Privacy Policy URL) : ce champ
n'est pas lié à une version, il s'applique à l'app en vente immédiatement, sans attendre la 3.4.

### Campagne 205 : le film était juste, et c'est le garde qui refusait

L'instrumentation posée au chantier précédent a tranché, et dans l'autre sens que prévu.

**Aucune ligne « ce plan vise X et montre Y » dans le journal.** Les quatre plans montrent
l'écran qu'ils visent, chacun avec dix fois la marge du suivant :

| plan | écart au bon écran | au suivant |
| --- | --- | --- |
| coach | 6,1 | 76,4 |
| stats | 5,9 | 66,5 |
| profil | 5,9 | 60,7 |
| accueil | 6,0 | 60,3 |

Le découpage est juste. La campagne échouait sur **l'autre** contrôle : « aucun changement
d'écran repéré ».

**Et la cause est dans le nombre d'images.** Les fenêtres portaient **3, 6, 7 et 11** images là
où `fps=30` sur 0,90 s en annonce vingt-sept. `simctl recordVideo` enregistre à **cadence
variable** : il n'émet une image que quand l'écran change, donc un écran immobile n'en produit
presque aucune, et un fondu de 0,22 s peut tomber entre deux images. `posee()` porte déjà cette
note pour son propre compte depuis qu'un film de quarante secondes avait été déclaré « plus court
que le découpage » ; `images()` ne l'avait pas.

**« Je n'ai pas pu mesurer » n'est pas « c'est faux ».** Ce contrôle existe pour attraper un
découpage décalé de plusieurs secondes — mais un décalage pareil met aussi chaque plan sur le
mauvais écran, et c'est le contrôle d'écran qui l'attrape, directement, sur l'image. Il l'a fait
aux campagnes 202 et 203. Les deux cas sont donc maintenant distingués : fenêtres trop pauvres →
on le dit et on passe ; fenêtres pleines et aucun changement → on refuse.

Ce n'est pas un desserrage de confort : le contrôle qui tranche le découpage reste entier, et
c'est lui qui a refusé les deux campagnes précédentes.

## 15 novembre 2026 — Instrument Sans remplace Inter

Le brief du 15 novembre demandait « remplacer SF Pro partout par Geist (ou General Sans) ».
**L'app n'était pas en SF Pro** : elle embarquait Inter en six graisses et DM Mono en deux,
déclarées et appelées par `.custom(...)`, avec `check_fonts.py` pour refuser une police demandée
et non livrée. Le reproche, lui, tenait : Inter avait été choisie le 9 novembre pour être « le
sosie le plus proche de SF Pro qui se distribue en fichier », après six familles refusées pour
avoir « une voix ».

**Le choix s'est fait sur une image, pas sur un nom.** Les trois candidates ont été montées sur
de vraies chaînes de l'app, à la nouvelle échelle, avec le nouvel accent. Charlotte a tranché
pour Instrument Sans.

**Et General Sans était un piège juridique.** Sa licence (ITF Free Font License, pas OFL)
autorise l'embarquement dans une app — §01 — mais interdit explicitement de la mettre à
disposition « through […] a **repository** ». Le dépôt Haizo est public, vérifié. La déposer
aurait été une infraction livrée dans un commit. Instrument Sans et Space Grotesk sont sous
**OFL 1.1**, vérifié sur leurs fichiers de licence : redistribuables, donc déposables comme Inter
l'était.

### Ce qui a été livré

Google Fonts ne publie qu'un fichier **variable**. Les quatre graisses statiques ont été tirées
de lui avec `fontTools.varLib.instancer` — l'OFL l'autorise, et aucun nom réservé n'est déclaré
dans celui d'Instrument Sans. Cinq fichiers : Regular, Medium, SemiBold, Bold, Italic, plus
l'OFL. Les six fichiers d'Inter sont retirés.

**Il n'y a pas de maigre.** L'axe de graisse d'Instrument Sans commence à 400 : `.light` retombe
sur le Regular. Une police absente ne lève rien — elle rend la police système, en silence.

**Le facteur de taille passe de 1,09 à 1,101**, par la même méthode qu'au changement précédent :
il suit la hauteur de capitale, parce que c'est elle qui décide de la taille perçue. Mesuré sur
les fichiers — Instrument Sans 0,7200 em contre 0,7275 pour Inter, 1,0 % de moins, donc le
facteur monte d'autant pour que les titres ne bougent pas.

| | Inter | Instrument Sans |
| --- | --- | --- |
| hauteur de capitale | 0,7275 em | 0,7200 em (**−1,0 %**) |
| hauteur d'x | 0,5459 em | 0,5100 em (**−6,6 %**) |
| « Charlotte 14,1 6:18 » | 8,583 em | 8,254 em (**−3,8 %**) |

Le texte courant paraîtra donc un peu plus petit à taille de point égale, et les lignes tiendront
dans moins de largeur. C'est assumé, et la capture tranchera s'il faut monter d'un cran.

**Le garde a attrapé la vraie faute de ce chantier.** `instancer` avec `updateFontNames` a
fabriqué l'italique sous le nom PostScript `InstrumentSansItalic-Italic`, pas
`InstrumentSans-Italic`. L'app l'aurait demandée, ne l'aurait pas trouvée, et serait retombée sur
la police système **sans rien dire** — exactement la panne que `check_fonts.py` a été écrit pour
rendre impossible. Les trois enregistrements de nom ont été reposés à la main, pour les deux
plateformes.

### Ce que le changement de police a cassé, et que seul le CI voyait

La campagne 207 a photographié les trente-neuf écrans, puis s'est arrêtée à l'étape de
composition sur `OSError: cannot open resource`. **Quarante-cinq minutes pour une ligne.**

`screenshots.py` et `montage.py` ouvrent eux aussi des fichiers de police — pour composer les
images de la fiche App Store et le film — et ils les nomment en dur : trois appels à
`Inter-Light.ttf`, un à `Inter-SemiBold.ttf`. J'ai retiré les six fichiers d'Inter sans chercher
qui les lisait en dehors de l'app.

`check_fonts.py` était passé au vert, et il avait raison sur son périmètre : il vérifie la chaîne
Swift — déclarations, `UIAppFonts`, livraison par cible. Personne ne regardait les scripts.

**Le garde couvre maintenant les deux côtés.** Tout chemin de `.ttf` écrit dans un script de
`ci_scripts` doit exister, cherché dans les polices de l'app et dans celles de la fiche. Hors
ligne, exact, sans faux positif possible : un nom de fichier est un nom de fichier. Éprouvé en
réintroduisant la faute — le garde refuse et nomme le script.

Les quatre appels pointent sur Instrument Sans. `Inter-Light` n'a pas d'équivalent : ils prennent
le Regular, comme le cran `.light` de l'app.

## 15 novembre 2026 — une seule échelle, en points rendus

Le brief demandait « échelle unique : 12 / 14 / 16 / 20 / 28 / 40 ».

**Le plus important n'est pas les six nombres, c'est qu'ils soient enfin les vrais.** Les valeurs
écrites dans le code passaient par deux facteurs de compensation — 1,25 pour le texte, 1,09 pour
les chiffres — hérités de tailles dessinées contre Bebas Neue, une police abandonnée depuis
longtemps. Aucun nombre du fichier n'était donc la taille à l'écran : « corps = 12 » rendait
15 points.

Ce n'est pas une subtilité d'implémentation. **Le 15 novembre, en relisant l'app pour ce brief,
j'ai moi-même lu « 12 » et conclu que le texte courant était trop petit.** Il ne l'était pas. Un
fichier dont les nombres ne veulent pas dire ce qu'ils disent finit par tromper ceux qui l'ont
écrit.

Les deux facteurs valent 1,0 et disparaissent. L'échelle ne vient plus d'un dessin ancien qu'il
faut rattraper : elle est donnée en points rendus, et ce sont les écrans qui s'y ajustent.

### La correspondance, cran par cran

| cran | rendu avant | rendu après |
| --- | --- | --- |
| `RUTextSize.micro` | 10,6 | **12** |
| `RUTextSize.small` | 13,1 | **14** |
| `RUTextSize.body` | 15,0 | **16** |
| `RUTextSize.label` | 17,5 | **16** |
| `RUTextSize.emphasis` | 20,0 | **20** |
| `RUTextSize.title` | 23,1 | **20** |
| `RUDisplaySize.caption` | 12,0 | **12** |
| `RUDisplaySize.label` | 15,3 | **16** |
| `RUDisplaySize.subtitle` | 19,6 | **20** |
| `RUDisplaySize.title` | 24,0 | **28** |
| `RUDisplaySize.figure` | 30,5 | **28** |
| `RUDisplaySize.hero` | 38,2 | **40** |
| `RUDisplaySize.banner` | 48,0 | **40** |

**Quatre paires partagent désormais un nombre**, et c'est voulu : l'échelle n'a que six valeurs,
et ce qui sépare un libellé d'un corps de texte à taille égale, c'est la graisse — le brief le
dit. Les crans restent distincts parce qu'ils nomment un RÔLE, et qu'un rôle se redimensionne
sans toucher ses voisins.

Les deux mouvements à surveiller sur la capture : le titre de page monte de 17 % (24 → 28) et le
plus grand chiffre descend de 17 % (48 → 40).

**Un banc a été réécrit plutôt que re-épinglé.** `test_design.py` affirmait « `title` vaut 18,5
d'un côté et 22 de l'autre » pour poser la prémisse « même nom, deux valeurs ». Il l'affirme
maintenant en inégalité : ce cas ne porte pas sur CE que valent les crans, mais sur le fait que
le contrôle lit chaque tableau dans sa propre règle. Deux nombres en dur obligeaient à retoucher
le banc à chaque réglage d'échelle — le meilleur moyen de le voir finir désactivé.

## 15 novembre 2026 — un seul accent, #F0225F

Le brief : « un seul accent #F0225F : boutons, onglet actif, séance du jour, progression ». Les
huit thèmes restent — c'est D1, réaffirmée le jour même — mais le rose, qui est le défaut et ce
que montrent la fiche et les captures, prend cette valeur.

**`primary` et `light` prennent la MÊME, et les fondre est le propos.** `light` servait à
74 endroits qui « veulent tous de l'éclat » — l'anneau, l'onglet actif, le libellé RUN — et c'est
exactement la liste que le brief range sous l'accent unique. Deux roses à vingt points de teinte
l'un de l'autre, ce n'est pas de l'éclat : c'est l'hésitation que le brief appelle « sept
couleurs d'accent ».

**Mesuré sur blanc**, et l'accent gagne du contraste en se simplifiant :

| | sur blanc | seuil maison 3,5 |
| --- | --- | --- |
| ancien `primary` `#F50D7A` | 4,02:1 | OK |
| ancien `light` `#FF1F85` | 3,63:1 | OK |
| **`#F0225F`** | **4,12:1** | OK |

`tail` passe du `#7053E6` de la maquette au **`#7B3FE4`** du logo. Il ne sert plus qu'à une
chose : le tracé GPS sur fond noir, la seule signature graphique que le brief conserve.

**Le thème sombre n'est pas touché.** Seule la déclinaison claire est redéfinie ; le brief ne
décrit que le fond clair, et le sombre sera redessiné ensuite avec la même grammaire.

**Deux commentaires devenaient faux, et ils sont corrigés.** `AccentTheme.swift` affirmait que
« `tail` vient toujours de la maquette » — ce n'est plus vrai. `Colors.swift` illustrait le
calcul du fond teinté avec « le rose de marque (#F50D7A) » — la démonstration tient, mais la
valeur n'est plus celle-là, et la phrase le dit maintenant. Un commentaire qui ment est pire
qu'un commentaire absent : c'est celui-là qu'on croit.

### Le compilateur a refusé l'échelle, et il avait raison

Campagne 209, morte en 81 secondes : `error: raw value for enum case is not unique`, quatre fois.
Swift refuse deux cas d'énumération à la même valeur brute, et l'échelle unique faisait tomber
quatre paires sur deux nombres. **Le harnais local ne compile pas de Swift** — c'est écrit depuis
le 11 novembre, et c'est la deuxième fois que ça coûte une campagne.

**Les quatre noms deviennent des alias, pas des suppressions.** `label` est `body`, `title` est
`emphasis` ; côté chiffres, `title` est `figure` et `hero` est `banner`. Les 114 appels à
`.label` et les 8 à `.title` continuent de nommer leur rôle, et le jour où l'un des deux rôles
doit bouger, il bougera sans emporter l'autre. Un libellé de carte n'est pas un corps de texte,
même quand les deux font 16 points.

**Une conséquence à assumer** : `title`, côté chiffres, prend la graisse de `figure`. Un titre de
page passe du demi-gras au gras. Le brief le demande — « titres d'écran en 40 lourd ».

### Deux gardes réparés plutôt que desserrés

**Le plancher de `check_design.py` est désormais compté.** Il exigeait « au moins 13 crans » — un
nombre écrit à la main quand il y en avait treize. Avec neuf cas réels, il refusait un document
juste, et la correction évidente aurait été de **baisser le plancher** : le geste exact par
lequel un garde perd son sens. Il compte maintenant les cas des deux énumérations, donc il suit
l'app sans qu'on y touche.

**Et un cas de test a été réécrit, pas supprimé.** Il vérifiait que `title` était lu dans le bon
tableau — la prémisse étant « le même nom, deux valeurs ». Il n'y a plus aucun homonyme entre les
deux échelles, donc cette prémisse ne peut plus s'écrire. Le supprimer aurait retiré la seule
protection contre un contrôle qui mélangerait les deux tables. Il porte maintenant sur la
propriété qui rendait le défaut possible : **l'étanchéité** — un cran de chiffre n'apparaît
jamais dans l'échelle du texte, et réciproquement.

### Le ruban passait sous la barre d'onglets, et la carte du programme a rendu la ligne

Comparé à pleine résolution, campagne 208 contre campagne 210 : avant, les quantièmes
« 9 10 11 12 13 14 15 » étaient lisibles au-dessus de la barre d'onglets ; après, **coupés en
deux**. Les lettres des jours ont grossi avec l'échelle et ont poussé la rangée des nombres de
douze pixels — assez pour qu'elle passe sous la barre flottante.

Rien n'est perdu, l'écran défile. Mais sur la première hauteur, le ruban de la semaine n'est plus
qu'à moitié lisible, sur l'écran le plus ouvert de l'app. Un nombre coupé en deux n'est le choix
de personne.

**Charlotte a tranché : alléger ce qui est au-dessus.** Et une précision de méthode qui compte —
retirer la pastille d'écart n'aurait rien gagné : elle partage sa ligne avec « 28,3 / 24 km ».
Pour remonter le ruban il faut retirer de la HAUTEUR, pas des éléments.

**Deux changements, une seule ligne rendue.**

L'objectif sort de l'en-tête. Il disait « Ton programme · 10 km · 47:30 » ; la distance et le
chrono vivent déjà sur le profil, dans la pastille « 10 km · 47:30 · 27 décembre 2026 », et sur
l'écran du plan dont cette carte est le bouton. C'était la troisième copie.

Et la semaine passe en sous-titre. Elle était à `displayStyle(.subtitle)` — 20 points, encre
pleine — soit la taille d'un titre de carte, juste sous un titre de carte. Deux titres empilés ne
font pas une hiérarchie, ils font une hésitation. À 14 points en `text2`, elle rend six points de
hauteur, qui sont exactement ce qui manquait en bas.

---

## 16 novembre 2026 — six teintes d'intensité, et plus un dégradé qui décore

Points 2 et 3 du brief du 15 novembre, en un seul chantier parce qu'ils tombent sur les mêmes
écrans : la couleur d'une séance et les dégradés qui l'entouraient se regardent sur la même
capture.

### Une décision du 11 novembre est renversée, et la raison est écrite des deux côtés

DESIGN.md § 7 portait **« les sept teintes d'intensité actuelles restent »**, daté du 11, avec un
argument mesuré : les valeurs du brief sont construites pour un fond sombre, et le clair venait de
devenir le thème par défaut. Le brief du 15 les redemande nommément, en tête de ses cinq
corrections obligatoires, et il redessine le clair AUTOUR d'elles. C'est la décision la plus
récente, et elle est prise en connaissance du thème.

La ligne du 11 est barrée, pas effacée — dans DESIGN.md comme ici. Une décision qui s'inverse doit
laisser sa mesure derrière elle, sinon elle s'inversera encore.

| Famille | Avant | Après |
| --- | --- | --- |
| Récupération | `#0E9C8C` 3,41:1 | `#5AA9E6` **2,54:1** |
| Endurance | `#6B9E00` 3,22:1 | `#2FB37A` **2,68:1** |
| Tempo | `#B86A00` 4,12:1 | `#F5A524` **2,04:1** |
| Fractionné | `#C2352A` 5,47:1 | `#F0225F` 4,12:1 |
| Sortie longue | `#5B3FD6` 6,72:1 | `#7B3FE4` 5,72:1 |
| Fonctionnel | `#0F62C8` 5,83:1 | `#44506B` **8,06:1** |

Mesuré sur blanc pur. Trois passent sous 3:1, le seuil demandé à un objet graphique **porteur de
sens**. Elles n'en sont pas : chaque famille porte aussi une FORME, et c'est déjà la raison pour
laquelle elle en a une — « environ un homme sur douze distingue mal le rouge du vert, et ce sont
précisément les deux extrémités de cette palette ». La couleur appuie, elle ne porte pas.

**Ce ne sont pas `lime` / `cyan` / `amber` / `ember` / `grape` / `azure`.** Ces six-là sont des
couleurs sémantiques d'interface — `lime` veut dire MIEUX, `amber` veut dire MOINS BIEN — et
`check_teintes.py` tient la liste fermée de leurs emplois pour que ce sens ne se dilue pas. Les
faire servir aussi de palette d'entraînement, c'était deux grammaires sur un même jeton : un écart
hebdo vert et un footing vert, à deux centimètres, sans rapport. Six jetons de rôle, donc, et les
anciens gardent leur travail.

### L'anneau perd ses trois couleurs

Il portait `[rose, violet, cyan]` et un balayage par arc dont le dernier arrêt était la couleur du
voisin, pour que les trois se lisent comme un ruban plutôt que comme trois bâtons posés en cercle.
Tout ce mécanisme servait à réconcilier trois teintes ; avec une seule, il n'a plus rien à
réconcilier — il ne restait qu'un éclaircissement décoratif, et le brief l'interdit.

Ce qui sépare les trois objectifs reste ce qui les séparait vraiment, et que le commentaire de la
piste grise disait déjà : **la légende les nomme en toutes lettres**, dans l'ordre où l'anneau les
dessine. La pastille de légende ne désigne plus son arc, elle le puce.

Trois choses sont mortes avec le dégradé : `gradientStartDegrees` et son jumeau, le cas de test
qui ne comparait qu'eux, et `Color.vivid(_:)`, dont la première ligne de documentation disait
« le pendant de `darkened` pour les dégradés d'accent ». Supprimés avec ce qu'ils servaient,
plutôt que laissés à décrire une app qui n'existe plus.

### Une dérive trouvée en chemin, et le garde qui ne la voyait pas

Le widget recopie `AccentTheme.all` à la main — il tourne dans un autre processus et ne peut pas
lire l'objet en mémoire — et `check_accent.py` tient la copie d'accord avec la source.

**Mais l'app n'affiche pas `all` en thème clair.** Elle affiche `resolvedOnLight`, où le rose vaut
`#F0225F` depuis le 15 novembre. Le miroir était donc exact sur la table qu'il copiait, et faux
sur ce qui est dessiné : le widget rendait un `#FF0A78` assombri de 10 %. Deux roses voisins, sur
deux écrans qu'on voit l'un après l'autre, et aucun garde pour le dire — **la copie surveillée
était juste, c'est la table surveillée qui n'était pas celle qu'on regarde.**

`check_accent.py` compare maintenant les deux tables claires aussi. Éprouvé en réintroduisant la
faute dans les deux sens : valeur fausse, et ligne absente.

### Le reste du point 3

- L'aire sous la courbe des stats passe du fondu `22 % → 0` à un **aplat à 8 %**, la valeur du
  brief. Le fondu disait « ce n'est pas une surface pleine » ; huit pour cent le disent aussi,
  sans dégradé. L'aire était le deuxième objet le plus présent d'une carte de stats, derrière le
  chiffre, pour une information que la ligne porte déjà seule.
- Le tracé GPS perd son **halo** — une copie floutée du trait à 1,6 fois sa largeur, qui empâtait
  les virages au lieu de les montrer — et la **lueur de sa tête**. Le trait passe de 3 à 4 points,
  qui est ce que le halo donnait vraiment à lire. La tête reste : ce qui fait lire un déplacement,
  c'est qu'un point avance, pas qu'il brille.

### Trois exceptions sortent de `check_degrade.py`

Sa quatrième catégorie, « la couleur porte une information », est fermée. Ses trois raisons
étaient bonnes **dans leur cadre**, et le brief retire le cadre. Le script compte exactement par
fichier, donc il se plaint aussi d'un dégradé qui MANQUE : l'oubli était impossible dans un sens
comme dans l'autre. Il reste 10 dégradés autorisés dans 7 fichiers — la marque, trois images
produites, deux voiles de lisibilité, et l'avatar que Charlotte a demandé à garder.

### Et un cas de test réécrit plutôt que re-épinglé, pour la troisième fois cette semaine

« une teinte de famille fausse est attrapée » substituait le littéral `ember` dans DESIGN.md. Le
fractionné s'appelle `intervalles` depuis ce matin : la substitution ne trouvait plus rien, et le
cas **passait en ne testant rien**. Il lit maintenant le jeton courant dans le code, et vérifie
que les deux familles qu'il compare ne partagent pas la même valeur — sans quoi il ne prouverait
plus rien le jour où elles la partageraient.

Première version de la correction : substituer un nom inventé. Le garde se plaignait alors du
COMPTE de lignes au lieu de nommer le fractionné, et le cas serait passé pour la mauvaise raison.
C'est un autre jeton de famille qui est substitué.

---

## 16 novembre 2026 — le verdict du film gardait le plus net, pas le bon écran

Le film d'aperçu était refusé depuis trois campagnes. L'instrumentation posée le 15 novembre —
imprimer les TROIS instants au lieu du seul verdict — a donné la réponse à la première lecture.

Campagne 211, plan « coach » :

```
instant 1 (+0,50 s) : « coach » à 6,0,  « coach » à 6,0
instant 2 (+1,00 s) : « coach » à 6,0,  « coach » à 6,0
instant 3 (+1,50 s) : « stats » à 5,8,  « coach » à 117,6  ← jugé
```

**Six, c'est la distance d'un écran posé** — le journal emploie ce chiffre partout pour dire
« reconnu ». Le plan contenait le bon écran deux fois sur trois. **Deux dixièmes de netteté ont
emporté le verdict contre l'identité de l'écran.**

### La règle était écrite, elle n'était pas appliquée

Le docstring de `instants_juges`, posé la veille, dit : *« il suffit qu'il CONTIENNE le bon
écran »*. Le code gardait `min` sur la distance au plus proche, quel que soit l'écran — et son
propre commentaire le disait en toutes lettres trois lignes plus bas : *« pas celui qui montre
l'écran visé »*. **Les deux textes se contredisaient dans le même fichier**, et la recherche
d'alignement, qui lit le même enregistrement au même décalage, concluait « chaque plan sur son
écran » pendant que ce verdict-ci en déclarait un de travers.

Ce n'est pas un desserrage. Un plan posé sur le mauvais écran — le défaut de trois secondes qui a
sorti trois films faux — n'a AUCUN instant dont l'écran le plus proche soit le bon : on retombe
sur le plus net et il est refusé comme avant. Les deux moitiés de la règle ont leur cas.

### Le choix devient une fonction, et c'est la vraie leçon

Il vivait au milieu de `main`, entre une extraction d'images et un `print`. **Aucun cas ne pouvait
l'atteindre, et c'est exactement pour ça qu'il a pu rester faux sous un commentaire juste.**

Pire : les deux cas qui l'approchaient le **recopiaient** à la main. La copie est restée verte
pendant que l'originale était fausse. Un banc qui refait le travail au lieu de l'appeler ne
surveille que lui-même. Ils appellent maintenant `instant_retenu`, qui a cinq cas purs — dont les
chiffres réels de la campagne 211, et un faux plan pour la moitié de la règle qu'il ne faut pas
perdre.

### Une fenêtre vide n'est pas une mesure, et celui-là m'a eu le premier

`instant_du_changement` rendait la longueur de la fenêtre dès qu'aucune image n'était celle de
l'écran d'avant — **zéro image comprise**. Sur la 211, trois fenêtres sur quatre portaient zéro
image, et le journal a imprimé trois fois « changement d'écran à 0,90 s avant le plan (attendu
0,60) », dans la forme exacte d'un relevé.

**J'en ai conclu un décalage uniforme de trois dixièmes, et je l'ai annoncé à Charlotte avant de
chercher d'où venait le nombre.** Il n'existe pas : 0,90 est la longueur de la fenêtre. C'est la
même faute que la comparaison d'une vignette au tiers avec une image pleine — lire un nombre sans
vérifier ce qu'il mesure.

Le raisonnement d'origine est juste **quand il y a des images** : la branche est donc gardée, et
les deux silences ne s'écrivent plus pareil. Cette valeur polluait aussi la moyenne de
l'alignement ; à 0,30 s de l'attendu elle est passée sous la tolérance de 0,5, et rien ne
garantissait qu'une fenêtre plus courte reste du bon côté.

---

## 16 novembre 2026 — le ruban remonté, vérifié à pleine résolution

Campagne 210 contre 211, même résolution, bandes d'encre relevées dans la zone du ruban :

| Campagne | barres | lettres des jours | quantièmes |
| --- | --- | --- | --- |
| 210 (avant) | 2400–2477 | 2505–2530 — 26 px | 2555–2561 — **7 px** |
| 211 (après) | 2400–2448 | 2476–2501 — 26 px | 2526–2551 — **26 px** |

Un chiffre entier fait 26 pixels. Avant, il en restait **sept** au-dessus de la barre d'onglets :
73 % de la rangée passait dessous. Après, les vingt-six sont là, et la dernière ligne d'encre
tombe dix pixels au-dessus du bord de la barre. **Identique dans les trois langues** — mesuré,
pas regardé.

**Correction d'une prédiction : j'avais annoncé « six points de hauteur rendus ».** Le ruban est
remonté de 29 pixels, soit 9,7 points. Les deux gestes — l'objectif hors de l'en-tête, la semaine
en sous-titre — rendent plus que ce que j'avais calculé.

Et une trouvaille en chemin, qui n'a rien à voir avec le chantier : **l'accueil photographié un
lundi montre « 0,0 / 24 km » et une barre vide.** Voir la tâche correspondante — la graine pose
son historique en jours en arrière, donc un lundi aucune sortie ne tombe dans la semaine en cours,
et la fiche App Store montre une app vide une fois sur sept.

---

## 16 novembre 2026 — RunUp devient Haizo

Décision de Charlotte. Le nom était écrit **1 415 fois dans 338 fichiers** : 174 fichiers Swift,
100 scripts, 6 cibles Xcode, 6 dossiers, 26 clés de traduction et leurs 52 traductions, les
documents, la fiche App Store. À cette échelle, un `sed` est un piège.

### La seule question qui comptait : qu'est-ce qui est irréversible

Quatre décisions prises avant la première ligne, et c'est ce qui protège l'app.

**L'identifiant reste `com.hicsuntco.runup`.** Chez Apple, un identifiant différent est une app
différente : nouvelle fiche, zéro avis, aucune mise à jour pour qui a déjà l'app. Et il porte
`.plus.monthly` et `.plus.yearly`, **les produits d'abonnement** — les renommer aurait cessé de
reconnaître tous les abonnements en cours. Personne ne voit jamais cet identifiant.

**Le groupe applicatif reste.** `group.com.hicsuntco.runup` est le seul canal par lequel le widget
et la montre lisent les données. Le renommer les vide.

**Le domaine reste**, décision explicite : les liens de club et de parrainage déjà partagés
continuent de marcher.

**Et le dépôt GitHub ne change pas de nom.** C'est la trouvaille du chantier. L'adresse de la
politique de confidentialité — celle qui est **sur la fiche App Store** — est
`hukaia.github.io/RUNUP/privacy.html`, et elle contient le nom du dépôt. `Liens.swift` porte déjà
la cicatrice du jour où le dépôt a changé de compte et où les neuf copies de cette adresse ont
pointé vers un 404. Renommer le dépôt referait exactement ça.

S'y ajoutent, trouvés en relisant : le schéma d'URL `runup://strava-callback`, **déclaré chez
Strava, hors de notre portée** ; l'en-tête HTTP `X-RunUp-Session-Renewed`, qu'un garde tient
d'accord entre client et serveur — le renommer des deux côtés aurait passé le garde et cassé
quand même, parce que l'app se livre en jours quand le serveur se déploie en minutes ; et les
**quatre variables d'environnement Vercel**, qui vivent dans le tableau de bord et dont le
renommage dans le seul dépôt fait échouer `requireEnv` et coupe le serveur.

### Trois fixtures cassées en silence par le même geste

Un renommage en masse ne laisse pas seulement des oublis. Il **casse** des choses qui continuent
de compiler.

1. `ContactMatcherTests` vérifie que la casse ne change pas l'empreinte d'une adresse. Le
   remplacement a transformé `TEST@RUNUP.APP` en `TEST@Haizo.APP` : le cas comparait désormais
   deux adresses différentes. Toute la famille est passée sur un seul domaine, empreinte SHA-256
   recalculée.
2. `test_liens` épelle l'**ancienne adresse morte** pour prouver qu'elle est refusée.
   `hicsuntco.github.io/RUNUP` est devenu `hicsuntco.github.io/Haizo`, qui n'est l'ancienne
   adresse de personne : trois cas ont cessé de prouver quoi que ce soit. Elle est maintenant
   DÉRIVÉE de l'adresse déclarée, en ne remplaçant que le compte — ce qui est d'ailleurs ce que
   le défaut décrit.
3. `check_liens.py` a refusé mon propre fichier de cas pour y avoir écrit une adresse publiée en
   dur. Même réponse que la semaine dernière : pas d'exemption, on lit la source.

### Le garde, et son angle mort

`check_marque.py` : l'ancien nom ne subsiste QUE dans dix identifiants, chacun avec sa raison
écrite, et `HAIZO` en capitales n'a sa place que dans les quatre fichiers qui portent le logo.
Seize cas, dont un qui vérifie que chaque tolérance porte une vraie raison — il a refusé deux de
mes propres entrées qui disaient « même raison ».

**Et il a eu un angle mort, qu'il faut écrire parce qu'il est instructif.** Sa première liste
d'extensions ne portait pas `.xcstrings`. Il annonçait donc « l'ancien nom ne subsiste nulle
part » pendant que `InfoPlist.xcstrings` en gardait **dix-huit** occurrences, et la montre neuf —
c'est-à-dire les textes des demandes d'autorisation iOS, « RunUp lit tes données Santé… », la
première phrase que l'app adresse à quelqu'un. Le garde était vert et l'app portait l'ancien nom.
Un garde qui choisit les fichiers qu'il regarde ne vaut que ce que vaut cette liste. `.gitignore`
gardait six chemins de l'ancienne arborescence, pour la même raison.

### Ce qui ne demande aucun travail

**L'icône ne porte aucun mot** — quatre barres ascendantes sur le dégradé de marque. Elle survit
sans être redessinée. Et les trois images de la montre, recomposées, sont identiques octet pour
octet : leur empreinte de code avait bougé parce que le module a été renommé, pas parce que le
dessin a changé.

### Graphie

`HAIZO` dans le logo et l'écran de lancement — quatre endroits, tous en `Text(verbatim:)`.
`Haizo` partout ailleurs, parce que dans une phrase c'est un mot et non un cri. C'est ce que
l'app faisait déjà sans l'avoir décidé, d'où les deux graphies `RunUp` et `RUNUP` mélangées.

---

## 16 novembre 2026 — le mot de la marque est dessiné, plus composé

Charlotte a livré le kit de marque et tranché deux choses : **le `haizo` minuscule**, et l'image
du kit plutôt que le nom typographié.

### Ce que le kit confirme sans qu'on ait rien à faire

**Le symbole est déjà celui de l'app** — quatre barres ascendantes — et son dégradé,
`#FF0F5C → #7C5CFE`, est à deux niveaux près celui de l'icône en place. L'icône ne porte aucun
mot : elle survit au changement de nom sans être redessinée.

**En revanche l'icône du kit ne peut pas la remplacer en l'état.** Ses barres touchent le bord :
1 % de marge à droite, 2,5 % en haut, contre ~20 % aujourd'hui. Sous le masque réel d'iOS — une
superellipse — **1,21 % des barres blanches disparaît, dans la zone x 901–1015 / y 26–160**,
c'est-à-dire la pointe arrondie de la plus haute barre. L'icône en place n'y perd aucun pixel.
Le symbole à **94 %** suffit à tout faire rentrer. C'est à la designer de ré-exporter ; d'ici là
l'icône actuelle reste la bonne, et le canal alpha du kit est opaque, donc Apple l'accepterait.

### Cinq endroits composaient le nom, aucun ne portait le logo

L'écran de lancement, l'image de fin de course, la carte de partage, la carte de badge — tous
écrivaient le nom en capitales dans Instrument Sans, avec un `tracking` réglé à la main. Et le
**carton d'ouverture et de fin du film App Store** l'écrivait à 220 points dans une TROISIÈME
fonte, Bricolage Grotesque Condensed. C'est la première et la dernière image qu'on voit de la
marque sur la fiche, et elle montrait le nom tapé.

Un logo est un dessin. Il ne se retape pas, et surtout il ne suit pas la fonte de l'interface le
jour où elle change — ce qui est arrivé deux fois cette semaine.

### Une seule image, template, pour quatre habillages

Le mot paraît en encre de marque, en blanc, et — sur une des trois styles de carte de partage —
en **dégradé**. Un aplat n'aurait pas su faire le troisième. L'image est donc déclarée
`template` : elle ne porte que sa forme et prend le `foregroundStyle` qu'on lui donne, dégradé
compris. Ce n'est pas une licence prise sur la marque : **le kit lui-même livre la même forme en
deux encres.** La forme est la marque, la couleur est le contexte.

Le script du film lit **le même fichier** et le teinte de son côté, plutôt que d'en garder un
second exemplaire dans `appstore/` qui divergerait au premier ajustement.

### Les tailles sont mesurées, pas choisies

Sur `haizo_A_white.png` : le mot fait **0,835 fois la hauteur du symbole**. Dans `AppMarkView`,
les barres occupent **0,59** de la tuile. Le mot vaut donc `0,835 × 0,59 ≈ 0,49` fois la tuile
qui l'accompagne — la seule constante de `MotDeMarque`. Sur le carton du film, il est posé à la
hauteur d'encre exacte qu'occupait le nom composé, 151 pixels, et prend alors 37 % du cadre.

### Une encre de marque, qui ne suit pas le thème

`#1A1023`, mesuré sur les deux verrous sombres du kit. C'est un noir **froid** — bleu 0x23
au-dessus du rouge 0x1A — là où `textPrimary` est passé au **chaud** le 12 novembre pour suivre
la famille des fonds. Même luminance à un dixième près (18,31:1 contre 18,19:1 sur blanc),
familles opposées. Un logo garde son encre quand tout le reste s'accorde au fond ; c'est ce qui
le fait lire comme une signature.

**C'est le troisième signal dans le même sens**, et il attend une décision : le brief demande
`#F3EEF4` pour les pastilles, le logo porte un noir froid, et les fonds clairs sont chauds.

### Un garde pour deux pannes qui ne se ressemblent pas

`check_marque.py` surveille désormais aussi le fichier du mot. La première panne est bruyante
mais tardive : le fichier absent, et la campagne photographie trente-neuf écrans avant de mourir
à la composition — c'est la panne du 15 novembre, quarante-cinq minutes pour une ligne. La
seconde ne fait **aucun bruit** : l'intention de rendu repassée de `template` à `original`, et
le dégradé de la carte de partage cesse de s'appliquer — le mot devient un bloc blanc, sans
erreur et sans avertissement.

Vingt-cinq cas. Et trois de mes propres cas étaient devenus faux, tous dits par le banc : un
mélangeait les deux règles du contrôle — séparées en `le_mot` et `noms`, parce qu'un contrôle
qu'on ne peut plus éprouver par morceaux finit éprouvé par aucun — et un autre vérifiait une
exemption que je venais de retirer. Réécrit sur la propriété plutôt que sur un nom épinglé.

### Et une sortie d'échelle qui disparaît avec sa cause

`check_echelle.py` compte les `display(horsEchelle:)` par fichier et se plaint dans les deux
sens. Les trois fichiers d'export en perdent une chacun : le mot y était composé hors échelle,
à juste titre — un logo n'a pas à suivre l'échelle du texte. Il n'est plus composé du tout, et
une image n'a pas de cran de typographie.

---

## 16 novembre 2026 — l'horloge de la démonstration est figée

La fiche App Store montrait une app **vide deux jours sur sept**, et personne ne le choisissait.

### Le calcul, avant la correction

`CaptureSeed.historique` pose ses seize sorties en JOURS EN ARRIÈRE — 2, 4, 6, 9… — à partir de
l'horloge réelle. Ce que la semaine en cours contient dépend donc du jour où la campagne tourne.
Calculé sur la vraie table :

| « aujourd'hui » de la démo | la semaine en cours |
| --- | --- |
| lundi, **mardi** | **0,0 / 24 km** — aucune sortie, barre grise, pastille d'écart absente |
| mercredi, jeudi | 8,1 / 24 km — une sortie |
| vendredi, samedi | 14,1 / 24 km — deux sorties |
| dimanche | 28,3 / 24 km — trois sorties, et la pastille « ▼ 1,2 km » |

**Le modèle se vérifie sur une observation.** La campagne 210 tournait un dimanche et montrait
bien 28,3 ; la 212 tournait un lundi et montrait 0,0. C'est la même famille de défaut que le
tracé GPS photographié à moitié dessiné en campagne 166 : le minutage décide de ce qu'Apple
reçoit.

**Et j'avais sous-déclaré.** En signalant le défaut j'ai écrit « une fois sur sept ». Le calcul
dit deux : le mardi aussi.

### Le dimanche, et pourquoi ce n'est pas un choix esthétique

C'est l'image qui est **déjà sur la fiche** et que Charlotte a validée. Changer ce que la vitrine
raconte — une semaine bouclée plutôt qu'une semaine en cours — serait une décision de direction
artistique. Celle-ci n'en est pas une : elle rend constant ce qui était tiré au sort.

L'heure est figée aussi, à 18 h. `historique` choisit l'heure d'une sortie selon son type et
`poseDUneActiviteDuJour` borne l'activité du club au matin même : une campagne lancée à 23 h et
une autre à 7 h ne rendraient pas les mêmes écrans.

Et c'est le **dernier** dimanche, pas celui de la semaine en cours : un dimanche à venir serait
dans le futur, et la démonstration montrerait des sorties pas encore courues — la seule chose que
cette app ne doit jamais faire.

### Un piège de calendrier, évité de justesse

Un premier jet posait `firstWeekday = 2` juste au-dessus de la recherche, ce qui ne changeait
rien et laissait croire que `weekday: 1` valait lundi. Les deux se confondent facilement :
`firstWeekday` dit par quel jour une SEMAINE commence, `weekday` numérote les jours du calendrier
grégorien, où 1 est toujours le dimanche. La ligne est partie, la confusion est écrite.

### Quatre cas, dans le fichier qui porte déjà ce raisonnement

`CaptureSeedHeureTests` existe parce qu'un défaut qui ne casse qu'entre minuit et 5 h ne peut pas
être attrapé par une chaîne qui tourne quand quelqu'un pousse. Le même argument vaut mot pour
mot ici, sur les jours plutôt que les heures.

Trois cas décrivent le MOYEN — c'est toujours un dimanche à 18 h, jamais dans le futur, et le
dimanche matin on recule d'une semaine. **Le quatrième décrit la fin** : quel que soit le jour,
la semaine de la démonstration porte au moins trois sorties et plus de 20 km. C'est celui qui
protège la vitrine ; les autres protègent la façon d'y arriver.

L'intention a été éprouvée en Python sur 14 jours × 7 heures avant d'être écrite en Swift — le
harnais local ne compile pas de Swift, et il n'était pas question d'envoyer une campagne d'une
heure vérifier une arithmétique de calendrier.

### Ce que ça ne corrige pas

**Trois des six teintes d'intensité restent invisibles sur les captures.** Le seuil, la
récupération et le renforcement n'apparaissent sur aucun des écrans photographiés — dont le seuil
`#F5A524`, le plus bas des six en contraste à 2,04:1. Ce n'est pas la graine qui en décide mais
le programme que le moteur compose pour ce profil. Chantier à part.

---

## 16 novembre 2026 — les couleurs décoratives, et la palette que personne ne voyait

Point 2 du brief du 15 novembre, la moitié qui restait : la liste de couleurs que Charlotte avait
relevées écran par écran.

### Les cinq qu'elle avait nommées

| Ce qu'elle a vu | Ce que c'était | Ce que c'est |
| --- | --- | --- |
| le vert « séance faite » | `lime`, et `#C9FF3B` dans la cloche | un ✓ d'accent |
| le RECORD lime | `limeSombre` sur la courbe d'allure | l'accent de la nuit |
| les kcal turquoise | `cyan` | l'encre |
| « Zone optimale » turquoise | `cyan` | gris — **l'ambre de la charge haute reste** |
| le turquoise du mur | `cyan`, quatre emplois | l'encre et le gris |

**`statTile` rendait déjà `RUColor.textPrimary` par défaut.** Trois tuiles du récap la
surchargeaient — rose, turquoise, lime, côte à côte. Il suffisait de ne pas passer l'argument.
Le brief ne nomme que les calories ; la fréquence cardiaque et le dénivelé sont la même ligne,
le même défaut et la même correction.

Sur le mur du Club, le turquoise peignait la pastille, l'icône, le libellé du genre et son
contour : **quatre emplois pour redire ce que le drapeau à damier dit déjà.**

Et « Zone optimale » montre la bonne frontière. L'ambre d'une charge trop haute DIT quelque
chose — c'est un avertissement. Une charge juste est l'état normal, et l'état normal n'a pas de
couleur.

### La trouvaille : la cloche avait sa propre palette

**Neuf couleurs de notification écrites en dur, une par site d'appel.** Trois roses voisins —
dont deux qui n'étaient pas l'accent — deux verts, un orange, un violet, un turquoise et un
ambre. Personne ne les avait choisies ensemble.

Le défaut était plus difficile à voir que les autres, et pour une raison structurelle : **une
notification ne paraît qu'après un geste précis** — une course récupérée après une fermeture, une
paire de chaussures usée — donc elle n'est sur aucune capture. Un écran qu'on ne photographie pas
dérive sans que rien ne le dise.

Ce qu'une cloche a besoin de dire tient en trois registres, désormais nommés dans
`AppNotification` : **un fait** (`accent`), **un écart à surveiller** (`avertissement`), **une
panne dont on s'est relevé** (`incident`). Huit sites sur neuf y passent.

### Le neuvième est une question, et le garde la porte

La flamme orange de la série. Le brief demande le gris ; `check_teintes.py` justifie nommément la
flamme conditionnelle de l'écran des stats comme porteuse de sens — « elle ne décore pas la
flamme, elle dit si la flamme est allumée ». **Les deux ne peuvent pas être vraies.**

Elle est donc tolérée avec cette raison écrite, en attendant l'arbitrage de Charlotte. Une
attente inscrite dans la CI ne se confond pas avec un oubli ; une attente non écrite, si.

Le contrôle refuse toute autre couleur de cloche en dur — éprouvé en en réintroduisant une.

---

## 16 novembre 2026 — la flamme et le ▼, tranchés par une synthèse

Les deux dernières couleurs du point 2, celles où le brief et le code se contredisaient.

### La flamme : les deux avaient raison sur leur moitié

Le brief du 15 novembre demandait de retirer la flamme colorée. `check_teintes.py` la défendait
nommément — « la seule teinte conditionnelle de l'app, et c'est ce qui la justifie : elle ne
décore pas la flamme, elle dit si la flamme est allumée ».

Ce qui devait partir n'était pas la distinction, c'était **une troisième couleur dans une app qui
n'en a qu'une**. Allumée à l'accent, éteinte au gris : la même information, sans vocabulaire
ajouté. Le vert de l'écran des stats, l'ambre `#FFB03D` du widget et l'orange `#FF6B4A` de la
cloche partent ensemble.

Le widget compte double : c'est la seule surface de l'app qu'on voit **sans l'ouvrir**.

### Le ▼ : le brief a raison, contre une décision du 14 novembre

La pastille d'écart gardait son ambre, avec cette raison écrite : « l'ambre y veut dire *moins
bien que la semaine passée* ». L'argument est exact — et c'est **précisément ce qu'on ne veut
plus dire.** Une semaine plus courte qu'une autre n'est pas un échec : elle peut être une
semaine de récupération, que le programme a lui-même demandée.

Les flèches `▲` et `▼` portent l'information en entier, et dans une forme qui ne dépend ni du
daltonisme ni du contraste. La couleur n'ajoutait qu'un jugement.

### L'exception du garde part avec la question

`CLOCHE_TOLEREE` a porté une entrée pendant une heure. Elle existait pour rendre la contradiction
**visible** plutôt que de la laisser passer pour un oubli. La contradiction est tranchée, l'entrée
n'a plus d'objet, et le commentaire qui la remplace raconte pourquoi elle a existé.

Une attente inscrite dans la CI se referme ; une attente non écrite s'oublie.

## 16 novembre 2026 — une seule carte, et ce qui tenait debout grâce à la deuxième

Le point 4 du brief du 15 novembre tient en une phrase : **« une seule carte : blanche, rayon 20,
ombre `0 2px 12px rgba(0,0,0,0.06)`, pas de contour, padding 20 ; pastilles `#F3EEF4` ; badges en
cercles de 64 ; barres de semaine à 8 »**. L'app en avait deux, et la deuxième ne vivait pas
seulement dans son composant.

### La carte « héros » n'existait pas qu'à un endroit

`ruHeroCard` posait un lavis d'accent sous **sept** cartes — la forme du jour, la relance du
coach, le résumé du programme, la reprise après un objectif. Supprimer le modificateur aurait
laissé **quatre lavis peints à la main**, hors du composant, dans quatre écrans qui écrivaient
`RUColor.heroSurface` en direct. C'est la même famille que les hexagones ci-dessous : *un
composant supprimé ne supprime pas ce que d'autres ont recopié à la main.*

Ce que la carte héros servait — « celle-ci compte plus que les autres » — était déjà dit par la
place (la première sous l'en-tête) et par la taille du chiffre. Le lavis le **redisait**, au prix
d'une deuxième surface dans le vocabulaire.

Le jeton `heroSurface` reste déclaré et n'est appelé par personne. C'est un choix écrit : il nomme
une surface d'accent **opaque, calculée par mélange** plutôt que par transparence, et cette
raison-là se perd avec la ligne qui la portait.

### Les hexagones étaient dessinés quatre fois

`HexagonBadgeShape` est parti — et avec lui `BadgeHexTile`, devenu `BadgeTile`. Mais **trois
écrans dessinaient l'hexagone à la main** : `ClubBadgeTile`, `BadgeUnlockedView`,
`BadgeShareCardView`. Le fichier supprimé, l'app aurait gardé trois hexagones et un cercle.

### L'ombre revient là où son argument de départ ne s'applique plus

Le 12 novembre, l'ombre portée avait été retirée au profit d'un filet, avec une raison qui
tenait : « sur du papier, une ombre portée empile du gris sur un fond déjà gris ». Elle tenait
**pour une ombre à 16 % posée sur un fond teinté**. À 6 % sur du blanc, ce n'est plus du gris
empilé, c'est un bord qui s'adoucit. Le filet tombe, l'ombre revient, et `cardBorder` vaut
`.clear` dans les deux thèmes.

Au passage, une conversion qui se perd souvent : **le `radius` de SwiftUI vaut la moitié du flou
CSS.** 12 px de flou donnent 6 ; le décalage vertical, lui, se lit tel quel.

### Deux endroits où je n'ai pas suivi la lettre du brief

**Le padding : 18, pas 20.** La grille d'espacement a fusionné 16, 20 et 22 dans 18 ou 24 le jour
où 409 appels l'ont rejointe, avec cet argument : « au-dessus de 14, deux points ne se voient
pas ». Et son commentaire prévient : « ajouter une valeur ici la rend légale partout ». 14 → 18
reste le vrai changement que le brief demande — quatre points de plus sur les quatre côtés.

**Les pastilles sur `card2`, pas sur `#F3EEF4`.** La valeur du brief est une lavande **froide** ;
les fonds clairs de l'app sont chauds depuis le 12 novembre, et `check_jetons_de_texte.py` tient
la règle « la famille du fond ». Je garde la direction — une surface **déclarée** au lieu d'un
noir dilué, qui ne rendait pas la même couleur sur une carte et sur une sous-surface — et la
famille de la page : luminance 0,839 contre 0,867, un cran plus marqué. Si l'app passe au froid,
cette ligne et `card2` bougent ensemble ; c'est une ligne, pas un chantier.

### Le rayon, lui, est un remplacement, pas un ajout

`radiusCard` passe de 24 à 20. Quatre points sur un angle **se voient**, contrairement aux deux
points d'écart que la grille juge invisibles. `rayons` compte toujours cinq valeurs, et aucun
rayon écrit à la main ne valait 24 : l'échelle ne s'ouvre pas.

## 16 novembre 2026 — il ne reste qu'une carte de nuit, et c'est le tracé GPS

Le brief du 15 novembre dit **trois fois la même chose**, sur trois écrans différents :

> « Les cartes noires n'existent que pour un tracé GPS ou l'écran de séance. » (point 4)
> « La courbe de stats devient un trait accent de 2 px sur fond blanc […] sur carte blanche et
> non noire. » (point 3)
> « Le bloc "Ce qu'il regarde" passe en blanc. » (point 5)

L'app en avait **cinq** : la courbe des Stats, le graphique du Plan, l'anneau de la Journée, le
ruban du Coach, et le tracé de l'accueil. Quatre repassent sur du blanc.

**C'est une décision de Charlotte qui en renverse une autre.** Le 13 novembre elle avait demandé
d'étendre la signature de nuit aux quatre écrans qui ne l'avaient pas ; `CarteDeNuit` existe pour
ça, et son en-tête énonce les cinq règles qui font qu'un fond sombre est une signature plutôt
qu'un goût. Le brief du 15 revient dessus. Une signature qui tient sur cinq écrans sur six n'en
est plus une : elle devient le fond de l'app.

Le composant reste, et ses règles aussi — il porte le tracé de l'accueil, et il portera le
suivant. `check_nuit.py` ne perd rien non plus : il ne lit pas une liste d'écrans mais les appels
à `CarteDeNuit` là où ils sont.

### Ce que le retour sur la page a supprimé, et qui n'existait que pour la nuit

**Trois booléens `surLaNuit`.** `DailyGoalsBarsView`, `RubanDeSemaine` et la ligne d'allure des
Stats en recevaient un pour calibrer leurs encres sur le fond. Les trois n'ont plus qu'un fond.
Un paramètre qui ne prend plus qu'une valeur ne décrit plus un choix : il entretient l'idée qu'il
en reste un.

**Deux tables de couleurs pour quatre blocs.** Le graphique du Plan avait
`couleurDeBlocSurLaNuit` pour ses barres et `couleurDeBlocSurLaPage` pour les pastilles de sa
propre légende, deux centimètres plus bas — parce que les deux objets n'étaient pas sur le même
fond **dans la même carte**. Il n'en reste qu'une, et les barres reprennent exactement les
couleurs que leur légende annonce.

**`SessionFamily.tintSurLaNuit`**, les sept familles sur du presque-noir. Seul le ruban la
lisait. Elle ne portait aucune connaissance propre : six de ses sept cas rendaient les jumelles
de nuit déjà déclarées (`limeSombre` et les cinq autres, qui restent et servent le thème sombre).

**`DailyGoalsBarsView.fillColorSurLaNuit`** et son jumeau `fillColorsSurLaNuit` — qui, lui,
n'avait jamais eu d'appelant.

### Le dégradé que le garde ne pouvait pas voir

La courbe des Stats était peinte avec un **dégradé** sous elle, de 35 % à transparent. La règle 7
interdit les dégradés dans l'interface depuis le 15 novembre et `check_degrade.py` les compte
fichier par fichier — mais celui-ci est peint dans un `Canvas`, pas déclaré en SwiftUI. L'en-tête
du garde l'annonce depuis son premier jour : *« ce qu'il ne voit pas : un dégradé fabriqué
autrement, une image, un `Canvas` »*. Le brief le nomme, lui : « remplissage à 8 % d'opacité,
sans glow ». Trait de 2,5 → **2 px**, dégradé → **aplat à 8 %**.

Et la pastille du point RECORD passe du lime à l'accent. Son étiquette avait fait ce chemin le
16 novembre au matin, **la pastille non** : le mot et le point qu'il désigne étaient de deux
couleurs.

### Le vide du Coach n'était pas sous le bloc, il était au-dessus du fil

« L'écran Coach supprime le vide », dit le brief, « et le fil de conversation commence directement
dessous ». Le fil était collé **au bas de l'écran** par une hauteur minimale égale à la hauteur
visible : avec un seul message d'accueil, il restait plaqué contre la barre de saisie, six cents
points sous le bloc. La raison écrite le jour où ce réglage est arrivé était « un seul message
d'accueil restait sinon accroché en haut, avec six cents points de vide sous lui » — c'est-à-dire
qu'on avait **déplacé** le vide, pas supprimé.

Ce réglage n'avait d'effet que sur un fil plus court que l'écran. `onAppear` et `onChange` font
déjà défiler jusqu'au dernier message : une vraie conversation ne change pas d'un point.

Les deux branches du bloc n'en font plus qu'une — elles ne différaient que par le fond.

### Et « BOUCLÉS » devient « Bouclés »

Point 1 du brief, qui nomme le procédé. Les capitales étaient dans la **chaîne**, pas dans un
`textCase` : c'est donc le catalogue qui change, dans les trois langues. `check_strings.py` a
refusé le premier jet, parce que « Bouclés » n'y était pas encore — il a fait exactement ce pour
quoi il existe.

## 16 novembre 2026 — l'écran de séance : un label discret, un chiffre à 72

> « L'écran de séance garde son panneau noir, remplace "ALLURE CIBLE" par un label discret et
> agrandit le chiffre central à 72. La toast "Course trop courte" perd son tiret cadratin et se
> positionne au-dessus de la barre d'onglets, jamais dessus. »

### Le chiffre central, c'est l'allure — vérifié sur la capture

Les deux membres de la phrase parlent du même bloc : le label qu'on remplace est celui de
l'allure, et le chiffre juste dessous est **6:18/km**. La capture de la campagne du 16 novembre
au matin le montre sans ambiguïté — « ALLURE CIBLE » en rose espacé, puis l'allure en gros, puis
le chrono plus petit.

### Ce qui empêchait le chiffre de grandir, c'était un mot

Le 13 novembre, un plafond avait été posé à 44 points, avec sa mesure : *« "CIBLE 10:30/km" — le
pire cas, un coureur lent pendant son échauffement — occupe 261 pt à 44 et 301 à 52. Au-delà, la
consigne se tronque en course sans qu'aucun test ne puisse le voir. »*

Largeurs recalculées sur `InstrumentSans-Bold.ttf`, avec le `tracking` de −3 % que l'échelle
applique, contre les **284 points utiles** de l'iPhone le plus étroit :

| | 40 pt | 72 pt |
| --- | ---: | ---: |
| `6:18/km` | 146 | **263** |
| `10:30/km` | 174 | 313 |
| `CIBLE 10:30/km` | 289 | 520 |

Le plafond ne venait donc pas de l'allure : il venait du **mot posé à côté d'elle**. Seul, le
chiffre tient à 72 pour toute allure à un chiffre de minutes — c'est-à-dire tout le monde entre
4:00 et 9:59.

Le mot monte donc dans le label, qui annonce déjà le segment : « Échauffement · cible ». Il dit
exactement la même chose, un cran plus haut dans la lecture, et il ne pèse plus sur la largeur du
nombre. **Même place, même taille, aucun saut de mise en page toutes les quatre-vingt-dix
secondes** — ce que la note du 13 novembre tenait à préserver, et qui n'était plus tenable
autrement à 72.

### Le label était en accent, c'est-à-dire de la couleur de ce qu'il annonce

En capitales espacées (`tracking(2)`) **et** en `Ink.accentSoft` : deux objets allumés dans un
bloc qui n'en veut qu'un. 12 points, gris, casse normale.

Les quatre libellés de segment suivent — « ÉCHAUFFEMENT » devient « Échauffement ». Les capitales
étaient dans la **chaîne**, pas dans un `textCase` : six clés sortent du catalogue, trois y
entrent, dans les trois langues.

### La toast était déjà au bon endroit, et l'arithmétique le dit

`tabBarBottomInset (12) + tabBarHeight (56) + 14` = 82 points sous le bord bas ; la barre occupe
12 à 68. Quatorze points d'écart, jamais dessus. Il restait le tiret cadratin.

**Et il y en a 193 autres.** Le catalogue compte 194 chaînes qui en portent un. Le tiret cadratin
est de la ponctuation française légitime ; c'est sa répétition mécanique qui se lit comme un tic.
Réécrire 194 chaînes en trois langues change le **ton** de l'app : c'est une décision de
direction, pas une correction. Celle que le brief nomme est corrigée, les autres sont comptées.

### Un garde ne voyait pas le plus gros chiffre de l'app

`check_grands_chiffres.py` vérifie qu'un grand corps limité à une ligne peut rétrécir. Son motif
connaissait `displayStyle(horsEchelle:)` — le modificateur de vue — mais **pas**
`RUFont.display(horsEchelle:)`, la fabrique de police qu'on passe à `.font(…)`. Les deux écrivent
le même grand corps ; seule la première était contrôlée. Ce qui sortait par là : le **96** du
compte à rebours de la course.

Même forme de trou que le dégradé peint dans un `Canvas` : un garde ne voit que les orthographes
qu'on lui a données.

Son test de l'écran de séance exigeait « au moins trois grands corps ». Il en trouvait trois
parce que l'allure cible en fournissait **deux à elle seule**, une par branche de
`targetPaceLine`. Les branches fusionnées, le compte est tombé à deux et le test a refusé — à
raison. Il est maintenant exact plutôt que minoré, parce que sa seule raison d'être est de ne pas
pouvoir passer en ne regardant rien.

## 16 novembre 2026 — l'accueil ouvre sur une image

> « L'accueil ouvre sur une image plein écran en en-tête (photo de coureur, lumière naturelle,
> grain conservé, sombre vers le bas) avec "Charlotte" et la séance du jour par-dessus, comme
> l'accueil Hukaia mais avec la palette Haizo. »

### L'image, et pourquoi ce n'est pas une photo

L'app n'en possède aucune. Une silhouette fabriquée pour l'occasion est exactement ce que la
question 3 de la direction artistique refuse — « est-ce qu'on devine qu'il a été généré ? ». Une
photo de banque d'images a la même réponse, avec une question de licence en plus.

L'app possède **une** image, et le brief la nomme lui-même au point 3 : le tracé GPS, « la seule
signature graphique de l'app ». Elle vient de ce qu'on a couru, elle ne ressemble à personne
d'autre, et elle change à chaque sortie. Le jour où les photos existent, c'est un fichier à poser
derrière ce même cadre.

### Ce qui est écrit dessus — la référence tranche mieux qu'un raisonnement

J'ai ouvert `vitrine/1-accueil.png`. Sur l'accueil Hukaia, ce qui est posé sur la photo, c'est la
salutation, le **grand mot** et un sous-titre ; la carte « Votre itinéraire » est dans la feuille
blanche qui chevauche l'image par le bas. Et surtout : **l'image et le mot se répondent** — la
photo montre l'Islande, le mot dit « Islande ».

Ici l'image montre la dernière sortie. Ce qui est écrit dessus la **nomme** donc, et la carte de
la séance du jour est la première de la feuille, juste dessous — « par-dessus » au sens où la
référence le montre.

C'est aussi la règle 4 de `CarteDeNuit` : les chiffres se posent **sur** le dessin, ils le
légendent. Un tracé sans sa ligne deviendrait un papier peint, c'est-à-dire la seule chose que le
composant refuse — « un fond sombre n'est pas une signature, c'est un goût ».

### Deux conséquences qui tombent juste

**Le bandeau du milieu de page disparaît.** C'était une deuxième carte de nuit sur le même écran,
et la règle 5 dit « une seule par écran : deux points de fixation n'en font aucun ».

**L'argument du 14 novembre n'est pas défait, il est déplacé.** « On ouvre l'accueil pour savoir
ce qu'on court aujourd'hui », donc ce qui se fait passe avant ce qui s'est fait : l'accueil ouvre
sur une image, et la carte qui porte le bouton reste la première chose qu'on lit **sur la page**.

### Le prénom à 40

Point 1 du brief, qui le nomme : « titres d'écran en 40 lourd ("Charlotte", "Ta forme évolue",
"Le fil") ». Il était à 24 depuis le 14 novembre, avec un argument qui tenait **pour une page
blanche** : « un prénom qu'on ne lit pas — on le sait déjà — occupait le haut du barème »,
au-dessus des chiffres qu'on vient voir. Sur l'image, il ne concurrence plus rien.

### Pourquoi un fichier à part, et ce que ça a attrapé

Le premier jet écrivait l'en-tête dans `HomeView`. `check_nuit.py` a dit « rien de la page n'est
peint sur la nuit » — et il avait raison de se taire : il n'inspecte que le corps des appels à
`CarteDeNuit`, et son en-tête le dit depuis toujours — « une vue tierce appelée depuis une carte
de nuit : son corps est écrit ailleurs ».

La rangée du haut est exactement ce cas : le mot de la marque, la pastille de série et la cloche
sont posés **sur** la nuit mais vivent hors du bloc. Le premier jet y laissait une capsule
`RUColor.card`, c'est-à-dire **blanche en thème clair**, sur du presque-noir, à côté d'un bouton
voilé.

Sorti dans `EnTeteDAccueil.swift` et inscrit dans `FICHIERS_DE_NUIT`, tout son contenu est tenu à
la règle.

### Et la flamme de l'accueil, oubliée par sa propre correction

Le 16 novembre à midi, la flamme passait « allumée à l'accent, éteinte au gris » sur l'écran des
stats, dans le bilan hebdo, dans la feuille de débriefing et dans le widget. **Pas sur
l'accueil** — l'écran qu'on ouvre tous les jours.

`check_teintes.py` n'a rien dit, et il avait raison de se taire lui aussi : il n'inspecte que
`RUCardHeader(tint:)` et `RUStatTile(tint:)`. Une couleur posée en `.foregroundColor` directe est
hors de sa portée. Le relevé complet en donne **74 dans 32 fichiers** — c'est un chantier à part,
et le garde doit grandir avec lui.

## 16 novembre 2026 — figer la graine ne figeait rien

Ce matin j'ai écrit : « l'horloge de la démonstration est figée », et j'ai fait une prédiction
vérifiable — « on est lundi, et l'accueil devra montrer **28,3 / 24 km** avec la pastille
« ▼ 1,2 km ». Si c'est 0,0, mon calcul est faux. »

**La campagne 214 a livré 0,0 / 24 km et « ▼ 14,2 km »**, sur l'image composée de la fiche, pas
seulement sur la capture brute. Mon calcul était faux.

### Pourquoi

J'ai figé l'horloge de la **graine**, pas celle de l'**app**. Les seize sorties sont posées à
« dimanche dernier 18 h moins 2, 4, 6 jours » — vendredi 13, mercredi 11, lundi 9 novembre,
toutes dans la semaine du 9 au 15. L'écran, lui, demande au calendrier réel ce que contient
« cette semaine » : lundi 16, donc du 16 au 22. Aucune.

Figer un seul des deux ne fige rien. C'est la même erreur de raisonnement que le `0.90` du mois
dernier : j'ai lu un mécanisme à moitié et je l'ai annoncé comme un résultat.

### Et le cas de test ne protégeait rien

Il était écrit comme ça : « quel que soit le jour, la semaine de la démonstration porte au moins
trois sorties et plus de 20 km ». Il prenait le début de semaine de **l'instant figé** et comptait
les sorties entre ce début et lui. Vert d'office : il mesurait la semaine que la graine venait de
remplir.

L'écran ne fait pas ça. Il appelle `SemaineComparable.kilometres`, dont le paramètre `maintenant`
valait `.now`.

**Un banc qui refait le travail au lieu de l'appeler ne surveille que lui-même.** C'est la
troisième fois que cette forme coûte quelque chose — après le verdict du film, qui réimplémentait
sa propre sélection, et le ruban. Le cas appelle maintenant la fonction que l'écran appelle, avec
l'instant que l'écran utilise.

### La correction

`Demonstration.maintenant` : l'instant figé quand la démonstration tourne, `.now` partout
ailleurs. Trois lectures y passent, et seulement celles qui décident de **ce que la semaine
courante contient** — `SemaineComparable.kilometres`, `AdaptivePlanEngine.currentWeekRange`,
l'index du jour.

Ce qu'on **écrit** garde l'horloge réelle : la date de départ d'un programme, l'instant d'un
débriefing. En démonstration on n'écrit rien, et une horloge figée qui se propagerait aux
écritures serait un piège pour la première fonctionnalité qui en dépendrait.

### Éprouvé en Python avant de dépenser une campagne — sur l'écran, cette fois

Quatorze jours × quatre heures, en modélisant ce que `SemaineComparable` rendra :

```
campagne lancée le      instant figé      sorties   km affichés
Mon 16 Nov 11h          Sun 15 Nov 18h          3      28,3
…
Sun 22 Nov 11h          Sun 15 Nov 18h          3      28,3
Mon 23 Nov 11h          Sun 22 Nov 18h          3      28,3
```

Toujours trois sorties et 28,3 km. Le dimanche à 11 h renvoie au dimanche **précédent**, parce
que 11 h est avant 18 h : la scène ne montre jamais une sortie pas encore courue.

Conséquence assumée : la date en haut de la fiche dira « dimanche 15 novembre » et non le jour de
la campagne. C'est la scène.

## 16 novembre 2026 — les majuscules espacées, et les trois façons dont elles vivaient

> « Supprimer les majuscules espacées ("TA JOURNÉE", "CE QU'IL REGARDE", "ALLURE CIBLE") : ce
> sont des labels en 12 gris, casse normale. » — point 1 du brief du 15 novembre.

C'était le dernier morceau du brief qui restait, et il n'avait jamais été fait.

### Trois façons, et retirer l'une laissait les deux autres

1. **`.textCase(.uppercase)` posé sur la vue** — sept emplois, sur l'accueil et le Coach.
2. **`tracking(1.5)` sur une chaîne déjà capitalisée.** Et ce style était **écrit cinq fois**,
   mot pour mot : `LiveRunView` (trois fois), `RecapView`, `StatsView`, `RaceGoalView`. C'est ce
   qui a permis à `eyebrowStyle` de perdre ses capitales le 15 novembre pendant que les cinq
   autres gardaient les leurs. Un seul `metaStyle()` les coiffe — 12 points, gris, casse normale,
   pas d'interlettrage.
3. **Les capitales dans la chaîne elle-même**, au catalogue, en trois langues — **43 clés**.
   Celles-là ne se voient pas en relisant une vue : « ÉCHAUFFEMENT » est un littéral comme un
   autre. 34 clés en casse normale les remplacent, 9 existaient déjà.

### Deux clés pour un mot dont seule la casse changeait

`Discipline.rythmeLabel` rendait « Allure » ; `rythmeLabelMajuscules` rendait « ALLURE ». Deux
traductions à tenir, dans trois langues, parce qu'un libellé d'écran était en capitales. Le
jumeau est parti avec la raison qui le faisait exister.

### Où passe la ligne, et comment la déplacer

Les trois exemples du brief sont des **labels**. Un bouton en capitales est autre chose : une
convention assumée, que le brief ne nomme nulle part. Restent donc **67 libellés dans 30
fichiers** — des boutons, deux affiches qu'on exporte (la carte de partage, les images de la
vidéo), l'onglet `RUN`, et une dette nommée.

Le jour où Charlotte tranche que les boutons passent en casse normale, c'est la liste de
`check_majuscules.py` qui se vide — et comme il compte dans les deux sens, il le dira.

### La dette, et sa condition de levée

« EN PAUSE » et « EN COURS » sur la montre **sont** des labels. `check_requis.py` a refusé le
changement : la capture montre **livrée à Apple** est empreintée contre **tout** le code de la
cible `HaizoWatch`, et elle ne se recompose pas dans ce conteneur — elle se prend sur un
simulateur watchOS. Deux mots en casse normale contre une capture App Store qui montrerait autre
chose que l'app : le marché est mauvais. Le widget les garde par symétrie — le même état écrit de
deux façons sur deux surfaces serait pire.

La condition de levée est écrite dans le garde : refaire la capture sur un Mac, puis ces deux
entrées disparaissent.

### Un troisième trou d'orthographe, après le dégradé et le 96

`check_chiffres.py` refuse qu'un grand chiffre et son unité soient composés à la main, et il en
tolère exactement un. Son motif cherchait `RUFont.sans`. En faisant passer l'unité par
`metaStyle`, **le dernier couple à la main de l'app est sorti de son champ** sans que rien ne
change à l'écran — toujours là, simplement plus écrit pareil.

Trois fois dans la même journée : le dégradé peint dans un `Canvas`, le 96 du compte à rebours
écrit avec `display(horsEchelle:)` plutôt que `displayStyle(horsEchelle:)`, et celui-ci. **Un
garde ne voit que les orthographes qu'on lui a données** — et ça se vérifie en changeant une
écriture, pas en relisant le garde.

`check_cablage.py` a refusé aussi : le nouveau garde et ses cas ne tournaient dans aucun
workflow. Il vérifie exactement ça, et c'est pour ça qu'il existe.

## 16 novembre 2026 — j'ai figé une horloge en énumérant ses lecteurs

La campagne 215 a validé deux prédictions sur quatre, et m'en a montré une cinquième chose que
je n'avais pas prédite du tout.

| | prédit | mesuré |
| --- | --- | --- |
| En-tête plein cadre, le tracé, « Charlotte », la ligne | oui | **oui** |
| Semaine à **28,3 / 24 km** | oui | **oui** — l'horloge figée marche |
| Eyebrow « dimanche 15 novembre » | oui | **non** — « lundi 16 novembre » |
| Pastille ▼ en gris | oui | **non** — toujours ambre |
| Aucune carte noire sur Coach, Stats, Plan, Journée | oui | **oui** |

### La régression que j'ai causée, et que seule la capture pouvait dire

« Ta journée » montrait **0/3 bouclés, 0 kcal, 0 pas**. La capture d'avant : 2/3, 612 kcal,
9 240 pas.

`CaptureSeed` écrit `lastDailyResetDay` au jour de l'instant figé — dimanche.
`resetDailyGoalsIfNewDay` lisait `.now` — lundi. Pas le même jour, donc **remise à zéro**.

Et le commentaire de la graine décrit ce défaut **mot pour mot**, parce qu'il s'était déjà
produit dans l'autre sens : « l'accroche *Trois objectifs par jour* surmontait trois zéros, et
l'anneau de l'accueil affichait 0/3 sur un profil qui venait de poser 9 240 pas ». En figeant
l'horloge à trois endroits et pas au quatrième, je l'ai ramené.

### Les trois autres lecteurs oubliés

- **La date de l'en-tête** : « lundi 16 novembre » au-dessus d'une semaine qui s'arrête au
  dimanche précédent.
- **Les quantièmes sous les barres de la semaine** : la carte affichait « 28,3 / 24 km » — la
  semaine figée — avec les quantièmes **16 à 22** dessous, c'est-à-dire la semaine réelle. Deux
  semaines différentes sur le même objet.
- **La remise à zéro du jour**, ci-dessus.

**La leçon est à moi : j'ai figé une horloge en énumérant ses lecteurs, et énumérer est
exactement la façon d'en oublier un.** Les quatre se sont trouvés en ouvrant la capture, pas en
relisant le code.

### Rendre la scène testable plutôt que compter sur ma vigilance

`Demonstration.enCours` s'écrivait une seule fois et ne se refermait jamais — ce qui est juste
pour l'app, et qui rendait la scène **intestable** : l'invariant qui compte ici, « ce que la
graine écrit, la remise à zéro ne l'efface pas », n'est vrai QUE pendant une démonstration. Un
cas qui ne peut pas entrer dans la scène ne peut pas le vérifier.

Un `arreter()` sous `#if DEBUG`, et le cas y entre. Il aurait rougi ce matin. L'app livrée, elle,
n'a de quoi ni allumer ni éteindre quoi que ce soit.

### Le ▼ de l'accueil, en trois temps

1. Négatif, il s'affichait en `amber` — la couleur de l'attention. Or le plan **programme** des
   semaines où le volume baisse.
2. Le 14 novembre, `baisseProgrammee` a éteint l'ambre quand la baisse était prescrite. Moitié du
   défaut réglée : une semaine courte pour cause de maladie restait peinte en alerte.
3. Le brief du 15 novembre tranche le reste. La correction est passée le 16 dans les stats, le
   bilan hebdo, le débriefing et le widget — **pas dans `WeekKmSummary`**, celui de l'accueil,
   celui qui part sur la fiche App Store. La campagne 215 l'a photographié encore ambre.

Et le paramètre `baisseProgrammee` de `WeekKmSummary` est devenu du code que deux écrans
calculent et que personne ne lit : il part, comme les trois booléens `surLaNuit` ce matin.
`AdaptivePlanEngine.baisseProgrammee` reste, avec ses cas — le jour où une **phrase** dira la
chose sous la barre plutôt qu'une couleur, elle est là.

## 16 novembre 2026 — mon garde des capitales avait deux heures, et il avait un trou

J'ai écrit `check_majuscules.py` le matin même pour refuser un libellé tout en capitales, et je
l'ai cru fini parce que ses dix cas passaient. Il cherchait un littéral avec
`"([^"\\]{2,60})"` — une paire de guillemets sans guillemet ni échappée entre les deux.

### Ce motif ne peut pas voir un littéral qui contient une interpolation

Sur `statTile("\(n)", String(localized: "GARDÉ"))`, la classe exclut `\`, donc le premier
littéral ne s'apparie pas. Le moteur repart, trouve le guillemet **fermant** de `"\(n)"` et
l'apparie avec le guillemet **ouvrant** de `"GARDÉ"`. Ce qu'il lit entre les deux,
`, String(localized: `, n'est pas en capitales. Et « GARDÉ » n'est dans aucune paire.

Un scanner de caractères remplace le motif : il traverse les interpolations, descend dedans, et
rend chaque littéral séparément. **Vingt-et-un libellés sont sortis de ce trou**, dont douze clés
de catalogue — et cinq d'entre elles sont des titres d'écran de l'embarquement : « COMMENT TU
T'APPELLES ? », « POURQUOI TU COURS ? », « COURS COMME SI TU AVAIS UN COACH », « ON CONSTRUIT TON
PROGRAMME », « ON PEUT COMPTER TES PAS DANS L'APP ? ». Les quatre premiers écrans que voit
quelqu'un qui installe l'app. Le garde les regardait sans les voir.

### Le quatrième garde de la journée à ne connaître qu'une orthographe

Après le dégradé peint dans un `Canvas`, le 96 du compte à rebours écrit `display(horsEchelle:)`
au lieu de `displayStyle(horsEchelle:)`, et le couple chiffre+unité caché par `metaStyle`. Les
trois premiers étaient des gardes anciens. Celui-ci, je venais de l'écrire.

La leçon ne porte donc pas sur l'âge du code : **un garde se vérifie en changeant l'écriture
qu'il surveille, pas en le relisant.** Je l'ai relu trois fois ce matin-là.

Cinq cas nouveaux le disent maintenant, dont celui qui aurait suffi : un littéral derrière une
interpolation, un littéral dedans, une échappée ordinaire, un sigle dans une phrase, un libellé
qui n'est **que** des capitales.

Et un cas périmé réparé : `"5 KM"` servait de témoin positif à « un mot d'une seule lettre n'est
pas un libellé », mais « KM » est entré dans la liste des sigles — le témoin passait, et
l'assertion lisait un indice dans une liste vide. **Un témoin qui devient légitime ne protège
plus rien.**

### Deux lignes Swift cassées, et la campagne 216 est tombée en 84 secondes

Mon remplacement de « KM » par « km » était textuel, et il a produit
`String(localized: verbatim: "km")` et `statTile(…, verbatim: "km", index: 0)`. Un remplacement
qui ne regarde pas ce qu'il y a autour du mot écrit du Swift qui ne compile pas, et **aucun garde
local ne compile le Swift** : seule la campagne le fait.

### Point 2 du brief, le reste

Les emplois directs de `lime`, `amber` et `cyan` passent de **71 à 29**. Ce qui reste a trois
familles, chacune déclarée dans `check_teintes.py` avec sa raison :

- **les avertissements**, où l'ambre veut dire « moins bien » ;
- **le repère de discipline Vélo**, turquoise par convention et pas par décoration ;
- **deux palettes qui attendent une décision de Charlotte** — les couleurs des badges de club
  (`ClubBadgeCatalog`) et celles des types d'objectif (`GoalType.tint`). Elles ne sont ni
  décoratives ni sémantiques tant qu'on n'a pas tranché ce qu'elles distinguent.

Le garde compte dans les deux sens : le jour où elle décide, c'est lui qui dira que la liste doit
se vider.

### Un seul commit pour deux chantiers, et c'est assumé

Les capitales et les teintes tombent sur les mêmes lignes : **trente-quatre des quatre-vingts
blocs** du diff portent les deux. Les séparer demanderait de couper à l'intérieur des blocs, à la
main, pour fabriquer un état intermédiaire que la barrière n'aurait jamais vu. Une histoire plus
lisible ne vaut pas un commit non vérifié.

## 16 novembre 2026 — un renommage de marque a éteint TestFlight, en silence, pendant douze commits

En lisant les déclencheurs pour une autre raison, j'ai vu que `testflight.yml` part sur
`claude/haizo-ios-swiftui-app-5b1yv6`. **Cette branche n'existe pas.** Le dépôt en a quatre, et le
développement se fait sur `claude/runup-ios-swiftui-app-5b1yv6`, la seule que Charlotte ait
nommée.

Le renommage de la marque (`f4dcc9b`) avait changé la ligne. Depuis, **douze commits** — tout le
brief de direction artistique, points 1 à 5 — et pas une exécution. La dernière build TestFlight
date de ce matin 9 h 11.

### Ce que ça a coûté, et ce que ça n'a pas coûté

- **Aucune build installable sur un téléphone depuis 9 h 11.** C'est le vrai prix : Charlotte ne
  peut essayer aucun des écrans refaits aujourd'hui.
- **Les 122 appels de gardes de `testflight.yml` ne tournaient plus en CI.** La barrière locale
  (`tout.sh`) les lance tous, et je l'ai passée avant chaque commit — le travail n'est donc pas
  non vérifié. Mais il ne l'était plus que sur ma machine.
- **`check_declencheur.py` et `check_cablage.py` se sont tus avec lui**, alors que leur objet est
  précisément de dire qu'un garde ne tourne pas. Ils étaient câblés dans le fichier éteint.
- **La compilation Swift, elle, a continué** : `captures.yml` construit pour un simulateur, et
  c'est ce qui a fait tomber la campagne 216 en 84 secondes. Rien de cassé n'est passé.

### Un renommage de marque a touché une adresse

Un nom de branche, un identifiant de paquet, un domaine ne sont pas des mots de marque : ce sont
des endroits où quelque chose se trouve. Charlotte l'avait tranché le même jour pour les deux
autres — le paquet reste `com.hicsuntco.runup`, le domaine reste `runup-nu.vercel.app` — et la
branche a glissé **parce qu'elle n'était pas dans la question**.

Et `check_marque.py`, le garde écrit pour ce renommage, décrit cette catégorie mot pour mot :
« chacun est un identifiant qu'une personne ne voit jamais, et dont le renommage coûte une
panne ». Dix identifiants y figuraient. La branche n'y était pas, donc le balayage l'a emportée.
Elle y est maintenant, onzième, avec son histoire.

### Un relevé daté réécrit à l'aveugle ne relève plus rien

Quatre documents nommaient la branche, et pas comme un mot de marque :

> `PROGRESS.md` : « confirmé dans les réglages Vercel le 7 novembre : `Branch Tracking` porte
> `claude/haizo-ios-swiftui-app-5b1yv6` »

Le 7 novembre, cette branche n'existait pas. C'était une **observation datée**, et le renommage
l'a rendue fausse — même chose dans `IOS_SETUP.md`, `PHASE2.md` et `AUDIT.md`. Restaurées.

### Le garde, et pourquoi il ne pouvait pas vivre dans `testflight.yml`

**GitHub lit le bloc `on:` du fichier tel qu'il est sur le commit poussé.** Un workflow dont le
déclencheur vient d'être cassé ne part pas, donc ne peut pas se plaindre de lui-même. C'est
exactement ce qui s'est produit, et ça exclut `testflight.yml` comme hôte.

`captures.yml` part bien sur toutes les branches, mais sa liste de chemins ne couvre pas les
autres workflows — et l'y ajouter ferait payer soixante minutes de machine macOS à chaque virgule
de CI.

D'où **`gardes.yml`** : `branches: "**"`, donc aucun nom de branche à casser ; des chemins
étroits, donc il ne part que quand le câblage change ; du Python sur Ubuntu, donc quelques
secondes. Il lance `check_branche.py`, `check_declencheur.py` et `check_cablage.py` — les trois
contrôles qui portent sur la chaîne et non sur l'app, dont deux étaient dans le fichier éteint.

### Et le cas qui compte le plus

**Un contrôle de cohérence n'aurait rien vu.** Le renommage a changé les sept occurrences de la
même façon : elles étaient toutes d'accord entre elles, et toutes fausses. Vérifier qu'un nom est
écrit partout pareil ne dit rien du tout.

`check_branche.py` compare donc au **réel** — `GITHUB_REF_NAME` en CI, `git branch --show-current`
en local — et refuse plutôt que de se taire si la branche est introuvable. Treize cas, dont « un
renommage cohérent partout passe quand même », qui est le défaut d'origine écrit en banc.

Il s'est attrapé lui-même en chemin : la raison que j'écrivais pour dispenser `RELEASE.md` nommait
les deux autres branches, et il a aussitôt compté quatre citations là où j'en déclarais deux.
C'est exactement son travail.

## 16 novembre 2026 — l'en-tête n'était pas plein cadre, et c'est ce qui coupait le ruban

La campagne 217 a livré ses trente-neuf écrans. Les teintes sont au brief, mesurées sur la passe
claire : `#2FB37A`, `#F0225F`, `#7B3FE4`, accent `#F0225F`, jours vides en gris, cartes blanches.
La pastille ▼ est passée en gris, l'eyebrow dit « dimanche 15 novembre », et « Ta journée » est
revenu à 2/3 — la régression de la veille est corrigée.

**Et la capture n° 1, celle qui ouvre la fiche, portait deux défauts.**

### Ils n'en faisaient qu'un

Une coupe verticale dans la marge de page les a reliés :

    page       0,0 →   62,0  ( 62,0 pt)   ← le bandeau clair
    nuit      62,0 →  382,0  (320,0 pt)   ← l'en-tête
    page     382,0 →  956,0

Le bandeau mesure **exactement l'encart de sécurité du haut**. Et le ruban de la semaine, lui,
était tranché : la barre du lundi en deux morceaux, 849,7 → 854,0 puis 910,0 → 915,7, séparés par
168 px de barre d'onglets.

**Les barres ne pouvaient rien donner.** Leur ligne de base est à 915,7 et la barre d'onglets
s'arrête à 910 : toute barre de plus de six points passe derrière. Et les quantièmes sont SOUS
les barres, donc leur position ne dépend pas de leur hauteur. Seule la carte entière pouvait
remonter — de 89 points, pour que le bloc repasse au-dessus de 854.

Soixante-deux de ces 89 étaient dans le bandeau. Vingt-sept dans la hauteur de l'en-tête, qui
passe de 320 à 285. L'image n'est pas plus petite : elle commence au bord.

### Ce que le brief demandait déjà

Point 5 : « l'accueil ouvre sur une image **plein écran** en en-tête ». Ce n'était pas le cas, et
**le défaut était invisible en thème sombre** — le fond de page est noir lui aussi, la bande se
confond avec l'en-tête. Seule la passe claire le montre, et c'est elle qui part sur la fiche.

Le dépôt avait déjà écrit la méthode. `PaywallView` : « `ignoresSafeArea` sur un enfant de
`ScrollView` ne fait pas ce qu'on croit — la vue est disposée dans l'espace du défilement. »
C'est donc le DÉFILEMENT qui l'ignore, comme le fait `RecapView`, dont la capture confirme que
son fond atteint bien la première rangée de pixels.

### L'heure, et une décision qui a changé en cours de route

Une fois l'en-tête sous la barre d'état, l'heure devient noire sur `#14131E` : 1,2:1.

J'ai d'abord proposé d'écrire le mécanisme, et Charlotte l'a choisi. **En cherchant comment,
j'ai trouvé que ça coûtait plus cher que je ne l'avais dit** : les couleurs de Haizo suivent
`ThemeStore`, son propre réglage, et non le système. Forcer l'heure en blanc demandait donc soit
de remplacer la voie de démarrage de l'app par un contrôleur maison — un raté, et l'app ne
s'ouvre plus — soit de faire basculer le thème de la fenêtre à chaque changement d'onglet.

**Et une mesure a réduit la question.** `screenshots.py` repeint la bande du haut et redessine
9:41, avec une encre qu'il choisit sur le fond : `blanc si sum(bg) < 384`. Sa bande fait 185/2868
de la capture — exactement le bandeau supprimé. **L'image App Store était donc déjà protégée,
sans une ligne de code.** Il ne restait que l'app réelle.

Je suis retourné le dire avec le vrai coût. Décision : on masque l'heure sur l'accueil.
`.statusBarHidden()`, une ligne, une API supportée, et le démarrage de l'app n'est pas en jeu.
Un seul écran est rendu à la fois — `RootTabView` fait un `switch` — donc l'heure revient dès
qu'on quitte l'accueil.

### Le plafond des barres, et ce qu'il ne règle pas

Soixante-six points mesurés pour huit de large : un rapport de vingt-cinq contre un. Le brief dit
« hauteur proportionnelle » sans donner de maximum. Quarante, décidé par Charlotte.

C'est écrit dans le code que **ce plafond ne règle pas le ruban coupé**, pour qu'on ne le croie
pas plus tard : les deux changements voyagent ensemble, ils ne se remplacent pas.

### Un détour en trois exemplaires devient un jeton

`LiveRunView` portait un `ScreenEdges` privé pour lire l'encart du bas sur la FENÊTRE — « à
l'intérieur d'un `ignoresSafeArea()`, les encarts rapportés par la mise en page valent zéro ». Son
commentaire ajoutait : « le même détour existe déjà dans `StravaService` pour la même raison ». Il
en aurait fallu un troisième ici. `BordsDeLEcran` les remplace, avec `haut` et `bas`.

### Ce que la campagne 218 doit montrer

- La nuit à la première rangée de pixels, plus aucun bandeau clair.
- Aucune heure, aucun wifi, aucune batterie sur la capture brute — et 9:41 **en blanc** sur
  l'image composée de la fiche.
- Le ruban entier au-dessus de la barre d'onglets : barres vers 779 → 819, lettres et quantièmes
  vers 825 → 846, pour un bord haut de barre d'onglets à 854.
- La plus haute barre à 40 points au lieu de 66.

Si le bandeau est toujours là, c'est que `ignoresSafeArea` sur le défilement ne suffit pas et il
faudra le lire autrement. Si le ruban reste coupé, c'est mon calcul de 89 qui est faux.

## 16 novembre 2026 — la campagne 218 a validé trois prédictions et démenti une phrase

Mesuré sur `raw/fr-FR/clair/1-accueil.png` :

| ce qui était prédit | ce qui est mesuré |
|---|---|
| la nuit à la première rangée de pixels | bandeau clair : **0 px** (hier 186), première rangée `#14131E` |
| l'en-tête de 0 à 285 pt | **0 → 285,0 pt**, exactement |
| aucune heure sur la capture brute | **0 pixel clair** dans la bande ; 94,8 % de `#14131E` |
| 9:41 en blanc sur l'image composée | **818 pixels blancs** sur la bande sombre |
| le ruban au-dessus de la barre d'onglets | barres **747 → 782**, quantièmes **798 → 816**, pour un bord à 854 |

### La phrase qui était fausse

J'avais écrit, dans `RubanDeSemaine` et dans le message du commit, que **le plafond des barres ne
pouvait rien pour le ruban coupé** — « les quantièmes sont sous les barres, donc leur position ne
dépend pas de leur hauteur ».

Le raisonnement traitait la ligne de base des barres comme fixe. Elle ne l'est pas : une carte
s'écoule **du haut**, donc tout ce qui suit une barre plus courte remonte avec elle. Le ruban
devait monter de 89 points ; l'en-tête plein cadre en a donné 97, et le plafond **31 de plus**.
D'où des quantièmes à 798 là où j'en prédisais 825.

Le commentaire est corrigé sur place, avec la mesure. Une phrase fausse dans un commentaire est
exactement ce qui trompe la prochaine lecture — c'est le même genre de défaut que le relevé Vercel
réécrit à l'aveugle ce matin.

### Et une régression que j'ai causée, visible sur l'image de la fiche

**Le tracé GPS est coupé net.** `screenshots.py` repeint la bande d'état d'un aplat — 185 px sur
2868, soit 61,7 points — pour effacer l'heure du téléphone qui a pris la photo. Tant que
l'en-tête s'arrêtait sous la barre d'état, il n'y avait rien dessous. Depuis qu'il monte jusqu'au
bord, le tracé y passe : **11 385 pixels de tracé détruits**, et la courbe tranchée à
l'horizontale sur la capture n° 1.

J'avais vu le risque en lisant `clean_status_bar` et je l'avais écarté d'un « probablement sans
conséquence », sans le mesurer. Il suffisait de compter les pixels roses dans les 185 premières
rangées.

La correction est la règle que j'avais appliquée à la rangée du haut et pas au dessin : **le fond
va au bord, le dessin non.** Un encart du haut sur `SelfDrawingRoute`. Ce n'est pas un
contournement du compositeur — un dessin n'a rien à faire sous l'îlot dynamique.

### Ce qui reste à regarder, et qui n'est pas tranché

La carte « 2/3 · Ta journée » passe maintenant sous la barre d'onglets, et le chiffre y est coupé.
Le ruban est sauvé, mais la limite s'est déplacée d'une carte. Mesuré : la carte « Ton programme »
finit à 847, la barre couvre 854 → 910, et le « 2/3 » reparaît à 942.

Courir après cette limite est sans fin — il y aura toujours quelque chose au bord. La question
est de savoir si ce qui est coupé doit être un BORD DE CARTE plutôt qu'un chiffre, et c'est une
décision de direction artistique.

## 16 novembre 2026 — le coach avait une icône d'application en guise de visage

Point 3 du brief : « l'icône du coach devient le pictogramme des quatre barres en noir sur
`#F3EEF4` ». Elle était restée la tuile en dégradé de marque.

### Ce que le brief vise, et ce qu'il ne vise pas

`AppMarkView` sert à **seize endroits** — lancement, connexion, bienvenue, cartes de partage,
barre d'onglets, notifications, profil déconnecté, Club, amis, mur. Partout ailleurs, elle EST la
signature de l'app, et un logo garde son dessin : c'est la décision du 16 novembre au matin.

Le brief ne vise donc pas la marque. Il vise le seul endroit où elle ne signe rien : à côté de
« Ton coach · Connaît ton programme », elle tient lieu de **portrait d'interlocuteur**. Une icône
d'application en guise de visage, c'est ce qui fait lire « une app me parle » plutôt que
« quelqu'un me répond ».

### Deux endroits, pas un — et ce n'est pas un élargissement

`RingsView` porte un bloc titré « Coach » qui affiche sa phrase du jour, avec la même tuile. Le
brief ne le nomme pas, mais c'est le même interlocuteur : deux visages pour une seule personne
serait exactement le défaut que la règle existe pour éviter.

### `card2` et non `#F3EEF4`, et c'était déjà écrit

`ChipView`, le 16 novembre : « la valeur est `card2`, pas `#F3EEF4`, et c'est une décision
assumée — `#F3EEF4` est une lavande FROIDE, les fonds clairs de l'app sont chauds depuis le
12 novembre, et `check_jetons_de_texte.py` tient la règle de la famille du fond ». `ProfileView`
renvoie à la même raison. On garde la direction du brief — une surface déclarée, opaque — et la
famille de la page.

## 16 novembre 2026 — la moitié de la palette d'intensité n'était photographiée nulle part

Compté sur les 27 captures de la passe claire de la campagne 218, pixel par pixel :

| teinte | pixels |
|---|---|
| facile `#2FB37A` | 25 706 |
| intervalles `#F0225F` | 2 419 128 |
| sortie longue `#7B3FE4` | 71 540 |
| **seuil `#F5A524`** | **0** |
| **récupération `#5AA9E6`** | **0** |
| **fonctionnel `#44506B`** | **0** |

Trois des six teintes que Charlotte a choisies le 15 novembre n'avaient jamais été vues sur une
image. Elles sont dans le code, `check_teintes.py` les tient — mais aucun garde ne sait si elles
sont belles, lisibles, ou si elles jurent entre elles.

### Pourquoi elles manquaient

Le `fonctionnel` est le renforcement HYROX : le profil de démonstration vise un 10 km, il n'en
fait pas. Légitimement absent.

Les deux autres ne sont pas des teintes mortes : **le plan les produit, mais dans le bloc
SPÉCIFIQUE**. L'écran du plan s'ouvre sur « Semaine 1 · Base », qui ne porte que de l'endurance
et du fractionné léger. Trois semaines en avant suffisent à y entrer.

### Une capture de diagnostic, pas une de plus sur la fiche

`plan-specifique` ne part pas chez Apple. Elle existe pour qu'on puisse juger ces deux teintes
sur une image au lieu de les croire sur parole — ce que la règle « l'image EST la vérification »
demande pour tout ce qui a un visage.

Le geste tape la flèche de semaine **en coordonnées**, comme le défilement juste à côté : le
fichier s'interdit l'arbre d'accessibilité depuis que cette requête a tué le premier essai de ces
captures.

## 16 novembre 2026 — le garde des teintes n'avait aucun banc, et c'était structurel

Soixante-quatre gardes du dépôt ont un `test_*.py`. `check_teintes.py` n'en avait aucun, et pas
par négligence : il était écrit en **code de premier niveau**, exécuté à l'import et terminé par
`sys.exit`. On ne pouvait donc pas le faire tourner sur un faux dépôt comme `avec()` le fait pour
les autres.

Il a gagné sa troisième règle le jour même — les valeurs recopiées à la main — et porte
maintenant **quatre listes d'exceptions**. Chacune doit pouvoir maigrir, et c'est ce sens-là qui
pourrit quand personne ne le vérifie : une liste d'exceptions qui ne se vide jamais devient une
liste de passe-droits.

### La refonte

Quatre fonctions, `ecarts_en_tetes`, `ecarts_cloche`, `ecarts_directs`, `ecarts_recopies`, qui
prennent une racine et rendent leurs écarts et leur compte ; un `ecarts()` qui les enchaîne ; un
`main()` qui imprime. Les tables restent au niveau du module, pour que le banc les échange comme
il le fait déjà pour `check_majuscules`. La sortie est identique au caractère près.

### Dix-neuf cas, dont les deux sens pour chacune des quatre règles

Et un cas qui a trouvé une faute dans son propre fixtur : « une teinte déclarée au compte juste
passe » posait `RUColor.lime` dans l'en-tête, ce qui réveille AUSSI la règle 3. **Un cas qui
réveille deux règles à la fois n'en éprouve aucune.** Le fixtur porte maintenant une teinte
neutre.

C'est la même leçon que le reste de la journée, prise par l'autre bout : un banc se vérifie en
regardant ce qu'il allume, pas en relisant son intention.

## 16 novembre 2026 — la campagne 220 : l'icône du coach est faite, et la moitié de #41

### Ce qui est vérifié

| promesse | mesure |
|---|---|
| `plan-specifique.png` existe dans les trois langues | oui, 28 captures claires au lieu de 27 |
| l'icône du coach est un aplat | tuile `#EEECE7`, encre `#181511`, **0 pixel rose/violet** |
| et dans le bloc « Coach » des anneaux | dégradé de marque : 8 766 → **820 px** (le reste est le violet d'intensité du ruban) |
| récupération `#5AA9E6` | **1 922 px** — elle n'existait sur aucune image |
| seuil `#F5A524` | **toujours 0** |
| rien de cassé | tracé 0 px dans la bande, nuit 0 → 285,0 pt, bande d'état vide, ruban 747 → 782 |

### Pourquoi le seuil manque encore, et pourquoi je ne devine pas une deuxième fois

Trois sauts menaient à la **semaine 4**, qui est la **décharge** — « À venir · Récup », le creux
gris du graphique. Elle porte un footing récup et un footing tonique. Une semaine d'allègement ne
porte pas de seuil : c'est sa définition.

Plutôt qu'un second essai au jugé, j'ai lu le moteur. `AdaptivePlanEngine` ligne 749 pose un
archétype **« Tempo run »** — `kind: .tempoRun`, que `SessionFamily` rend en `.tempo` — dans le
bloc **spécifique**, et nulle part ailleurs pour ce profil. Le plafond de deux séances de qualité
par semaine laisse la place au fractionné VMA **et** au tempo quand la semaine compte quatre
séances, ce qui est le cas.

Quatre sauts mènent à la **semaine 5**, le pic du plan — 34 km, la plus haute barre — qui est une
semaine spécifique pleine.

### Le `functional` restera absent, et c'est juste

`#44506B` est le renforcement HYROX. Le profil de démonstration vise un 10 km : il n'en fait pas.
Le photographier demanderait un second profil de démonstration, ce qui est un autre chantier —
et pas un défaut.

## 17 novembre 2026 — la campagne a franchi minuit, et l'image de tête a perdu son bouton

La 221 devait vérifier une seule chose — le seuil `#F5A524` sur la capture du bloc spécifique.
Il y est : **1 488 pixels**, la semaine 5, le pic du plan. Le raisonnement tiré du moteur était
juste.

**Mais le contrôle de non-régression a trouvé autre chose.** La barre du lundi est passée de 747
à **603,7 points** — cent quarante-trois points plus haut, sans qu'aucun commit n'ait touché
l'accueil.

### Ce que l'image montrait

- la carte de séance sans durée, sans allure, sans zone, et **sans bouton « DÉMARRER »** ;
- sa pastille passée de « Séance du jour » à « Aujourd'hui », avec une lune ;
- « Ta journée » à **2/2** au lieu de 2/3.

### La cause

```swift
private var todayWeekdayIndex: Int {
    (Calendar.current.component(.weekday, from: .now) + 5) % 7
}
```

`.now`. La campagne a tourné de 23 h 57 à 00 h 56 : elle a franchi minuit, on est passé au
**mardi**, et mardi est un jour de **repos** dans la semaine de démonstration.

**La carte portait donc deux horloges.** Son titre vient de `todaySession`, que la graine écrit
sur l'instant figé — « Sortie longue ». Son état de repos venait d'ici, sur l'instant réel. Elle
annonçait une sortie longue et se dessinait comme un jour de repos.

### Le septième lecteur oublié, et la leçon enfin tirée

- **14 novembre** — la graine est figée, pas l'app. L'accueil montrait 0,0 / 24 km.
- **16 novembre** — trois lecteurs ajoutés ; la remise à zéro, la date de l'en-tête et les
  quantièmes manquaient. « Ta journée » est tombé à 0/3.
- **17 novembre** — celui-ci.

J'avais écrit la leçon le 16 **sans en tirer la conséquence** : « j'ai figé une horloge en
énumérant ses lecteurs, et énumérer est exactement la façon d'en oublier un. » Une liste tenue à
la main ne se répare pas en la relisant mieux.

### `check_horloge.py`, et son huitième

Il refuse toute expression qui demande un **jour de semaine** ou une **semaine calendaire** à
l'horloge réelle. Deux motifs, pas plus :

    component(.weekday, from: .now)          quel jour on est
    dateInterval(of: .weekOfYear, for: .now) ce que la semaine courante contient

**Il a trouvé un huitième lecteur à sa première exécution** : `StatsView.parSemaine`, l'ancre des
huit semaines du graphique — sur un écran photographié.

Ce qu'il ne regarde pas, et c'est délibéré : les **170 autres** lectures de l'horloge. Horodater
une course, mesurer un temps écoulé, dater un message — tout cela doit prendre l'heure réelle,
même en démonstration. Un garde qui les refuserait serait désactivé la semaine suivante. Un cas
le dit en toutes lettres.

Six lecteurs épinglés : `UserProfile.todayWeekdayIndex`, `WeeklyRecapView.todayWeekdayIndex`,
trois ancres de semaine dans `AdaptivePlanEngine`, et `StatsView.parSemaine`. La liste
d'exceptions est **vide**, et c'est le bon état.

## 17 novembre 2026 — la campagne 222 dit oui, et TestFlight était rouge depuis quatre commits

### Ce que la 222 a prouvé

Elle tournait un **mardi**, un jour de repos dans la semaine réelle, sur une scène figée au
dimanche 15. C'était tout l'enjeu.

| Ce qu'on attendait | Mesuré sur `raw/fr-FR/clair/1-accueil.png` |
| --- | --- |
| la pastille dit « Séance du jour », pas « Aujourd'hui » | « Séance du jour », icône de famille |
| la carte porte ses trois chiffres et son bouton | « 39 minutes · 6:18 Allure · Z2 Zone » + **DÉMARRER** |
| l'accent revient dans la bande y 0,60 → 0,70 | **1 343 px** de `#F0225F` (0 sur la 221) |
| « Ta journée » affiche 2/3 | 2/3 |
| la barre du lundi remonte vers 747 → 782 pt | **748,0 → 780,7 pt** (603,7 quand la carte s'était vidée) |

Et rien n'est cassé par ailleurs : tracé **0 px** dans les rangées 0 → 185, nuit **0,0 → 285,0 pt**
exactement, bande d'état **0 px** hors `#14131E`, seuil `#F5A524` à **1 536 px** dans les trois
langues, icône du coach en aplat, 28 captures claires et 28 sombres par langue.

### Mais le vrai défaut était ailleurs, et il avait quatre commits

**TestFlight a échoué sur 579, 580, 581 et 582.** Je lisais la campagne de captures après chaque
poussée et pas l'autre atelier. Quatre fois.

La cause est d'un seul tenant. Le 16 novembre, le `uppercased()` a quitté `TimeFormat` — le point
1 du brief avait tué sa raison. Quatre lignes de `DisciplineTests` décrivaient encore l'ancien
comportement :

```swift
XCTAssertEqual(course.unite, "/KM")          // ligne 85
XCTAssertEqual(velo.unite, "KM/H")           // ligne 88
XCTAssertEqual(lu.unite, "/100 M")           // ligne 276
discipline.rythmeUnite.uppercased()          // ligne 127
```

Et le commentaire au-dessus de la quatrième affirmait la règle morte : « `TimeFormat` ne recopie
plus l'unité : il met celle de la discipline en capitales. »

Le test est plus fort maintenant : il compare une **identité**, pas une transformation. Une unité
qui change de casse en traversant `TimeFormat` est exactement ce qu'on ne veut plus.

### Pourquoi rien ne l'a vu en local, et ce qui le verra

`tout.sh` ne compile pas le Swift — c'est une limite connue, et aucune machine Linux ne la lèvera.
Le seul banc Swift est TestFlight, qui tourne **après** la poussée.

Mais une ligne de ce défaut était lisible depuis Linux : `discipline.rythmeUnite.uppercased()`.
`check_majuscules.py` refuse ce motif depuis hier — **et ne lisait pas les cibles de test.**

La leçon est la neuvième de la même famille, prise par un bout nouveau : un garde ne voit pas que
les orthographes qu'on lui a données, il ne voit que **les dossiers** qu'on lui a donnés.

### Une règle, deux portées — et la seconde est mesurée

Mesuré avant de décider : faire lire les deux cibles de test au garde entier lève **14 écarts**,
dont **un seul** est un défaut. Les treize autres sont des données de test — un code `ABC123`, un
horodatage `2026-08-26T10:00:00Z`, sept fois le sigle `VDOT`, une adresse `TEST@HAIZO.APP` posée
exprès pour vérifier qu'on normalise la casse. Treize entrées d'exception pour zéro libellé : une
liste qu'on gonfle de treize passe-droits est une liste qu'on finit par ne plus lire.

Les deux règles n'ont donc pas la même portée, et chacune porte la sienne écrite :

- **les littéraux** s'arrêtent aux trois cibles de l'app — un test écrit des données, pas des
  libellés d'écran ;
- **`uppercased()`** va jusqu'aux tests — un test ne dessine pas d'écran, mais il *décrit* le
  comportement de l'app, et cette description survit au code qu'elle décrit.

Un seul écart levé dans tout le dépôt, celui du jour. **Zéro nouvelle exception.**

Et le banc a été corrigé avant les cas : `avec()` aplatissait tous les dossiers dans `CIBLES`, ce
qui rendait la distinction intestable — la faute exacte de `check_teintes.py` la veille. Il
**dérive** maintenant la partition des tables du module, pour qu'une cible ajoutée là-bas soit
suivie ici sans qu'on y touche. Trois cas : le `uppercased()` d'une cible de test sonne, le
littéral d'une cible de test ne sonne pas, et le **même** littéral dans une cible d'app sonne
toujours — sans ce troisième, « ça ne sonne pas » ne prouverait pas que c'est la portée qui
change. 24 cas au total.

### Ce que la 222 a montré en passant

`accueil-libre.png` — l'accueil sans programme — est sain, mais sa phrase du bas est tranchée en
plein milieu par la barre d'onglets : « Pas de plan fixe — le coach te propose de quoi garder la
forme, » et rien après. C'est la limite de la carte « 2/3 » (#52), en plus visible : un nombre
coupé se devine, une phrase tronquée se lit comme une panne. La question part avec l'autre.

Et `--libre` pose `programPhase = .freerun`, pas `planUnlocked == false` : l'accueil du
**non-abonné** (#32) reste le dernier écran que personne n'a jamais vu. Le chemin est écrit —
`--libre` est le modèle exact à copier.

### Et j'ai cherché s'il y en avait d'autres, au lieu d'attendre le prochain rouge

Treize fichiers de l'app ont changé depuis le dernier TestFlight vert, et **aucun fichier de
test**. C'est le signal qu'il fallait suivre. Neuf symboles touchés, croisés avec les deux cibles
de test : deux correspondances, une seule qui pose question.

`RestDayErasedByRunTests:44` recopie la convention de `UserProfile.todayWeekdayIndex` — et son
commentaire le disait : « la même convention, recopiée parce qu'elle est privée ». **Ce n'est plus
la même depuis le 17 au matin** : l'app lit `Demonstration.maintenant`, le test lit `.now`.

Le cas reste juste, et je ne le maquille pas en défaut : `Demonstration.maintenant` rend `.now`
hors campagne, et un test unitaire n'en lance jamais. Ce n'est pas lui qui a fait rougir
TestFlight — les sept échecs étaient tous dans `DisciplineTests`. Mais le commentaire, lui, était
devenu faux, et un commentaire faux trompe la prochaine lecture. Il dit maintenant qu'il recopie
un **décalage**, pas une source.

### `check_horloge.py` ne lira PAS les tests, et c'est mesuré aussi

La tentation était forte de lui appliquer la même extension qu'à `check_majuscules.py` dans
l'heure. Sa raison l'interdit : il refuse l'horloge réelle **parce qu'une campagne de captures
fige la scène**, et un test unitaire ne tourne jamais dans une campagne.

Mesuré avant de trancher : l'étendre lève quatre lignes, dont trois — `BilanDeLaSemaineTests`,
`ContinuiteDuPlanTests`, `CycleTrackingTests` — construisent une semaine pour y poser des données.
Les forcer sur `Demonstration.maintenant` serait un contresens, et le message du garde leur dirait
quelque chose de faux. **Quatre écarts, zéro défaut** : la portée reste où elle est, et la décision
est écrite dans le garde pour qu'on ne la reprenne pas par symétrie.

Une portée se justifie par la raison de sa règle, jamais par celle du garde d'à côté. C'est le
pendant de la leçon du jour, et il compte autant : étendre partout est aussi mauvais que n'étendre
nulle part.

## 17 novembre 2026 — l'accueil du non-abonné n'était pas oublié, il était imphotographiable

TestFlight 583 est vert, le premier depuis le 578. La campagne 223 ne pouvait rien montrer de
neuf — le commit précédent ne touche aucun fichier de l'app — alors plutôt que d'attendre
soixante-dix minutes, chantier #32 : le dernier écran que personne n'avait jamais vu.

### La cause, et elle n'est pas un oubli

```swift
func unlocks(_ feature: PlusFeature) -> Bool {
    if Demonstration.enCours { return true }
    ...
```

**En démonstration, tout est ouvert.** Toutes les captures de l'accueil, depuis le premier jour,
montrent une abonnée. Et la raison écrite au-dessus de cette ligne est bonne — « une capture de
l'App Store doit montrer le produit, pas son verrou » : « Un plan qui s'adapte » a vraiment
surmonté un graphique flouté.

Mais `HomeView` porte **quatre branches** qui ne se dessinent que dans l'autre état :

| branche | ce qu'elle change |
| --- | --- |
| `switch planUnlocked ? programPhase : .active` | la carte du haut |
| `if planUnlocked` | un bloc entier disparaît |
| `if !planUnlocked` | `PlusLockCard` arrive en **dernière** position |
| `if isFreeRun && planUnlocked` | la ligne du coach disparaît |

Celle du milieu porte un commentaire qui mérite d'être vérifié : « à la troisième place sur trois,
cette carte était un mur ; sous quatre blocs de contenu réel, c'est une proposition. » C'est une
affirmation sur ce que ça fait à l'œil, et personne n'a jamais regardé.

### `--verrouille`, sur le modèle exact de `--film`

Lecture de l'argument dans `CaptureSeed.verrouDemande`, drapeau dans `Demonstration.verrouille`,
posé au lancement à côté de `filmer()`, sous `#if DEBUG`. La construction envoyée à l'App Store ne
contient toujours **aucune ligne** capable de l'allumer. `unlocks` devient :

```swift
if Demonstration.enCours { return !Demonstration.verrouille }
```

### Le détour que j'ai failli prendre, et pourquoi il rendait l'inverse

Passer par `Entitlement.unlocks` avec les valeurs d'un non-abonné aurait été plus propre : la
décision du droit d'accès vit là-bas, sous test, et le commentaire de `SubscriptionService` le dit
lui-même.

Ça ne marche pas, et le détail compte. **Un simulateur n'a pas StoreKit** : `products` y est vide,
donc `canSell` est faux, et `Entitlement` ouvre tout quand on n'a rien à vendre — « le petit
risque d'abus que la règle laisse est très en dessous du coût de la panne qu'elle évite ». Le
chemin le plus propre rendait donc exactement le contraire de ce qu'on demande. Le court-circuit
affirme l'état « non-abonnée à qui on peut vendre », que le simulateur est incapable de produire,
et la raison est écrite sur place.

### Le danger n'est pas qu'il s'allume, c'est qu'il reste allumé

Une campagne prend trente-neuf écrans. Un verrou qui survivrait à la prise de diagnostic
verrouillerait toutes les suivantes, et les six images de la fiche partiraient chez Apple avec un
`PlusLockCard` dessus.

`arreter()` le remet, comme il remet `enCours` et `filme`, et c'est exactement le genre de ligne
qu'on supprime « parce qu'elle est symétrique » en refactorant. Quatre cas dans
`DemonstrationVerrouTests` : éteint par défaut, `verrouiller()` l'allume sans toucher à la
démonstration, `arreter()` l'éteint, et — celui qui protège les trente-sept autres captures —
**entrer en démonstration ne l'allume pas**.

C'est la leçon de l'horloge prise par l'autre bout : le 17 au matin, un état ne se propageait pas
assez ; ici, il se propagerait trop.

### Ce que la campagne 224 devra montrer

`accueil-verrouille.png` et `accueil-verrouille-bas.png`, en diagnostic, dans les trois langues.
La carte du programme absente, `PlusLockCard` en bas, pas de ligne de coach. Et surtout : les six
images de la fiche **inchangées** — si l'une d'elles porte un verrou, le drapeau fuit.

## 17 novembre 2026 — la campagne 223 : l'écran que personne n'avait vu, et le verrou n'a pas fui

TestFlight 584 est vert — le Swift compile, XcodeGen a pris le fichier de cas neuf, les quatre cas
du verrou passent. Deux builds verts d'affilée après quatre rouges.

### Les trois contrôles, dans l'ordre d'importance

| ce qu'il fallait prouver | mesuré sur la 223 |
| --- | --- |
| les deux captures existent, 3 langues × 2 thèmes | **12 images**, le compte passe de 28 à 30 par langue et par thème |
| **le verrou n'a pas fui sur la fiche** | « Ton programme · Semaine 1/6 · 28,3 / 24 km · J-40 » toujours présent sur `1-accueil.png` |
| rien d'autre n'a bougé | tracé 0 px (0 → 185), nuit 0,0 → 285,0 pt, bande d'état 0 px hors `#14131E`, barre du lundi 748,0 → 780,7 pt |

Le second est le contrôle qui compte, et il fallait choisir la bonne mesure. J'ai d'abord comparé
les six images de la fiche par **empreinte**, 222 contre 223 : les six sont ressorties
« différentes », ce qui ne prouvait RIEN — l'anticrénelage du simulateur varie d'une exécution à
l'autre, et les quatre mesures structurelles étaient identiques au dixième de point.

La bonne mesure était ailleurs : la carte « Ton programme » est précisément celle qui disparaît
quand `planUnlocked` est faux. Sa présence sur l'image de la fiche est la preuve directe que le
drapeau ne traverse pas les prises.

### Ce que l'écran montre, maintenant qu'on peut le regarder

Le commentaire de `HomeView` affirmait depuis des semaines : « à la troisième place sur trois,
cette carte était un mur ; sous quatre blocs de contenu réel, c'est une proposition. »

**C'est vrai.** La carte dit « Haizo PLUS · Ton programme qui s'adapte · Un plan périodisé calé sur
ton objectif, qui se recalcule après chaque sortie selon ta forme et ton ressenti », avec un seul
bouton. Au-dessus d'elle : une séance à faire aujourd'hui, avec sa durée, son allure, sa zone et
son bouton de départ ; le ruban des sept jours ; les anneaux du jour. Une personne qui n'a pas
payé a de quoi courir tout de suite, et la proposition arrive après, pas avant.

Les trois questions de la direction artistique : une débutante y trouve une séance et un bouton,
sans rien de bloqué ; un traileur y trouve allure, zone et durée ; rien n'y sent la génération.

### Deux constats que cet écran a révélés

**La carte « 2/3 · Ta journée » passe sous la barre d'onglets ici aussi** — troisième écran après
l'accueil abonné et l'accueil libre. C'est #52, confirmé une fois de plus : ce n'est pas un cas
particulier, c'est la limite de la page.

**Deux boutons roses pleins, deux casses, sur le même écran.** « DÉMARRER » à deux cartes de
« Découvrir Haizo Plus ». Même forme, même couleur, même rôle visuel — l'un en capitales, l'autre
non. La liste `PERMIS` de `check_majuscules.py` tolère les capitales d'un bouton, et sa raison
écrite le dit : « le jour où elle tranche l'inverse, c'est cette liste qui se vide ». Cette image
est la première à montrer les deux conventions côte à côte.

## 17 novembre 2026 — « il faut un Mac » était faux depuis sept jours, et c'est moi qui l'avais écrit

TestFlight 585 vert, le troisième d'affilée. En vérifiant ce que ma poussée avait déclenché, j'ai
trouvé un workflow dont j'ignorais l'existence : **« Capture de la montre »**, à sa 38ᵉ exécution.

### Ce que j'avais écrit, et depuis quand c'était faux

Le 16 novembre, dans la liste d'exceptions de `check_majuscules.py` :

> « EN PAUSE » et « EN COURS » sont une dette nommée — la capture montre livrée à Apple est
> empreintée contre toute la cible et **ne se refait pas sans machine macOS**.

`.github/workflows/montre.yml` existe depuis le **9 novembre**. Il construit `HaizoWatch` pour un
simulateur watchOS, pose la langue sur l'appareil, photographie les trois langues et publie les
images. Cinq à huit minutes. Les runs 36, 37 et 38 sont verts.

J'ai écrit cette phrase sept jours après la naissance du workflow, sans vérifier, et elle a fait
porter à Charlotte une tâche qui ne lui revenait pas. C'est la troisième fois cette semaine qu'une
phrase fausse écrite par moi coûte quelque chose — après « le plafond des barres ne peut rien
pour le ruban » et « probablement sans conséquence » sur la bande d'état.

### Le vrai chaînon manquant, lui, était réel

L'artefact publiait `appstore/raw-montre/**` et `appstore/requis/montre/**` — les images — mais
pas `appstore/requis/SOURCES.json`, qui porte les empreintes.

Et sans elles, les images ne servent à rien. `check_requis.py` compare `empreinte_code` au hachage
du dossier `HaizoWatch` **tel qu'il est maintenant** : si le code a changé, l'image est classée
périmée et le contrôle refuse. Il est câblé dans **quatre** workflows, TestFlight compris.

C'est un mécanisme, pas un défaut, et sa raison est écrite sur place : « une capture ne vieillit
pas toute seule, c'est l'app qui bouge sous elle » — c'est exactement ainsi que le bouton de la
montre est passé de la pilule au cercle le 6 août sans que l'image livrée bouge pendant trois mois.

Recalculer l'empreinte à la main après coup est précisément ce que `requis.py` dit d'éviter :
« une empreinte reposée à part, après coup, pourrait… ». Il fallait donc la faire voyager avec
l'image. Une ligne.

### Une faute attrapée en l'écrivant

J'ai d'abord posé les commentaires **dans** le bloc `path: |`. Un bloc littéral YAML n'a pas de
commentaires : un `#` y est du texte, donc un motif de chemin. Les quinze lignes d'explication
seraient devenues quinze motifs d'artefact. Aucun garde du dépôt ne regarde l'intérieur d'un
scalaire littéral, et `if-no-files-found: error` ne se serait pas déclenché puisque les trois
autres motifs correspondent. Corrigé avant le gate.

### Le cycle, maintenant qu'il est possible

1. cette ligne, qui laisse tout vert et prouve que les empreintes arrivent dans l'artefact ;
2. « EN PAUSE » → « En pause » et « EN COURS » → « En cours », dans `HaizoWatch/WatchViews.swift`
   **et** `HaizoWidgets/DailyGoalsWidget.swift` — les deux entrées voyagent ensemble, « le même
   état écrit de deux façons sur deux surfaces est pire que les deux en capitales » ;
3. récupérer l'artefact, poser les trois images et `SOURCES.json` ;
4. vider les deux entrées de `PERMIS` — « le compte à zéro fera parler le garde tout seul ».

Le rouge entre 2 et 3 est le mécanisme qui parle, pas une panne : c'est l'empreinte qui refuse une
image que le code a dépassée. Huit minutes, le temps du workflow.

## 17 novembre 2026 — la refonte visuelle, étape 1 : les jetons, les composants, la planche

Charlotte a arrêté un design complet sur un canvas de dix écrans et demandé une refonte de toute
la couche visuelle et de la navigation. Sa méthode est écrite, en cinq points ; celui-ci est le
premier : « Écris les tokens et les composants de base. Montre-moi une capture de la planche.
J'approuve avant la suite. » **Rien d'autre n'est commencé, et rien ne le sera avant son accord.**

### Ce que le canvas contient, mesuré

Dix planches de 390 points de large. Une seule fonte, Archivo variable, chargée par le canvas en
quatre faces seulement — ce qui a une conséquence : un texte sans graisse déclarée s'y affiche en
500, et un 800 à largeur normale en 700. La référence est ce qui se voit, donc l'app n'a que
trois graisses d'interface (500, 600, 700) et une d'affichage (800 à 125 %).

Dix rayons, trente-deux styles d'affichage ayant chacun leur interlettrage, vingt-neuf icônes,
une barre flottante de 60 de haut, des boutons d'action de 58, une semaine en sept points.
L'encre d'un petit texte sur l'accent est `#2B0011` pour le rose et le blanc pour les trois
autres couleurs.

### Ce qui est écrit

| | Où |
| --- | --- |
| La fonte Archivo, et sa licence | `Haizo/Resources/Fonts/` |
| Couleurs, accents, intensités | `HZCouleur.swift` |
| Rayons et espaces partagés | `HZForme.swift` |
| La fonte et ses trente-deux styles | `HZPolice.swift` |
| Les vingt-neuf icônes | `design/icones.json` → `ci_scripts/icones.py` → `HZDessins.swift` |
| Bouton rond, action, bouton en pilule, avatar, amorce de recherche | `HZBoutons.swift` |
| Pilule, filtre | `HZPilules.swift` |
| Feuille, titre de section, bandeau du coach | `HZFeuille.swift` |
| Carte-affiche, tuile, tuile chiffre | `HZCartes.swift` |
| Ligne de liste, semaine en points | `HZListe.swift` |
| Barre flottante | `HZBarreFlottante.swift` |
| Les mesures propres à un écran | `HZEcrans.swift` |
| La planche, six pages | `Haizo/Views/Refonte/PlancheView.swift` |

### Quatre décisions de méthode

**Un système parallèle.** Les jetons `HZ…` cohabitent avec `RUColor` et `RUFont`. Chaque
construction poussée reste cohérente : un écran bascule d'un bloc, l'ancien système est retiré
avec le dernier. Repeindre `RUColor` en place aurait donné, pendant dix écrans, une app à moitié
dans chaque design.

**Les icônes sont celles du canvas.** « Tu reproduis » : elles sont extraites en géométrie
neutre et rendues en tracés SwiftUI par un générateur, dont le mode `--verifier` compare le
Swift à sa source. Cela renverse « les SF Symbols restent » du 11 novembre.

**Les fichiers du canvas n'entrent pas dans le dépôt.** Ils portent des données d'exemple
personnelles, et le dépôt est public. Seule la géométrie des icônes y entre.

**La planche remonte des morceaux du canvas.** Un composant montré seul sur un fond gris ne se
compare à rien. Quatre des six pages recomposent donc, avec les seuls composants, le haut de
l'accueil, sa feuille, le haut du plan et le haut des stats, aux contenus d'exemple du canvas.
Chaque capture se pose à côté du rendu de la référence et l'écart se mesure.

### L'outillage de comparaison

La campagne de captures dure soixante-dix minutes : elle ne peut pas porter une boucle « capture,
écarts, correction, nouvelle capture » par écran. `refonte.yml` construit l'app et photographie
la planche sur un simulateur de 390 points de large en quelques minutes ; un rendu local de
chaque planche du canvas sert de référence ; un script pose les deux côte à côte avec leur
différence.

### Ce que la passe locale a refusé, et ce que j'en ai fait

Trois écarts, tous sur la planche :

- trois marges de 20 et 22, hors de la grille de `RUSpacing` ;
- « CG », les initiales de l'avatar, écrites en capitales.

Les deux gardes appartiennent à l'ancien système et jugeaient un fichier du nouveau. La
correction facile était une dispense dans chacun. Elle aurait été fausse deux fois.

**Pour les marges**, le défaut n'était pas d'être hors grille, mais d'être écrites dans la vue :
le point 5 de la méthode dit « aucune valeur en dur dans les vues », et la planche en portait
trente-cinq. Elles ont toutes un nom maintenant, dans le système de design. Et comme
`check_grille.py` ne lit que trois écritures — il n'a jamais vu un `.frame(width: 318)` —, un
nouveau garde tient la règle sans liste : `check_valeurs.py` refuse tout nombre dans une vue de
la refonte. Vingt-deux cas. `check_grille.py` lui passe les deux dossiers, avec la raison écrite,
et échoue si son remplaçant disparaît.

**Pour les initiales**, le littéral n'avait pas à exister : dans l'app, des initiales se
calculent à partir d'un nom. `HZAvatar.initiales(prenom:nom:)` le fait, la planche l'appelle, et
la capitale posée à l'exécution est inscrite dans `PERMIS_A_LA_VOLEE` avec la même raison que les
deux entrées qui y étaient : des lettres, pas un mot.

### Ce qui n'est pas prouvé à l'heure du commit

Il n'y a pas de compilateur Swift sur la machine où ce code est écrit. Deux mille deux cents
lignes n'ont donc jamais été compilées : TestFlight est le premier banc. Et l'axe de largeur
d'Archivo ne s'atteint que par un attribut de variation CoreText ; s'il ne prenait pas, tous les
grands chiffres seraient étroits. La première page de la planche imprime donc la famille résolue
et l'état des deux axes, pour que la capture le dise elle-même.

### Ce qui attend Charlotte avec la planche

- Le canvas montre un interrupteur Clair / Sombre et ne dessine qu'un mode.
- Trois intensités : la couleur d'une séance de qualité qui n'est pas celle du jour n'est pas
  dessinée.
- Le texte agrandi : l'interface suit le réglage jusqu'à 1,3 fois, l'affichage ne bouge pas. À
  reprendre écran par écran.
- Cinquante-trois écrans dans l'app, dix dans le canvas.

### La première capture de la planche, et ce qu'elle a montré (17 novembre, run 1 de `refonte.yml`)

TestFlight 587 vert, tests et envoi compris : les deux mille deux cents lignes de Swift jamais
compilées compilent, et le garde `check_valeurs.py` a tourné sur CI. Le workflow Refonte a
photographié les six pages en treize minutes.

**Ce qui était juste du premier coup.** La page 1 imprime son propre constat : « Archivo · axe de
largeur actif · axe de graisse actif ». La crainte de l'étape — que l'axe de largeur, atteint par
un attribut CoreText, ne prenne pas — est levée. Le simulateur fait 1170 × 2532 pixels : 390
points, la largeur des planches du canvas. Le décalage HORIZONTAL est de 0,00 pt sur toutes les
bandes mesurées de l'accueil et des stats.

**Ce qui ne l'était pas, par ordre de gravité.**

1. *Le plan glissait de 294 points vers la gauche.* Les trois cartes du jour font 978 points de
   large. Posées dans un cadre `.frame(maxWidth: .infinity)`, elles l'élargissent, et la pile
   entière est centrée sur cette largeur : l'en-tête, le titre et le bouton de retour sortaient de
   l'écran, « Démarrer » s'étalait en bande blanche, la carte du centre était celle de « Repos ».
   Une seule cause pour cinq symptômes. Le rang est maintenant une surface vide de la bonne
   hauteur, avec les cartes en `overlay(alignment: .leading)`.
2. *Une ligne ne fait pas la même hauteur dans Chromium et dans SwiftUI.* Le canvas est du HTML ;
   Chromium arrondit l'ascendante et la descendante de la fonte à l'entier (12 pt : 11 + 3 = 14,
   là où SwiftUI compte 13,06), et, quand l'interligne est plus petit que le texte, arrondit la
   demi-marge vers le bas. Mesuré : les points de la semaine 0,7 pt trop hauts (la lettre qui les
   précède est trop courte), les deux tuiles de stats à 86,33 pt au lieu de 86,00 (chaque rangée
   0,33 pt plus bas que la précédente : +0,33, +0,67, +1,0), le « 500 » et le « 118 » à 1,0 pt trop
   bas. Une cause, quatre symptômes, qui s'additionneraient sur chaque écran long.
   `HZLigne` reproduit la règle de Chromium ; `hzTexte` (une ligne) et `hzLigne` (une boîte de
   hauteur imposée) la posent par un guide d'alignement, et non par un centrage, qui hériterait de
   l'arrondi de SwiftUI.
3. *Le paragraphe du bandeau du coach faisait 2 pt de moins.* `line-height: 1.35` donne à chaque
   ligne 1,35 fois la taille, la différence étant coupée en deux de part et d'autre. `lineSpacing`
   n'ajoute de l'espace qu'ENTRE les lignes. `hzParagraphe` rend les demi-marges du haut et du
   bas.
4. *« 1h20 » s'affichait « 1h… ».* Le canvas laisse le texte déborder sous le bord de la tuile ;
   l'app ne peut pas : une durée tronquée est une durée fausse. La valeur de la tuile rétrécit
   jusqu'à 80 % avant de se couper.
5. *« Historique » n'avait pas son chevron* (14 points, trait 2,4, à six points du mot, graisse
   600 d'après la source du canvas).

**Ce que j'ai failli faire.** Corriger chaque décalage d'un point par une marge de plus ou de
moins dans la vue : `.padding(.top, 21)`. Chacun aurait disparu de la capture suivante, et
l'écart serait revenu, d'un autre ordre, sur l'écran d'après. Les mesures ont d'abord été
regroupées par cause. C'est aussi pourquoi `decalage.py` existe : il mesure par bande le décalage
en dixièmes de point entre la capture et la référence, et je l'ai éprouvé sur une image que
j'avais moi-même descendue de trois pixels avant de croire son signe — je l'avais écrit à
l'envers dans son commentaire.

**Ce qui reste volontairement différent de la référence**, et que la planche ne cherche pas à
copier : la barre d'état (le canvas n'en dessine pas), les tracés des vignettes de sorties (le
canvas les dessine à la main ; l'app y mettra le vrai tracé), le graphique d'allure des stats
(pas un composant de base), la rangée des jours du plan (idem).

### Le deuxième tour (run 2 de `refonte.yml`) : ce que les corrections ont donné, et trois choses de plus

TestFlight 588 vert. Mesuré sur la capture du commit `65be49d`, contre le rendu du canvas :

| | avant | après |
| --- | --- | --- |
| Accueil, haut : décalage vertical par bande | jusqu'à 1,0 pt | 0,00 pt jusqu'aux actions, 0,33 pt ensuite |
| Anneau du jour (semaine) | 140,3 à 154,3 | **141,0 à 155,0**, exactement la référence |
| Bandeau du coach | 64,0 pt | 62,4 pt, pour 62,7 dans la référence |
| Tuiles de stats : hauteur | 86,33 pt | **86,00 pt**, décalage constant de 0,33 pt au lieu de cumulé |
| Plan : pixels en écart | 51,7 % | 10,8 % |
| Bas de l'accueil : pixels en écart | 4,5 % | 1,7 % |

« 1h20 » s'affiche en entier. Le plan est à sa place : en-tête, titre, carte du jour à 36 pt, les
deux boutons en pilules, la barre flottante.

**Trois choses que ce tour a montrées en plus.**

1. *Le tabulaire n'est pas partout.* « 1h20 » restait 2 % plus étroit que dans le canvas, et la
   mise à l'échelle que j'avais ajoutée en secours se déclenchait — la preuve que mon texte était
   plus large AVANT. La cause : j'imposais `tnum` à tout l'affichage. Le canvas ne le pose que sur
   certains éléments, et `font-variant-numeric` s'hérite. Relevé sur les dix écrans, avec
   l'héritage : les très grands chiffres (156 à 64), les records, les chiffres de stats et de
   mesure sont tabulaires ; les titres, les préfixes (« 5 × ») et la durée des tuiles de l'accueil
   ne le sont pas. Chaque style porte donc son drapeau. Un premier relevé, sans l'héritage, avait
   donné un résultat faux (le 36 de stats « proportionnel ») : c'est ce qui a fait ajouter
   l'héritage, et c'est le même piège que `check_valeurs` évite en lisant tout nombre.
2. *Le plan restait 5 pt trop haut.* Le contenu fait 849 pt dans un écran de 844 ; une pile
   alignée en bas remonte de son dépassement. La pile est maintenant alignée en haut, et la
   barre flottante posée par-dessus, en bas.
3. *Le bandeau du coach se tronquait en « Si… »* quand la feuille manquait de hauteur. Un
   paragraphe ne se coupe jamais en hauteur : c'est l'écran qui coupe la feuille, comme dans le
   canvas.

### Le troisième tour : le plan montait encore, et la cause n'était pas celle que je croyais

TestFlight 589 vert, campagne 225 verte (elle est allée au bout ; je n'ai pas comparé ses images à
celles de la précédente, donc je ne dis pas qu'aucun écran n'a bougé : seul `HaizoApp.swift`
touche l'app, et il ne route vers la planche que sous `--planche`).

Mesuré sur `bf0edff` : l'accueil et les stats sont à 0,00 à 0,33 pt de la référence sur toutes les
bandes, « 1h20 » a exactement l'étendue de la référence sans réduction. Le plan, lui, montait de
16 pt au lieu de 6.

Mon explication du tour précédent (« une pile alignée en bas remonte de son dépassement ») était
juste à moitié. Le vrai mécanisme : un cadre souple, `.frame(maxHeight: .infinity)`, GRANDIT avec
son contenu quand celui-ci dépasse, puis son parent le recentre. Aligner la pile en haut n'y
changeait rien, parce que ce n'est pas la pile qui était recentrée mais le cadre qui la porte. Le
bandeau du coach ayant cessé de se tronquer, il a ajouté une ligne, le dépassement a doublé, et
le décalage avec lui. La planche pose maintenant sa page en superposition sur une surface de la
taille de l'écran : le dépassement tombe vers le bas, comme dans le canvas, où l'écran coupe la
feuille.

C'est un piège qui reviendra sur chaque écran plus haut que 844 pt, c'est-à-dire presque tous.
Règle pour les écrans de la refonte : la racine d'un écran est une surface de la taille de
l'écran avec le contenu en `overlay(alignment: .top)`, jamais un `.frame(maxHeight: .infinity)`
autour d'un contenu qui peut dépasser.

## 17 novembre 2026 — le nom de l'app sur App Store Connect, et l'Accueil de la refonte

Charlotte a approuvé la planche (« commence par l'accueil ») et demandé que le nom de l'app change
aussi sur App Store Connect, avec un push sur `main`.

### Le nom : il n'avait jamais été envoyé

`asc.py push-metadata` envoie la description, les mots-clés, le texte promotionnel, les notes de
version et les deux adresses. **Jamais le nom.** Il avait été posé à la main sur la page web, et le
renommage du 16 novembre ne l'a donc pas atteint. L'essai à blanc l'a montré noir sur blanc :
« RUNUP : Coach de Course » dans les TROIS langues — l'anglais et l'espagnol portaient le nom
français, avec l'ancien nom.

`push-name` ne change que le nom, par langue, sur chaque `appInfo`. Il y en avait deux :
`READY_FOR_DISTRIBUTION` (la fiche en vente, qui REFUSE un changement de nom) et
`PREPARE_FOR_SUBMISSION` (la prochaine version), qui a ACCEPTÉ les trois. Le nom change donc à la
mise en vente de la 3.4, pas avant. Huit cas de test contre une fausse API d'Apple, câblés dans
TestFlight et dans le workflow « App Store » lui-même.

**Ce que j'ai appris sur `main`.** Je croyais qu'il fallait y pousser quatre fichiers. `main` ne
contient que le SERVEUR (`api`, `db`, `lib`, les pages publiques) et un seul workflow,
`appstore.yml`. Le formulaire de lancement se lit sur `main` ; le script, lui, est cherché sur la
branche iOS (`branche: claude/runup-ios-swiftui-app-5b1yv6`). Un seul fichier est donc allé sur
`main` (`6acb8e7`), et je l'ai dit à Charlotte plutôt que de pousser les quatre qu'elle avait
autorisés. Ma référence locale `origin/main` était en retard sur le dépôt distant : elle disait
l'ancien commit alors que la poussée avait réussi. `git ls-remote` est la seule source.

### L'Accueil : le premier écran de la refonte

Refait à partir des composants, dans `Haizo/Views/Refonte/AccueilView.swift`. La logique de ce
qu'on affiche est dans `Haizo/Models/AccueilModele.swift`, sans une vue, et se teste
(`AccueilModeleTests`, vingt-sept cas).

**D'où vient chaque chose du canvas.**

| Dans le canvas | Dans l'app |
| --- | --- |
| « CG » | initiales du prénom et du nom du profil |
| sept points | `profile.weekSessions` : fait, aujourd'hui, à venir, repos |
| « Mardi 17 novembre » | la date du jour, par le gabarit du système |
| « 5 × » et « 500 » | `session.intervals` (répétitions × mètres) ; sinon la durée (« 40' », « 1h20 ») |
| « Fractionné léger » | `session.displayTitle` |
| « 45 min · 4:22/km · Z3 » | durée, allure SI c'EN est une, zone SI elle existe |
| le bandeau du coach | l'ajustement de la séance, sinon `PourquoiCetteSeance` ; rien s'il n'a rien à dire |
| « La suite » | les séances à venir cette semaine, après aujourd'hui |
| les cinq catégories | cinq boutons vers le hub du Club (provisoire, voir plus bas) |
| « Dernières sorties » | les deux dernières courses, avec LEUR tracé GPS dans la vignette |

**Les états que le canvas ne dessine pas**, et ce que j'en ai fait : jour de repos (« Off »),
séance faite (la pilule dit « Fait », comme la carte du plan), plan prévu en repos mais on court
quand même (« Libre »), plan verrouillé (pas de semaine, pas de « Déplacer » ni de « Semaine »,
l'offre en bas de feuille), aucune sortie (une phrase, pas une liste vide).

### Ce qui est une hypothèse de ma part, et attend une décision

1. **Explorer n'est pas un écran de l'app.** L'entrée de la barre, la recherche et les cinq
   catégories mènent toutes au hub du Club, où vivent aujourd'hui les parcours, les courses et les
   clubs. Provisoire, jusqu'à l'écran Explorer (huitième de l'ordre).
2. **La barre du canvas n'a pas de bouton de course.** L'ancienne en avait un, avec le cadran de
   discipline (course, vélo, trail, nage). Sur l'Accueil on démarre la séance du jour. La course
   libre d'une autre discipline reste joignable depuis tout écran qui garde l'ancienne barre —
   donc partout sauf l'Accueil — mais c'est un trou : où va-t-elle dans le design ?
3. **Une séance passée et non faite** s'affiche comme un repos (point éteint). Le canvas n'a que
   quatre états. VoiceOver, lui, dit la vérité.
4. **La couleur du fractionné, du seuil et du renforcement.** Le canvas n'a que trois
   intensités (vert, bleu, violet). Ces trois-là prennent l'accent, avec son encre.
5. **Ce que le canvas retire de l'Accueil** : l'anneau des objectifs du jour, la carte de la
   semaine du programme, la ligne « demain », les premiers jalons, le « + » qui ajoute une séance
   déjà faite, et le point rouge des notifications non lues (la cloche garde son nombre pour
   VoiceOver). Leurs destinations existent toujours ; leur entrée, plus.
6. **L'état « plan verrouillé »** garde l'ancienne carte d'offre en bas de feuille. C'est l'un des
   écrans hors canvas : il sera habillé avec les mêmes composants et montré avant validation.
7. **Récupération et choix**, les deux phases du programme, ont leurs écrans et ne sont pas
   refaits.
8. **« Niveau 2 » dans le bandeau du coach.** Le moteur écrit dans `adjustment` soit la raison d'un
   allègement (une phrase), soit l'étiquette de palier « Niveau N » (`AdaptivePlanEngine`, ligne
   1714). L'ancien écran affichait l'étiquette comme une pastille ; le bandeau du canvas attend une
   phrase, et l'étiquette seule s'y lit mal (c'est vrai, mais ce n'est pas un message). Je n'ai rien
   inventé : question posée — pastille à part, ou phrase à écrire ensemble ?

### Deuxième relevé (commit `22ba46d`, simulateur 390 pt)

TestFlight 593 verte (les 27 cas passent, après les trois expressions réécrites). Mesuré sur
la capture, contenu différent mis à part (le canvas dessine un mardi de fractionné, la capture un
dimanche de sortie longue, donc seules les positions comptent) :

| Mesure | Canvas | Capture |
|---|---|---|
| pas d'une ligne de « Dernières sorties » | 73 pt | 73 pt |
| hauteur de la barre flottante | 60 pt | 59 pt |
| haut de page (recherche, lettres, points, date) | — | mêmes ordonnées |
| bas de la barre au bord de l'écran | 28 pt | **63 pt** — écart |

L'écart de la barre : `.ignoresSafeArea` posé sur la barre elle-même ne fait rien, une vue de
taille fixe reste dans la zone sûre (34 pt de plus). Corrigé en posant la barre en bas d'une
surface qui occupe l'écran et l'ignore. Les vignettes en forme de « bird » sont la boucle à lobes
du profil de démonstration (`CaptureSeed.trace`), pas un défaut de dessin.

## 17 novembre 2026 — Charlotte laisse les huit hypothèses à ma décision ; le Plan, écran 2 sur 10

Message de Charlotte : « Fait tout comme il te semble parfait, ajoute s'il faut ajouter, enlève
s'il faut enlever, et on tranchera une fois qu'on aura la maquette sous les yeux. » Les huit
hypothèses de l'Accueil restent donc **telles que je les ai écrites** (ce sont mes décisions
provisoires, à revoir sur la maquette), et je passe au Plan sans attendre une validation écrite
de l'Accueil — sa capture lui a été montrée côte à côte.

### Le Plan : `PlanSemaineView` (Haizo/Views/Refonte), logique dans `PlanSemaineModele`

Le canvas : « Ta semaine », la rangée des sept jours (initiale + point à la couleur du jour, le
jour choisi en pilule), sept cartes qu'on fait glisser (318 × 430, pas de 330), « Démarrer » et
« Déplacer », puis la feuille : le coach, « Passer à un objectif ».

**Branché sur les vraies données** : les dates (« 16 au 22 novembre »), le nombre de séances, les
sept cartes (grand nombre, préfixe, titre, mesures : ceux de l'accueil, par `AccueilModele.hero`),
l'état de chaque jour, les objectifs (`GoalType`, hors celui qu'on suit).

**Ce que j'ai décidé, faute de canvas** (à revoir sur la maquette) :
1. **L'écran de la forme du plan n'est pas dans le canvas** (une barre par semaine, les phases, les
   autres semaines). C'est ce que Haizo Plus vend : je ne le supprime pas. « Le plan complet » reste
   joignable sous les objectifs et ouvre l'ancien écran par-dessus ; il sera habillé comme les
   autres (écran hors canvas, à montrer avant validation).
2. **Une séance passée et non faite** : pilule « Non faite » sur sa carte (le canvas n'a que Fait,
   Aujourd'hui, À venir, Repos). La rangée la peint à la couleur de sa séance.
3. **Couleur des cartes** : l'accent pour aujourd'hui, le noir doux pour un repos, vert / bleu /
   violet pour l'endurance / la récupération / la sortie longue ; seuil, fractionné et renforcement
   prennent l'accent (même hypothèse que l'accueil).
4. **« Démarrer » n'est actif que sur la carte d'aujourd'hui.** Sur un autre jour il reste là,
   éteint, plutôt que de faire sauter la mise en page.
5. **Le bandeau du coach** : le canvas dit « Si tu déplaces une séance, je réorganise le reste ».
   Le déplacement (`enregistrerDeplacement`) change le jour d'UNE séance et avertit si deux séances
   dures se touchent ; il ne réorganise rien. Écrire le canvas aurait été écrire une chose fausse
   sur l'entraînement : « Déplacer te laisse changer le jour d'une séance de cette semaine. »
6. **« Passer à un objectif »** : une tuile par objectif proposable (`estProposable`), quatre au
   plus ; toucher une tuile ouvre l'assistant de programme, sans présélection de l'objectif (il n'en
   a pas la possibilité aujourd'hui). La ligne du haut de chaque tuile est une phrase courte écrite
   pour l'occasion (neuf textes, trois langues) ; le canvas n'en montre que trois.
7. **La pastille du haut** : « Mode course libre » en course libre (comme le canvas), sinon
   l'objectif du programme en cours.
8. **Plan verrouillé** : la carte d'aujourd'hui seule, les autres jours ne se choisissent pas, et
   l'offre Plus remplace le coach et les objectifs.
9. **« 1h20 » et quatre signes** : le canvas règle le corps carte par carte (112, ou 84 pour « 1h20 »).
   Règle tirée : quatre signes ou plus passent au corps réduit.

Tests : `PlanSemaineModeleTests` (24 cas : les cinq états d'une carte, repos, séance faite le jour
même, séance de nage sans allure, lundi d'un dimanche, semaine à cheval sur deux mois).
Capture : `RefonteUITests.test03Plan` (`plan`, `plan-mardi`, `plan-bas`) ; `refonte.yml` se lance
désormais aussi sur `PlanView.swift`, `PlanSemaineModele.swift`, `RootTabView.swift`.

### Plan : premier relevé (commit `c4a2110`) et ce qu'il a trouvé

TestFlight 596 verte (les 24 cas du Plan passent). Mesuré sur la capture, contenu différent mis à
part (le canvas dessine un mardi de fractionné, la capture un dimanche de sortie longue) : le haut
de page (retour, pastille, titre, dates, rangée des jours) à 0,0 pt ; la carte 430 pt de haut,
même pas de 330 ; Démarrer et Déplacer à 0,0 pt ; bandeau du coach à 22 pt du coin de la feuille ;
tuiles d'objectif de 150 × 170, à 1 pt près.

Trois défauts, trouvés sur l'image, corrigés :
1. **La surface pleine écran qui porte la barre flottante absorbait les touches** (`Color.clear`
   sur tout l'écran, posée par RootTabView au relevé précédent, pour passer la barre sous la zone
   sûre). Le test a touché le mardi dans la rangée des jours : rien ne s'est passé. C'était aussi
   le cas de l'Accueil depuis ce commit — aucune capture n'y touche rien, donc rien ne l'avait
   montré. `allowsHitTesting(false)` sur la surface, posé avant la barre.
2. **Les coins arrondis de la feuille étaient blancs sur du blanc** : l'espace de 26 pt entre les
   boutons et la feuille était une marge de la feuille, et laissait voir le fond de la page, blanc
   dans la moitié basse. Il fait maintenant partie du haut de page, noir.
3. **« (Re)commencer » finissait en points de suspension** dans sa tuile d'objectif : un mot que
   rien ne coupe, 190 pt à 24 de corps pour 122 disponibles. Réduction jusqu'à 0,6.

### Plan : deuxième relevé (commit `b5a8765`)

Mesuré sur l'image : **le coin de la feuille était toujours carré** — le blanc commence à la même
ligne à 3 pt du bord et à 20 pt, alors que dans le canvas il commence 20 pt plus bas à 3 pt (le coin
est arrondi, avec du noir derrière). Mon correctif du premier relevé ne l'avait pas réglé : le noir
s'arrêtait AU bord haut de la feuille, donc rien ne passait derrière le coin. **L'Accueil a le même
défaut, et je ne l'avais pas vu** (je l'avais jugé « arrondi » à l'œil sur le côte à côte ; la
mesure dit le contraire). Corrigé sur les deux : la feuille REMONTE sur le haut de page d'un rayon
de coin (`spacing: -HZRayon.feuille`), et le bloc de couleur descend d'autant sous elle.

**Le tap sur « mardi » ne change toujours pas le jour** malgré le correctif de la surface de la
barre. Je ne sais pas encore pourquoi. Le test fait désormais trois essais, une image chacun :
par coordonnées (`plan-tap-coordonnees`), par identifiant d'accessibilité (`plan-tap-identifiant`,
sur le quatrième jour), et par glissement de la carte (`plan-mardi`). Le résultat dira si c'est la
position du tap, la rangée, ou une couche qui prend les touches. Tant que ce n'est pas élucidé, le
Plan n'est pas validé : un écran qui s'affiche bien et ne répond pas ne vaut rien.

### Plan : le changement de jour ne se faisait pas (relevés 3 à 5)

Constats, dans l'ordre : le tap par coordonnées, le tap par identifiant d'accessibilité et le
glissement de la carte laissent l'écran **pixel pour pixel identique** (0 pixel de différence) ;
« Déplacer », sur la même page, ouvre bien sa feuille ; les sept boutons de la rangée existent,
sont touchables, aux bons cadres. Ce n'est donc ni une couche qui prend les touches (la surface de
la barre a quand même été corrigée, c'était une vraie erreur), ni la position du tap.
L'état lu dans l'app : `choix=nil`, `debloque=true`, `visibles=7` après les gestes — **la sélection
n'est jamais écrite**. Les trois chemins passaient par une même fonction gardée, et un optionnel
de fermeture (`choisir: ((Int) -> Void)?` avec `.disabled(choisir == nil)`). Chemin simplifié : la
fermeture est obligatoire, le verrou est un paramètre à part, la garde a disparu de la fonction. Un
compteur `demandes` (DEBUG) dit si l'action s'exécute. Cause non établie à cette ligne.

### Plan : relevé 7 — la rangée des jours est le seul bouton de la page qui ne répond pas

Quatre lancements, un geste chacun : le retour du plan répond, la carte du jour répond (la feuille
de la séance s'ouvre), la recherche de l'accueil répond, « Déplacer » répondait ; la rangée des jours
non, même après 5 s d'attente (`demandes=0`). Le défaut est donc propre à la rangée, ni la page ni
les couches de la racine. Ce qui la distingue : son bouton vivait dans un composant et recevait son
action par une propriété de type fermeture ; les autres ont leur action écrite dans la vue. Je n'ai
pas d'explication de SwiftUI pour cela. Le composant ne dessine plus que la colonne
(`HZColonneDeJour`), le bouton est posé par l'écran.

(`test01Planche` a échoué sur cette exécution de `refonte.yml` : la planche de l'étape 1, non
touchée. À surveiller ; elle n'avait jamais échoué avant.)

### Plan et Accueil : ce que le journal de l'app et le journal système ont établi (relevés 8 à 13)

**Établi.** (a) Sortir de l'accueil : l'action part (`AccueilView: action Coach`), `go(prog → coach)`
est appelée, `RootTabView.body screen=coach` est réévalué 6 ms après — la barre change — et le contenu
reste l'accueil. (b) Plan : `selectionner jour=3` s'exécute (compteur incrémenté, retour haptique dans
le journal système), mais `PlanSemaineView.body` n'est PAS réévalué ensuite. (c) Aucun des interrupteurs
(barre d'état, fond, zone sûre, recouvrement, barre flottante, transition, animation, tout à la fois)
ne répare. (d) Le journal système de l'app ne contient ni cycle d'attributs, ni « Modifying state »,
ni message SwiftUI : **l'hypothèse du cycle, que j'avais avancée, est infirmée.**

**Pas établi : la cause.** Ce que je sais seulement : une partie du contenu cesse de se mettre à jour,
pas la barre ni les feuilles ; l'état d'un écran refait n'invalide pas sa vue.

**Fautes de ma part dans ce chantier**, à garder écrites : j'ai lu l'image « touche-accueil-recherche »
sans voir que l'ancienne barre y figurait avec « Profil » en surbrillance (Charlotte me l'a montré sur son
téléphone) ; j'ai poussé des fichiers de diagnostic sans relancer toutes les gardes (`check_decimales` a
refusé `%.3f` sans locale ; `check_valeurs` un `20` en dur) ; j'ai avancé « cycle d'attributs » avant
d'avoir un seul message qui le dise.

**Méthode actuelle : la bissection.** `--sans-nu` remplace l'accueil et le plan par un texte et un bouton ;
`--sans-ligne` retire l'enveloppe de ligne du texte de la refonte ; `--sans-defilement` retire le
`ScrollView`. `test09Bissection` rejoue les deux défauts avec chacun. Si l'écran trivial se remplace, la
cause est dans le sous-arbre de l'écran refait. À retirer ensuite : `DiagnosticRefonte.swift` et ses appels.

### Plan et Accueil : la cause des boutons morts, trouvée et corrigée (relevés 14 à 30)

**Cause : la lecture de la zone sûre de la fenêtre dans le corps d'une vue.** `HZEspace.haut` — la marge
du haut de tous les écrans refaits — lisait `BordsDeLEcran.haut`, soit `keyWindow.safeAreaInsets`, à chaque
évaluation. Mesures, toutes sur le simulateur de 390 pt, toutes concordantes :

| mesure | avec la lecture de la fenêtre | avec la constante du canvas (60 pt) |
|---|---|---|
| page réduite au titre : un compteur change-t-il l'écran ? | 0 sur 5 | 5 sur 5 |
| écran complet : une sonde posée DANS le contenu qui défile suit-elle ? | 0 sur 3 | 3 sur 3 |
| écran complet : le jeudi de la rangée change-t-il l'image ? | 0 sur 3 | 3 sur 3 |

**Mécanisme : NON établi.** On sait que cette lecture est la cause, pas pourquoi elle fige le contenu qui
défile. Le commentaire de `HZEspace.haut` le dit, et interdit d'y remettre la lecture de la fenêtre.
Une valeur fixe de 60 pt est celle du canvas ; sur un téléphone à îlot (encart de 59 pt) le contenu
commence donc 1 pt sous l'encart, sur un téléphone à encoche (47 pt) 13 pt dessous.

**Ce que ça explique, et ce que je ne sais pas.** Ça explique l'Accueil et le Plan (ils utilisent tous deux
cette marge), les boutons « morts » sur le téléphone de Charlotte, l'ancienne barre qui restait sur
l'Accueil. Je n'ai pas expliqué pourquoi la sonde posée par-dessus la page suivait sur l'écran complet alors
que le contenu dessous non ; je n'ai pas vérifié l'Accueil par la même mesure (il est dans le test de
non-régression, ci-dessous).

**Les anciens écrans lisent encore la fenêtre, dans leur corps** : `EnTeteDAccueil` (`.padding(.top,
BordsDeLEcran.haut)`) et `LiveRunView` (`BordsDeLEcran.bas`). Ils fonctionnent aujourd'hui ; ils disparaissent
avec l'ancien système de design. À ne pas copier dans un écran refait.

**Mes fautes dans ce chantier**, à garder écrites, en plus des précédentes :
- Plusieurs « false » de mes sondes ne prouvaient rien : la première, posée dans une pile dont le haut de page
  remontait sur elle (espacement négatif), était cachée — le test touchait le fond noir. Je l'ai vu en
  regardant la capture, après avoir lu le résultat. Règle : **regarder la capture avant de lire le rapport.**
- L'arbre d'accessibilité et le journal de l'app m'ont donné des états faux ou en retard (`demandes=0` alors que
  le journal disait `choix=3`). Seule la comparaison des octets de la capture avant et après un geste est fiable.
- Trois exécutions de `refonte.yml` ont été annulées par le runner macOS après 15 minutes de file, sans démarrer :
  ce n'est pas le code, mais cela m'a coûté plus d'une heure.

**Ce qui reste du chantier.** `DiagnosticRefonte.swift` et tous ses appels sont supprimés. `RefonteUITests`
ne garde que la planche, l'Accueil, le Plan, et un test de non-régression qui échoue si une touche ne change pas
l'image (recherche de l'accueil, retour du plan, carte du jour, jeudi de la rangée), avec un témoin de stabilité.
Le Plan et l'Accueil ne sont validés qu'une fois ce test vert ET les captures comparées à la référence.

## 18 novembre 2026 — « l'ancienne app partout » : le Coach passe sous la nouvelle DA, et j'arrête d'avancer un écran à la fois

Charlotte a envoyé deux captures de son téléphone : le Club et le Coach, avec l'ancien design et l'ancienne
barre d'onglets. **Elle avait raison, et c'était l'état exact du dépôt** : seuls l'Accueil et le Plan étaient
refaits. La méthode « un écran, une validation, puis le suivant » m'a fait perdre la journée du 17 sur le défaut
des boutons ; sa consigne (« tu mets tout sous la nouvelle DA ») demande la couverture. **Je refais maintenant
les écrans restants par lots**, chacun vérifié par captures, et je les montre à mesure.

### Coach (`Haizo/Views/Refonte/CoachView.swift`, ex-`Haizo/Views/Coach/`)

Composants nouveaux dans `DesignSystem/Refonte/HZConversation.swift` : `HZTuileDuCoach`, `HZBulle`,
`HZTexteDeBulle`, `HZSaisie` ; une hauteur de bouton (`HZHauteurDeBouton.reponse`, 46 pt) ; les mesures dans
`HZCoach` (`HZEcrans.swift`). **La logique ne bouge pas** : fil persistant, échange verrouillé, annulation,
réessai, message d'accueil. La barre flottante remplace l'ancienne sur cet écran, l'entrée « Coach » y est
allumée (`ongletRefait` lit maintenant l'écran courant).

**Ajouté, parce que le canvas ne le dessine pas** : le séparateur de jour, l'effacement du fil (bouton rond),
le compte rendu d'un changement avec « Annuler », l'indicateur de frappe, la bulle d'erreur avec « Réessayer ».
**Retiré** : le ruban des sept jours de « Ce qu'il regarde » (le canvas ne l'a pas ; la semaine est sur
l'accueil et le plan). **Changé de texte** : les suggestions prennent les mots du canvas (« Nutrition »,
« Analyse ma sortie ») et le champ perd ses points de suspension ; ce que la puce envoie au coach change donc
d'autant. La tuile « Dernière sortie » devient « Dernière, km » (valeur sans l'unité), comme le canvas.
Quatre clés au catalogue, en trois langues. Le bouton d'envoi s'éteint (40 %) tant que le champ est vide.

**Non vérifié à cet instant** : la compilation et la capture. Rien de ceci n'a été compilé avant le commit.

### Stats (`Haizo/Views/Refonte/StatsView.swift`, ex-`Haizo/Views/Stats/`)

Composants nouveaux dans `DesignSystem/Refonte/HZStatistiques.swift` : `HZCourbeDAllure` (le trait accent de
4 pt, un anneau pour le record), `HZCarteDAllure`, `HZLigneDeTemps`, `HZCarteDeLien`. Le haut de l'écran
(titre, grand total, périodes, quatre chiffres, records) reprend ce que la planche de l'étape 1 avait déjà
dessiné. Les calculs ne bougent pas : `PaceModel`, `SemaineComparable`, `TrainingLoad`, la projection des temps.

**Ce qui change de comportement, et que le canvas impose** : la période choisie commande maintenant le grand
total, le nombre de sorties, le temps cumulé ET la courbe (« Depuis le 11 octobre » sous « 4 sem. »). Avant, les
totaux portaient sur toute l'histoire et seule la courbe suivait le sélecteur. « Cette semaine » et « Série en
cours » restent des états au présent. La fenêtre se compte sur l'horloge de la scène (`Demonstration.maintenant`),
plus sur `.now`.

**Retiré** : le dépliage « Voir l'analyse approfondie » (records et temps possibles sont dans la page, comme dans
le canvas) ; l'aplat sous la courbe et le point sur le dernier relevé (le canvas n'en a pas) ; la précision du D+
sous la vitesse du vélo ; les icônes SF Symbols des anciennes cartes. **Conservé hors canvas** : le bloc Vélo (s'il y
a une sortie à vélo), la charge d'entraînement (Haizo Plus), l'état vide, la précision sous les temps possibles.
« Tes temps possibles » reste derrière Haizo Plus (aperçu estompé et verrou). « Cette semaine » est un bouton vers le
bilan de la semaine. Vingt-quatre clés au catalogue, en trois langues ; la barre flottante est sur cet écran.

**Non vérifié à cet instant** : compilation et captures.

### Club — le fil (`Haizo/Views/Refonte/WallView.swift`, ex-`Haizo/Views/Club/`)

**Le « Club » du canvas est le FIL, pas le hub du club.** La maquette dessine la carte du club, les filtres
« Tout / Club / Amis / Courses » et les sorties — c'est `WallView` (qui avait déjà ces quatre filtres), pas
`ClubView` (Aperçu / Classement / Activité). L'entrée « Club » de la barre ouvre donc le fil (`AppScreen.fil`) ;
le hub reste joignable par la carte du club, par « Inviter », et par les tuiles du Profil. L'entrée
« Explorer » mène encore au hub (provisoire, comme avant).

Composants nouveaux dans `DesignSystem/Refonte/HZFil.swift` : `HZCarteDeClub`, `HZSortieDuFil` (avec
`normaliser`, qui ramène un tracé GPS dans un carré), `HZNoteDuFil`. **La logique du fil ne bouge pas** :
chargement, pagination, filtres, applaudir, commenter, signaler, bloquer, modifier, supprimer, annonces de course.

**Décisions de ma part, à confirmer sur la maquette** : le bloc d'une sortie est à l'accent quand c'est un
record, noir sinon (le canvas montre les deux, sans dire pourquoi) ; « Inviter » mène au club, où se trouve le
lien à partager, au lieu d'ouvrir le partage depuis le fil ; « J'y vais » répond à la prochaine sortie du club
(`toggleEventRsvp`) ; sans club, la carte dit « Rejoins un club » et mène au hub ; un badge ou une séance sans
distance devient une note (une phrase, une coche), pas un bloc. **Gardé hors canvas** : le menu de chaque sortie
(modifier, supprimer, signaler, bloquer), la photo de la sortie (elle prend la place du fond), l'avatar photo,
le titre que l'autrice a donné à sa sortie. **Perdu** : l'apparition en cascade des cartes. **Rendus le 18 novembre, à la demande de Charlotte** : le double-tape
pour applaudir (sur le bloc de la sortie ; un tap simple l'ouvre, avec le délai habituel du double-tape ; le cœur
qui s'ouvre au centre remplace la main), la ligne « Aimé par … » et l'aperçu du dernier commentaire sous Bravo
et Commenter.
Dix clés au catalogue, en trois langues.

**Non vérifié à cet instant** : compilation et capture.

**Défaut trouvé sur la première capture du fil (18 novembre).** Le bloc de chaque sortie s'affichait EN BLANC : son
fond, la distance et le tracé n'étaient pas visibles, et les textes blancs se lisaient blanc sur blanc. Le fond était
le premier enfant d'une pile conditionnelle (`ZStack { if photo … else { (couleur) ; trace } … }`) ; il est désormais
posé en arrière-plan d'une surface de la bonne taille, et le fond d'une photo ou d'une couleur est une vue à part. Je
n'ai pas établi pourquoi l'ancienne écriture ne se dessinait pas ; je n'ai établi que sa capture. À revérifier sur la
capture suivante.

**Vérifié le 18 novembre** : le bloc de chaque sortie se dessine (captures `club`, `club-amis`, `club-bas`, run #36), et le
tracé a été décalé vers la droite pour ne plus passer sous le grand nombre (`zoneDeLaTraceX` 0,62).

## Profil (18 novembre) : refait d'après le canvas « Profil »

Le haut est noir (retour, réglages, l'avatar de 84 en initiales sur l'accent, le prénom, le pseudo, la capsule
d'objectif, trois totaux) ; la feuille blanche porte la communauté (cinq destinations en lignes, plus quatre tuiles),
les badges en grille de quatre et le prochain badge avec sa jauge. **La logique ne bouge pas** : la photo, l'objectif et son
chemin, le chargement social, les demandes d'amis en attente, l'état déconnecté et la session expirée, le détail d'un badge.

**La barre n'allume aucune entrée sur le Profil** : le canvas la dessine éteinte, et le profil n'est plus un onglet. Elle prend
un paramètre `aucuneActive`. L'avatar de l'accueil reste la porte d'entrée.

**Décisions de ma part, à confirmer sur la maquette** : la marque d'un badge est son symbole (le canvas écrit un court texte, « 300 »,
« 10 »), parce que seuls les symboles existent pour les seize badges ; la flamme de la série est retirée (le canvas n'en a pas) ;
le crayon de modification de la photo est CONSERVÉ (Charlotte, 18 novembre : la photo doit rester modifiable, c'est ce que voit tout le club) : un
toucher sur l'avatar ouvre la photothèque et un appui long propose de la retirer ; avant la première sortie, les trois totaux deviennent ceux du programme (semaines, phases, jours avant la
course) au lieu de trois zéros ; « Running Club » garde la graphie du catalogue existant (le canvas écrit « Running club » ;
la capitale du mot « Club » est celle de la marque) ; l'ambre de « Session expirée » disparaît, la carte est neutre.
Cinq clés au catalogue, en trois langues. **Vérifié le 18 novembre** (Refonte #39, vert) : captures `profil`, `profil-bas`; la grille de badges s'alignait mal (une rangée prend la hauteur de son nom le plus long), le prochain badge était coupé, la bio aussi : corrigés.

## Réglages (18 novembre) : refaits d'après le canvas « Réglages »

Page blanche en feuille : titre et bouton de fermeture, la carte d'offre noire « Haizo Plus » (état, bouton blanc « Voir l'offre »),
puis cinq groupes sur la surface claire : Apparence (Mode, Couleur), Sources de données (Apple Santé), Préférences (notifications du coach,
alerte de pluie), Objectifs quotidiens (Pas, Calories actives, avec moins/plus), Compte et équipement. **Les réglages et leurs effets
ne bougent pas** : mêmes valeurs, mêmes endroits d'écriture, mêmes autorisations demandées, mêmes refus renvoyés au toast.

Pièces nouvelles dans `DesignSystem/Refonte/HZReglages.swift` : `HZGroupeDeReglages`, `HZLigneDeReglage`, `HZStyleDInterrupteur` (un
`ToggleStyle` : VoiceOver l'annonce toujours comme un interrupteur), `HZCompteur`, `HZChoixADeux`, `HZPastilleDeCouleur`, `HZCarteDOffre`.

**Décisions de ma part, à confirmer sur la maquette** : l'habillage (Neutre/Teinté) disparaît de l'écran, comme le brief du 17 le demande
(« supprimer l'habillage Teinté ») ; la valeur enregistrée n'est pas touchée ; les huit couleurs deviennent quatre, et choisir l'une écrit
l'identifiant de l'ancien thème de même nom (le choix d'un ancien thème sans équivalent s'affiche comme rose) ; « Mode » se lit Clair/Sombre
(« Blanc » devient « Clair ») ; « Gérer mon abonnement » reste dans Compte et équipement alors que le canvas ne l'a pas (la validation App Store
l'exige dans l'app) ; la mention « Météo Apple Weather », exigée par WeatherKit, reste sous la ligne de pluie ; les compteurs affichent le nombre
seul (le titre de la ligne porte l'unité) ; sur une feuille, le haut est à 28 et non 60 (le canvas dessine un écran plein).
Quatorze clés au catalogue, en trois langues. **Vérifié le 18 novembre** (Refonte #39) : captures `profil-reglages` et `profil-reglages-bas`. La ligne de Strava, qui n'était plus affichée, a quitté ce fichier pour `Profil/StravaConnectionRow.swift`.

## Run, l'écran de course (18 novembre) : refait d'après le canvas « Run »

La carte en haut (réduire, état « En direct » avec son point qui respire, recentrer), puis un panneau noir : une barre par
répétition de la séance (faites en blanc, la courante remplie de l'accent selon sa progression réelle) et son restant, l'allure
en grand (100) avec la cible à droite, trois mesures (Temps, Kilomètres, Cardio) et les trois commandes du pouce (terminer, pause,
coach). **Rien de la logique ne bouge** : la vraie carte et son tracé (mise à jour toutes les cinq positions), le GPS et ses trois
bandeaux et leur vibration, l'écran verrouillé, le coach vocal et son verrou, le décompte de départ, la confirmation avant de
terminer. Une seule lecture ajoutée au modèle de vue : `repetitionsPrevues`.

**Décisions de ma part, à confirmer sur la maquette** : les calories ne s'affichent plus pendant la course (le canvas montre le
cardio à leur place ; elles restent enregistrées et au résumé) ; l'allure cible, qui dominait, devient « Cible » à droite de
l'allure ; sur une séance continue ou à vélo il n'y a pas de bloc, donc pas de barres (on n'en invente pas) ; l'ambre des
bandeaux disparaît, ils sont noirs avec le texte blanc ; le bas du panneau respecte la zone sûre du système (la pause ne doit pas
chevaucher le geste d'accueil) au lieu des 32 du canvas ; la carte rétrécit sur un écran plus court pour laisser le panneau entier.
**Non vérifiable en simulateur** : le tracé (pas de GPS) et la carte réelle de la coureuse.
Huit clés au catalogue (cinq nouvelles), en trois langues. Cinq gardes qui lisaient l'ancien fichier suivent (échelle, chiffres,
majuscules, grands chiffres, chaînes). **Non vérifié à cet instant** : compilation et capture.

## Résumé de la sortie (18 novembre) : refait d'après le canvas « Résumé »

La carte du tracé en haut (fermer, « Sortie terminée », agrandir), la feuille blanche dessous : la date, la distance en très grand
(104), le titre, deux tuiles (allure moyenne, durée), la phrase du record quand il y en a un, puis « Partager » et « Détail ». **Rien ne
disparaît** : les splits (nouveau composant `HZSplits`), le profil d'élévation, la carte à partager et ses trois couleurs, la vidéo, l'export
GPX, la publication de l'itinéraire, le ressenti. Les records, le rendu de la carte et celui de la vidéo n'ont pas bougé d'une ligne.

**Décisions de ma part, à confirmer sur la maquette** : « Donner mon ressenti » (que le canvas n'a pas : c'est l'entrée du plan adaptatif)
est un bouton accent pleine largeur au-dessus de « Partager » ; trois tuiles de plus (FC moy., kcal, D+) sous les deux du canvas, parce
que l'écran les donnait déjà ; la distance garde ses deux décimales (le canvas en écrit une : « 8,9 ») pour qu'un record de quelques dizaines
de mètres se voie ; la date n'a pas le lieu (« Malakoff ») : l'app n'enregistre pas de nom de lieu ; « Détail » mène à l'historique, et
disparaît quand on regarde une ancienne sortie ; l'aperçu de la carte à partager est sur un fond noir (la carte est transparente et son
texte blanc disparaîtrait sur du blanc) ; l'icône « agrandir le tracé » reste le symbole du système (le canvas dessine trois points).
Le fondu en bas du défilement a disparu avec le reste. Graine de captures : `--resume` pose la sortie la plus récente comme dernière sortie.
Six clés au catalogue, en trois langues. **Non vérifié à cet instant** : compilation et capture.

**Vérifié le 18 novembre** (Refonte #42, vert ; TestFlight #631, vert) : captures `course-decompte`, `course`, `course-pause`, `resume`, `resume-bas`.
Écran de course : la mise en page, la bulle du coach, le bandeau GPS, la pause (le bouton devient lecture, l'image change) conformes au
canvas ; sans lecture, l'allure « --:-- » s'éteint (de gros blocs blancs attiraient l'œil). Les barres de blocs n'ont pas pu être vues : la
séance de la graine est continue, donc il n'y en a pas ; à voir sur une séance à répétitions. Résumé : conforme ; le bloc des splits n'apparaît
pas, la sortie de la graine n'en a pas. La première version du Résumé ne compilait pas (`capitalizationContext` est une propriété du format,
pas une méthode) : corrigé.

## Explorer (18 novembre) : écran nouveau, d'après le canvas « Explorer »

Explorer n'existait pas comme écran : la barre l'envoyait provisoirement vers le hub du Club. Il existe maintenant (`AppScreen.explorer`, entrée
de la barre) : un champ (« Où cours-tu aujourd'hui ? ») qui ouvre la carte de recherche des itinéraires, cinq filtres (Pour toi, Route, Trail,
HYROX, Clubs), l'itinéraire le plus gardé autour de soi en vedette (bloc noir, tracé en accent, « À 400 m de toi », distance en grand), et les
courses à venir en tuiles de couleur (mois, distance, nom, « n coureurs la préparent »).

**Rien de nouveau côté données** : `fetchRoutesNearby`, `upcomingRaces`, `suggestedClubs`, les mêmes appels que les écrans du hub. Un itinéraire
ouvre sa feuille de détail, une course sa page (plein écran, comme depuis la liste des courses), un club le hub. **Une chose ajoutée** : un relevé
de position unique (`LocationPermission.requestPosition`), pour chercher dans un carré d'environ 11 km autour d'elle ; la même autorisation que
la carte de recherche, et le même type de requête (une zone, pas une position précise).

**Honnête quand il n'y a rien** : sans autorisation, un lien vers les Réglages ; en attendant la position, une phrase qui le dit ; sans itinéraire
publié autour, l'invitation à publier le sien ; sans réseau, le motif réel de la panne ; un filtre vide dit ce qu'il n'a pas.

**Décisions de ma part, à confirmer sur la maquette** : la pastille dit « À 400 m de toi » et non « de chez toi » (l'app ne connaît pas le domicile) ;
le sous-titre du champ dit « Autour de toi » et non « Autour de Malakoff » (pas de nom de lieu connu) ; la ligne du canvas « Enregistrée par 34 coureurs
Haizo » devient « Gardé par 34 coureurs Haizo » (c'est ce que mesure `savesCount`) ; les couleurs des tuiles sont celles de la palette d'intensité,
l'une après l'autre (rien ne rattache une couleur à une discipline) ; le canvas montre aussi une troisième tuile vide, que je n'ai pas reprise ;
« Tout voir » mène à l'onglet des courses du hub, et le champ à celui des itinéraires. Graine de captures : deux itinéraires, quatre courses, trois clubs.
Quatorze clés au catalogue, en trois langues. **Non vérifié à cet instant** : compilation et capture.

**Vérifié le 18 novembre** (TestFlight #634 vert ; Refonte #45, hors deux tests de l'accueil et du plan qui ont expiré au lancement du simulateur) :
captures `explorer-trail`, `explorer-clubs`, `course`. L'allure grisée de l'écran de course est conforme. Explorer : la fenêtre de localisation
du système recouvrait la première capture ; elle n'est plus demandée en démonstration. Les erreurs de compilation de cette série (format de date du
Résumé, ordre des arguments d'Explorer) venaient de moi, qui ne peux pas compiler ici : la CI est le seul juge.

**Explorer, vérifié le 18 novembre** (Refonte #47, entièrement vert, accueil et plan compris) : capture `explorer` propre (plus de fenêtre de localisation),
le mois des tuiles à 14 pt du bord (la boîte de ligne de `hzTexte` fait remonter un texte superposé au coin d'une tuile : en pile, la place vient des
tailles), le tracé du bloc noir qui ne croise plus la distance. **Tous les écrans du canvas sont maintenant refaits** : Accueil, Plan, Coach, Stats, fil du
Club, Profil, Réglages, Run, Résumé, Explorer. **Reste, hors canvas** : le hub du Club (`SocialView`, `ClubView`, `FriendsView`, `RouteDiscoveryView`,
`RaceDiscoveryView`), les pages de course, l'historique, le récap hebdo, les chaussures, la carte de chaleur, l'inscription, le paywall, les feuilles ; puis le
retrait de l'ancien système de design.

## La refonte est terminée (19 novembre) : plus un écran dans l'ancienne DA, et l'ancien système est supprimé

**Ce qui a été refait ce jour-là**, à partir du brief « On termine la refonte » : le paywall (noir plein écran, « Haizo Plus » en grand, trois
bénéfices, deux formules dont la choisie en blanc, prix et conditions sans défilement) ; **toutes les feuilles** sur un seul composant,
`HZFeuilleModale` (titre d'affichage 22, bouton rond de fermeture 44, rayon 30, poignée, actions en pilules), posé par un seul réglage,
`.hzFeuille(detents:gereSonBas:)` ; et tout ce qui était resté dans l'ancienne DA :

- **Feuilles** : séance, déplacer une séance, journal d'une séance, bilan, ajouter une sortie, réglages (« Plus de réglages », administration,
  changement de compte, notifications, réglages du programme, sauvegarde), gestion du club (défi, sortie, profil d'un membre), détail d'un badge,
  commentaires, modifier une sortie ou une annonce, publier et détailler un itinéraire, formulaire de participation, ajouter une course, les trois
  « Jour J ».
- **Pages** : profil public, objectif de course, page d'une course, plan complet, Journée (`RingsView`), nouvel objectif, fin de programme et
  récupération, badge débloqué (plein écran noir), le tracé en grand.
- **Transverse** : la barre flottante est maintenant celle de **tous** les écrans (sauf la course en direct et son résumé). L'ancienne barre et son cadran
  de discipline sont supprimés : le bouton de course n'est plus dans la barre depuis le canvas, démarrer est la première action de l'accueil. Le retour
  vers une course commencée passe par une pastille « Course en cours · 12:34 » (`HZCourseEnCours`), au-dessus de la barre. Le message passager
  (`ToastCenter`) est une pilule noire.

**Ce qui est supprimé, et la preuve** : `Colors.swift`, `Typography.swift`, `Spacing.swift`, `Motion.swift`, `AccentTheme.swift`, `Habillage.swift` ;
tout `Views/Components` sauf six fichiers déplacés dans `Views/Refonte` et passés aux jetons (la marque, le tracé, le profil d'altitude, la carte du
tracé, le bouton de code promo) ; une vingtaine de fichiers morts (ancien accueil, onboarding en onze écrans, rubans, ligne Strava) ; les gardes qui
ne gardaient que l'ancien système (`check_filet`, `check_vides`, `check_nuit`, `check_grille`, `check_jetons_de_texte`, `check_echelle`, `check_encres`,
`check_accent`, `check_barre`, `check_inscription`). `check_design.py` est réécrit : il lit `HZCouleur` et `HZMouvement` et compare `DESIGN.md`.
La recherche `RUColor|RUFont|RUSpacing|RURadius|RUMotion|RUTextSize|RUDisplaySize|RUIconSize|haizoSheetStyle|ruBarreDuBas|ruCard|displayStyle|metaStyle|AccentTheme|Habillage`
dans `Haizo`, `HaizoTests`, `HaizoUITests`, `HaizoWidgets`, `HaizoWatch` ne rend plus rien que des commentaires d'histoire (listés plus bas s'il en reste).
Ce qui reste du réglage : `ThemeStore` (accent et clair/sombre, dans `HZApparence.swift`) ; `UserProfile.habillageID` reste un champ enregistré que
plus rien ne lit, parce qu'une propriété enregistrée ne se retire pas sans migration et qu'il est dans les sauvegardes déjà exportées.

**Décisions de ma part, à confirmer** (aucune n'est de Charlotte) :
- Les erreurs, avertissements et états (« Signaler ce club », « Quitter le club », un dossard à confirmer, une erreur de saisie) n'ont **plus de teinte** : le
  système n'a pas de couleur d'alerte, ils s'écrivent en encre sur la surface claire. À trancher : veut-on une teinte d'alerte dans le système ?
- Les capitales des boutons et des étiquettes sont passées en casse normale, partout (« ENREGISTRER » → « Enregistrer »), y compris sur les cartes partagées
  en image (« Nouveau record », « Distance », « Allure », « Temps »).
- Le champ d'écriture d'un commentaire est sur une ligne (envoi au retour clavier), comme celui du coach.
- La carte de marque (icône, lancement) est en accent plein : le dégradé de marque n'existe plus dans l'app. Les images de la fiche App Store gardent leur
  palette, écrite dans `screenshots.py`.
- Le plan complet : les phases n'ont pas de couleur dans le canvas ; Base = accent, Spécifique = encre, Affûtage = la teinte « longue », décharge = gris.
  L'icône SF par famille de séance est retirée au profit de la bande colorée : les familles ne se distinguent plus que par la couleur et le libellé
  (repère forme perdu pour les daltoniens, à valider).
- **« Préparer une course » à l'inscription ne cale pas encore le programme sur la date de la course** : le choix pose un objectif « progresser » (aucune date),
  et ouvre la liste des courses. « Je prépare cette course » n'écrit rien dans le profil. La phrase qui promettait « le plan se calera sur sa date » était fausse ;
  elle est retirée. À faire : relier le choix d'une course à l'objectif et à la date du profil (`raceDate`), ce qui change le programme généré — pas fait ici,
  parce que c'est une décision de logique d'entraînement.
- Bogue connu, non touché : dans `RaceGoalView`, `strategieStructurelle` ne rend rien pour le triathlon et le duathlon, donc leurs feuilles « Jour J » sont
  injoignables (comme avant).
- Au retour depuis l'écran des jours du nouvel objectif, un objectif sans étape de détails demande deux appuis. Défaut hérité, non corrigé.

**À vérifier à l'œil** (non vérifiable sans appareil) : la connexion Apple et le pseudo (`SignInView`) ; le clavier qui ne s'ouvre plus tout seul sur « Distance »
dans le journal d'une séance (`HZChampDeTexte` n'expose pas de focus) ; le détent de 400 pt du détail d'un badge (estimé) ; les rangées de choix qui défilent
sur un iPhone 375 ; les trois « Jour J » (inatteignables, voir plus haut).

**Les gardes** : `ci_scripts/check_*.py`, tous verts dans cet arbre, hors `check_branche` et `check_cjs` (nom de branche, `node_modules`) qui ne tournent qu'en CI.
`check_valeurs` s'applique maintenant à tout `Views/Refonte` (le seul dossier de vues qui reste, hors `RootTabView` et trois petits fichiers du Club).

**Vérifié le 19 novembre** : Refonte #61 vert sur `38df334` (compilation, 72 captures) ; TestFlight #653 sur `64b1055` : tous les contrôles, la compilation,
les 933 tests unitaires verts (le test des symboles a dû voir son plancher baissé de 50 à 10 : la plupart des icônes sont maintenant dessinées). Une première
tentative avait échoué sur deux oublis de ma part : un nom en double (`HZCourseEnCours`) et la taille de texte de l'appareil (`TextSizeStore`), qui vivait dans
l'ancienne typographie et que la refonte appelait encore. **Captures regardées** : séance, réglages, déplacer, journal, programme, notifications, objectif,
Journée, objectif de course. Le workflow « Serveur » est rouge pour une raison sans rapport : la page de confidentialité publiée (servie depuis `main`) diffère de
`privacy.html`, et ne se corrige pas depuis cette branche.

## Moins de rose (19 novembre) : décision de Charlotte

Charlotte : « le rose est trop présent, c'est too much ». Elle a choisi **moins de rose** (plutôt qu'une autre couleur par défaut). Le rose n'est plus une
surface, c'est une touche : l'**Accueil passe sur le noir** (hero blanc, pilules et actions en noir doux), les **cartes du plan** gardent la couleur de leur séance
(vert, bleu, violet) ou prennent le noir doux (seuil, fractionné, renforcement, repos), **aujourd'hui** n'est plus une carte rose (son point est blanc), les
tuiles « plus longue » (Stats), « Forme » (Coach) et celles de « La suite » quittent l'accent. Reste en accent, en petit : l'anneau et les jauges de la Journée,
la dernière barre de la charge, les tracés, la pastille « Course en cours », les pastilles étiquetées. Le choix du rose, du violet, du bleu ou du vert reste dans
Réglages. Nouveaux paramètres des composants pour porter ces deux fonds : `HZAction`, `HZSemaineEnPoints`, `HZAmorceDeRecherche`.

**Reste à confirmer** (rien de tout cela n'est de Charlotte) : veut-on une teinte d'alerte dans le système ? Relier « Préparer une course » à la date de la course
(le programme ne s'y cale pas aujourd'hui). Le rose du widget et de la montre est encore l'ancien (`#FF0A78`, contre `#FF2E6E` dans l'app) : leurs palettes
recopiées n'ont plus de garde depuis la suppression de `check_accent` et `check_encres`. Les rouges et le « Serveur » ci-dessus.

## « Préparer une course » donne enfin sa date au programme (20 novembre) : décision de Charlotte, « oui obligatoire »

Le défaut : l'inscription posait un objectif « progresser » sans date, ouvrait la liste des courses, et « Je prépare cette course » n'écrivait qu'un drapeau social.
Le programme restait ouvert (ni bloc spécifique ni affûtage) pendant que l'écran promettait le contraire.

**Ce qui change.** Une course du calendrier devient un objectif de programme (`ProgrammePourUneCourse`, `Haizo/Models/`) : la discipline et la distance choisissent
l'objectif (route : 5 km, 10 km, semi, marathon, sinon « 15 km » en distance libre ; trail : en dessous de 50 km une course, au-dessus un ultra, avec son dénivelé), la
date de la course ancre le plan (`AdaptivePlanEngine.startNewProgram`, qui sait déjà construire base, spécifique et affûtage vers une date). Le jour du calendrier
(« AAAA-MM-JJ », sans fuseau) est ramené à midi, heure locale, du même jour : lu tel quel à l'ouest de Greenwich il tomberait la veille et le programme finirait un jour trop tôt.

**Quand.** Juste après l'inscription où la personne a dit « Préparer une course », le programme d'attente se recale tout seul au moment de « Je prépare cette course »
(rien à perdre, le programme a quelques minutes). Partout ailleurs, remplacer un programme qu'elle suit déjà se demande : « Caler ton programme sur cette course ? »,
et le refus ne coûte rien. Rien n'est proposé quand le profil est déjà calé sur cette date.

**Ce qui ne cale rien, volontairement.** Le triathlon, le duathlon et le HYROX : le calendrier n'a ni leur format ni leur division, et le moteur construirait un plan sans
natation, sans transitions, sans division. Une course sans distance, passée, ou à la date illisible non plus. On ne devine pas ; la course reste suivie, le programme garde sa forme.

Neuf tests (`ProgrammePourUneCourseTests`), dont les fuseaux de Pacific/Auckland à Pacific/Honolulu et le programme qui reçoit sa date. **Vérifié** : compilation et 933 tests verts (TestFlight n° 654).

## La montre suit la nouvelle DA (20 novembre) : décision de Charlotte, « le rose reste, mais la DA s'adapte »

Les trois écrans de la montre (départ, course, bilan) passent aux aplats de l'iPhone : départ en disque blanc de 60 points portant le triangle noir, chiffres gras et
serrés, libellés en casse de phrase, plus aucune majuscule espacée. Le rose, d'abord laissé à `#FF0A78`, a été aligné sur celui de l'app (`#FF2E6E`) à sa demande le 20 novembre : en touches seulement (allure, durée, barre de progression).
Symboles SF conservés, boutons de course de 40 points (plancher 30). Police : voir « La montre passe en Archivo » ci-dessous.

**Vérifié sur CI** : la montre se compile, et la capture a été refaite (`montre.yml`, trois langues). Une première image avait la phrase du bas collée à l'arête de l'écran
en anglais : `check_captures_montre.py` l'a refusée, le disque est passé de 72 à 60 points, la seconde passe est propre. Le premier relevé de cette seconde passe a échoué
sur un simulateur occupé (« Busy »), sans rapport avec le code ; relancé, il est passé. L'image de l'App Store (`appstore/requis/montre`) est celle de la nouvelle DA.

**Décisions de Charlotte** : aucune teinte d'alerte dans le système (on laisse comme ça).
**Pas vérifié** : l'écran de course et le bilan sur une vraie montre (seul l'écran de départ est photographié) ; une montre de 40 mm.

## La montre passe en Archivo (20 novembre) : « oui » de Charlotte

La montre écrit maintenant dans la fonte de l'iPhone, Archivo (`Archivo-Variable.ttf`, embarquée et déclarée dans l'`UIAppFonts` de la cible montre ; les cinq Instrument Sans
n'y sont plus embarquées). UIKit n'existe pas sur le poignet : `WT.gras/semi/moyen` règlent l'axe de graisse (700, 600, 500) par un descripteur CoreText, largeur 100.
**Pas reprise : la largeur d'affichage de l'iPhone (125 %)**, qui ferait perdre un quart de place au chrono de 42 points sur un écran de 184 de large.
`WatchRunMetrics` garde son facteur de ligne 1,211 (celui d'Inter) comme borne haute : la ligne naturelle d'Archivo fait 1,088, donc l'écran de course occupe moins que ce que le calcul annonce.

**Vérifié** : compilation de la cible montre sur CI (run n° 64), `check_fonts` et `check_spec` (une police enregistrée, livrée). La capture de l'écran de départ a été refaite et
comparée, lettre à lettre, à un rendu d'Archivo et à un rendu d'Instrument Sans : c'est Archivo. Cette comparaison est la seule preuve de chargement : une famille introuvable ne lève
rien, CoreText rend la police système. **Pas vérifié** : l'écran de course et le bilan, sur une vraie montre. **Resté en Instrument Sans** : le widget et la Live Activity (`DisplayFont`),
parce que la demande portait sur la montre.

## Le widget et la Live Activity passent à la nouvelle DA (20 novembre) : « on met tout sur la même DA »

`HaizoWidgets` (widget d'écran d'accueil, Live Activity, Dynamic Island) suit l'app : Archivo (`WG.police`, CoreText sur `Archivo-Variable.ttf`, seul fichier enregistré par la cible),
des gris opaques pour les textes secondaires (plus de blanc à 42 ou 55 %), des libellés en casse de phrase (« En direct », « En pause » ; plus de `textCase(.uppercase)` ni d'interlettrage
positif), des rails en jetons (`filetSombre`, `filetGroupe`), une pastille de série en surface neutre, et, pendant une course, un fond noir franc à la place du rose plein : l'accent n'est plus
qu'un point d'état et une barre. Les jetons recopiés vivent dans `HaizoWidgets/WidgetStyle.swift` (`WG`).

**Les accents suivent l'app.** `WidgetAccentPalette` reprend `HZAccent` (rose, violet, bleu, vert) et son repli : « cyan », « lime » et « vert » donnent le vert, le reste revient au rose. Avant, un téléphone
réglé sur « lime » affichait un anneau lime sous une app verte. **Le rose du widget et de la montre est `#FF2E6E`, comme l'app** (aligné le 20 novembre à la demande de Charlotte, après avoir été laissé à `#FF0A78`).

**Vérifié** : compilation de l'extension et du build complet (TestFlight n° 660 et suivants), `check_fonts`, `check_spec`, `check_strings`, `check_majuscules` (les deux dernières entrées de dette, montre et widget, sont levées).
**Pas vérifié** : le rendu. Aucune capture CI ne photographie un widget ni la Live Activity ; il faut les regarder sur le téléphone (accueil, écran verrouillé, Dynamic Island, une course en cours).

**Restes** : (1) `AccentColor.colorset` de l'app vaut `#FF0F5B`, un troisième rose, non demandé et non touché ; (2) `DisplayFont` (Instrument Sans) ne sert plus qu'à `WatchRunMetrics.displayLine`, avec un facteur 1,0 : à retirer le jour où ce calcul
n'en dépend plus ; (3) les nombres de mise en page des widgets (marges, espacements) sont encore littéraux dans les vues, hors du contrôle `check_valeurs` qui ne couvre que `Haizo/Views`.

## Une belle Live Activity (20 novembre) : « Je veux une belle live activity »

`RunActivityWidget` est redessiné, écran verrouillé et Dynamic Island. **Écran verrouillé** : le chrono domine (52 points, Archivo gras et serré, en chiffres tabulaires), la distance et
l'allure sont posées dans deux tuiles `surfaceSombre` à droite, une barre avance vers la durée prévue avec cette durée à côté (masquée quand la séance n'en a pas), et l'accent n'est que le point
d'état et le remplissage de la barre. **Trois états** : en direct (point d'accent), en pause (point éteint, chrono et barre en gris), terminée (coche d'accent, « Sortie terminée »).
**Dynamic Island déployé** : chrono et état à gauche, distance et allure à droite, barre et titre en bas. Compact et minimal inchangés (le coureur d'accent, le chrono).

**Pourquoi deux colonnes.** La pile verticale (chrono pleine largeur puis les tuiles), plus proche de la grande fonte large de l'iPhone, mesurait 172 points : sous le plafond d'environ 160 que le système
accorde à une carte d'écran verrouillé, elle aurait été coupée. La carte retenue en mesure 138. Les deux ont été comparées sur une maquette Chromium rendue avec le vrai `Archivo-Variable.ttf`,
à 359 points de large ; les tailles et formes sont des jetons (`WG.Corps`, `WG.Forme`).

**Vérifié** : compilation de l'extension et du build complet (TestFlight n° 663), contrôles de chaînes, de polices et de capitales. **Pas vérifié** : le rendu sur appareil. La maquette n'est pas une capture, et
aucun contrôle CI ne photographie une Live Activity. La barre suit `elapsedSeconds`, republié toutes les ~5 secondes par l'app : sur 40 minutes elle bouge d'un huitième de point par seconde, ce qui ne se voit pas ;
le chrono, lui, avance seul (`Text(timerInterval:)`). À regarder : écran verrouillé en course, pause, fin, Dynamic Island compact et déployé, une course sans durée prévue (barre absente), un chrono de plus d'une heure.

## Quatre retours de Charlotte du 20 novembre : accueil fade, balayage du Plan, carte sous la barre, débrief

**1. « Le noir et blanc fait trop fade »** (après « le rose est trop présent »). Règle posée : **le très grand chiffre d'un écran porte l'accent, et rien d'autre à cette taille.** `hzVedette()`
(`HZPolice.swift`) sur : le nombre de la séance du jour (accueil), le total de la période (stats), celui du bilan hebdo, la distance de la sortie (résumé, détail d'une activité), l'allure en direct et le
décompte, et le grand nombre d'une carte du plan **neutre** (repos, séance sans teinte) ; sur une teinte d'intensité le nombre reste blanc (du rose sur du vert ou du violet serait une collision).
Vu sur la capture CI : le « 39' » rose de l'accueil est lisible et donne enfin un point d'accroche ; la carte violette du plan garde son blanc. Une ligne pour revenir en arrière. Écrit dans DESIGN.md.
S'il paraît encore fade, le levier suivant est de teinter davantage la feuille de l'accueil, pas d'ajouter du rose aux petits éléments.

**2. Le balayage des cartes du Plan** : la carte ne bougeait qu'à la fin du geste, d'un cran, quelle que soit la vitesse. Elle suit maintenant le doigt (`HZCarrousel`, `seuilDeDebut` 8 points), résiste au
bout de la semaine (0,3), et un geste rapide saute jusqu'à deux cartes ; un geste surtout vertical reste un défilement de la page. La décision du cran est une fonction pure testée (`CarrouselDuPlanTests`, 8 cas).
**Pas vérifié** : le ressenti du geste, qui ne se voit que sur l'appareil (le suivi du doigt, la fluidité, l'interaction avec le défilement vertical de la page).

**3. La carte sous la barre flottante** (Mes routes) : la feuille blanche s'arrêtait à la zone sûre du bas, la carte (qui l'ignore) reparaissait dessous avec son attribution. Le fond blanc descend jusqu'au bord
de l'écran. Vérifié sur la capture. Les autres cartes plein écran (itinéraires) passent volontairement sous la barre : il n'y a pas de feuille dessus.

**4. Le débrief de fin de course** : la carte de partage (trois styles), l'image de la vidéo et le profil d'élévation étaient restés dans l'ancien style (tracé néon en dégradé rose et violet, flou, halos, contours,
libellés espacés, lueur rose). Ils sont en aplats : un trait net d'accent, Archivo, libellés gris en casse de phrase ; le style « Haizo » est un noir franc opaque ; une seule ombre est gardée (style Blanc, DESIGN.md).
~Vingt jetons `HZJournee` retirés, `check_degrade` sans plus aucune exception. La feuille « Comment tu te sens ? » (`DebriefSheet`) n'avait rien à corriger : elle utilisait déjà les composants de la refonte ; elle est
maintenant photographiée (`feuille-debrief`, `feuille-debrief-bas`). **« Donner mon ressenti » reste en accent** : la première reprise l'avait passé au noir, ce qui allait à contre-courant de la demande ; annulé.
Vérifié sur les captures CI (résumé, carte de partage, feuille du débrief). **Pas vérifié** : l'ombre du style Blanc sur une vraie photo claire ; la vidéo exportée.

**Restes** : les clés « KM » et « M D+ » du catalogue n'ont plus d'usage (aucun contrôle ne les signale). Corrections du même jour : `test_model_defaults.py` passe 21 cas sur 21 — j'avais écrit qu'il
échouait parce que je l'avais lancé depuis la racine du dépôt ; il se lance depuis `ci_scripts`, comme `testflight.yml`. Et `AccentColor` (la couleur d'accent par défaut de l'app, celle que iOS utilise pour ce qu'il
dessine lui-même : boutons d'alerte, feuille de partage, curseur de saisie, interrupteurs ; ce n'est pas l'icône de l'app) valait `#FF0F5B`, un troisième rose : elle vaut maintenant `#FF2E6E`, celui de
`HZAccent.rose`. Elle ne suit pas le choix de la personne (violet, bleu, vert) : une ressource ne se règle pas à l'exécution ; ces éléments système restent roses pour elle.

## Le rythme d'une sortie s'écrit comme sa discipline l'écrit (21 novembre)

Reprise de « la feuille de séance écrit /km en dur ». Le « — /km » d'une séance de nage était déjà réparé dans `SessionDetailSheet` (`AccueilModele.allureValide`) ; ce qui restait était plus large : la carte de
partage, le tracé agrandi (`RouteZoomView`) et le résumé (`RecapView`) écrivaient « /km » à la main sous `avgPace`, quelle que soit la sortie, donc des kilomètres-heure lus comme des minutes au kilomètre sur une
sortie à vélo. `RunRecord.rythmeEcrit` et `rythmeLibelle` (fin de `RunRecord.swift`) passent par `TimeFormat.rythmeEcrit` et `Discipline.rythmeLabel` : « 5:18/km » à pied, « 25,3 km/h » à vélo, « 1:42/100 m » en bassin,
« — » rendu tel quel. Le résumé dit « Vitesse moyenne » à vélo. Cinq tests (`RythmeDuReleveTests`). Au passage, la carte de partage écrit « 5:18/km » collé (la règle de l'espace de `TimeFormat`) au lieu de « 5:18 /km ».
**Pas vérifié** : le rendu d'une sortie à vélo ou de nage à l'écran (la graine de capture n'en pose pas). Les phrases de la feuille de séance gardent « /km » en littéral : ce sont des allures de course à pied (`session.pace`),
et une séance sans allure n'écrit pas l'unité. Les deux clés de catalogue « KM » et « M D+ », sans usage depuis le débrief, sont retirées.

## Plus de tiret cadratin dans les textes de l'app (21 novembre)

Le tiret cadratin est de la ponctuation française légitime ; sa répétition mécanique se lit comme un tic, et Charlotte l'a fait retirer. **177 phrases du catalogue** ont été réécrites en trois langues, une par une, avec le
séparateur que la phrase demande : un point et une majuscule (« Annulé. Ton programme n'a pas changé. »), deux-points (« Impossible d'enregistrer : … », « Charges renforcées : pour un niveau confirmé »), une virgule
(« …selon ta forme, pas séance par séance »), ou des parenthèses (la phrase sur ce qui appartient au Club). **50 traductions** sous des clés techniques (les sous-titres de séance `session.*.subtitle`, trois phrases anglaises) aussi.
Les textes du code qui s'affichent ont suivi : les sous-titres de repli de `AdaptivePlanEngine` (l'app affiche le catalogue par `kind`, le texte du code ne sert qu'aux anciens plans), les textes de démonstration de `CaptureSeed`,
la carte défi (« base · 40 % »), l'objet du mail de retour. Deux entrées orphelines (« — %lld confirmé ») supprimées.

**Le coach ne doit plus en écrire** : `CoachLanguage` (consigne de style et consigne vocale, dans les trois langues) lui interdit le tiret cadratin. **Pas vérifié** : que ses réponses suivent la consigne, ce qui ne se voit qu'à
l'usage.

**Un garde** : `check_tirets.py` (et `test_tirets.py`, 8 cas) lit le catalogue, clés et traductions, et refuse tout tiret cadratin ; étape `testflight.yml`. Le « — » SEUL (espace réservé d'une valeur absente) est permis.
**Restes volontaires** : les commentaires de code, les messages d'assertion des tests, les textes de développement (`Sauvegarde`), le « — » seul. **Pas vérifié** : le rendu de chaque phrase à l'écran ; certaines sont un peu plus
longues et pourraient serrer dans un gabarit étroit. La capture montre, dont la phrase du bas a changé (« Cours à ta sensation. Ta séance arrive de l'iPhone. »), a été refaite et regardée dans les trois langues.

## Le widget d'accueil devient l'accueil en miniature (21 novembre) : « le widget est vraiment naze comparé à l'app »

**Le constat.** Le widget avait pris la nouvelle DA (Archivo, jetons, aplats) le 20 novembre, mais gardait sa
mise en page d'avant : un anneau et des libellés gris. L'accueil de l'app est une affiche, avec un grand chiffre
dans l'accent. Même fonte, deux objets sans rapport.

**Ce qui change.** Fond noir `0B0B0C` dans les deux modes (comme l'en-tête de l'accueil). Semaine en points, aujourd'hui
cerclé, série en pastille. Le grand chiffre de la séance du jour dans l'accent (Archivo 800, largeur 125, jusqu'à
rétrécir de moitié plutôt que d'être coupé), son préfixe (« 5 × »), son titre, ses mesures. Le moyen ajoute l'anneau des
objectifs (« 2/3 », « bouclés ») et la date. Jour de repos : « Off ». Séance faite : « Fait ».

**La séance voyage dans l'instantané** (`heroPrefixe/Nombre/Titre/Mesures/Faite`), composée par `AccueilModele.hero`,
la même fonction que l'accueil : le widget ne recompose rien. Champs optionnels, décodés avec `decodeIfPresent` : un
instantané ancien n'a pas de séance et le widget retombe sur l'anneau seul, sans inventer de chiffre
(`WidgetWeekStripTests`).

**Ce que le widget perd, dit sans détour.** Le moyen n'affiche plus les lignes calories et pas (« 110 kcal restantes »,
« 2400 pas ») : l'anneau reste, mais plus leurs légendes. Description de la galerie : « La séance du jour et tes
objectifs, d'un coup d'œil. » (en/es traduits).

**Non vérifié ici.** Aucune capture de widget en CI et pas de simulateur : le rendu réel (surtout la largeur du grand chiffre
en petit, et les titres longs) reste à regarder sur l'iPhone. Le chiffre rétrécit (`minimumScaleFactor` 0,5) plutôt que d'être
coupé ; mesuré sur une maquette avec le vrai fichier Archivo, pas sur WidgetKit.

**Correction du même jour : le grand nombre débordait à gauche (retour de Charlotte sur l'appareil).** Cause : le système pose
16 points de marge autour d'un widget (iOS 17) et la vue ajoutait les siens, soit ~98 points utiles sur 158 au lieu des
130 de la maquette. Le nombre, mesuré à 62 points, n'y tenait pas. Les marges système sont désactivées
(`contentMarginsDisabled`), et le nombre est cadré à gauche sur la largeur disponible. La Live Activity n'est pas concernée
(autre mécanisme). Les états de course du widget gagnent aussi leurs 14 points de marge propres, sans le doublon.
Toujours non vérifié ici : à revoir sur l'iPhone.

**Le widget se photographie maintenant en CI (21 novembre).** Après deux livraisons jugées sur une maquette HTML fausse, la cible
`HaizoWidgetTests` (`project.yml`, schéma `Widget`) compile les sources du widget dans un paquet de test sans hôte et en rend
les vues en images (`ImageRenderer`, vrai Archivo) ; `.github/workflows/widget.yml` publie l'artifact `widget` (27 PNG : petit
158 et 170, moyen 338, neuf cas dont repos, quatre chiffres, instantané ancien, course en cours). Ce n'est PAS le rendu de
WidgetKit : ni marges ni coins du système, `containerBackground` n'y fait rien (le test pose le fond), et la taille est
imposée par `DailyGoalsWidgetView.familleImposee` (`widgetFamily` est en lecture seule). La mise en page, la fonte et les
débordements sont vrais.

Ce que le premier rendu a révélé : la pastille de série coupée dans le petit widget (corrigée : `fixedSize`, points de la
semaine resserrés) et l'interlettrage négatif qui mangeait les espaces du titre (retiré, il ne sert qu'aux grands chiffres).
Le chrono « 8813:47 » du premier rendu était un défaut du test (date de départ en 2025), corrigé.

## Le balayage du Plan passe au défilement natif (21 novembre) : « Ça fonctionne toujours très mal »

Charlotte a filmé l'écran (7 s, 60 images par seconde). Ce que la vidéo montre, mesuré image par image sur le bord de la carte de
dimanche : le geste fait bien changer de carte (le jour se pose, le point de la rangée suit), mais il se fait à la volée : trois
essais maison successifs (une pile de cartes décalée à la main, un `DragGesture` simultané dans le `ScrollView` vertical de la page, un
seuil, une prévision de fin, une résistance au bout) ne peuvent ni être repris en cours de route ni avoir l'élan et le rebond du système, et
le geste se dispute avec le défilement vertical. On ne peut pas, d'ici, mesurer « le ressenti » : le code est donc passé à ce que le système
sait faire. Le carrousel est un `ScrollView(.horizontal)` calé sur les cartes (`scrollTargetBehavior(.viewAligned)`,
`scrollPosition`, `contentMargins`) ; la rangée des jours le commande par `choix`. `HZCarrousel` ne garde que le mouvement de la rangée
(340 ms) ; `CarrouselDuPlanTests` (la décision du cran) est supprimé avec la fonction qu'il testait.

Deux choses vues sur la même vidéo et pas encore traitées : toucher la carte d'un jour de repos ouvre la feuille d'une « Footing récap »
(la carte dit « Off », la feuille décrit une séance : les deux ne viennent pas de la même définition du repos), et la bande blanche du
bas, sous la barre flottante, est coupée (« Passer à un objectif » passe sous la barre).

**Vérifié sur la capture CI (21 novembre, 19h58).** Plan natif : dimanche à l'ouverture est à 36 points du bord avec samedi qui dépasse à
gauche (la place vide après la dernière carte valait 0 : `containerRelativeFrame` rend la largeur du défilement SANS ses marges de
contenu), jeudi à 36 points avec la voisine à droite, et un balayage réel (`plan-glisse`) pose samedi à 36 points et fait passer la
pastille de la rangée sur « S ». Reste à juger sur l'appareil : l'élan, la reprise du geste, le rebond. Build #679 (le Plan natif avec
le défaut de placement de dimanche) distribué ; le correctif de dimanche est sur la branche.

**Live Activity : la carte 2 de la maquette (22 novembre).** Charlotte a dit que la Live Activity ne ressemblait pas aux maquettes ; sa capture
de l'écran verrouillé montrait la carte 1 (deux colonnes), pas la carte 2 (chrono en fonte d'affichage, barre pleine largeur, tuiles côte à côte),
que j'avais écartée parce que la pile mesurait ~172 points pour un plafond d'iOS d'environ 160, sans le lui dire. Elle a choisi la carte 2.
Construite en resserrant le corps du chrono (46, `chronoAffichage`), les marges (12) et l'espace entre rangées (6). Le test de rendu REFUSE
toute carte de plus de 158 points : mesurées en CI, 152 (en direct, en pause, titre long), 154 (terminée), 134 (sans durée prévue).
L'île dynamique n'a pas bougé. Non vérifié : le rendu réel d'iOS (ses marges, ses coins) et la hauteur réelle sur l'appareil.

## Ce qui restait après le Plan et la Live Activity (22 novembre)

**La carte de repos du Plan ouvrait la feuille d'une séance.** Cause : en COURSE LIBRE (la vidéo montrait « Mode course libre »), `weekSessions` est
celle d'un ancien programme et `todaySession` un modèle choisi à part. « Ta semaine » dessinait sept cartes de ce plan mort, dont un
« Off / Jour de repos » aujourd'hui, et la feuille lisait `todaySession` : « Footing récap ». En course libre, le Plan montre maintenant UNE
carte, la séance proposée aujourd'hui (`PlanSemaineModele.joursEnCourseLibre`, testée), sans la rangée des sept jours, sans le bandeau qui parle de
glisser, sans « Déplacer », et sans compter de séances d'un programme qui n'existe plus.

**Le bandeau blanc sous la barre flottante : pas un défaut du code.** Le canvas a la même composition : la feuille blanche commence là où flotte la
barre, et la page se défile. Laissé tel quel.

**Widget moyen :** l'anneau passe de 84 à 78 points et « bouclés » reprend son écart (le rendu CI le montrait collé). **Île dynamique :** son chrono prend la
fonte d'affichage de la carte. **DESIGN.md** décrit désormais le widget, la Live Activity et leur contrôle en image (§ 4.6).

## Le balayage du Plan, quatrième essai (22 novembre) : « toujours pas fonctionnel » (build 682)

Charlotte, sur le build 682 : plusieurs cartes, la rangée des jours fait glisser la carte, le doigt ne la fait pas bouger. Le défilement
PROGRAMMÉ marche, le défilement au doigt non : la capture CI (balayage par coordonnées) ne peut donc pas l'attraper. Deux suspects, retirés ensemble
faute de pouvoir les séparer d'ici : (1) la liaison `scrollPosition` FABRIQUÉE (lue depuis `choisi`, écrite avec des garde-fous), remplacée par
`$choix` lui-même, avec le retour tactile dans un `onChange` ; (2) un `Button` par carte, remplacé par un toucher (`onTapGesture`) : un bouton
posé sur chaque carte peut se disputer le geste avec le défilement qui les porte. `scrollDisabled` ne coupe plus que s'il n'y a qu'une carte.
Non vérifié : tout ce qui touche au doigt. À essayer sur l'appareil avec le build suivant.

**Correction (22 novembre) : la course libre garde SA SEMAINE.** Le build 682 réduisait « Ta semaine » à une seule carte en course libre ; Charlotte :
« il n'y a plus qu'une seule carte là ». C'était une décision que je n'avais pas à prendre : les sept cartes se parcourent, c'est le carrousel. Maintenant
`joursEnCourseLibre(semaine:seance:…)` laisse la semaine telle quelle et fait seulement prendre à AUJOURD'HUI la séance proposée (la carte ne dit plus « Off »
quand la feuille décrit un footing). Il ne reste qu'une carte que sans semaine du tout. La rangée des sept jours, le bandeau et « Déplacer » reviennent
dès qu'il y a plusieurs cartes ; le sous-titre compte les séances visibles sur les cartes.

**Confirmé sur l'appareil (22 novembre, build 684) : le balayage du Plan fonctionne**, au doigt, et la semaine entière est revenue en course libre. Cause la plus
probable du défaut des builds 679 à 682, non isolée : la liaison `scrollPosition` fabriquée et/ou le `Button` par carte (retirés ensemble). Le ressenti
(élan, reprise du geste) est validé par Charlotte : « ça fonctionne parfaitement ».

## Le rose de l'app devient celui du logo (22 novembre) : choix « B » de Charlotte

Charlotte : « le logo n'a plus du tout la même couleur que l'app, j'aimais bien le rose du logo ». L'icône est un dégradé de `#FC105E` à `#7F5AFB` ; l'app avait
`#FF2E6E` (le rose du canvas) depuis le 19 novembre. Trois options montrées sur une planche ; elle a choisi B : l'icône garde son dégradé (c'est le logo, le
seul dégradé de Haizo), l'app reste en aplats et prend `#FC105E`. Changé : `HZAccent.rose`, `AccentColor`, `WG.rose` (widget, Live Activity), `WT.rose` (montre),
`DESIGN.md` § 2.1 et § 10. L'encre sombre sur le rose (`#2B0011`) tient : 4,8:1 dessus, contre 3,9:1 pour du blanc ; le grand chiffre dans l'accent passe 3:1 sur
blanc et 5,4:1 sur noir. Le choix d'accent (violet, bleu, vert) et les teintes d'intensité du Plan ne changent pas. À recapturer : la montre (empreinte du code), et les
captures de la fiche App Store qui montrent l'ancien rose, au prochain passage de `captures.yml`.

## La montre : la course, la pause et le résumé, photographiés pour la première fois (22 novembre)

Une graine de lancement DEBUG (`HaizoWatch/WatchCaptureSeed.swift`, `--ecran=course|pause|resume`) pose l'état d'une sortie sans capteur ; `montre.yml` les
photographie dans les trois langues (`appstore/raw-montre/<langue>/2-course.png`, `3-pause.png`, `4-resume.png`, chiffres de démonstration : 24:18, 4,32 km).
Défaut vu à la première capture du résumé : la phrase du bas (« Your debrief is waiting on the iPhone. », deux lignes) était coupée par le bord de l'écran sur un
46 mm. Anneau 108 → 92, jeu intérieur 14 → 10 : la phrase est entière dans les trois langues, le haut du bouton « OK » paraît dessous (il se rejoint à la
couronne). Course et pause : rien à redire, y compris en pause (chrono et barre en gris). Recapture des images livrables (`requis/montre`, `SOURCES.json`) avec le rose
`#FC105E`. Non vu : la montre réelle (couronne, lisibilité au poignet).
