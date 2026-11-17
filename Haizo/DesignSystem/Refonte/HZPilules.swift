import SwiftUI

/// La composition d'une pilule de texte : son corps, sa graisse, ses marges.
struct HZStyleDePilule {
    let corps: HZCorps
    let graisse: HZGraisse
    let margeHorizontale: CGFloat
    let margeVerticale: CGFloat
    let tabulaire: Bool

    /// « Aujourd'hui », « Fait », « 1 membre ».
    static let etiquette = HZStyleDePilule(corps: .c13, graisse: .semi, margeHorizontale: 12,
                                           margeVerticale: 6, tabulaire: false)
    /// « Record », « À 400 m de chez toi » : la même, en gras, sur un fond plein.
    static let etiquetteGrasse = HZStyleDePilule(corps: .c13, graisse: .gras, margeHorizontale: 12,
                                                 margeVerticale: 6, tabulaire: false)
    /// « 45 min · 4:22/km · Z3 » : les chiffres d'une séance, alignés.
    static let chiffres = HZStyleDePilule(corps: .c14, graisse: .semi, margeHorizontale: 14,
                                          margeVerticale: 8, tabulaire: true)
    /// « Mode course libre » : un état, en haut d'un écran.
    static let etat = HZStyleDePilule(corps: .c13, graisse: .semi, margeHorizontale: 14,
                                      margeVerticale: 10, tabulaire: false)
}

/// LA PILULE : un mot ou une mesure, dans une capsule. Elle n'est pas un bouton.
///
/// Sur l'accent ou sur une teinte, elle est VOILÉE — un noir à 26 % — et c'est ce voile qui
/// autorise son petit texte blanc. Sur le blanc ou sur le noir, elle est pleine.
struct HZPilule: View {
    let texte: String
    var style: HZStyleDePilule = .etiquette
    var fond: Color = HZCouleur.voile
    var couleur: Color = HZCouleur.blanc

    var body: some View {
        Text(texte)
            .hzTexte(style.corps, style.graisse, tabulaire: style.tabulaire)
            .foregroundStyle(couleur)
            .lineLimit(1)
            .padding(.horizontal, style.margeHorizontale)
            .padding(.vertical, style.margeVerticale)
            .background(fond, in: Capsule())
    }
}

/// Où vit une rangée de filtres, donc de quoi ses pilules sont faites.
enum HZFondDeFiltre {
    /// Sur un écran noir : l'active est blanche, les autres en surface sombre.
    case sombre
    /// Sur une feuille blanche : l'active est noire, les autres en surface claire.
    case clair
    /// Une suggestion, sous une conversation : un simple contour, jamais d'état actif.
    case contour
}

/// UN FILTRE : une pilule qu'on choisit, dans une rangée.
struct HZFiltre: View {
    let libelle: String
    var actif: Bool = false
    var fond: HZFondDeFiltre = .sombre
    var graisse: HZGraisse = .gras
    var margeVerticale: CGFloat = HZFiltre.margeCourante
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(libelle)
                .hzTexte(.c14, graisse, tabulaire: true)
                .foregroundStyle(encre)
                .lineLimit(1)
                .padding(.horizontal, HZFiltre.margeHorizontale)
                .padding(.vertical, margeVerticale)
                .background(remplissage, in: Capsule())
                .overlay {
                    if fond == .contour {
                        Capsule().strokeBorder(HZCouleur.contour, lineWidth: HZFiltre.filet)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(actif ? .isSelected : [])
    }

    private var encre: Color {
        switch fond {
        case .sombre: return actif ? HZCouleur.noir : HZCouleur.blanc
        case .clair: return actif ? HZCouleur.blanc : HZCouleur.encre
        case .contour: return HZCouleur.encre
        }
    }

    private var remplissage: Color {
        switch fond {
        case .sombre: return actif ? HZCouleur.blanc : HZCouleur.surfaceSombre
        case .clair: return actif ? HZCouleur.encre : HZCouleur.surfaceClaire
        case .contour: return HZCouleur.blanc
        }
    }

    static let margeHorizontale: CGFloat = 16
    static let margeCourante: CGFloat = 11
    /// Les périodes des stats sont un point plus basses que les autres filtres.
    static let margeDePeriode: CGFloat = 10
    static let filet: CGFloat = 1
}
