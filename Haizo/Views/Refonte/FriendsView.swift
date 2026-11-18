import SwiftUI
import UIKit

/// The lighter, club-independent social option (see `SocialView`) — follow real accounts
/// directly, no shared leaderboard/challenges/invite-code "esprit club" required. A follow is
/// completely separate from club membership: someone with no club (or a different one) still
/// shows up here once followed, and her own feed here is powered by `api/friends/*.js`, not
/// `api/clubs/*.js`.
struct FriendsView: View {
    @Environment(AppState.self) private var appState

    @State private var isLoading = true
    @State private var errorMessage: String?
    /// Faux tant que `api/friends/list` n'a pas répondu. Tout ce qui décrit le COMPTE — le
    /// réglage « Compte privé » en tête — en dépend : voir `privacyRow`.
    @State private var listeRecue = false
    @State private var isPrivate = false
    @State private var following: [PublicUser] = []
    @State private var followers: [PublicUser] = []
    @State private var incomingRequests: [PublicUser] = []
    /// Les sorties des gens suivis : elles ne s'affichent plus ici (le fil les montre, filtre « Amis »),
    /// elles disent seulement quand chacun a couru pour la dernière fois.
    @State private var feed: [FeedItem] = []

    @State private var query = ""
    @State private var searchResults: [PublicUser] = []
    @State private var isSearching = false
    /// Le message d'échec de la recherche, ou `nil`. Un booléen ne pouvait porter qu'une seule
    /// explication — et c'était la même devinette qu'ailleurs sur cet écran : « vérifie ta
    /// connexion », y compris quand la session a expiré. Voir `PanneReseau.phrase(pour:)`.
    @State private var searchError: String?
    @State private var searchTask: Task<Void, Never>?

    /// Les gens qu'on n'a pas besoin de chercher — membres de ses clubs non suivis, et abonnés
    /// sans retour. Chargés à l'ouverture, affichés tant que le champ est vide.
    @State private var suggestions: [PublicUser] = []
    @State private var isMatchingContacts = false
    @State private var contactsDenied = false
    /// Les comptes trouvés dans le carnet d'adresses. Un état à part, et non le champ de
    /// recherche : y écrire relancerait une recherche par nom, qui écraserait aussitôt ces
    /// résultats — le champ pilote `scheduleSearch` à chaque frappe.
    @State private var contactMatches: [PublicUser]?

    @State private var showSignIn = false
    @State private var peopleSheet: PeopleSheetKind?
    @State private var reportTarget: ReportTarget?
    @State private var pendingBlock: (userId: String, name: String)?

    private enum PeopleSheetKind: Identifiable, Hashable {
        case following, followers
        var id: Self { self }
    }

    private var auth: AuthService { appState.auth }
    private var clubService: ClubService { ClubService(auth: auth) }
    private var isSearchingMode: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        HZPage {
            hautDePage
        } contenu: {
            feuille
        }
        .task { await load() }
        .refreshable { await load() }
        .onChange(of: query) { _, newValue in scheduleSearch(newValue) }
        .onChange(of: auth.isSignedIn) { _, signedIn in if signedIn { Task { await load() } } }
        .sheet(isPresented: $showSignIn) { SignInView().hzFeuille(detents: [.large]) }
        .sheet(item: $peopleSheet) { kind in
            PeopleListSheet(
                // `PeopleListSheet` reçoit des `String` : sans `String(localized:)` ils ne
                // passeraient jamais par le catalogue.
                title: kind == .following ? String(localized: "Abonnements") : String(localized: "Abonnés"),
                people: kind == .following ? following : followers,
                actionLabel: kind == .following ? String(localized: "Ne plus suivre") : String(localized: "Retirer"),
                onAction: { user in
                    Task {
                        if kind == .following { await unfollow(user) } else { await removeFollower(user) }
                    }
                }
            )
            .hzFeuille()
        }

