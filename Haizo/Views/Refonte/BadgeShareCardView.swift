import SwiftUI

/// The share card for a freshly unlocked badge — rendered off-screen (via `ImageRenderer` in
/// `BadgeUnlockedView`, same mechanism `RecapView` uses for `RunShareCardView`) into a `UIImage`
/// handed to a `ShareLink`. Unlike the run recap card, a badge has no photo to layer over, so this
/// one is a plain opaque brand card rather than a transparent PNG — the achievement itself is the
/// visual, not something meant to sit on top of a story background.
///
/// UN RENDU FIXE : la carte fait toujours `HZClubGestion.largeurDeLaCarte` sur
/// `HZClubGestion.hauteurDeLaCarte`, quel que soit l'écran qui la fabrique. Elle est noire, comme la
/// célébration qui la propose : le disque porte l'accent, le reste est blanc ou gris sur noir.
struct BadgeShareCardView: View {
    var badge: ClubBadge

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    var body: some View {
        VStack(spacing: HZClubGestion.ecartDeLaCarte) {
            disque
            VStack(spacing: HZClubGestion.ecartDuTexteDeLaCarte) {
                Text("Badge débloqué")
                    .hzTexte(.c14, .gras)
                    .foregroundStyle(HZCouleur.secondaireSurSombre)
                Text(badge.name)
                    .hzAffichage(.titreDEcran)
                    .foregroundStyle(HZCouleur.blanc)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(badge.detail)
                    .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurSombre)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            marque
                .padding(.top, HZClubGestion.avantLaMarque)
        }
        .padding(HZClubGestion.margeDeLaCarte)
        .frame(width: HZClubGestion.largeurDeLaCarte, height: HZClubGestion.hauteurDeLaCarte)
        .background(HZCouleur.noir)
    }

    private var disque: some View {
        Image(systemName: badge.symbole)
            .font(HZPolice.affichage(HZClubGestion.symboleDeLaCarte))
            .foregroundStyle(HZCouleur.encreSurAccent)
            .frame(width: HZClubGestion.disqueDeLaCarte, height: HZClubGestion.disqueDeLaCarte)
            .background(HZCouleur.accent, in: Circle())
    }

    private var marque: some View {
        VStack(spacing: HZClubGestion.ecartDeLaDate) {
            HStack(spacing: HZEspace.entrePilules) {
                HZIcone(dessin: .marque, cote: HZClubGestion.coteDeLaMarque, couleur: HZCouleur.blanc)
                MotDeMarque(tuile: HZClubGestion.coteDeLaMarque).foregroundStyle(HZCouleur.blanc)
            }
            Text(Self.dateFormatter.string(from: .now))
                .hzTexte(.c12, .medium, tabulaire: true)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
        }
    }
}
