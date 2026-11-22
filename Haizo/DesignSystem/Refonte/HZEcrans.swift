import CoreGraphics

/// LES MESURES PROPRES À CHAQUE ÉCRAN DU CANVAS.
///
/// # POURQUOI ELLES SONT ICI ET PAS DANS LES VUES
///
/// « Aucune valeur en dur dans les vues » : une vue de la refonte ne contient pas un nombre.
/// `ci_scripts/check_valeurs.py` le refuse, sans liste d'exceptions. Les blancs qu'un seul écran
/// emploie — les 22 points sous la rangée de commandes de l'accueil, les 26 sous sa semaine —
/// ne sont pas des jetons de rythme : le canvas les règle écran par écran, et les ranger de
/// force sur une grille serait le réinterpréter. Ils portent donc un nom, ici, à côté des jetons
/// partagés de `HZEspace`.
///
/// Chaque valeur est relevée dans le fichier source de l'écran, `project/<Nom>.dc.html`.
/// Ce fichier s'allonge d'un espace de noms par écran refait ; il n'en déclare aujourd'hui que
/// ce que la planche de l'étape 1 remonte.
enum HZAccueil {
    /// Sous la rangée avatar, recherche, cloche : les points de la semaine.
    static let sousLesCommandes: CGFloat = 22
    /// Sous les points de la semaine : la séance du jour.
    static let sousLaSemaine: CGFloat = 26
    /// Sous la ligne de date : le préfixe du nombre (« 5 × »).
    static let sousLaDate: CGFloat = 20
    /// Le grand nombre sort de 5 points à gauche : l'approche du premier chiffre, à 128 points,
    /// le décollerait sinon de la marge où s'alignent les autres lignes.
    static let debordDuNombre: CGFloat = 5
    /// Sous le grand nombre : le nom de la séance.
    static let sousLeNombre: CGFloat = 10
    /// Sous le nom de la séance : la pilule de durée, d'allure et de zone.
    static let sousLeNom: CGFloat = 12
    /// Sous la séance : la rangée des quatre actions.
    static let sousLaSeance: CGFloat = 26
    /// Sous les actions : la feuille.
    static let sousLesActions: CGFloat = 30
    /// Avant « Explorer » et « Dernières sorties » : deux points de plus qu'entre les autres
    /// sections, parce que la rangée qui précède finit sur une légende et non sur une tuile.
    static let avantUneSectionBasse: CGFloat = 30
    /// Sous le titre « Dernières sorties » : la première ligne, qui porte déjà sa propre marge.
    static let sousLeTitreDesSorties: CGFloat = 4
    /// Sous le dernier bloc : de quoi dégager la barre flottante (60 de haut, à 28 du bas) et
    /// laisser un peu d'air au-dessus.
    static let basDePage: CGFloat = 112
    /// La feuille descend toujours jusqu'au bas de l'écran, même quand elle a peu à dire.
    static let hauteurMiniDeLaFeuille: CGFloat = 440
    /// Le très grand chiffre rétrécit jusqu'à la moitié plutôt que de se couper : « 1600 » en 128
    /// points ne tient pas dans 342.
    static let reductionDuNombre: CGFloat = 0.5
    /// Combien de dernières sorties l'écran montre.
    static let sortiesAffichees = 2
    /// L'unité d'une allure de course à pied : la même dans les trois langues.
    static let uniteDAllure = "/km"
    /// Les sorties qui comptent pour « Dernières sorties » : celles des six dernières semaines.
    static let semainesDHistorique = 6
    static let joursParSemaine = 7
    /// `Calendar.weekday` compte de 1 (dimanche) à 7 (samedi) ; avec ce décalage, lundi vaut 0.
    static let decalageDuLundi = 5
}

