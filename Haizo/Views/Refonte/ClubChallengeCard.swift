import SwiftUI

/// LE DÉFI DU CLUB : un objectif de kilomètres à se partager, avec une date de fin.
struct ClubChallengeCard: View {
    let magasin: ClubStore
    @Binding var showManagement: Bool

    var body: some View {
        if let defi = magasin.board.challenge {
            HZPlaque {
                HStack(alignment: .firstTextBaseline) {
                    Text("Défi du club")
                        .hzTexte(.c13, .semi)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                    Spacer(minLength: HZEspace.entreCommandes)
                    HZPilule(texte: String(localized: "J-\(joursRestants(jusqua: defi.endDate))"),
                             style: .etiquetteGrasse, fond: HZCouleur.accent, couleur: HZCouleur.encreSurAccent)
                }
                Text(defi.title)
                    .hzAffichage(.titreDeTuile)
                    .foregroundStyle(HZCouleur.encre)
                    .fixedSize(horizontal: false, vertical: true)
                HZJauge(fraction: defi.targetKm > 0 ? defi.progressKm / defi.targetKm : 0,
                        couleur: HZCouleur.accent)
                HStack {
                    Text(avancement(defi))
                        .hzTexte(.c14, .semi, tabulaire: true)
                    Spacer(minLength: HZEspace.entreCommandes)
                    Text("ensemble").hzTexte(.c14, .medium)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                }
                .foregroundStyle(HZCouleur.encre)
            }
        } else {
            VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                HZTitreDeSection(titre: String(localized: "Défi du club"), lien: String(localized: "Créer")) {
                    showManagement = true
                }
                HZPhrase(texte: String(localized: "Aucun défi en cours — un objectif de kilomètres à se partager, avec une date de fin."))
            }
        }
    }

    private func joursRestants(jusqua date: Date) -> Int {
        max(0, Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0)
    }

    private func avancement(_ defi: ClubChallenge) -> String {
        let base = "\(Int(defi.progressKm)) / \(Int(defi.targetKm)) km"
        guard defi.targetKm > 0 else { return base }
        let pourcent = Int((defi.progressKm / defi.targetKm * HZHub.centPourcent).rounded())
        return "\(base) — \(pourcent) %"
    }
}
