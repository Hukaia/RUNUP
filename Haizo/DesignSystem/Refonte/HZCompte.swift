import SwiftUI

/// LES MESURES DES FEUILLES DU COMPTE ET DES RÉGLAGES SECONDAIRES : « Plus de réglages », la fiche
/// admin, la sauvegarde, le changement de compte, les notifications, le programme, et la carte
/// « réservé à Plus ». Ce qui existe déjà (`HZEspace`, `HZRayon`, `HZReglages`, `HZHub`) n'est pas
/// redéclaré ici : seules les mesures que ces écrans sont seuls à porter.
enum HZCompte {
    // MARK: - La carte « réservé à Plus »

    /// Entre les lignes de la carte, sur un écran entier.
    static let ecartDuVerrou: CGFloat = 12
    /// Les mêmes, dans une section verrouillée au milieu d'un écran qui fonctionne.
    static let ecartDuVerrouCompact: CGFloat = 8
    /// Au-dessus du bouton, en plus de l'écart.
    static let avantLeBoutonDuVerrou: CGFloat = 2
    /// L'aperçu estompé d'une section verrouillée : assez flou pour ne pas se lire.
    static let flouDApercu: CGFloat = 5
    static let opaciteDApercu: Double = 0.45
    /// De quoi reconnaître un graphique sans pouvoir le lire.
    static let hauteurDApercu: CGFloat = 150

    // MARK: - Les notifications

    /// Sous le titre de la feuille, avant la phrase d'une liste vide.
    static let avantLeVide: CGFloat = 8
    static let entreLesLignesDUneNotification: CGFloat = 4

    // MARK: - Le programme

    /// Entre deux jours de la rangée : au plus serré que permet une cible de 44 points sur le
    /// plus petit téléphone pris en charge.
    static let ecartDesJours: CGFloat = 4

    // MARK: - Plus de réglages

    /// Le cycle moyen se règle entre trois semaines et cinq.
    static let cycleMin = 21
    static let cycleMax = 35
    static let pasDuCycle = 1
    /// Le temps de laisser la feuille se poser avant que la capture du cycle y défile.
    static let attenteAvantLeDefilement: Double = 0.4

    /// Les trois refus du serveur à l'enregistrement du pseudo et du nom : déjà pris, mal écrit,
    /// pas autorisé.
    static let pseudoPris = 409
    static let pseudoInvalide = 400
    static let nomRefuse = 422
}