enum HZPlan {
    /// Entre « Ta semaine » et la ligne de dates.
    static let sousLeTitre: CGFloat = 2
    /// Sous la rangée du bouton de retour : le titre.
    static let sousLeRetour: CGFloat = 18
    /// Sous l'en-tête : la rangée des sept jours.
    static let sousLEntete: CGFloat = 18
    /// La hauteur de la rangée des sept jours.
    static let rangeeDesJours: CGFloat = 44
    /// Sous la rangée des jours : la carte.
    static let sousLesJours: CGFloat = 16
    /// La carte du jour commence à 36 points du bord : la précédente dépasse à gauche.
    static let departDeLaCarte: CGFloat = 36
    /// Sous la carte : « Démarrer » et « Déplacer ».
    static let sousLaCarte: CGFloat = 18
    /// Sous les deux boutons : la feuille.
    static let sousLesBoutons: CGFloat = 26
    /// Sous le bandeau du coach : « Passer à un objectif ».
    static let avantLesObjectifs: CGFloat = 26
    /// Sous les objectifs : l'accès au plan complet.
    static let avantLePlanComplet: CGFloat = 22
    /// La page finit sous la barre flottante : sa hauteur, plus le jeu que le canvas lui laisse.
    static let basDePage: CGFloat = 112
    /// La feuille ne descend pas sous cette hauteur, pour que le blanc remplisse l'écran même
    /// quand il n'y a presque rien dessus.
    static let hauteurMiniDeLaFeuille: CGFloat = 400
    /// Une carte et l'espace qui la sépare de la suivante : le pas du carrousel.
    static var pasDuCarrousel: CGFloat { HZCarteAffiche.largeur + HZEspace.entreTuiles }
    /// Une carte au moins : un nombre de quatre signes ou plus passe au corps réduit.
    static let signesDuGrandNombre = 4
    /// L'opacité d'un bouton éteint, et celle d'un bouton allumé.
    static let eteint: Double = 0.4
    static let pleine: Double = 1
    /// Un objectif proposé à la fois au plus : au-delà, la rangée n'est plus un choix.
    static let objectifsAffiches = 4
}

enum HZStats {
    static let sousLeTitre: CGFloat = 22
    static let debordDuTotal: CGFloat = 6
    static let sousLeTotal: CGFloat = 8
    static let sousLeLibelle: CGFloat = 18
    static let sousLesPeriodes: CGFloat = 26
    static let basDePage: CGFloat = 112
    static let hauteurMiniDeLaFeuille: CGFloat = 400
    static let hauteurDeLaCourbe: CGFloat = 120
    static let traitDeLaCourbe: CGFloat = 4
    static let bordDeLaCourbe: CGFloat = 4
    static let rayonDuRecord: CGFloat = 7
    static let diametreDuRecord: CGFloat = 14
    static let traitDuRecord: CGFloat = 3.5
    static let sousLeHaut: CGFloat = 0.15
    static let etendueDeLaCourbe: CGFloat = 0.7
    static let margeHautDeCarte: CGFloat = 18
    static let margeBasDeCarte: CGFloat = 14
    static let sousLaCourbe: CGFloat = 4
    static let sousLEnteteDeCarte: CGFloat = 12
    static let sousLaSection: CGFloat = 6
    static let apresLesTemps: CGFloat = 16
    static let margeDuChip: CGFloat = 12
    static let margeVerticaleDuChip: CGFloat = 7
    static let uniteDAllure = "/km"
    static let hauteurDesBarres: CGFloat = 70
    static let hauteurMiniDUneBarre: CGFloat = 4
    static let ecartDesBarres: CGFloat = 6
    static let semainesDeCharge = 8
    static let rayonDUneBarre: CGFloat = 4
    static let tailleDuCercleDeLien: CGFloat = 44
    static let coteDeLIconeDeLien: CGFloat = 20
    static let jourParAn = 365
    static let reductionDuTotal: CGFloat = 0.5
    static let pointsMinimumDeCourbe = 2
    static let ecartDeRecord = 0.01
    static let sortiesRetenuesPourUnePrediction = 10
    static let distanceMinimaleDUnePrediction: Double = 2
    static let cinqKm: Double = 5
    static let dixKm: Double = 10
    static let joursDeLaSemaine = 7
    static let joursDuMois = 28
    static let joursDuTrimestre = 90
    static let kilometresParSemi: Double = 21.0975
    static let kilometresParMarathon: Double = 42.195
    static let seuilDuMarathon: Double = 28
    static let paliersDeSerie = [3, 7, 30]
}

