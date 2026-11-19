import CoreGraphics

/// LA GESTION DU CLUB, LA PAGE D'UN COUREUR ET LES BADGES : les mesures des feuilles et des écrans de
/// `ClubManagementView`, `PublicProfileView`, `ClubBadgeTile`, `BadgeUnlockedView` et
/// `BadgeShareCardView`.
///
/// Les marges, les couleurs et les rayons viennent de `HZEspace`, `HZRayon` et `HZCouleur`, les
/// disques de badge de `HZProfil` : ce qui est ici, c'est ce qu'un seul de ces écrans emploie.
enum HZClubGestion {

    // MARK: - La feuille de détail d'un badge

    /// La hauteur voulue de `BadgeDetailView` (titre, disque, phrase, partage). Le Profil et la page
    /// d'un coureur la posent par `.hzFeuille(detents: [.height(HZClubGestion.hauteurDuDetailDeBadge)])`.
    static let hauteurDuDetailDeBadge: CGFloat = 400
    static let disqueDuDetail: CGFloat = 76

    // MARK: - La page d'un coureur

    /// Le code que le serveur rend pour « ce profil n'existe pas, ou l'un de vous a bloqué l'autre ».
    static let introuvable = 404
    /// Les trois points du menu, sur la pastille ronde du haut.
    static let coteDesOptions: CGFloat = 18

    // MARK: - La gestion du club

    static let lignesDeLaDescription: ClosedRange<Int> = 2...5
    static let lignesDuStatut: ClosedRange<Int> = 1...3
    /// 1080 de large : une bannière occupe toute la largeur de l'écran, et le serveur refuse au-delà
    /// de 500 ko.
    static let coteMaxDeLaCouverture: CGFloat = 1080
    static let qualiteDeLaCouverture: CGFloat = 0.7
    /// Un niveau tous les 250 XP.
    static let xpParNiveau = 250
    /// Un défi dure un mois tant qu'on n'a pas choisi sa date.
    static let joursDUnDefiParDefaut = 30
    /// Ce que montre le champ de la distance cible quand il est vide : un nombre, dans les trois langues.
    static let exempleDeDistance = "200"
    /// La photo d'un membre, en tête de son profil.
    static let avatarDeMembre: CGFloat = 72

    // MARK: - La célébration d'un badge débloqué

    static let hauteurDeLaScene: CGFloat = 180
    static let sousLaScene: CGFloat = 18
    static let disqueDeLaCelebration: CGFloat = 108
    static let symboleDeLaCelebration: CGFloat = 42
    static let coteDuConfetti: CGFloat = 7
    static let opaciteDesConfettis: Double = 0.85
    static let echelleDeDepart: CGFloat = 0.5
    static let echelleRevelee: CGFloat = 1
    static let reponseDuRessort: Double = 0.55
    static let amortissementDuRessort: Double = 0.62
    /// Le rendu de la carte attend ce délai (en millisecondes) : il ne tourne pas pendant l'entrée.
    static let attenteAvantLeRendu = 400
    /// Où tombent les huit points de couleur autour du disque. Fixes, pour qu'ils ne tremblent pas à
    /// chaque évaluation du corps.
    static let confettis: [CGPoint] = [
        CGPoint(x: -72, y: -58), CGPoint(x: 58, y: -70),
        CGPoint(x: -96, y: 10), CGPoint(x: 90, y: -10),
        CGPoint(x: -50, y: 62), CGPoint(x: 66, y: 54),
        CGPoint(x: -16, y: -92), CGPoint(x: 20, y: 88),
    ]

    // MARK: - La carte à partager

    /// Une carte de taille fixe, rendue en image : elle ne dépend pas de l'écran qui la fabrique.
    static let largeurDeLaCarte: CGFloat = 360
    static let hauteurDeLaCarte: CGFloat = 640
    static let margeDeLaCarte: CGFloat = 40
    static let ecartDeLaCarte: CGFloat = 18
    static let ecartDuTexteDeLaCarte: CGFloat = 8
    static let avantLaMarque: CGFloat = 18
    static let disqueDeLaCarte: CGFloat = 132
    static let symboleDeLaCarte: CGFloat = 52
    static let coteDeLaMarque: CGFloat = 22
    static let ecartDeLaDate: CGFloat = 6
}
