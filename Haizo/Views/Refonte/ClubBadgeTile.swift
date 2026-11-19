import SwiftUI

/// One badge tile's real state — `key` matches `ClubBadgeCatalog`/the server's `KNOWN_BADGES`, so
/// this same shape works whether the progress/earned state came from local data (mine, in
/// `ClubView`) or from another member's synced `badgeKeys` (`ClubMemberProfileView`). Internal
/// (not private) since both files construct one.
struct ClubBadge: Identifiable {
    // `key` is already unique per badge definition (`ClubBadgeCatalog.all`) — a fresh `UUID()`
    // here meant every rebuild of `badges` (any body re-evaluation: a kudos tap, tab switch, RSVP)
    // handed `ForEach` an entirely new identity for every tile, defeating diffing and triggering
    // spurious re-animations even when nothing about the badges actually changed.
    var id: String { key }
    var key: String
    /// Le nom d'un symbole SF — voir `ClubBadgeCatalog.Definition.symbole`.
    var symbole: String
    var name: String
    var detail: String
    /// nil for binary badges ("Lève-tôt") or whenever there's no local data to compute progress
    /// from (any badge on someone else's profile).
    var progressText: String?
    var earned: Bool
    /// LA MÊME AVANCÉE, EN NOMBRE — 0 à 1.
    ///
    /// `progressText` rend « 2/3 jours », ce qui se lit mais ne se compare pas : pour désigner
    /// LE badge dont on est le plus proche, il faut pouvoir les classer. Et une chaîne traduite
    /// ne se range pas — « 18,3/21 km » et « 2/3 jours » n'ont ni la même unité ni le même
    /// séparateur décimal selon la langue.
    ///
    /// En dernier et avec un défaut : les autres constructeurs de cette structure
    /// (`PublicProfileView`, qui n'a pas l'historique de la personne) continuent de compiler
    /// sans y toucher.
    var fraction: Double?
}

/// LE DISQUE D'UN BADGE : noir avec son symbole en blanc quand il est gagné, gris clair et symbole
/// gris sinon. C'est le dessin du Profil, écrit une fois pour les quatre endroits qui montrent un
/// badge (la grille, la feuille de détail, la page d'un coureur, la célébration).
struct ClubBadgeDisque: View {
    let badge: ClubBadge
    var cote: CGFloat = HZProfil.disqueDeBadge
    var police: Font = HZAffichage.badge.fonte

    var body: some View {
        Image(systemName: badge.symbole)
            .font(police)
            .foregroundStyle(badge.earned ? HZCouleur.blanc : HZCouleur.secondaireSurClair)
            .frame(width: cote, height: cote)
            .background(badge.earned ? HZCouleur.noir : HZCouleur.surfaceClaire, in: Circle())
            .accessibilityHidden(true)
    }
}

/// LA GRILLE DES BADGES : quatre colonnes, le disque et son nom dessous, comme sur le Profil. Toucher
/// un badge le remet à l'appelant, qui ouvre sa feuille de détail.
struct ClubBadgeGrille: View {
    let badges: [ClubBadge]
    let choisir: (ClubBadge) -> Void

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: HZProfil.entreBadges),
                                 count: HZProfil.colonnesDeBadges),
                  spacing: HZProfil.entreRangeesDeBadges) {
            ForEach(badges) { badge in
                Button(action: { choisir(badge) }) {
                    VStack(spacing: HZProfil.sousUnBadge) {
                        ClubBadgeDisque(badge: badge)
                        Text(badge.name)
                            .hzParagraphe(.c12, .semi, interligne: HZProfil.interligneDeBadge)
                            .foregroundStyle(badge.earned ? HZCouleur.encre : HZCouleur.secondaireSurClair)
                            .multilineTextAlignment(.center)
                            .lineLimit(HZProfil.lignesDeNomDeBadge)
                    }
                    // Une rangée prend la hauteur de son nom le plus long ; sans ceci, un nom sur une
                    // ligne centre sa pastille plus bas que sa voisine dont le nom en prend deux.
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(badge.earned
                                    ? String(localized: "\(badge.name), débloqué")
                                    : String(localized: "\(badge.name), à débloquer"))
            }
        }
    }
}

/// « Partager ce badge », en pilule : le même libellé sous la feuille de détail (pilule noire sur
/// blanc) et sous la célébration (pilule blanche sur noir).
struct ClubBadgeLibelleDePartage: View {
    var fond: Color = HZCouleur.encre
    var couleur: Color = HZCouleur.blanc