/// LE COACH : les mesures de `Coach.dc.html` qui ne sont ni un rayon ni une marge du système.
enum HZCoach {
    static let sousLEntete: CGFloat = 18
    static let sousLesTuiles: CGFloat = 22
    static let ecartDesTuiles: CGFloat = 10
    static let hauteurDeTuile: CGFloat = 104
    static let margeVerticaleDeTuile: CGFloat = 12
    static let retraitDUneValeur: CGFloat = 0.5
    static let largeurMaxDeBulle: CGFloat = 290
    static let ecartDeFil: CGFloat = 12
    static let margeHorizontaleDeBulle: CGFloat = 16
    static let margeVerticaleDeBulleDuCoach: CGFloat = 14
    static let margeVerticaleDeBulleDeLaCoureuse: CGFloat = 12
    static let ecartDeLEntete: CGFloat = 12
    static let coteDeLaMarque: CGFloat = 20
    static let coteDeLaCoche: CGFloat = 16
    static let ecartDesPointsDeFrappe: CGFloat = 4
    static let rebondDuPoint: CGFloat = 3
    static let dureeDuRebond: Double = 0.5
    static let decalageDuRebond: Double = 0.15
    static let avantLesPuces: CGFloat = 16
    static let avantLaSaisie: CGFloat = 12
    static let hauteurDeSaisie: CGFloat = 54
    static let margeGaucheDeSaisie: CGFloat = 18
    static let margeDroiteDeSaisie: CGFloat = 6
    static let envoiEteint: Double = 0.4
    static let coteDeLEnvoi: CGFloat = 18
    static let traitDeLEnvoi: CGFloat = 2.4
    static let ecartDansUneBulle: CGFloat = 12
    static let pointDeFrappe: CGFloat = 6
    static let interligne: CGFloat = 1.4
    /// Les trois seuils de la forme (sur 100) dont le message d'accueil du coach tire sa phrase.
    static let formeAuTop = 85
    static let formeCorrecte = 65
    static let formeMoyenne = 50
}

/// LE CLUB ET SON FIL : les mesures de `Club.dc.html`.
enum HZFil {
    static let sousLEntete: CGFloat = 18
    static let hauteurDeLaCarteDeClub: CGFloat = 214
    static let margeDeLaCarteDeClub: CGFloat = 20
    static let sousLaCarteDeClub: CGFloat = 16
    static let sousLesFiltres: CGFloat = 22
    static let ecartEntreSorties: CGFloat = 22
    static let ecartDeLIdentite: CGFloat = 12
    static let hauteurDeLaCarte: CGFloat = 200
    static let margeGaucheDuNombre: CGFloat = 18
    static let margeBasDuNombre: CGFloat = 14
    static let margeDuLibelle: CGFloat = 20
    static let margeHautDuLibelle: CGFloat = 16
    static let sousLIdentite: CGFloat = 12
    static let sousLaCarteDeSortie: CGFloat = 12
    static let traitDeLaTrace: CGFloat = 6
    /// Le lissage du tracé GPS (Chaikin) : deux passes, chacune coupant un coin au quart.
    static let passesDeLissage = 2
    static let coupeDuLissage: CGFloat = 0.25
    /// En dessous, un tracé n'a pas de coins à couper.
    static let pointsMinimumPourLisser = 2
    static let zoneDeLaTraceX: CGFloat = 0.62
    static let zoneDeLaTraceLargeur: CGFloat = 0.32
    static let zoneDeLaTraceY: CGFloat = 0.1
    static let zoneDeLaTraceHauteur: CGFloat = 0.82
    static let rayonDeLaNote: CGFloat = 20
    static let disqueDeLaNote: CGFloat = 36
    static let coteDeLaCocheDeNote: CGFloat = 18
    static let traitDeLaCocheDeNote: CGFloat = 2.4
    static let coteDuBravo: CGFloat = 18
    static let basDePage: CGFloat = 112
    static let hauteurMiniDeLaFeuille: CGFloat = 400
    static let voileDePhoto: Double = 0.26
    static let tailleDeLAvatar: CGFloat = 44
    static let kilometreMinimum: Double = 0.05
    static let coteDuDrapeau: CGFloat = 16
    static let disqueDuDrapeau: CGFloat = 34
    static let enAttente: CGFloat = 50
    static let sousIdentiteDuTitre: CGFloat = 8
    static let lignesDUneAnnonce = 4
    static let entreesAvantLaFin = 3
    static let coteDeLEclat: CGFloat = 72
    static let traitDeLEclat: CGFloat = 2
    static let rayonDeLOmbreDeLEclat: CGFloat = 14
    static let opaciteDeLOmbreDeLEclat: Double = 0.35
    static let echelleDeDepartDeLEclat: CGFloat = 0.5
    static let ressortDeLEclat: Double = 0.28
    static let amortissementDeLEclat: Double = 0.5
    static let entreeSansRessort: Double = 0.12
    static let sortieDeLEclat: Double = 0.22
    static let dureeDeLEclatEnMillisecondes = 480
    static let sousLesGestes: CGFloat = 10
    static let lignesDuCommentaire = 2
    static let nomsDApplaudisseurs = 2
    static let tapsDuDoubleTape = 2
    static let echelleDeLEclat: CGFloat = 1
    static let moitie: Double = 2
    static let demiTour: Double = 180
    static let moitieDeLEcart: CGFloat = 4
}