        .confirmationDialog(
            "Signaler",
            isPresented: Binding(get: { reportTarget != nil }, set: { if !$0 { reportTarget = nil } }),
            presenting: reportTarget
        ) { target in
            Button("Contenu inapproprié") { Task { await submitReport(target, reason: "Contenu inapproprié") } }
            Button("Harcèlement") { Task { await submitReport(target, reason: "Harcèlement") } }
            Button("Spam") { Task { await submitReport(target, reason: "Spam") } }
            Button("Annuler", role: .cancel) {}
        } message: { target in
            Text("Pourquoi signales-tu \(target.displayName) ?")
        }
        .alert(
            "Bloquer \(pendingBlock?.name ?? "") ?",
            isPresented: Binding(get: { pendingBlock != nil }, set: { if !$0 { pendingBlock = nil } })
        ) {
            Button("Bloquer", role: .destructive) {
                if let target = pendingBlock { Task { await confirmBlock(target.userId) } }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Vous ne verrez plus vos activités l'un de l'autre, et ça retire tout suivi entre vous.")
        }
    }

    // MARK: - Le haut, sur le noir

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZCommandesDuHaut(retour: { appState.go(.profile) }) { EmptyView() }
            Text("Amis")
                .hzAffichage(.titreDEcran)
                .foregroundStyle(HZCouleur.blanc)
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZHub.sousLesCommandes)
            if auth.isSignedIn {
                // Les compteurs restent affichés pendant une recherche : ils font partie de l'en-tête
                // de l'écran, pas de son contenu.
                if !(isLoading && followers.isEmpty && following.isEmpty) {
                    compteurs
                        .padding(.horizontal, HZEspace.marge)
                        .padding(.top, HZHub.sousLaCarte)
                }
                HZChampDeRecherche(invite: String(localized: "Pseudo, email ou nom…"), texte: $query,
                                   surNoir: true, enRecherche: isSearching)
                    .padding(.horizontal, HZEspace.marge)
                    .padding(.top, HZHub.sousLaCarte)
            }
        }
    }

    private var compteurs: some View {
        HStack(spacing: HZEspace.entrePilules) {
            HZFiltre(libelle: Pluriel.choisir(followers.count,
                                              String(localized: "\(followers.count) abonné"),
                                              String(localized: "\(followers.count) abonnés"))) {
                peopleSheet = .followers
            }
            HZFiltre(libelle: Pluriel.choisir(following.count,
                                              String(localized: "\(following.count) abonnement"),
                                              String(localized: "\(following.count) abonnements"))) {
                peopleSheet = .following
            }
        }
    }

    // MARK: - La feuille

    @ViewBuilder private var feuille: some View {
        if !auth.isSignedIn {
            signInPrompt
        } else if isSearchingMode {
            searchResultsList
        } else if let contactMatches {
            contactResultsList(contactMatches)
        } else if isLoading && following.isEmpty {
            VStack(spacing: HZEspace.groupe) {
                ProgressView()
                Text("Chargement…")
                    .hzTexte(.c14, .semi)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, HZFil.enAttente)
        } else {
            VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                contactsButton
                // Les demandes en attente passent avant le réglage « Compte privé » : ce sont des
                // actions qui attendent une réponse, pas un paramètre.
                if !incomingRequests.isEmpty { requestsCard }
                // Elles s'effacent pendant une recherche et pendant l'affichage des contacts : ces
                // deux écrans répondent à une question posée.
                if !suggestions.isEmpty { suggestionsList }
                abonnements
                // SEULEMENT si la liste a répondu : `isPrivate` vaut `false` au départ, et une carte
                // qui affirmerait « tout le monde peut te suivre » à quelqu'un dont le compte est
                // peut-être privé annoncerait le contraire de la vérité sur un réglage de confidentialité.
                if listeRecue { privacyRow }
            }
        }
        if let errorMessage {
            VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
                Text(errorMessage)
                    .hzParagraphe(.c14, .semi, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.encre)
                    .fixedSize(horizontal: false, vertical: true)
                HZBoutonPilule(libelle: String(localized: "Réessayer"), hauteur: .petite) {
                    Task { await load() }
                }
            }
            .padding(HZEspace.groupe)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HZCouleur.surfaceClaire,
                        in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
            .padding(.top, HZEspace.entreCommandes)
        }
    }

    private var signInPrompt: some View {
        VStack(alignment: .leading, spacing: HZEspace.groupe) {
            HZPhrase(texte: String(localized: "Connecte-toi pour suivre qui tu veux et voir ses séances dans un fil, sans passer par un club."),
                     titre: String(localized: "Suis de vraies personnes"))
            HZBoutonPilule(libelle: String(localized: "Se connecter"), etendu: true) { showSignIn = true }
        }
    }

    /// Les gens que je suis : leur dernière sortie en gris, et « Suivi » pour ne plus suivre. Le détail
    /// de ce qu'ils font est dans le fil, filtre « Amis ».
    @ViewBuilder private var abonnements: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Abonnements"),
                             lien: feed.isEmpty ? nil : String(localized: "Voir le fil")) {
                appState.go(.fil)
            }
            if following.isEmpty && !isLoading && errorMessage == nil {
                VStack(alignment: .leading, spacing: HZEspace.groupe) {
                    HZPhrase(texte: String(localized: "Cherche quelqu'un par son nom ou son pseudo juste au-dessus — ou invite ceux avec qui tu cours déjà."),
                             titre: String(localized: "Personne à suivre pour l'instant"))
                    InvitationCard()
                }
            }
            LazyVStack(spacing: 0) {
                ForEach(Array(following.enumerated()), id: \.element.id) { index, user in
                    personRow(user, detail: derniereSortie(de: user), filet: index < following.count - 1) {
                        HZBoutonSuivre(libelle: String(localized: "Suivi"), suivi: true) {
                            Task { await unfollow(user) }
                        }
                    }
                }
            }
        }
    }

    /// « 8,4 km · il y a 2 h » : la dernière sortie de la personne, quand le fil des amis en montre une.
    private func derniereSortie(de user: PublicUser) -> String? {
        guard let item = feed.first(where: { $0.userId == user.id }) else { return nil }
        guard let km = item.distanceKm, km > HZFil.kilometreMinimum else { return item.createdAt.relativeDescription }
        return "\(Distances.km(km)) · \(item.createdAt.relativeDescription)"
    }

    @ViewBuilder private var contactsButton: some View {
        if !isSearchingMode {
            HZBoutonPilule(libelle: contactsDenied ? String(localized: "Autoriser l'accès aux contacts")
                                                   : String(localized: "Trouver mes contacts sur Haizo"),
                           dessin: isMatchingContacts ? nil : .groupe, hauteur: .moyenne,
                           fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre, etendu: true) {
                Task { await matchContacts() }
            }
            .opacity(isMatchingContacts ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
            .disabled(isMatchingContacts)
        }
    }

    private func matchContacts() async {
        if ContactMatcher.authorizationStatus == .denied || ContactMatcher.authorizationStatus == .restricted {
            contactsDenied = true
            if let url = URL(string: UIApplication.openSettingsURLString) { await UIApplication.shared.open(url) }
            return
        }

        isMatchingContacts = true
        searchError = nil
        defer { isMatchingContacts = false }

        do {
            let hashes = try await ContactMatcher.emailHashes()
            contactMatches = try await clubService.matchContacts(emailHashes: hashes)
        } catch ContactMatcher.Failure.denied {
            contactsDenied = true
        } catch {
            searchError = PanneReseau.phrase(pour: error)
        }
    }

    private func contactResultsList(_ users: [PublicUser]) -> some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Tes contacts sur Haizo"), lien: String(localized: "Fermer")) {
                contactMatches = nil
            }
            if users.isEmpty {
                HZPhrase(texte: String(localized: "Personne de ton carnet d'adresses n'a encore de compte, ou ils se sont inscrits avec une autre adresse. La recherche par nom reste le chemin le plus sûr."))
            }
            LazyVStack(spacing: 0) {
                ForEach(Array(users.enumerated()), id: \.element.id) { index, user in
                    personRow(user, filet: index < users.count - 1) { followButton(for: user) }
                }
            }
        }
    }

    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Tu connais peut-être"))
            LazyVStack(spacing: 0) {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, user in
                    personRow(user, detail: raisonLisible(user.reason), filet: index < suggestions.count - 1) {
                        followButton(for: user)
                    }
                }
            }
        }
    }

    private func raisonLisible(_ raison: String?) -> String? {
        switch raison {
        case "club": return String(localized: "Dans ton club")
        case "follower": return String(localized: "Te suit déjà")
        default: return nil
        }
    }

    @ViewBuilder private var searchResultsList: some View {
        if isSearching && searchResults.isEmpty {
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, HZFil.enAttente)
        } else if let searchError {
            HZPhrase(texte: searchError)
        } else if searchResults.isEmpty {
            HZPhrase(texte: String(localized: "Personne ne porte ce nom."))
        }
        LazyVStack(spacing: 0) {
            ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, user in
                personRow(user, filet: index < searchResults.count - 1) { followButton(for: user) }
            }
        }
    }

    private func followButton(for user: PublicUser) -> some View {
        let libelle: String
        let suivi: Bool
        switch user.followStatus {
        case "accepted": libelle = String(localized: "Suivi"); suivi = true
        case "pending": libelle = String(localized: "Demande envoyée"); suivi = true
        default: libelle = String(localized: "Suivre"); suivi = false
        }
        return HZBoutonSuivre(libelle: libelle, suivi: suivi) { Task { await toggleFollow(user) } }
    }

    /// Une personne : sa photo, son nom, une ligne en gris (la dernière sortie, le pseudo ou la raison
    /// pour laquelle on la propose), et le bouton qu'on veut à droite.
    private func personRow<Trailing: View>(_ user: PublicUser, detail: String? = nil, filet: Bool = true,
                                           @ViewBuilder trailing: @escaping () -> Trailing) -> some View {
        HZLigneDePersonne(
            nom: user.nomComplet,
            sousTitre: detail ?? user.username.map { "@\($0)" },
            photo: HZPhotoDePersonne(urlString: user.avatarUrl, base64DataURI: user.avatarBase64,
                                     initiales: HZInitiales.de(user.name, user.lastName)),
            filet: filet,
            nomDuBouton: String(localized: "Voir le profil de \(user.name)"),
            ouvrir: { appState.ouvrirLeProfil(user.id) },
            queue: trailing)
            .contextMenu {
                Button("Signaler \(user.name)") {
                    reportTarget = ReportTarget(targetType: "user", targetId: user.id, displayName: user.nomComplet)
                }
                Button("Bloquer \(user.name)", role: .destructive) {
                    pendingBlock = (user.id, user.name)
                }
            }
    }

    private var privacyRow: some View {
        HZGroupeDeReglages(titre: String(localized: "Confidentialité")) {
            HZLigneDeReglage(titre: String(localized: "Compte privé"),
                             precision: isPrivate ? String(localized: "Une demande devra être acceptée avant qu'on puisse te suivre.")
                                                  : String(localized: "Tout le monde peut te suivre sans validation."),
                             filet: false) {
                Toggle(String(localized: "Compte privé"),
                       isOn: Binding(get: { isPrivate }, set: { _ in togglePrivate() }))
                    .labelsHidden()
                    .toggleStyle(HZStyleDInterrupteur())
            }
        }
    }

    private var requestsCard: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Demandes en attente"))
            LazyVStack(spacing: 0) {
                ForEach(Array(incomingRequests.enumerated()), id: \.element.id) { index, user in
                    HZLigneDePersonne(
                        nom: user.nomComplet,
                        photo: HZPhotoDePersonne(urlString: user.avatarUrl, base64DataURI: user.avatarBase64,
                                                 initiales: HZInitiales.de(user.name, user.lastName)),
                        filet: index < incomingRequests.count - 1,
                        nomDuBouton: String(localized: "Voir le profil de \(user.name)"),
                        ouvrir: { appState.ouvrirLeProfil(user.id) }) {
                        HStack(spacing: HZEspace.entrePilules) {
                            HZBoutonRond(dessin: .fermer, nom: "Refuser \(user.name)", diametre: .pas,
                                         fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre,
                                         cote: HZHub.coteDeLaCroix, trait: HZHub.traitDeLaCroix) {
                                Task { await respond(user, accept: false) }
                            }
                            HZBoutonRond(dessin: .coche, nom: "Accepter \(user.name)", diametre: .pas,
                                         fond: HZCouleur.accent, couleur: HZCouleur.encreSurAccent,
                                         cote: HZHub.coteDeLIcone, trait: HZHub.traitDeLIcone) {
                                Task { await respond(user, accept: true) }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Networking

    private func load() async {
        guard auth.isSignedIn else {
            // Sans ça, `isLoading` ne redescendait jamais et un compte déconnecté restait sur la
            // carte de chargement indéfiniment.
            isLoading = false
            return
        }
        errorMessage = nil
        // En démonstration, ce que la graine a posé : il n'y a pas de serveur à interroger.
        if Demonstration.enCours {
            if let liste = appState.cachedFriendsList {
                isPrivate = liste.isPrivate
                following = liste.following
                followers = liste.followers
                incomingRequests = liste.incomingRequests
                listeRecue = true
            }
            feed = appState.cachedClubFeed ?? []
            isLoading = false
            return
        }
        async let listAttempt = clubService.fetchFriendsList()
        async let feedAttempt = clubService.fetchFriendsFeed()

        var echec: Error?
        do {
            let liste = try await listAttempt
            isPrivate = liste.isPrivate
            following = liste.following
            followers = liste.followers
            incomingRequests = liste.incomingRequests
            listeRecue = true
        } catch {
            echec = error
        }
        do {
            feed = try await feedAttempt
        } catch {
            if echec == nil { echec = error }
        }
        if let echec { errorMessage = PanneReseau.phrase(pour: echec) }
        isLoading = false

        // APRÈS le reste, et sans faire échouer l'écran. Les suggestions sont un confort : si
        // elles ne reviennent pas, la recherche et le fil fonctionnent exactement comme avant, et
        // afficher une erreur pour une liste que personne n'a demandée serait pire que le silence.
        suggestions = (try? await clubService.suggestions()) ?? []
    }


    private func scheduleSearch(_ text: String) {
        searchTask?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            searchResults = []
            isSearching = false
            searchError = nil
            return
        }
        isSearching = true
        searchError = nil
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            do {
                let results = try await clubService.searchUsers(query: trimmed)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    isSearching = false
                    searchError = PanneReseau.phrase(pour: error)
                }
            }
        }
    }

    private func toggleFollow(_ user: PublicUser) async {
        Haptics.selection()
        if user.followStatus == nil {
            do {
                let status = try await clubService.followUser(userId: user.id)
                await MainActor.run { updateSearchStatus(user.id, status: status) }
            } catch {
                await MainActor.run { appState.toast(String(localized: "Impossible de suivre cette personne — réessaie.")) }
            }
        } else {
            do {
                try await clubService.unfollowUser(userId: user.id)
                await MainActor.run { updateSearchStatus(user.id, status: nil) }
            } catch {
                await MainActor.run { appState.toast(String(localized: "Impossible de mettre à jour — réessaie.")) }
            }
        }
    }

    private func updateSearchStatus(_ userId: String, status: String?) {
        guard let index = searchResults.firstIndex(where: { $0.id == userId }) else { return }
        searchResults[index].followStatus = status
    }

    private func unfollow(_ user: PublicUser) async {
        do {
            try await clubService.unfollowUser(userId: user.id)
            await MainActor.run { following.removeAll { $0.id == user.id } }
        } catch {
            await MainActor.run { appState.toast(String(localized: "Impossible de mettre à jour — réessaie.")) }
        }
    }

    private func removeFollower(_ user: PublicUser) async {
        do {
            try await clubService.removeFollower(userId: user.id)
            await MainActor.run { followers.removeAll { $0.id == user.id } }
        } catch {
            await MainActor.run { appState.toast(String(localized: "Impossible de mettre à jour — réessaie.")) }
        }
    }

    private func respond(_ user: PublicUser, accept: Bool) async {
        Haptics.impact(.light)
        do {
            try await clubService.respondToFollowRequest(followerId: user.id, accept: accept)
            await MainActor.run {
                incomingRequests.removeAll { $0.id == user.id }
                if accept { followers.append(user) }
            }
        } catch {
            await MainActor.run { appState.toast(String(localized: "Impossible de répondre — réessaie.")) }
        }
    }

    private func togglePrivate() {
        let next = !isPrivate
        isPrivate = next
        Haptics.selection()
        Task {
            do {
                try await clubService.setPrivateAccount(next)
            } catch {
                await MainActor.run {
                    isPrivate = !next
                    appState.toast(String(localized: "Impossible de mettre à jour — réessaie."))
                }
            }
        }
    }

    private func submitReport(_ target: ReportTarget, reason: String) async {
        do {
            try await clubService.report(targetType: target.targetType, targetId: target.targetId, reason: reason)
            appState.toast(String(localized: "Signalement envoyé — merci"))
        } catch {
            appState.toast(String(localized: "Impossible d'envoyer le signalement, réessaie."))
        }
    }

    private func confirmBlock(_ userId: String) async {
        do {
            try await clubService.blockUser(userId: userId)
            following.removeAll { $0.id == userId }
            followers.removeAll { $0.id == userId }
            incomingRequests.removeAll { $0.id == userId }
            feed.removeAll { $0.userId == userId }
        } catch {
            errorMessage = String(localized: "Impossible de bloquer cette personne.")
        }
    }
}

/// Following or followers, with a single contextual action per row ("Ne plus suivre" /
/// "Retirer") — the same two lists `FriendsView.countsRow` opens, just as a sheet since either
/// can get long.
private struct PeopleListSheet: View {
    var title: String
    @State var people: [PublicUser]
    var actionLabel: String
    var onAction: (PublicUser) -> Void

    @Environment(AppState.self) private var appState

    var body: some View {
        HZFeuilleModale(titre: title) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if people.isEmpty {
                        HZPhrase(texte: String(localized: "Personne pour l'instant."))
                    }
                    ForEach(Array(people.enumerated()), id: \.element.id) { index, user in
                        HZLigneDePersonne(
                            nom: user.nomComplet,
                            photo: HZPhotoDePersonne(urlString: user.avatarUrl, base64DataURI: user.avatarBase64,
                                                     initiales: HZInitiales.de(user.name, user.lastName)),
                            filet: index < people.count - 1,
                            nomDuBouton: String(localized: "Voir le profil de \(user.name)"),
                            ouvrir: { appState.ouvrirLeProfil(user.id) }) {
                            HZBoutonSuivre(libelle: actionLabel, suivi: true) {
                                people.removeAll { $0.id == user.id }
                                onAction(user)
                            }
                        }
                    }
                }
                .padding(.horizontal, HZEspace.marge)
            }
        }
    }
}