    var body: some View {
        HStack(spacing: HZEspace.entrePilules) {
            HZIcone(dessin: .partager, cote: HZResume.cotePartage, couleur: couleur)
            Text("Partager ce badge")
                .hzTexte(.c16, .gras)
                .foregroundStyle(couleur)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: HZHauteurDeBouton.grande.rawValue)
        .background(fond, in: Capsule())
        .contentShape(Capsule())
    }
}

/// Was previously just a static, untappable tile — no way to know what a badge required or how
/// close she was to earning a locked one. Tapping now opens this real detail instead. Internal so
/// `ClubMemberProfileView` can reuse it for other members' badges too.
///
/// C'est une FEUILLE : l'appelant lui pose
/// `.hzFeuille(detents: [.height(HZClubGestion.hauteurDuDetailDeBadge)])`.
struct BadgeDetailView: View {
    var badge: ClubBadge
    /// Rendue à la demande, et seulement pour un badge gagné : `ImageRenderer` coûte un rendu
    /// complet hors écran, inutile pour une tuile verrouillée qui ne sera pas partagée.
    @State private var shareImage: Image?
    @State private var shareRenderFailed = false

    var body: some View {
        HZFeuilleModale(titre: badge.name) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.groupe) {
                    entete
                    Text(badge.detail)
                        .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                        .fixedSize(horizontal: false, vertical: true)
                    partage
                }
                .padding(.horizontal, HZEspace.marge)
            }
            .scrollIndicators(.hidden)
        }
        .task {
            guard badge.earned, shareImage == nil else { return }
            renderShareCard()
        }
    }

    /// Le disque, l'état du badge et, tant qu'il n'est pas gagné, où l'on en est.
    private var entete: some View {
        HStack(spacing: HZEspace.groupe) {
            ClubBadgeDisque(badge: badge, cote: HZClubGestion.disqueDuDetail,
                            police: HZPolice.texte(.c24, .semi))
            VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
                if badge.earned {
                    HZPilule(texte: String(localized: "Débloqué"), style: .etiquetteGrasse,
                             fond: HZCouleur.accent, couleur: HZCouleur.encreSurAccent)
                } else {
                    HZPilule(texte: String(localized: "Pas encore débloqué"), style: .etiquette,
                             fond: HZCouleur.surfaceClaire, couleur: HZCouleur.secondaireSurClair)
                }
                if let progressText = badge.progressText, !badge.earned {
                    Text(verbatim: progressText)
                        .hzTexte(.c15, .gras, tabulaire: true)
                        .foregroundStyle(HZCouleur.encre)
                }
            }
            Spacer(minLength: 0)
        }
    }

    // La carte partageable existait déjà (`BadgeShareCardView`), mais n'était rendue que
    // par `BadgeUnlockedView` — l'animation de déblocage, vue une fois. Passé cette
    // fenêtre, un badge gagné n'était plus partageable du tout : la seule image que l'app
    // sait fabriquer d'une réussite devenait inatteignable une seconde après l'avoir
    // obtenue.
    @ViewBuilder private var partage: some View {
        if badge.earned {
            if let shareImage {
                ShareLink(item: shareImage, preview: SharePreview(badge.name, image: shareImage)) {
                    ClubBadgeLibelleDePartage()
                }
                .buttonStyle(.plain)
            } else if shareRenderFailed {
                // Même récupération que `RecapView` et `BadgeUnlockedView` : `uiImage` peut
                // revenir nil sous pression mémoire, et sans reprise manuelle le bouton
                // resterait absent pour toujours.
                HZBoutonPilule(libelle: String(localized: "Réessayer"), hauteur: .petite,
                               fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre) { renderShareCard() }
            } else {
                ProgressView()
                    .tint(HZCouleur.encre)
                    .frame(maxWidth: .infinity)
                    .frame(height: HZHauteurDeBouton.grande.rawValue)
            }
        }
    }

    @MainActor private func renderShareCard() {
        shareRenderFailed = false
        let renderer = ImageRenderer(content: BadgeShareCardView(badge: badge))
        renderer.scale = HZResume.echelleDeRendu
        guard let uiImage = renderer.uiImage else {
            shareRenderFailed = true
            return
        }
        shareImage = Image(uiImage: uiImage)
    }
}