/// LES MESURES DU PROFIL, relevées sur le canvas « Profil ».
enum HZProfil {
    /// Les commandes (retour, réglages) à l'identité.
    static let sousLesCommandes: CGFloat = 16
    static let avatar: CGFloat = 84
    /// Le crayon posé sur l'avatar : la photo se change ici. Son liséré est de la couleur du fond.
    static let pastilleDeModification: CGFloat = 28
    static let liseDeModification: CGFloat = 3
    static let entreAvatarEtNom: CGFloat = 16
    /// Le pseudo à la bio.
    static let sousLePseudo: CGFloat = 4
    static let reductionDuNom: CGFloat = 0.6
    static let opaciteEnCours: Double = 0.5
    static let opaciteNormale: Double = 1
    /// De l'identité à la capsule d'objectif.
    static let sousLIdentite: CGFloat = 14
    /// De la capsule aux trois totaux.
    static let sousLaPastille: CGFloat = 22
    static let sousUnTotal: CGFloat = 4
    /// Du dernier total au bord de la feuille.
    static let sousLesTotaux: CGFloat = 26
    static let phasesDUnProgramme = 3

    static let sousLeTitreDeCommunaute: CGFloat = 6
    static let disqueDeDestination: CGFloat = 44
    static let coteDeLIconeDeDestination: CGFloat = 20
    static let attente: CGFloat = 28
    static let dansLInvitation: CGFloat = 10
    static let interligne: CGFloat = 1.35

    static let entreSections: CGFloat = 24
    static let sousLeTitreDeBadges: CGFloat = 14
    static let colonnesDeBadges = 4
    static let entreBadges: CGFloat = 8
    static let entreRangeesDeBadges: CGFloat = 16
    static let disqueDeBadge: CGFloat = 68
    static let sousUnBadge: CGFloat = 8
    static let interligneDeBadge: CGFloat = 1.25

    static let sousLesBadges: CGFloat = 20
    static let dansLeProchain: CGFloat = 10
    static let entreTitreEtAvancee: CGFloat = 2
    /// La bio : deux lignes au plus ; au-delà elle se coupe.
    static let lignesDeBio = 2
    static let hauteurDeLaJauge: CGFloat = 10
    static let jaugePleine: Double = 1
    static let lignesDeNomDeBadge = 2
    /// La photo envoyée au club : une vignette, pas la photo de l'appareil.
    static let coteMaxDeLaPhoto: CGFloat = 240
    static let qualiteDeLaPhoto: CGFloat = 0.6
    /// Sous le dernier bloc : la barre flottante passe devant.
    static let basDePage: CGFloat = 112
}

