import CoreGraphics

/// LE PLAN COMPLET : les mesures de l'écran qui montre tout le programme, semaine par semaine.
///
/// Elles se déclarent ici parce qu'une vue de la refonte ne contient pas un nombre (voir
/// `HZEcrans.swift`). Ce qui vient d'un jeton partagé — `HZEspace`, `HZRayon`, `HZHub`, `HZPlan` —
/// n'est pas redéclaré.
enum HZPlanComplet {

    // MARK: - La forme du plan : une barre par semaine

    /// La hauteur d'une colonne de barre, repère compris : c'est aussi sa zone tactile.
    static let hauteurDeLaColonne: CGFloat = 108
    /// La barre de la semaine la plus chargée. Les autres lui sont proportionnelles.
    static let hauteurDesBarres: CGFloat = 84
    /// Une semaine presque vide reste une barre qu'on voit et qu'on touche.
    static let hauteurMiniDeLaBarre: CGFloat = 5
    static let rayonDeLaBarre: CGFloat = 3
    /// Seize semaines dans une largeur d'écran : les barres sont jointives.
    static let ecartDesBarres: CGFloat = 4
    static let ecartBarreEtRepere: CGFloat = 6
    /// Le point sous la semaine en cours : il ne dépend pas de la sélection.
    static let repereDeLaSemaine: CGFloat = 4
    /// Le cadre de la semaine choisie, autour de sa barre.
    static let rayonDeLaSelection: CGFloat = 4
    static let traitDeLaSelection: CGFloat = 1.5
    static let margeDeLaSelection: CGFloat = 8
    static let basDeLaSelection: CGFloat = 6
    static let opaciteDeLaSelection: Double = 0.45
    /// Les semaines faites reculent sans disparaître : elles font partie de la forme.
    static let opaciteDesSemainesFaites: Double = 0.3

    // MARK: - Les phases et leur légende

    static let ecartDesSegments: CGFloat = 4
    static let ecartDeLegende: CGFloat = 14
    static let ecartDeLaPastille: CGFloat = 6
    static let pastille: CGFloat = 8
    static let sousLaBarreDePhases: CGFloat = 8

    // MARK: - Le sélecteur de semaine

    /// Un libellé plus long rétrécit avant de se couper.
    static let reductionDuTexte: CGFloat = 0.8

    // MARK: - Une ligne de jour

    static let colonneDuJour: CGFloat = 32
    static let ecartDeLigne: CGFloat = 10
    static let ecartEntreJours: CGFloat = 4
    static let margeVerticaleDeJour: CGFloat = 10
    static let margeHorizontaleDeJour: CGFloat = 10
    /// La bande de couleur de la séance : sept lignes, et la semaine se lit comme une forme.
    static let largeurDeLaBande: CGFloat = 3
    static let hauteurDeLaBande: CGFloat = 34
    static let coteDeLaCoche: CGFloat = 16
    static let traitDeLaCoche: CGFloat = 2.4
    /// Les mesures d'une séance (durée, zone, allure) ne se coupent pas : c'est le titre qui cède.
    static let prioriteDesMesures: Double = 1
    /// L'interligne des titres et des phrases de l'écran, en multiple du corps.
    static let interligne: CGFloat = 1.3
    static let coteDeLIcone: CGFloat = 20

    // MARK: - Ce que l'écran affiche et calcule

    /// L'aperçu estompé du plan, pour qui n'a pas Haizo Plus.
    static let hauteurDeLApercu: CGFloat = 200
    /// Un programme ouvert n'a pas de fin : la page dessine une fenêtre autour de la semaine en
    /// cours — huit semaines avant, sept après, et huit au moins en tout.
    static let semainesPassees = 8
    static let semainesAVenir = 7
    static let semainesMinimum = 8
    /// Une allure s'écrit « 5:30 » : deux parties, et soixante secondes par minute.
    static let partiesDUneAllure = 2
    static let secondesParMinute: Double = 60
}
