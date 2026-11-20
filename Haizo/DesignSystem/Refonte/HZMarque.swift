import SwiftUI

/// LA MARQUE ET LE TRACÉ : la tuile aux quatre barres, et les mesures du tracé qui se dessine.
enum HZMarque {
    static let coteParDefaut: CGFloat = 24
    /// Le rayon de la tuile, relatif à son côté, et le glyphe, relatif à la tuile.
    static let rayonRelatif: CGFloat = 0.26
    static let glypheRelatif: CGFloat = 0.62
    /// Le glyphe est dessiné sur une grille de cent unités.
    static let grilleDuGlyphe: CGFloat = 100
    /// Le mot de la marque fait la moitié de la tuile.
    static let hauteurDuMot: CGFloat = 0.49
    /// Les quatre barres : x de départ, y de départ, x d'arrivée, y d'arrivée, épaisseur, opacité.
    /// Quatre foulées qui montent, de gauche à droite.
    static let barres: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, Double)] = [
        (11.75, 88, 15.5, 74, 14, 0.3),
        (29.25, 88, 36.75, 60, 19, 0.5),
        (49.25, 88, 61.25, 36, 19, 0.75),
        (69.25, 88, 85.75, 12, 19, 1.0)
    ]
    /// Chaque barre démarre un peu après la précédente et se dessine en un peu moins d'une demi-seconde.
    static let decalageDesBarres: Double = 0.18
    static let dureeDUneBarre: Double = 0.46

    // Le tracé d'une course qui se redessine.
    static let traitDuTrace: CGFloat = 4
    static let pointsDuTrace: Int = 220
    static let deux: CGFloat = 2
    static let opaciteDuFond: Double = 0.07
    /// En dessous de ce point d'avancement, la tête du tracé ne se dessine pas encore.
    static let seuilDeDepart: Double = 0.02
    /// La tête et le point d'arrivée : leur rayon est un multiple de l'épaisseur du trait.
    static let rayonDeLaTete: CGFloat = 1.5
    static let rayonDuPoint: CGFloat = 1.35
    static let opaciteDeLaTete: Double = 0.85
    static let traitDuContour: CGFloat = 0.7
    static let debutDeLaTete: Double = 0.01
    static let finDeLaTete: Double = 0.995
    /// L'écart entre deux points qui donne la direction du trait.
    static let pasDeTangente: Double = 0.001
    // Le profil d'altitude.
    static let pointsMinimaux: Int = 2
    static let opaciteDeLAire: Double = 0.12
    static let traitDuProfil: CGFloat = 2
    // La carte d'un tracé : la boîte du parcours, agrandie de 40 %, d'au moins 0,003 degré.
    static let margeDeCarte: Double = 1.4
    static let etendueMinimale: Double = 0.003
}
