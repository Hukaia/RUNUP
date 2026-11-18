import SwiftUI

/// TON NIVEAU DANS LE CLUB : le palier, les XP, la jauge. Le calcul vit dans `NiveauDuClub`.
struct ClubLevelCard: View {
    let xpTotal: Int

    var body: some View {
        let palier = NiveauDuClub.palier(xp: xpTotal)
        HZPlaque {
            HStack(spacing: HZEspace.groupe) {
                Text("\(palier.niveau)")
                    .hzAffichage(.chiffreDeProfil)
                    .foregroundStyle(HZCouleur.blanc)
                    .contentTransition(.numericText())
                    .frame(width: HZHub.tailleDuNiveau, height: HZHub.tailleDuNiveau)
                    .background(HZCouleur.encre, in: Circle())
                VStack(alignment: .leading, spacing: 0) {
                    Text("Ton niveau dans le club")
                        .hzTexte(.c13, .semi)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                    Text("Niveau \(palier.niveau) · \(palier.titre)")
                        .hzTexte(.c16, .gras)
                        .foregroundStyle(HZCouleur.encre)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HZJauge(fraction: Double(palier.xpDansLeNiveau) / Double(palier.xpParNiveau),
                    couleur: HZCouleur.accent)
            Text(verbatim: "\(palier.xpDansLeNiveau) / \(palier.xpParNiveau) XP")
                .hzTexte(.c13, .semi, tabulaire: true)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .contentTransition(.numericText())
        }
        .animation(.easeOut(duration: HZHub.dureeDeLaJauge), value: palier.xpDansLeNiveau)
    }
}
