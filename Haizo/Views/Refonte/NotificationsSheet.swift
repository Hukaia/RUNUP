import SwiftUI
import UIKit
import SwiftData

/// La feuille de la cloche : toutes les notifications, marquées lues à l'ouverture.
struct NotificationsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppNotification.timestamp, order: .reverse) private var notifications: [AppNotification]

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Notifications")) {
            ScrollView {
                if notifications.isEmpty {
                    // Était une zone de défilement vide sous le titre, sans un mot : tous les
                    // autres écrans de liste disent au moins quelque chose ici.
                    HZPhrase(texte: String(localized: "Tes séances, tes séries et l'activité du club apparaîtront ici."),
                             titre: String(localized: "Rien pour l'instant"))
                        .padding(.horizontal, HZEspace.marge)
                        .padding(.top, HZCompte.avantLeVide)
                }
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(notifications.enumerated()), id: \.element.persistentModelID) { index, n in
                        ligneDeNotification(n, filet: index < notifications.count - 1)
                    }
                }
                .padding(.horizontal, HZEspace.marge)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            for n in notifications where !n.read { n.read = true }
        }
    }

    private func ligneDeNotification(_ n: AppNotification, filet: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: HZMesuresDeLigne.ecart) {
                pastille(n)
                VStack(alignment: .leading, spacing: HZCompte.entreLesLignesDUneNotification) {
                    Text(n.title)
                        .hzParagraphe(.c16, .semi, interligne: HZBandeauDuCoach.interligne)
                        .foregroundStyle(HZCouleur.encre)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(n.text)
                        .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(n.timestamp, style: .relative)
                        .hzTexte(.c13, .medium)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, HZMesuresDeLigne.margeDeSortie)
            .accessibilityElement(children: .combine)
            if filet {
                Rectangle()
                    .fill(HZCouleur.filetFeuille)
                    .frame(height: HZMesuresDeLigne.filet)
            }
        }
    }

    /// Un disque noir, et dedans la marque de l'app, un symbole ou, à défaut, le texte brut.
    ///
    /// L'icône est ENREGISTRÉE dans la base avec la notification : celles qui sont déjà posées sur
    /// l'appareil portent encore un emoji, et `Image(systemName:)` sur « 🔥 » ne dessine rien du
    /// tout. On regarde donc si la chaîne nomme un symbole, et on retombe sur le texte sinon.
    private func pastille(_ n: AppNotification) -> some View {
        Group {
            if n.icon == "mark" {
                HZIcone(dessin: .marque, cote: HZBandeauDuCoach.marque, couleur: HZCouleur.blanc)
            } else if UIImage(systemName: n.icon) != nil {
                Image(systemName: n.icon)
                    .font(HZPolice.texte(.c15, .semi))
                    .foregroundStyle(HZCouleur.blanc)
            } else {
                Text(n.icon)
                    .hzTexte(.c15, .semi)
            }
        }
        .frame(width: HZDiametre.pas.rawValue, height: HZDiametre.pas.rawValue)
        .background(HZCouleur.encre, in: Circle())
        .accessibilityHidden(true)
    }
}
