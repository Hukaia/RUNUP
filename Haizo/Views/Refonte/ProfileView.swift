import SwiftUI
import SwiftData
import PhotosUI
import UIKit

/// LE PROFIL, refait d'après le canvas « Profil » : le noir en haut (retour, réglages, l'identité,
/// trois totaux), la feuille blanche dessous (la communauté, les badges, le prochain).
///
/// Le fond, les données et les chemins sont ceux de l'écran d'avant : la photo, l'objectif, les
/// quatre destinations sociales, les badges et leur détail, la connexion. Ce qui change est ce
/// qu'on voit. Le profil n'est plus un onglet : on y entre par l'avatar de l'accueil, et la barre
/// n'y allume donc aucune entrée.
struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \RunRecord.date, order: .reverse) private var runs: [RunRecord]
    private var profile: UserProfile { appState.profile }
    private var auth: AuthService { appState.auth }
    private var clubService: ClubService { ClubService(auth: auth) }

    @State private var showSettings = false
    @State private var selectedBadge: ClubBadge?
    @State private var showSignIn = false
    @State private var avatarPickerItem: PhotosPickerItem?
    @State private var isSavingAvatar = false

    @State private var isLoadingSocial = true
    @State private var board: ClubBoard?
    @State private var friendsList: FriendsList?
    @State private var todaysFriendActivityCount = 0
    /// La plus proche des courses qu'elle prépare : sert la ligne de « Courses ».
    @State private var nextRace: RaceEvent?

    private static let raceDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "d MMMM yyyy"
        return f
    }()

    // MARK: - La page

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: -HZRayon.feuille) {
                hautDePage
                feuille
            }
        }
        .scrollIndicators(.hidden)
        .background {
            VStack(spacing: 0) {
                HZCouleur.noir
                HZCouleur.blanc
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea(edges: .top)
        .statusBarHidden()
        .task { await loadSocialSummary() }
        .refreshable { await loadSocialSummary() }
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn { Task { await loadSocialSummary() } }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .hzFeuille(detents: [.large])
        }
        // La feuille des réglages s'ouvre d'elle-même pour la campagne de captures : elle n'est
        // pas un `AppScreen`, le harnais ne sait pas l'atteindre autrement.
        #if DEBUG
        .onAppear { if CaptureSeed.reglagesDemandes { showSettings = true } }
        #endif
        .sheet(isPresented: $showSignIn) {
            SignInView()
                .hzFeuille(detents: [.large])
        }
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailView(badge: badge).hzFeuille(detents: [.height(HZClubGestion.hauteurDuDetailDeBadge)])
        }
    }

    // MARK: - Le haut, sur le noir

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HZBoutonRond(dessin: .retour, nom: String(localized: "Retour"),
                             fond: HZCouleur.surfaceSombre, trait: HZBoutonRond.traitDuRetour) {
                    appState.go(.home)
                }
                Spacer(minLength: 0)
                HZBoutonRond(dessin: .curseurs, nom: String(localized: "Réglages"),
                             fond: HZCouleur.surfaceSombre) {
                    showSettings = true
                }
            }
            .padding(.horizontal, HZEspace.marge)

            identite
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZProfil.sousLesCommandes)

            pastilleDObjectif
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZProfil.sousLIdentite)

            totaux
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZProfil.sousLaPastille)
        }
        .padding(.top, HZEspace.haut)
        // Le noir se prolonge sous les totaux : c'est lui qui est derrière les coins arrondis de la
        // feuille, qui remonte d'un rayon.
        .padding(.bottom, HZProfil.sousLesTotaux + HZRayon.feuille)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HZCouleur.noir)
        .foregroundStyle(HZCouleur.blanc)
    }

    /// Mon statut, quand le club me l'a rendu. Sans club, pas de bio : la ligne disparaît.
    private var maBio: String? {
        guard let bio = board?.leaderboard.first(where: \.isMe)?.bio, !bio.isEmpty else { return nil }
        return bio
    }

    private var identite: some View {
        HStack(spacing: HZProfil.entreAvatarEtNom) {
            avatar
            VStack(alignment: .leading, spacing: 0) {
                Text(profile.nomComplet)
                    .hzAffichage(.prenom)
                    .lineLimit(1)
                    .minimumScaleFactor(HZProfil.reductionDuNom)
                if let pseudo = auth.currentUser?.username, !pseudo.isEmpty {
                    Text(verbatim: "@\(pseudo)")
                        .hzTexte(.c15, .medium)
                        .foregroundStyle(HZCouleur.secondaireSurSombre)
                }
                if let maBio {
                    Text(maBio)
                        .hzParagraphe(.c13, .medium, interligne: HZProfil.interligne)
                        .foregroundStyle(HZCouleur.secondaireSurSombre)
                        .lineLimit(HZProfil.lignesDeBio)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, HZProfil.sousLePseudo)
                }
            }
            Spacer(minLength: 0)
        }
    }

    /// La photo, ou les initiales sur l'accent. Un toucher ouvre la photothèque ; un appui long
    /// propose de retirer la photo.
    private var avatar: some View {
        PhotosPicker(selection: $avatarPickerItem, matching: .images) {
            Group {
                if let donnees = profile.avatarImageData, let image = UIImage(data: donnees) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Text(HZAvatar.initiales(prenom: profile.name, nom: profile.lastName))
                        .hzAffichage(.initiales)
                        .foregroundStyle(HZCouleur.encreSurAccent)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(HZCouleur.accent)
                }
            }
            .frame(width: HZProfil.avatar, height: HZProfil.avatar)
            .clipShape(Circle())
            .opacity(isSavingAvatar ? HZProfil.opaciteEnCours : HZProfil.opaciteNormale)
            // Ce qui dit que la photo se change : sans lui l'avatar se lit comme un décor. Cette photo
            // est celle que voit tout le club, dans le fil, le classement et les commentaires.
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: isSavingAvatar ? "arrow.triangle.2.circlepath" : "pencil")
                    .font(HZPolice.texte(.c13, .gras))
                    .foregroundStyle(HZCouleur.encre)
                    .frame(width: HZProfil.pastilleDeModification, height: HZProfil.pastilleDeModification)
                    .background(HZCouleur.blanc, in: Circle())
                    .overlay(Circle().strokeBorder(HZCouleur.noir, lineWidth: HZProfil.liseDeModification))
            }
        }
        .buttonStyle(.plain)
        .disabled(isSavingAvatar)
        .accessibilityLabel("Changer la photo de profil")
        .onChange(of: avatarPickerItem) { _, newItem in
            Task { await setAvatar(from: newItem) }
        }
        .contextMenu {
            if profile.avatarImageData != nil {
                Button("Supprimer la photo", role: .destructive) {
                    Task { await removeAvatar() }
                }
            }
        }
    }

    /// L'objectif en cours, dans une capsule. Elle en est aussi le chemin : sans objectif elle
    /// ouvre l'assistant (l'écran d'objectif est en lecture seule), avec un objectif elle ouvre
    /// l'écran de la course.
    private var pastilleDObjectif: some View {
        Button(action: {
            if objectifText == nil { appState.newGoalWizardPresented = true } else { appState.go(.race) }
        }) {
            HZPilule(texte: objectifText ?? String(localized: "Choisir une course à préparer"),
                     style: .etat, fond: HZCouleur.surfaceSombre)
        }
        .buttonStyle(.plain)
    }

    /// Seulement quand un programme ou une course libre est vraiment en cours : en récupération ou
    /// au choix, il n'y a pas d'objectif actif, et montrer celui du dernier programme ferait croire
    /// qu'on le poursuit encore.
    private var objectifText: String? {
        guard profile.programPhase == .active || profile.programPhase == .freerun else { return nil }
        if let raceDate = profile.raceDate {
            return "\(profile.goalDisplay) · \(Self.raceDateFormatter.string(from: raceDate))"
        }
        return profile.goalDisplay.isEmpty ? nil : profile.goalDisplay
    }

    // MARK: - Les trois totaux

    private var totalKm: Double { runs.onFoot.reduce(0) { $0 + $1.distanceKm } }

    /// Trois chiffres posés à même le noir. Avant la première sortie ils seraient trois zéros : à la
    /// place, ce que le programme va faire, qui existe depuis la fin de l'inscription.
    private var totaux: some View {
        let mesures = runs.isEmpty ? mesuresDuProgramme : mesuresDeLaPratique
        return VStack(alignment: .leading, spacing: HZProfil.sousLesTotaux) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(mesures, id: \.libelle) { mesure in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(verbatim: mesure.valeur)
                            .hzAffichage(.chiffreDeProfil)
                            .lineLimit(1)
                            .minimumScaleFactor(HZProfil.reductionDuNom)
                        Text(mesure.libelle)
                            .hzTexte(.c13, .semi)
                            .foregroundStyle(HZCouleur.secondaireSurSombre)
                            .padding(.top, HZProfil.sousUnTotal)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }
            }
            if runs.isEmpty {
                Text("Tes kilomètres, ta série et tes badges apparaîtront ici dès ta première sortie.")
                    .hzTexte(.c13, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurSombre)
            }
        }
    }

    private struct Mesure { let valeur: String; let libelle: String }

    private var mesuresDeLaPratique: [Mesure] {
        let km = Int(totalKm.rounded())
        return [
            Mesure(valeur: String(format: "%.0f", locale: Locale.current, totalKm),
                   libelle: Pluriel.choisir(km, String(localized: "kilomètre"), String(localized: "kilomètres"))),
            Mesure(valeur: "\(profile.streak)",
                   libelle: Pluriel.choisir(profile.streak, String(localized: "jour de suite"),
                                            String(localized: "jours de suite"))),
            Mesure(valeur: "\(earnedBadges.count)",
                   libelle: Pluriel.choisir(earnedBadges.count, String(localized: "badge"),
                                            String(localized: "badges")))
        ]
    }

    /// La durée du programme, ses phases, les jours avant la course : ce qui est vrai avant la
    /// première sortie.
    private var mesuresDuProgramme: [Mesure] {
        let forme = AdaptivePlanEngine.ProgramShape.compute(
            goal: profile.goalId, raceDate: profile.raceDate, from: profile.programStartDate ?? .now)
        var mesures: [Mesure] = []
        if let total = forme.totalWeeks {
            mesures.append(Mesure(valeur: "\(total)",
                                  libelle: Pluriel.choisir(total, String(localized: "semaine"),
                                                           String(localized: "semaines"))))
            mesures.append(Mesure(valeur: "\(HZProfil.phasesDUnProgramme)", libelle: String(localized: "phases")))
        } else {
            mesures.append(Mesure(valeur: "∞", libelle: String(localized: "sans date de fin")))
        }
        if let days = profile.daysUntilRace {
            mesures.append(Mesure(valeur: String(localized: "J-\(days)"), libelle: String(localized: "avant course")))
        }
        return mesures
    }

    // MARK: - La feuille

    private var feuille: some View {
        HZFeuille {
            communaute
            badgesDuProfil
            if let prochain = leProchain, let avancee = prochain.progressText {
                prochainBadge(prochain, avancee: avancee)
            }
        }
        .padding(.bottom, HZProfil.basDePage)
    }

    // MARK: Communauté

    @ViewBuilder private var communaute: some View {
        Text("Communauté").hzAffichage(.section)
        if !auth.isSignedIn {
            invitation(titre: String(localized: "Ton profil prend vie à plusieurs"),
                       texte: String(localized: "Ton classement de club, le fil de tes amis et les sorties de groupe t'attendent ici."),
                       bouton: String(localized: "Se connecter"))
        } else if auth.sessionRejected {
            // Avant le chargement : tant que le jeton est refusé, les lignes ne rendraient rien et
            // tourneraient indéfiniment.
            invitation(titre: String(localized: "Session expirée"),
                       texte: String(localized: "Ta session de trente jours est arrivée au bout. Tes données sont intactes. Reconnecte-toi pour retrouver ton club, tes amis et publier les sorties en attente."),
                       bouton: String(localized: "Me reconnecter"))
        } else if isLoadingSocial {
            ProgressView()
                .tint(HZCouleur.encre)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HZProfil.attente)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                destination(.fil, titre: String(localized: "Le fil"),
                            ligne: String(localized: "Club, abonnements et courses")) {
                    appState.go(.fil)
                }
                destination(.groupe, titre: String(localized: "Amis"), ligne: ligneDesAmis,
                            pastille: pastilleDesDemandes, etiquette: etiquetteDesDemandes) {
                    appState.openFriendsTabOnNextVisit = true
                    appState.go(.club)
                }
                destination(.trophee, titre: String(localized: "Running Club"), ligne: ligneDuClub) {
                    appState.go(.club)
                }
                destination(.drapeau, titre: String(localized: "Courses"), ligne: ligneDesCourses) {
                    appState.openRacesTabOnNextVisit = true
                    appState.go(.club)
                }
                destination(.itineraire, titre: String(localized: "Itinéraires"),
                            ligne: String(localized: "Où courir, ici ou en voyage"), filet: false) {
                    appState.openRoutesTabOnNextVisit = true
                    appState.go(.club)
                }
            }
            .padding(.top, HZProfil.sousLeTitreDeCommunaute)
        }
    }

    private func destination(_ dessin: HZDessin, titre: String, ligne: String,
                             pastille: String? = nil, etiquette: String? = nil,
                             filet: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HZLigneDeListe(titre: titre, sousTitre: ligne, graisse: .gras,
                           marge: HZMesuresDeLigne.margeDeDestination, filet: filet) {
                HZIcone(dessin: dessin, cote: HZProfil.coteDeLIconeDeDestination, couleur: HZCouleur.encre)
                    .frame(width: HZProfil.disqueDeDestination, height: HZProfil.disqueDeDestination)
                    .background(HZCouleur.surfaceClaire, in: Circle())
            } queue: {
                // Les demandes en attente : la seule chose de la liste qu'on ne doit pas manquer.
                if let pastille {
                    HZPilule(texte: pastille, style: .etiquetteGrasse, fond: HZCouleur.accent,
                             couleur: HZCouleur.encreSurAccent)
                        .accessibilityLabel(etiquette ?? pastille)
                }
                HZChevron()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Déconnectée, ou la session expirée : une porte, pas un mur. Dire ce qu'il y a derrière.
    private func invitation(titre: String, texte: String, bouton: String) -> some View {
        VStack(alignment: .leading, spacing: HZProfil.dansLInvitation) {
            Text(titre).hzTexte(.c16, .gras)
            Text(texte)
                .hzParagraphe(.c14, .medium, interligne: HZProfil.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
            HZBoutonPilule(libelle: bouton, hauteur: .petite) { showSignIn = true }
        }
        .foregroundStyle(HZCouleur.encre)
        .padding(HZEspace.groupe)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HZCouleur.surfaceClaire,
                    in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
        .padding(.top, HZProfil.sousLeTitreDeCommunaute)
    }

    // MARK: Badges

    private var badgesDuProfil: some View {
        let ordonnes = earnedBadges + badges.filter { !$0.earned }
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Badges").hzAffichage(.section)
                Spacer(minLength: 0)
                Text("\(earnedBadges.count) sur \(badges.count)")
                    .hzTexte(.c14, .gras, tabulaire: true)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: HZProfil.entreBadges),
                                     count: HZProfil.colonnesDeBadges),
                      spacing: HZProfil.entreRangeesDeBadges) {
                ForEach(ordonnes) { badge in
                    Button(action: { selectedBadge = badge }) {
                        VStack(spacing: HZProfil.sousUnBadge) {
                            Image(systemName: badge.symbole)
                                .font(HZAffichage.badge.fonte)
                                .foregroundStyle(badge.earned ? HZCouleur.blanc : HZCouleur.secondaireSurClair)
                                .frame(width: HZProfil.disqueDeBadge, height: HZProfil.disqueDeBadge)
                                .background(badge.earned ? HZCouleur.noir : HZCouleur.surfaceClaire, in: Circle())
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
            .padding(.top, HZProfil.sousLeTitreDeBadges)
        }
        .padding(.top, HZProfil.entreSections)
    }

    private func prochainBadge(_ badge: ClubBadge, avancee: String) -> some View {
        Button(action: { selectedBadge = badge }) {
            VStack(alignment: .leading, spacing: HZProfil.dansLeProchain) {
                // Sur une ligne quand elle tient ; sinon l'avancée passe sous le nom plutôt que de le tronquer.
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Prochain badge · \(badge.name)")
                            .hzTexte(.c15, .gras)
                        Spacer(minLength: 0)
                        Text(verbatim: avancee)
                            .hzTexte(.c15, .gras, tabulaire: true)
                    }
                    VStack(alignment: .leading, spacing: HZProfil.entreTitreEtAvancee) {
                        Text("Prochain badge · \(badge.name)")
                            .hzParagraphe(.c15, .gras, interligne: HZProfil.interligne)
                        Text(verbatim: avancee)
                            .hzTexte(.c15, .gras, tabulaire: true)
                    }
                }
                // La jauge : la fraction vraie du badge, le reste en gris.
                Capsule()
                    .fill(HZCouleur.contour)
                    .frame(height: HZProfil.hauteurDeLaJauge)
                    .overlay(alignment: .leading) {
                        GeometryReader { geo in
                            Capsule()
                                .fill(HZCouleur.accent)
                                .frame(width: geo.size.width * min(max(badge.fraction ?? 0, 0), HZProfil.jaugePleine))
                        }
                    }
            }
            .foregroundStyle(HZCouleur.encre)
            .padding(HZEspace.groupe)
            .background(HZCouleur.surfaceClaire,
                        in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .padding(.top, HZProfil.sousLesBadges)
    }

    // MARK: - La photo

    /// Resizes to a real thumbnail (240pt max side) before storing — the picker hands back full
    /// camera-resolution photos (several MB), and this is stored locally in SwiftData AND,
    /// base64-encoded, in the club backend's `users.avatar_data` column for every other member's
    /// leaderboard/feed row — keeping it small keeps both cheap.
    private func setAvatar(from item: PhotosPickerItem?) async {
        isSavingAvatar = true
        defer { isSavingAvatar = false }
        guard let item, let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data)
        else { return }
        let resized = uiImage.resized(maxDimension: HZProfil.coteMaxDeLaPhoto)
        guard let jpeg = resized.jpegData(compressionQuality: HZProfil.qualiteDeLaPhoto) else { return }
        await MainActor.run { profile.avatarImageData = jpeg }
        // Only club members can ever see this, so only sync it when there's actually an account —
        // it stays a purely local photo otherwise, same as every other profile field.
        guard auth.isSignedIn else { return }
        let dataURI = "data:image/jpeg;base64,\(jpeg.base64EncodedString())"
        do {
            try await auth.updateAvatar(dataURI: dataURI)
        } catch {
            // The local photo is already saved (see above) — only the club-visible copy failed to
            // sync, worth telling her since it silently used to just never reach other members.
            appState.toast(String(localized: "Photo enregistrée, mais pas encore visible du club : \(PanneReseau.motif(pour: error))."))
        }
    }

    private func removeAvatar() async {
        await MainActor.run {
            profile.avatarImageData = nil
            avatarPickerItem = nil
        }
        guard auth.isSignedIn else { return }
        do {
            try await auth.updateAvatar(dataURI: nil)
        } catch {
            // Mirrors setAvatar's error handling above — the local photo is already cleared, but
            // the server (and every other club member's leaderboard/feed/comments view) still
            // shows the old one until this actually lands, and without this she'd have no signal
            // that the removal didn't take.
            appState.toast(String(localized: "Photo supprimée localement, mais toujours visible du club : \(PanneReseau.motif(pour: error))."))
        }
    }

    // MARK: - Ce que chaque ligne sait dire

    // MARK: Ce que chaque tuile sait dire

    /// Ce qui s'est passé aujourd'hui d'abord : c'est la seule ligne qui donne une raison
    /// d'ouvrir l'écran MAINTENANT. Le nombre d'abonnements ne change pas d'un jour à l'autre.
    private var ligneDesAmis: String {
        if todaysFriendActivityCount > 0 {
            return Pluriel.choisir(todaysFriendActivityCount,
                                   String(localized: "\(todaysFriendActivityCount) sortie aujourd'hui"),
                                   String(localized: "\(todaysFriendActivityCount) sorties aujourd'hui"))
        }
        if let friendsList, !friendsList.following.isEmpty {
            return Pluriel.choisir(friendsList.following.count,
                                   String(localized: "\(friendsList.following.count) abonnement"),
                                   String(localized: "\(friendsList.following.count) abonnements"))
        }
        return String(localized: "Trouve des coureurs à suivre")
    }

    private var pastilleDesDemandes: String? {
        guard let friendsList, !friendsList.incomingRequests.isEmpty else { return nil }
        return "\(friendsList.incomingRequests.count)"
    }

    private var etiquetteDesDemandes: String? {
        guard let friendsList, !friendsList.incomingRequests.isEmpty else { return nil }
        return Pluriel.choisir(friendsList.incomingRequests.count,
                               String(localized: "\(friendsList.incomingRequests.count) demande en attente"),
                               String(localized: "\(friendsList.incomingRequests.count) demandes en attente"))
    }

    /// La prochaine sortie prime sur le nom du club : le nom est écrit sur l'écran d'arrivée, la
    /// sortie a une date et peut se manquer.
    private var ligneDuClub: String {
        if let event = board?.events?.first { return event.title }
        if let club = board?.club {
            return Pluriel.choisir(club.memberCount,
                                   String(localized: "\(club.name) · \(club.memberCount) membre"),
                                   String(localized: "\(club.name) · \(club.memberCount) membres"))
        }
        // La phrase disait « avec un code d'invitation » — un code qui n'existe plus : on
        // rejoint un club en le cherchant par son nom depuis que les codes ont été retirés.
        return String(localized: "Rejoins-en un, ou crée le tien")
    }

    /// « Marathon de Paris · J-162 ». La course la plus proche, celle que le serveur rend en
    /// tête de `mine` — pas un compte de courses suivies, qui ne dirait rien à faire.
    private var ligneDesCourses: String {
        guard let nextRace else { return String(localized: "Trouve celle que tu prépares") }
        guard let jours = nextRace.joursRestants, jours > 0 else { return nextRace.name }
        return String(localized: "\(nextRace.name) · J-\(jours)")
    }

    // MARK: - Les badges, calculés

    /// Les badges du catalogue, gagnés et verrouillés, calculés par `ClubBadgeEngine` — la même
    /// dérivation que l'écran Club, pas une seconde copie.
    private var badges: [ClubBadge] { ClubBadgeEngine.badges(runs: runs, profile: profile) }
    private var earnedBadges: [ClubBadge] { badges.filter(\.earned) }

    /// Le badge non débloqué dont on est le PLUS PRÈS.
    ///
    /// C'est la seule chose que la bande ne pouvait pas dire : sa progression vivait derrière un
    /// tap, dans la feuille de détail d'une tuile qu'il fallait d'abord deviner. Remontée ici,
    /// elle devient la phrase qui donne une raison de recourir — « 2/3 jours » sous le nom du
    /// badge, c'est un objectif ; la même chaîne cachée dans une feuille, c'est une statistique.
    ///
    /// Les badges binaires — « Lève-tôt », « Première sortie » — n'ont pas de progression et
    /// sont donc écartés : ils ne se gagnent pas en s'approchant, ils se gagnent d'un coup.
    private var leProchain: ClubBadge? {
        badges
            .filter { !$0.earned && $0.fraction != nil && $0.progressText != nil }
            .max(by: { ($0.fraction ?? 0) < ($1.fraction ?? 0) })
    }

    // MARK: - Data loading

    // MARK: - Data loading

    private func loadSocialSummary() async {
        guard auth.isSignedIn else { isLoadingSocial = false; return }

        // EN DÉMONSTRATION, LE CACHE EST TOUT — même raison qu'au Club (`ClubView.loadIfSignedIn`).
        //
        // Il n'y a pas de serveur en face d'un simulateur, et la session de démonstration n'est
        // pas un vrai jeton : les quatre requêtes ci-dessous prendraient un 401, donc
        // `markSessionRejected()`, donc toute la section Communauté remplacée par « Session
        // expirée » — dans la capture, en bonne place. `CaptureSeed` a déjà tout posé.
        if Demonstration.enCours {
            board = appState.cachedClubBoard
            friendsList = appState.cachedFriendsList
            nextRace = appState.cachedNextRace
            todaysFriendActivityCount = (appState.cachedClubFeed ?? [])
                .filter { Calendar.current.isDateInToday($0.createdAt) }.count
            isLoadingSocial = false
            return
        }

        isLoadingSocial = true
        // Independent requests, fired concurrently — same reasoning as `ClubView.loadIfSignedIn`:
        // none of these three depends on another's result, so the wait is the slowest single
        // request instead of the sum of all three.
        async let boardAttempt = try? await clubService.fetchBoard()
        async let friendsListAttempt = try? await clubService.fetchFriendsList()
        async let friendsFeedAttempt = try? await clubService.fetchFriendsFeed()
        // La quatrième part en même temps que les trois autres : l'attente reste celle de la plus
        // lente, pas la somme. C'est ce qui permet à la tuile « Courses » de montrer un vrai
        // compte à rebours sans rien coûter à l'ouverture de la page.
        async let racesAttempt = try? await clubService.myRaces()
        let (boardResult, friendsListResult, friendsFeedResult, racesResult) =
            await (boardAttempt, friendsListAttempt, friendsFeedAttempt, racesAttempt)

        board = boardResult
        friendsList = friendsListResult
        nextRace = (racesResult ?? []).first
        todaysFriendActivityCount = (friendsFeedResult ?? []).filter { Calendar.current.isDateInToday($0.createdAt) }.count
        isLoadingSocial = false
    }
}
