import SwiftUI

/// RIEN N'EST LANCÉ : le bloc qui dit quoi faire quand le club n'a ni défi, ni sortie, ni kilomètre.
/// Les deux boutons sont ceux que portaient les intertitres disparus.
struct ClubWakeCard: View {
    @Binding var showCreateEvent: Bool
    @Binding var showManagement: Bool

    var body: some View {
        HZPlaque {
            Text("Rien n'est lancé pour l'instant")
                .hzAffichage(.section)
                .foregroundStyle(HZCouleur.encre)
            Text("Un défi à se partager, ou une sortie à proposer : c'est ce qui donne au club une raison de se retrouver cette semaine.")
                .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: HZEspace.entreCommandes) {
                HZBoutonPilule(libelle: String(localized: "Créer un défi"), hauteur: .moyenne,
                               fond: HZCouleur.blanc, couleur: HZCouleur.encre, etendu: true) {
                    showManagement = true
                }
                HZBoutonPilule(libelle: String(localized: "Proposer une sortie"), hauteur: .moyenne,
                               etendu: true) {
                    showCreateEvent = true
                }
            }
        }
    }
}
