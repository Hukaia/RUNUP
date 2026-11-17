import SwiftUI

/// LA RANGÉE DES SEPT JOURS DU PLAN, sur le noir.
///
/// Une initiale, et dessous un point à la couleur du jour. Le jour choisi se lit à DEUX choses —
/// son initiale passe en blanc et en gras, son point s'allonge en pilule — pour que la couleur ne
/// porte pas seule ce qui est choisi. Les autres jours sont des points ronds, à la couleur de leur
/// séance : on lit la forme de la semaine avant d'avoir lu un mot.
///
/// Chaque jour est un bouton de la largeur d'un septième de l'écran, sur toute la hauteur de la
/// rangée : bien plus que la pastille qu'il dessine.
struct HZRangeeDesJours: View {
    struct Jour: Identifiable {
        let id: Int
        let initiale: String
        /// « Mardi 17 novembre » : ce que lit VoiceOver, et ce que la carte porte en haut.
        let nom: String
        let point: Color
    }

    let jours: [Jour]
    let choisi: Int
    /// Faux : les jours ne se choisissent pas (le plan est verrouillé).
    var actif: Bool = true
    let choisir: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(jours) { jour in
                Button {
                    choisir(jour.id)
                } label: {
                    colonne(jour, choisi: jour.id == choisi)
                }
                .buttonStyle(.plain)
                .disabled(!actif)
                .accessibilityLabel(jour.nom)
                .accessibilityIdentifier("rangee-des-jours-\(jour.id)")
                .accessibilityAddTraits(jour.id == choisi ? .isSelected : [])
            }
        }
    }

    private func colonne(_ jour: Jour, choisi: Bool) -> some View {
        VStack(spacing: 0) {
            Text(jour.initiale)
                .hzTexte(.c12, choisi ? .gras : .semi)
                .foregroundStyle(choisi ? HZCouleur.blanc : HZCouleur.secondaireSurSombre)
            Spacer(minLength: 0)
            // Le point qui n'est pas choisi remonte d'un point : le canvas le pose ainsi, et la
            // pilule, plus haute, garde le bas de la colonne.
            Capsule()
                .fill(jour.point)
                .frame(width: choisi ? HZRangeeDesJours.pastilleChoisie.width : HZRangeeDesJours.point,
                       height: choisi ? HZRangeeDesJours.pastilleChoisie.height : HZRangeeDesJours.point)
                .padding(.bottom, choisi ? 0 : HZRangeeDesJours.remonteeDuPoint)
        }
        .frame(maxWidth: .infinity)
        .frame(height: HZPlan.rangeeDesJours)
        .contentShape(Rectangle())
    }

    static let point: CGFloat = 8
    static let pastilleChoisie = CGSize(width: 22, height: 10)
    static let remonteeDuPoint: CGFloat = 1
}

/// LE MOUVEMENT DU CARROUSEL DU PLAN : 340 ms, la courbe du canvas — `cubic-bezier(0.2, 0.8, 0.2, 1)`,
/// qui part vite et se pose doucement.
enum HZCarrousel {
    static let animation = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.34)
    /// Au-delà de ce déplacement horizontal, le geste change de carte.
    static let seuilDeGlissement: CGFloat = 40
}