/// LES MESURES DES RÉGLAGES, relevées sur le canvas « Réglages ».
enum HZReglages {
    static let sousLeTitre: CGFloat = 26
    static let sousUnTitre: CGFloat = 10
    static let hauteurDeLigne: CGFloat = 64
    static let hauteurDeDestination: CGFloat = 58
    static let margeDUneLigneALaPrecision: CGFloat = 14
    static let entreTitreEtPrecision: CGFloat = 2
    static let interligne: CGFloat = 1.35
    /// Sous le titre de l'écran, avant la carte d'offre.
    static let sousLeTitreDePage: CGFloat = 20
    /// En haut de la feuille : le canvas dessine un écran plein, ici c'est une feuille, dont le bord
    /// arrondi tient la place des soixante points de la barre d'état.
    static let hautDeFeuille: CGFloat = 28
    static let basDePage: CGFloat = 40

    static let largeurDInterrupteur: CGFloat = 52
    static let hauteurDInterrupteur: CGFloat = 32
    static let boutonDInterrupteur: CGFloat = 26
    static let margeDuBouton: CGFloat = 3
    static let dureeDeBascule: Double = 0.15

    static let largeurDeLaValeur: CGFloat = 62

    static let margeDeLaPiste: CGFloat = 4
    static let margeVerticaleDuSegment: CGFloat = 7

    static let diametreDePastille: CGFloat = 32
    static let traitDeAnneau: CGFloat = 2
    static let debordDeAnneau: CGFloat = 10
    static let ecartDePastilles: CGFloat = 10

    static let hauteurDeLOffre: CGFloat = 120
    static let margeDeLOffre: CGFloat = 18
    static let hauteurDuBoutonDOffre: CGFloat = 40

    static let pasMin: Double = 2000
    static let pasMax: Double = 20000
    static let pasDuCompteurDePas: Double = 500
    static let caloriesMin: Double = 100
    static let caloriesMax: Double = 1000
    static let pasDuCompteurDeCalories: Double = 50
}

/// LES MESURES DE L'ÉCRAN DE COURSE, relevées sur le canvas « Run ».
enum HZLive {
    /// La carte : 400 sur le canvas, et elle cède la place au panneau sur un écran plus court.
    static let carte: CGFloat = 400
    static let carteMinimale: CGFloat = 180
    static let traitDuTrace: CGFloat = 6
    static let positionsEntreDeuxMisesAJour = 5

    static let entrePointEtEtat: CGFloat = 8
    static let pointEnDirect: CGFloat = 8
    static let grossissementDuPoint: CGFloat = 1.55
    static let opaciteDuPoint: Double = 0.45
    static let dureeDuBattement: Double = 1.1
    static let echelleAuRepos: CGFloat = 1
    static let opaciteAuRepos: Double = 1

    static let reponseDuRessort: Double = 0.4
    static let amortissement: Double = 0.85
    static let reponseDuDecompte: Double = 0.3
    static let amortissementDuDecompte: Double = 0.7
    static let echelleDuDecompte: CGFloat = 1.35
    static let sousLeDecompte: CGFloat = 10

    /// Le message de l'écran verrouillé reste le temps d'un démarrage, d'un regard au chrono et d'un
    /// geste vers les Réglages. Au-delà, elle court.
    static let secondesDuMessageEcranVerrouille: Double = 45
    static let interligne: CGFloat = 1.35
    static let disqueDuCoach: CGFloat = 34

    static let hautDuPanneau: CGFloat = 22
    static let basDuPanneau: CGFloat = 8
    static let entreMesuresEtCommandes: CGFloat = 14

    static let hauteurDesBarres: CGFloat = 6
    static let entreLesBarres: CGFloat = 6
    static let sousLesBarres: CGFloat = 10
    static let sousLesBlocs: CGFloat = 14
    static let progressionPleine: Double = 1

