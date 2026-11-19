import SwiftUI

/// A full-screen celebration the moment a badge is genuinely newly earned — until this, an earned
/// badge only ever showed up as a static tile in the `badgeStrip`/`ClubMemberProfileView` grid, the
/// same as one that had been sitting there unlocked for months. `ClubView.syncBadgesIfNeeded` is
/// what tells "just crossed the threshold" apart from "already earned before this feature existed"
/// (via `UserProfile.seenBadgeKeys`/`didBackfillSeenBadges`) and presents this as a `fullScreenCover`.
///
/// UN PLEIN ÉCRAN, PAS UNE FEUILLE : noir comme l'écran d'abonnement, le disque du badge sur
/// l'accent au centre, « Partager ce badge » en pilule blanche et « Continuer » dessous.
struct BadgeUnlockedView: View {
    var badge: ClubBadge
    var onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRevealed = false
    @State private var shareImage: Image?
    @State private var shareRenderFailed = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer(minLength: 0)
                HZBoutonRond(dessin: .fermer, nom: String(localized: "Fermer"), diametre: .outil,
                             fond: HZCouleur.surfaceSombre, cote: HZHub.coteDeLaCroix,
                             trait: HZHub.traitDeLaCroix, action: onDismiss)
            }
            .padding(.horizontal, HZEspace.marge)
            .padding(.top, HZPaywall.hautDePage)

            Spacer(minLength: 0)
            scene
            texte
                .padding(.top, HZClubGestion.sousLaScene)
            Spacer(minLength: 0)

            actions
                .padding(.horizontal, HZEspace.marge)
                .padding(.bottom, HZPaywall.basDePage)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(HZCouleur.blanc)
        .background(HZCouleur.noir.ignoresSafeArea())
        .onAppear {
            Haptics.success()
            if reduceMotion {
                isRevealed = true
            } else {
                withAnimation(.spring(response: HZClubGestion.reponseDuRessort,
                                      dampingFraction: HZClubGestion.amortissementDuRessort)) {
                    isRevealed = true
                }
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(HZClubGestion.attenteAvantLeRendu))
                renderShareCard()
            }
        }
    }

    /// Le disque et ses points de couleur : un par accent de l'app, à des positions fixes (pas
    /// retirées au hasard à chaque rendu, sinon les points tremblent à chaque évaluation du corps).
    private var scene: some View {
        ZStack {
            ForEach(Array(HZClubGestion.confettis.enumerated()), id: \.offset) { index, decalage in
                Circle()
                    .fill(HZAccent.allCases[index % HZAccent.allCases.count].couleur)
                    .frame(width: HZClubGestion.coteDuConfetti, height: HZClubGestion.coteDuConfetti)
                    .offset(x: decalage.x, y: decalage.y)
                    .opacity(isRevealed ? HZClubGestion.opaciteDesConfettis : 0)
            }
            Image(systemName: badge.symbole)
                .font(HZPolice.affichage(HZClubGestion.symboleDeLaCelebration))
                .foregroundStyle(HZCouleur.encreSurAccent)
                .frame(width: HZClubGestion.disqueDeLaCelebration, height: HZClubGestion.disqueDeLaCelebration)
                .background(HZCouleur.accent, in: Circle())
                .scaleEffect(isRevealed ? HZClubGestion.echelleRevelee : HZClubGestion.echelleDeDepart)
                .opacity(isRevealed ? HZHub.opaciteNormale : 0)
                .accessibilityHidden(true)
        }
        .frame(height: HZClubGestion.hauteurDeLaScene)
    }

    private var texte: some View {
        VStack(spacing: HZEspace.entrePilules) {
            Text("Badge débloqué")
                .hzTexte(.c14, .gras)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
            Text(badge.name)
                .hzAffichage(.titreDeReglages)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(badge.detail)
                .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, HZEspace.marge)
        .accessibilityElement(children: .combine)
    }

    private var actions: some View {
        VStack(spacing: HZEspace.entreCommandes) {
            if let shareImage {
                ShareLink(
                    item: shareImage,
                    preview: SharePreview(badge.name, image: shareImage)
                ) {
                    ClubBadgeLibelleDePartage(fond: HZCouleur.blanc, couleur: HZCouleur.encre)
                }
                .buttonStyle(.plain)
            } else if shareRenderFailed {
                // `ImageRenderer.uiImage` can come back nil under memory pressure — same
                // recovery as `RecapView`'s share card: a manual retry, "Continuer" below
                // still works either way if she doesn't bother.
                HZBoutonPilule(libelle: String(localized: "Réessayer"), hauteur: .petite,
                               fond: HZCouleur.blanc, couleur: HZCouleur.encre) { renderShareCard() }
            } else {
                ProgressView()
                    .tint(HZCouleur.blanc)
                    .frame(height: HZHauteurDeBouton.grande.rawValue)
            }
            HZBoutonPilule(libelle: String(localized: "Continuer"), hauteur: .moyenne,
                           fond: HZCouleur.surfaceSombre, couleur: HZCouleur.blanc, etendu: true,
                           action: onDismiss)
        }
    }

    private func renderShareCard() {
        let renderer = ImageRenderer(content: BadgeShareCardView(badge: badge))
        renderer.scale = HZResume.echelleDeRendu
        guard let uiImage = renderer.uiImage else {
            shareRenderFailed = true
            return
        }
        shareImage = Image(uiImage: uiImage)
    }
}
