import SwiftUI

/// LA PAGE DE QUELQU'UN.
///
/// Ouverte depuis n'importe quel nom de l'app — le fil, le classement, une page de course, une
/// liste d'abonnés. Elle est posée à la racine (`ContentRouterView`) et déclenchée par
/// `appState.ouvrirLeProfil(id)` : aucun écran n'a à savoir comment on présente un profil, donc
/// aucun ne peut oublier de le faire.
///
/// # TROIS ÉTATS, ET LA DIFFÉRENCE ENTRE LES DEUX DERNIERS EST TOUT L'OBJET DE L'ÉCRAN
///
///   · chargement, puis échec s'il y a lieu — avec le MOTIF, jamais « vérifie ta connexion » ;
///   · COMPTE PRIVÉ que je ne suis pas : l'en-tête seul, et une phrase qui dit pourquoi le reste
///     n'est pas là. Pas une liste vide, qui ferait croire que la personne ne court pas ;
///   · sinon : ses dernières sorties, avec les mêmes cartes que le fil (`FeedSortieView`).
///
/// Le bouton d'abonnement est la raison d'être de la page pour un compte privé : c'est le seul
/// endroit d'où l'on peut demander à suivre quelqu'un qu'on vient de croiser.
///
/// La page est celle du Profil : le noir en haut (la personne, ses quatre chiffres, le bouton), la
/// feuille blanche dessous (ses badges, ses sorties).
struct PublicProfileView: View {
    var userId: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var page: PublicProfilePage?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var enCours = false
    @State private var selectedBadge: ClubBadge?
    @State private var signalementPresente = false
    @State private var motif = ""
    /// Ce que vise le signalement en cours : `nil` pour la personne (menu du haut), sinon la
    /// sortie dont on a ouvert le menu. « Signaler cette activité » signalait la personne.
    @State private var sortieSignalee: FeedItem?
    /// Les trois gestes des cartes de sortie, présentés D'ICI : cet écran est une couverture, et
    /// une feuille présentée par la racine resterait derrière lui. Ils étaient branchés sur des
    /// fermetures vides, donc « Commenter », « Modifier ma sortie » et « Supprimer cette
    /// activité » s'affichaient et ne faisaient rien.
    @State private var commentairesDe: FeedItem?
    @State private var sortieEnModification: FeedItem?
    @State private var sortieASupprimer: FeedItem?
    @State private var blocageDemande = false

    private var clubService: ClubService { ClubService(auth: appState.auth) }
    private var profil: PublicProfile? { page?.profile }

    private static let inscritDepuis: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    var body: some View {
        HZPage {
            hautDePage
        } contenu: {
            feuille
        }
        .task { if page == nil { await charger() } }
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailView(badge: badge)
                .hzFeuille(detents: [.height(HZClubGestion.hauteurDuDetailDeBadge)])
        }
        .alert("Signaler", isPresented: $signalementPresente) {
            TextField("Pourquoi ?", text: $motif)
            Button("Envoyer") { signaler() }
            Button("Annuler", role: .cancel) { motif = ""; sortieSignalee = nil }
        } message: {
            Text("Ce signalement sera examiné. Merci de préciser ce qui pose problème.")
        }
        // Bloquer se confirme, comme sur le fil, le club et les amis : c'est un geste qui coupe
        // deux personnes l'une de l'autre partout dans l'app, et il partait au premier appui.
        .alert("Bloquer cette personne ?", isPresented: $blocageDemande) {
            Button("Bloquer", role: .destructive) { Task { await bloquer() } }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Vous ne verrez plus rien l'un de l'autre, nulle part dans l'app.")
        }
        .alert("Supprimer cette activité ?",
               isPresented: Binding(get: { sortieASupprimer != nil },
                                    set: { if !$0 { sortieASupprimer = nil } })) {
            // La sortie est lue AVANT la fermeture de l'alerte, qui remet l'état à `nil`.
            Button("Supprimer", role: .destructive) {
                if let sortie = sortieASupprimer { Task { await supprimer(sortie) } }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Elle disparaîtra du fil du club, avec ses applaudissements et commentaires. Tes XP restent acquis.")
        }
        .sheet(item: $commentairesDe) { item in
            ActivityCommentsSheet(
                activityId: item.id,
                currentUserId: appState.auth.currentUser?.id,
                clubService: clubService,
                onCommentPosted: { Task { await charger() } }
            )
            .hzFeuille(detents: [.medium, .large], gereSonBas: true)
        }
        .sheet(item: $sortieEnModification) { item in
            EditActivitySheet(item: item, onSaved: { Task { await charger() } })
                .hzFeuille(detents: [.large], gereSonBas: true)
        }
    }

