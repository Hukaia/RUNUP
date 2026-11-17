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
}

enum HZStats {
    /// Sous la rangée du titre : « Depuis le… ».
    static let sousLeTitre: CGFloat = 22
    /// Le total sort de 6 points à gauche, pour la même raison que le nombre de l'accueil ; il
    /// est plus grand, son approche aussi.
    static let debordDuTotal: CGFloat = 6
    /// Sous le total : « kilomètres courus ».
    static let sousLeTotal: CGFloat = 8
    /// Sous le libellé du total : les quatre périodes.
    static let sousLeLibelle: CGFloat = 18
    /// Sous les périodes : la feuille.
    static let sousLesPeriodes: CGFloat = 26
}
