import SwiftUI

/// De combien le contenu d'une feuille descend sous son bord arrondi.
enum HZRetraitDeFeuille: CGFloat {
    /// L'accueil et le résumé.
    case ample = 24
    /// Le plan, les stats, le club, le profil.
    case courant = 22
    /// La conversation du coach.
    case serre = 20
}

/// LA FEUILLE : la surface blanche qui monte du bas, arrondie de 30 en haut seulement.
///
/// C'est elle qui sépare les deux moitiés de presque tous les écrans du canvas — en haut une
/// couleur pleine ou le noir, avec un seul grand chiffre ; en bas le détail, sur le blanc. Sur la
/// séance en direct et le résumé, elle CHEVAUCHE la carte de la hauteur de son arrondi, pour que
/// la carte passe dessous au lieu de s'arrêter net : `HZRayon.feuille`, posé en marge négative
/// par l'écran qui l'emploie.
///
/// Ses angles sont des quarts de cercle, pas la courbe continue qu'iOS dessine par défaut : le
/// canvas est écrit en CSS, et `border-radius` trace un cercle.
struct HZFeuille<Contenu: View>: View {
    var retrait: HZRetraitDeFeuille = .courant
    var fond: Color = HZCouleur.blanc
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            contenu()
        }
        .padding(.top, retrait.rawValue)
        .padding(.horizontal, HZEspace.marge)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fond, in: UnevenRoundedRectangle(topLeadingRadius: HZRayon.feuille,
                                                     topTrailingRadius: HZRayon.feuille,
                                                     style: .circular))
    }
}

/// Le titre d'une section, et le lien qui lui fait face quand il y en a un.
struct HZTitreDeSection: View {
    let titre: String
    var lien: String? = nil
    var action: () -> Void = {}

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(titre)
                .hzAffichage(.section)
                .foregroundStyle(HZCouleur.encre)
            Spacer(minLength: HZEspace.entreCommandes)
            if let lien {
                Button(action: action) {
                    Text(lien)
                        .hzTexte(.c14, .gras)
                        .foregroundStyle(HZCouleur.encre)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// LE BANDEAU DU COACH : sa marque dans un disque noir, et une phrase.
///
/// Il revient sur l'accueil, le plan et le résumé, toujours en tête de feuille : c'est la voix
/// du coach là où elle a quelque chose à dire sur ce qu'on regarde.
struct HZBandeauDuCoach: View {
    let texte: String

    var body: some View {
        HStack(spacing: HZBandeauDuCoach.ecart) {
            HZIcone(dessin: .marque, cote: HZBandeauDuCoach.marque, couleur: HZCouleur.blanc)
                .frame(width: HZDiametre.pas.rawValue, height: HZDiametre.pas.rawValue)
                .background(HZCouleur.encre, in: Circle())
            Text(texte)
                .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.encre)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, HZEspace.groupe)
        .padding(.vertical, HZEspace.tuile)
        .background(HZCouleur.surfaceClaire,
                    in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
        .accessibilityElement(children: .combine)
    }

    static let ecart: CGFloat = 12
    static let marque: CGFloat = 16
    static let interligne: CGFloat = 1.35
}