    // MARK: - Le haut, sur le noir

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZCommandesDuHaut(retour: { dismiss() }) { menuDOptions }
            if let profil {
                entete(profil)
                    .padding(.horizontal, HZEspace.margeDeTitre)
                    .padding(.top, HZProfil.sousLesCommandes)
                if profil.followsMe, !profil.isMe {
                    relation(profil)
                        .padding(.horizontal, HZEspace.margeDeTitre)
                        .padding(.top, HZProfil.sousLIdentite)
                }
                chiffres(profil)
                    .padding(.horizontal, HZEspace.margeDeTitre)
                    .padding(.top, HZProfil.sousLaPastille)
                boutons(profil)
                    .padding(.horizontal, HZEspace.marge)
                    .padding(.top, HZProfil.sousLesTotaux)
            }
        }
    }

    @ViewBuilder private var menuDOptions: some View {
        if let profil, !profil.isMe {
            Menu {
                Button("Signaler cette personne") {
                    motif = ""
                    sortieSignalee = nil
                    signalementPresente = true
                }
                Button("Bloquer", role: .destructive) { blocageDemande = true }
            } label: {
                HZIcone(dessin: .options, cote: HZClubGestion.coteDesOptions, couleur: HZCouleur.blanc)
                    .frame(width: HZDiametre.commande.rawValue, height: HZDiametre.commande.rawValue)
                    .background(HZCouleur.surfaceSombre, in: Circle())
                    .frame(minWidth: HZBoutonRond.zoneTactile, minHeight: HZBoutonRond.zoneTactile)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Plus d'options")
        }
    }

    // MARK: - L'en-tête

    private func entete(_ profil: PublicProfile) -> some View {
        VStack(alignment: .leading, spacing: HZProfil.sousLePseudo) {
            HStack(spacing: HZProfil.entreAvatarEtNom) {
                // Le liséré dit le rond quand la personne n'a pas de photo : ses initiales sont posées
                // sur l'encre, presque aussi noire que le haut de la page.
                HZPhotoDePersonne(urlString: profil.avatarUrl, base64DataURI: profil.avatarBase64,
                                  initiales: HZInitiales.de(profil.name, profil.lastName),
                                  cote: HZProfil.avatar)
                    .overlay(Circle().strokeBorder(HZCouleur.surfaceSombre, lineWidth: HZHub.liseDesAvatars))
                VStack(alignment: .leading, spacing: 0) {
                    Text(profil.nomComplet)
                        .hzAffichage(.prenom)
                        .lineLimit(1)
                        .minimumScaleFactor(HZProfil.reductionDuNom)
                    if let username = profil.username, !username.isEmpty {
                        Text(verbatim: "@\(username)")
                            .hzTexte(.c15, .medium)
                            .foregroundStyle(HZCouleur.secondaireSurSombre)
                    }
                    Text("Inscrit en \(Self.inscritDepuis.string(from: profil.joinedAt))")
                        .hzTexte(.c13, .medium)
                        .foregroundStyle(HZCouleur.secondaireSurSombre)
                }
                Spacer(minLength: 0)
            }
            if let bio = profil.bio, !bio.isEmpty {
                Text(bio)
                    .hzParagraphe(.c13, .medium, interligne: HZProfil.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurSombre)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, HZProfil.sousLePseudo)
            }
        }
    }

    /// « Vous vous suivez » plutôt que deux boutons qui disent la même chose à l'envers.
    private func relation(_ profil: PublicProfile) -> some View {
        HZPilule(texte: profil.jeLaSuis ? String(localized: "Vous vous suivez")
                                        : String(localized: "Te suit"),
                 style: .etiquette, fond: HZCouleur.surfaceSombre, couleur: HZCouleur.blanc)
    }

    private func chiffres(_ profil: PublicProfile) -> some View {
        // Quatre chiffres en rang : ils se lisent ensemble ou pas du tout, aucun n'est désigné.
        HStack(alignment: .top, spacing: 0) {
            chiffre(Distances.km(profil.totalKm), String(localized: "Au total"))
            chiffre("\(profil.runs)", String(localized: "Sorties"))
            chiffre("\(profil.followers)", String(localized: "Abonnés"))
            chiffre("\(profil.following)", String(localized: "Abonnements"))
        }
    }

    private func chiffre(_ valeur: String, _ libelle: String) -> some View {
        VStack(alignment: .leading, spacing: HZProfil.sousUnTotal) {
            Text(verbatim: valeur)
                .hzAffichage(.chiffreDeProfil)
                .lineLimit(1)
                .minimumScaleFactor(HZProfil.reductionDuNom)
            Text(libelle)
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
                .lineLimit(1)
                .minimumScaleFactor(HZAction.retraitDuLibelle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Suivre

    @ViewBuilder
    private func boutons(_ profil: PublicProfile) -> some View {
        if !profil.isMe {
            let dejaSuivi = profil.jeLaSuis || profil.demandeEnvoyee
            HZBoutonPilule(libelle: libelleDuBouton(profil), hauteur: .moyenne,
                           fond: dejaSuivi ? HZCouleur.surfaceSombre : HZCouleur.blanc,
                           couleur: dejaSuivi ? HZCouleur.blanc : HZCouleur.encre,
                           etendu: true) {
                Task { await basculerLAbonnement(profil) }
            }
            .opacity(enCours ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
            .disabled(enCours)
        }
    }

    /// LE LIBELLÉ DIT CE QUE L'APPUI FAIT, PAS CE QUI EST.
    ///
    /// Il affichait « ABONNÉ » et « DEMANDE ENVOYÉE » : deux ÉTATS, sur un bouton dont l'appui
    /// désabonne ou annule la demande (`basculerLAbonnement`). On croyait lire un statut, et on
    /// agissait. C'est la convention de Strava, et elle ne tient que parce qu'on l'a apprise
    /// ailleurs — un bouton annonce ce que son appui fait.
    ///
    /// L'état ne se perd pas pour autant : « se désabonner » implique qu'on est abonnée.
    private func libelleDuBouton(_ profil: PublicProfile) -> String {
        if profil.jeLaSuis { return String(localized: "Se désabonner") }
        if profil.demandeEnvoyee { return String(localized: "Annuler la demande") }
        // Un compte privé ne se suit pas d'un coup : on DEMANDE. Le dire sur le bouton évite la
        // surprise d'un écran qui ne change pas après l'appui.
        return profil.isPrivate ? String(localized: "Demander à suivre") : String(localized: "Suivre")
    }

    // MARK: - La feuille

    @ViewBuilder private var feuille: some View {
        if isLoading {
            ProgressView()
                .tint(HZCouleur.encre)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HZFil.enAttente)
        } else if let loadError {
            HZPhrase(texte: String(localized: "Impossible d'ouvrir ce profil : \(loadError)."))
        } else if let profil {
            VStack(alignment: .leading, spacing: HZProfil.entreSections) {
                badges(profil)
                sorties(profil)
            }
        }
    }

    // MARK: - Badges

    @ViewBuilder
    private func badges(_ profil: PublicProfile) -> some View {
        // Gagnés seulement : une grille de badges VERROUILLÉS sur la page de quelqu'un d'autre
        // raconterait ce qu'il n'a pas fait. Sur ma propre page, c'est un objectif ; sur la
        // sienne, c'est un bulletin.
        let gagnes = ClubBadgeCatalog.all
            .filter { profil.badgeKeys.contains($0.key) }
            .map { ClubBadge(key: $0.key, symbole: $0.symbole, name: $0.name, detail: $0.detail,
                             progressText: nil, earned: true) }
        if !gagnes.isEmpty {
            VStack(alignment: .leading, spacing: HZProfil.sousLeTitreDeBadges) {
                Text("Badges")
                    .hzAffichage(.section)
                    .foregroundStyle(HZCouleur.encre)
                ClubBadgeGrille(badges: gagnes) { selectedBadge = $0 }
            }
        }
    }

    // MARK: - Ses sorties

    private func sorties(_ profil: PublicProfile) -> some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            Text("Ses sorties")
                .hzAffichage(.section)
                .foregroundStyle(HZCouleur.encre)
            if !profil.canSeeRuns {
                // LE CŒUR DE L'ÉCRAN POUR UN COMPTE PRIVÉ. Une liste vide ferait croire que la
                // personne ne court pas ; cette phrase dit pourquoi il n'y a rien, et le bouton
                // au-dessus dit quoi faire.
                HZPhrase(texte: String(localized: "Demande à le suivre pour voir ses sorties."),
                         titre: String(localized: "Ce compte est privé"))
            } else if (page?.items ?? []).isEmpty {
                HZPhrase(texte: String(localized: "Rien de publié pour l'instant."))
            } else {
                LazyVStack(alignment: .leading, spacing: HZFil.ecartEntreSorties) {
                    ForEach(page?.items ?? [], id: \.id) { item in
                        FeedSortieView(
                            item: item,
                            estLaMienne: profil.isMe,
                            applaudir: { Task { await applaudir(item) } },
                            commenter: { commentairesDe = item },
                            modifier: { sortieEnModification = item },
                            supprimer: { sortieASupprimer = item },
                            signaler: {
                                motif = ""
                                sortieSignalee = item
                                signalementPresente = true
                            },
                            bloquer: { blocageDemande = true })
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func charger() async {
        loadError = nil
        // EN DÉMONSTRATION, LE CACHE EST TOUT — même raison qu'au Club et au Profil : il n'y a
        // pas de serveur en face d'un simulateur, et la session de démonstration n'est pas un
        // vrai jeton. Sans ça, la capture ne montrerait qu'une ligne d'erreur.
        if Demonstration.enCours {
            page = appState.cachedPublicProfile
            isLoading = false
            return
        }
        do {
            page = try await clubService.fetchProfile(userId: userId)
        } catch ClubServiceError.badResponse(let code, _) where code == HZClubGestion.introuvable {
            // 404 couvre « n'existe pas » ET « l'un de vous a bloqué l'autre ». Les distinguer
            // ici retirerait au blocage son seul effet utile.
            loadError = String(localized: "ce profil n'est pas accessible")
        } catch {
            loadError = PanneReseau.motif(pour: error)
        }
        isLoading = false
    }

    private func basculerLAbonnement(_ profil: PublicProfile) async {
        enCours = true
        do {
            if profil.jeLaSuis || profil.demandeEnvoyee {
                try await clubService.unfollowUser(userId: profil.id)
            } else {
                _ = try await clubService.followUser(userId: profil.id)
            }
            Haptics.impact(.light)
            await charger()
        } catch {
            appState.toast(String(localized: "Impossible de mettre à jour. Réessaie."))
        }
        enCours = false
    }

    private func applaudir(_ item: FeedItem) async {
        guard let index = page?.items.firstIndex(where: { $0.id == item.id }) else { return }
        do {
            let maintenant = try await clubService.toggleKudos(activityId: item.id)
            page?.items[index].kudoedByMe = maintenant
            page?.items[index].kudos += maintenant ? 1 : -1
            Haptics.impact(.light)
        } catch {
            appState.toast(String(localized: "Impossible d'applaudir. Réessaie."))
        }
    }

    /// Le signalement vise ce qu'on a désigné : la sortie quand il vient du menu d'une carte, la
    /// personne quand il vient du menu du haut. Et il ne dit « envoyé » que s'il l'a été : un
    /// `try?` suivi du message de succès annonçait l'envoi même hors ligne.
    private func signaler() {
        let raison = motif.trimmingCharacters(in: .whitespacesAndNewlines)
        let sortie = sortieSignalee
        motif = ""
        sortieSignalee = nil
        guard !raison.isEmpty else {
            appState.toast(String(localized: "Écris ce qui pose problème pour envoyer le signalement."))
            return
        }
        Task {
            do {
                if let sortie {
                    try await clubService.report(targetType: "activity", targetId: sortie.id, reason: raison)
                } else {
                    try await clubService.report(targetType: "user", targetId: userId, reason: raison)
                }
                appState.toast(String(localized: "Signalement envoyé"))
            } catch {
                appState.toast(String(localized: "Signalement non envoyé. Réessaie."))
            }
        }
    }

    private func supprimer(_ item: FeedItem) async {
        do {
            try await clubService.deleteActivity(activityId: item.id)
            page?.items.removeAll { $0.id == item.id }
        } catch {
            appState.toast(String(localized: "Impossible de supprimer. Réessaie."))
        }
    }

    private func bloquer() async {
        do {
            try await clubService.blockUser(userId: userId)
            appState.toast(String(localized: "\(profil?.name ?? "") ne verra plus rien de toi."))
            dismiss()
        } catch {
            appState.toast(String(localized: "Impossible de bloquer cette personne."))
        }
    }
}
