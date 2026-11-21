import SwiftUI

/// SEULE DANS SON CLUB : un club prend vie à plusieurs, et la carte le dit en donnant le lien.
struct ClubAloneCard: View {
    let magasin: ClubStore

    var body: some View {
        if let club = magasin.board.club {
            HZPlaque {
                Text(verbatim: Accord.selon(f: String(localized: "Tu es seule dans \(club.name)"),
                                            m: String(localized: "Tu es seul dans \(club.name)")))
                    .hzAffichage(.section)
                    .foregroundStyle(HZCouleur.encre)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Un club prend vie à plusieurs : classement, défis, sorties de groupe. Envoie son lien aux gens avec qui tu cours.")
                    .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)
                ShareLink(item: String(localized: "Rejoins mon club \(club.name) sur Haizo : https://runup-nu.vercel.app/club/\(club.id)")) {
                    HStack(spacing: HZBoutonPilule.ecart) {
                        HZIcone(dessin: .partager, cote: HZBoutonPilule.coteDeLecture, couleur: HZCouleur.blanc)
                        Text("Partager")
                            .hzTexte(HZHauteurDeBouton.moyenne.corps, .gras)
                            .foregroundStyle(HZCouleur.blanc)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: HZHauteurDeBouton.moyenne.rawValue)
                    .background(HZCouleur.encre, in: Capsule())
                    .contentShape(Capsule())
                }
            }
        }
    }
}
