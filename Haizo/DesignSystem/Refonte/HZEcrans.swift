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
