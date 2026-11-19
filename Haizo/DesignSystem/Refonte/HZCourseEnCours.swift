import SwiftUI

/// Les mesures de la pastille « Course en cours ».
enum HZMesuresDeLaCourse {
    static let cotePoint: CGFloat = 8
    static let margeHorizontale: CGFloat = 18
    static let margeVerticale: CGFloat = 12
    static let ecart: CGFloat = 8
    /// Elle se pose au-dessus de la barre flottante : la hauteur de la barre plus un souffle.
    static let hauteurDeLaBarre: CGFloat = 64
    static let souffle: CGFloat = 12
    static let hauteurMinimale: CGFloat = 44
}

/// LA PASTILLE QUI RAMÈNE À UNE COURSE COMMENCÉE.
///
/// Quand une course est en cours et qu'on a quitté son écran, c'est le seul chemin de retour : la
/// barre flottante n'a plus de bouton de course. Accent plein, encre sur l'accent, chrono en
/// chiffres tabulaires pour que la pastille ne tremble pas à chaque seconde.
struct HZCourseEnCours: View {
    let ecoule: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: HZMesuresDeLaCourse.ecart) {
                Circle().fill(HZCouleur.encreSurAccent)
                    .frame(width: HZMesuresDeLaCourse.cotePoint, height: HZMesuresDeLaCourse.cotePoint)
                Text("Course en cours · \(ecoule)")
                    .hzTexte(.c14, .semi, tabulaire: true)
                    .foregroundStyle(HZCouleur.encreSurAccent)
                    .lineLimit(1)
            }
            .padding(.horizontal, HZMesuresDeLaCourse.margeHorizontale)
            .padding(.vertical, HZMesuresDeLaCourse.margeVerticale)
            .frame(minHeight: HZMesuresDeLaCourse.hauteurMinimale)
            .background(HZCouleur.accent, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
