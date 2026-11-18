import SwiftUI

/// LES CINQ ENTRÉES DE LA BARRE, dans l'ordre du canvas.
///
/// L'ancienne barre en portait cinq aussi — Prog, Coach, RUN, Stats, Profil — et ce ne sont pas
/// les mêmes. Le bouton RUN du milieu s'en va : démarrer devient la première des quatre actions
/// de l'accueil. Le profil passe par l'avatar, le plan par les points de la semaine. Explorer et
/// Club, eux, entrent.
enum HZOnglet: String, CaseIterable, Identifiable {
    case aujourdhui, explorer, club, stats, coach

    var id: String { rawValue }

    var dessin: HZDessin {
        switch self {
        case .aujourdhui: return .aujourdhui
        case .explorer: return .recherche
        case .club: return .groupe
        case .stats: return .barres
        case .coach: return .bulle
        }
    }

    var nom: String {
        switch self {
        case .aujourdhui: return String(localized: "Aujourd'hui")
        case .explorer: return String(localized: "Explorer")
        case .club: return String(localized: "Club")
        case .stats: return String(localized: "Statistiques")
        case .coach: return String(localized: "Coach")
        }
    }

    /// Le rectangle d'« Aujourd'hui » est dessiné deux points plus petit que les quatre autres.
    var cote: CGFloat { self == .aujourdhui ? 20 : 22 }

    /// Le trait s'épaissit d'un cran quand l'entrée est choisie — sauf pour la bulle du coach,
    /// que le canvas laisse à 2, et pour « Aujourd'hui », qui est à 2,2 dans les deux états.
    func trait(active: Bool) -> CGFloat {
        switch self {
        case .aujourdhui: return 2.2
        case .coach: return 2
        case .explorer, .club, .stats: return active ? 2.2 : 2
        }
    }
}

/// LA BARRE FLOTTANTE : une pilule noire, cinq entrées, l'active dans une pastille blanche.
///
/// Elle ne touche aucun bord : elle flotte à vingt-huit points du bas, centrée, et le contenu
/// passe dessous. Pas de libellé — chaque entrée a son nom pour VoiceOver.
struct HZBarreFlottante: View {
    @Binding var selection: HZOnglet
    /// Le profil n'est pas une entrée de la barre : on y entre par l'avatar, et le canvas l'y dessine
    /// sans entrée allumée.
    var aucuneActive: Bool = false

    var body: some View {
        HStack(spacing: HZBarreFlottante.ecart) {
            ForEach(HZOnglet.allCases) { onglet in
                let active = !aucuneActive && onglet == selection
                Button {
                    selection = onglet
                } label: {
                    HZIcone(dessin: onglet.dessin, cote: onglet.cote,
                            trait: onglet.trait(active: active),
                            couleur: active ? HZCouleur.encre : HZCouleur.ongletEteint)
                        .frame(width: HZBarreFlottante.largeurDEntree,
                               height: HZBarreFlottante.hauteurDEntree)
                        .background(active ? HZCouleur.blanc : HZCouleur.blanc.opacity(0),
                                    in: Capsule())
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(onglet.nom)
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        .padding(.horizontal, HZBarreFlottante.marge)
        .frame(height: HZBarreFlottante.hauteur)
        .background(HZCouleur.encre, in: Capsule())
    }

    static let hauteur: CGFloat = 60
    static let marge: CGFloat = 8
    static let ecart: CGFloat = 6
    static let largeurDEntree: CGFloat = 52
    static let hauteurDEntree: CGFloat = 44
}