    static let reductionDeLAllure: CGFloat = 0.5
    static let debordDeLAllure: CGFloat = 4
    static let entreCibleEtValeur: CGFloat = 2
    static let sousLaCible: CGFloat = 10

    static let sousLAllure: CGFloat = 14
    static let sousLeFiletDesMesures: CGFloat = 16

    static let entreCommandes: CGFloat = 22
    static let coteDuCarre: CGFloat = 18
    static let rayonDuCarre: CGFloat = 4
    static let coteDeLaLecture: CGFloat = 28
    static let barresDePause = 2
    static let largeurDeBarreDePause: CGFloat = 8
    static let hauteurDeBarreDePause: CGFloat = 28
    static let rayonDesBarresDePause: CGFloat = 3
    static let ecartDesBarresDePause: CGFloat = 8
    static let coteDuMicro: CGFloat = 22
    static let margeDuCadenas: CGFloat = 4
}

/// LES MESURES DU RÉSUMÉ, relevées sur le canvas « Résumé ».
enum HZResume {
    static let carte: CGFloat = 380
    /// Sans photo ni tracé : de quoi porter le retour sur le noir, la feuille remonte dessus.
    static let hauteurSansCarte: CGFloat = 150
    static let sousLaDate: CGFloat = 2
    static let sousLaDistance: CGFloat = 4
    static let sousLeTitre: CGFloat = 16
    static let reductionDeLaDistance: CGFloat = 0.5
    static let debordDeLaDistance: CGFloat = 4
    static let disqueDuTrophee: CGFloat = 36
    static let coteDuTrophee: CGFloat = 18
    static let cotePartage: CGFloat = 18
    static let dureeDEntree: Double = 0.3
    static let opaciteEteinte: Double = 0.5
    static let hauteurDeLApercu: CGFloat = 300
    static let hauteurDeLElevation: CGFloat = 80
    static let hauteurDeLaJauge: CGFloat = 6
    static let attenteAvantLeRendu = 450
    static let opacitePleine: Double = 1
    /// La carte de partage est rendue en 3x : une image nette, à la taille logique de 360 par 640.
    static let echelleDeRendu: CGFloat = 3
    /// « Même itinéraire » : une distance à 15 % près de celle de la sortie.
    static let rapportMinimal: Double = 0.85
    /// Un record d'allure ne se prend que sur 2 km au moins : un court footing ne bat pas une vraie sortie.
    static let distanceMinimaleDUnRecord: Double = 2
    /// Même départ : à moins de 150 m l'un de l'autre.
    static let rayonDuMemeDepart: Double = 150
    static let rapportMaximal: Double = 1.15
    static let basDePage: CGFloat = 32

    // La courbe dessinée quand il n'y a pas de GPS : de bas à gauche à haut à droite.
    static let departX: CGFloat = 0.1
    static let departY: CGFloat = 0.82
    static let arriveeX: CGFloat = 0.9
    static let arriveeY: CGFloat = 0.12
    static let controleUnX: CGFloat = 0.25
    static let controleUnY: CGFloat = 0.35
    static let controleDeuxX: CGFloat = 0.55
    static let controleDeuxY: CGFloat = 0.5
}

/// LES MESURES D'EXPLORER, relevées sur le canvas « Explorer ».
enum HZExplorer {
    static let hauteurDuChamp: CGFloat = 58
    static let margeDuDisque: CGFloat = 8
    static let coteDeLaLoupe: CGFloat = 20
    static let coteDesReglages: CGFloat = 18
    static let sousLeChamp: CGFloat = 14
    static let sousLesFiltres: CGFloat = 18

    static let hauteurDeLaCarte: CGFloat = 214
    static let margeDeLaPastille: CGFloat = 16
    static let margeDeLaDistance: CGFloat = 18
    static let sousLaDistance: CGFloat = 14
    static let reductionDeLaDistance: CGFloat = 0.6
    static let traitDuTrace: CGFloat = 5
    // Le tracé reste dans la moitié haute, à droite : la distance, en bas à gauche, ne doit pas le croiser.
    static let traceX: CGFloat = 0.46
    static let traceY: CGFloat = 0.10
    static let traceLargeur: CGFloat = 0.46
    static let traceHauteur: CGFloat = 0.56
    static let moitie: CGFloat = 2

