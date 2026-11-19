import SwiftUI

/// L'écran d'ouverture : la tuile de la marque, son tracé, puis le mot qui se dévoile.
enum HZLancement {
    static let coteDeLaTuile: CGFloat = 72
    static let ecartTuileMot: CGFloat = 18
    /// Le rayon de la tuile, relatif à son côté.
    static let rayonRelatif: CGFloat = 0.26
    /// La tuile arrive à 88 % de sa taille et grandit jusqu'à 100 %.
    static let echelleDeDepart: CGFloat = 0.88
    static let echellePleine: CGFloat = 1
    static let gainDEchelle: CGFloat = echellePleine - echelleDeDepart
    /// La courbe du tracé des quatre barres.
    static let courbe: (Double, Double, Double, Double) = (0.2, 0.7, 0.3, 1)

    /// L'encre du mot de la marque est celle du kit, pas celle de l'interface : un noir froid, bleu
    /// au-dessus du rouge. Un logo garde son encre, c'est ce qui le distingue d'un mot de l'interface.
    static let encreDeMarque = Color(hex: 0x1A1023)

    /// Les temps, en secondes. L'animation doit être FINIE quand le fondu commence : `check_lancement`
    /// additionne chaque départ et chaque durée contre `fondu`.
    enum Tempo {
        static let traceDuree = 0.75
        static let tuileDepart = 0.42
        static let revealDepart = 0.58
        static let fondu = 1.150
        static let fonduDuree = 0.28
        static let apresFondu = 0.290

        static let replatTenue = 0.650
        static let replatFondu = 0.25
        static let replatApres = 0.260
    }
}
