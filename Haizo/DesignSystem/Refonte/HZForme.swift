import SwiftUI

/// LES RAYONS — dix, relevés un par un dans le canvas.
///
/// Le brief en nomme quatre (cartes 36, feuilles 30, tuiles 24, groupes 22). Le canvas en porte
/// dix, et la consigne est de reproduire : les six autres ne sont pas des écarts à normaliser,
/// ce sont des objets que le brief ne nommait pas.
enum HZRayon {
    /// La carte-affiche d'un jour, dans le plan.
    static let carte: CGFloat = 36
    /// La carte du club.
    static let carteDeClub: CGFloat = 32
    /// Le haut d'une feuille — et le héros de l'écran Explorer.
    static let feuille: CGFloat = 30
    /// La carte d'une sortie dans le fil, et celle de l'offre dans les réglages.
    static let carteDuFil: CGFloat = 28
    /// Une tuile : séance à venir, record, course, objectif.
    static let tuile: CGFloat = 24
    /// Un groupe de lignes, une tuile de chiffre, une bulle du coach.
    static let groupe: CGFloat = 22
    /// Une tuile de mesure dans le résumé, une ligne d'activité du fil.
    static let mesure: CGFloat = 20
    /// Le bandeau du coach.
    static let bandeau: CGFloat = 18
    /// La proposition du coach, à l'intérieur d'une bulle.
    static let proposition: CGFloat = 16
    /// La vignette carrée d'une sortie, dans une liste.
    static let vignette: CGFloat = 14
    /// Le petit coin d'une bulle de conversation, du côté de celui qui parle.
    static let coinDeBulle: CGFloat = 6
}

/// LES ESPACES qui reviennent d'un écran à l'autre.
enum HZEspace {
    /// La marge des rangées de commandes et de l'intérieur d'une feuille.
    static let marge: CGFloat = 20
    /// La marge des textes posés à même un fond de couleur.
    static let margeDeTitre: CGFloat = 24
    /// L'intérieur d'une tuile.
    static let tuile: CGFloat = 14
    /// L'intérieur d'un groupe ou d'un bandeau.
    static let groupe: CGFloat = 16
    /// Entre deux tuiles d'une rangée qui défile.
    static let entreTuiles: CGFloat = 12
    /// Entre deux commandes d'une même rangée.
    static let entreCommandes: CGFloat = 10
    /// Entre deux pilules d'une rangée de filtres.
    static let entrePilules: CGFloat = 8
    /// Sous le titre d'une section, avant son contenu.
    static let sousUnTitre: CGFloat = 14
    /// Entre deux sections d'une feuille.
    static let entreSections: CGFloat = 28
    /// Ce dont le contenu descend sous l'encart de sécurité du haut. Le canvas pose ses
    /// premières commandes à 60 points du bord, sur un téléphone dont l'encart en fait 59.
    static let sousLEncart: CGFloat = 1
    /// Ce dont la barre flottante se tient au-dessus du bord bas de l'écran.
    static let sousLaBarre: CGFloat = 28
}

extension HZEspace {
    /// Le canvas pose ses premières commandes à 60 points du haut de l'écran.
    static let hautDuCanvas: CGFloat = 60

    /// OÙ COMMENCE LE CONTENU D'UN ÉCRAN, mesuré depuis le bord haut — les écrans de la refonte
    /// peignent jusqu'au bord et se retirent eux-mêmes.
    ///
    /// Soixante points, comme le canvas, sur un téléphone à encoche (encart de 47) comme sur un
    /// téléphone à îlot (encart de 59) : dans les deux cas le contenu passe sous la barre d'état.
    /// Si un appareil réclame un jour un encart plus profond, le contenu descend avec lui.
    static var haut: CGFloat { max(BordsDeLEcran.haut + sousLEncart, hautDuCanvas) }
}