    static let sousLaCarte: CGFloat = 12
    static let sousLeNomDeLaCarte: CGFloat = 2
    static let sousLesCourses: CGFloat = 14

    static let largeurDeLaTuile: CGFloat = 160
    static let hauteurDeLaTuile: CGFloat = 150
    static let margeDeLaTuile: CGFloat = 14
    static let sousLaDistanceDeTuile: CGFloat = 12
    static let entreLesTuiles: CGFloat = 12

    static let basDePage: CGFloat = 112
    static let attente: CGFloat = 40
    /// Le carré de latitude et de longitude autour de la position : 0,1 degré, une dizaine de
    /// kilomètres, la zone qu'une personne parcourt à pied ou en courant sans y penser.
    static let demiCote: Double = 0.1
    static let itinerairesRetenus = 12
    static let disqueDeClub: CGFloat = 44
    static let metresDansUnKilometre: Double = 1000
}

/// LE BILAN DE LA SEMAINE : ce que le haut noir ajoute à celui des Stats.
enum HZRecap {
    /// Du premier au dernier jour d'une semaine.
    static let joursAvantLaFin = 6
    static let dureeDesBarres: Double = 0.5
    static let decalageDesBarres: Double = 0.05
}

/// L'ENTRÉE DANS L'APP : cinq écrans, une question chacun — le nom, l'objectif, les jours, le niveau, le compte.
enum HZEntree {
    static let ecrans = 5
    static let hauteurDUnSegment: CGFloat = 6
    static let ecartDesSegments: CGFloat = 6
    static let sousLaProgression: CGFloat = 28
    static let sousLaQuestion: CGFloat = 8
    static let sousLeTitre: CGFloat = 24
    static let ecartDesReponses: CGFloat = 10
    static let hauteurDUneReponse: CGFloat = 68
    static let basDeLEcran: CGFloat = 12
    static let sousLesReponses: CGFloat = 16
    static let dureeDeLaTransition: Double = 0.25
    /// Du jeu de jours choisi : les rangs de la semaine, lundi à zéro.
    static let joursDeDeux = [2, 6]
    static let joursDeTrois = [1, 3, 6]
    static let joursDeQuatre = [1, 2, 4, 6]
    static let joursDeCinq = [0, 1, 3, 4, 6]
    static let choixDeJours = [2, 3, 4, 5]
    static let jourDeLaSortieLongue = 6
    /// Quatre jours, le choix du milieu : celui que prend le bouton si l'on n'a rien touché.
    static let parDefaut = 4
    /// Les noms des trois questions, pour la mesure.
    static let noms = ["name", "goal", "running_days", "level", "account"]

    /// Les jours de la semaine que dit le nombre choisi.
    static func joursDeCourse(_ nombre: Int) -> Set<Int> {
        switch nombre {
        case choixDeJours[0]: return Set(joursDeDeux)
        case choixDeJours[1]: return Set(joursDeTrois)
        case choixDeJours[3]: return Set(joursDeCinq)
        default: return Set(joursDeQuatre)
        }
    }
    /// Ce que le niveau dit du point de départ, faute de le demander.
    static let minutesEnSemaine = 45
    static let minutesLeWeekEnd = 90
}

/// LE MUR D'ABONNEMENT : noir, plein écran, tout ce que l'App Store exige visible sans défiler.
enum HZPaywall {
    static let hautDePage: CGFloat = 8
    static let basDePage: CGFloat = 12
    static let sousLeTitre: CGFloat = 22
    static let sousLesAvantages: CGFloat = 24
    static let sousLesFormules: CGFloat = 20
    static let disqueDeLaCoche: CGFloat = 26
    static let coteDeLaCoche: CGFloat = 14
    static let reductionDuTitre: CGFloat = 0.5
    static let reductionDuPrix: CGFloat = 0.6
    static let moisParAn: Double = 12
    static let moisParAnEntier = 12
}
