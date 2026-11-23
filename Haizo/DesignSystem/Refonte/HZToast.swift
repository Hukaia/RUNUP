import SwiftUI

/// Les mesures du message qui passe : une pilule noire, posée au-dessus de la barre flottante.
enum HZToast {
    static let dureeAffichage: Double = 2.2
    static let dureeDeSortie: Double = 0.25
    static let reponseDuRessort: Double = 0.35
    static let amortissement: Double = 0.8
    static let margeHorizontale: CGFloat = 18
    static let margeVerticale: CGFloat = 12
    static let opaciteDeLOmbre: Double = 0.3
    static let rayonDeLOmbre: CGFloat = 16
    static let decalageDeLOmbre: CGFloat = 8
    static let souffle: CGFloat = 14
    /// Deux lignes au plus : au-delà, c'est une alerte qu'il faut, pas un message passager.
    static let lignes = 2
}
