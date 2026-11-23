import SwiftUI

/// LE FIL : UN SEUL ENDROIT OÙ TOUT ATTERRIT — refait à partir des composants de la refonte
/// (`Club.dc.html`) : la carte du club sur le noir, les quatre filtres, puis la feuille des sorties.
///
/// # CE QU'IL REMPLACE
///
/// Trois fils séparés — le club, les amis, le mur d'une course — demandaient de savoir OÙ
/// regarder avant de savoir QUOI regarder. Celui-ci retourne la question : tout arrive, et les
/// filtres servent à restreindre, pas à trouver.
///
/// # CE QUI AURAIT PU SE PERDRE, ET QUI NE SE PERD PAS
///
/// Le contexte. Un fil mélangé où rien ne dit pourquoi telle personne y figure n'est plus un
/// réseau, c'est un annuaire. Chaque sortie porte donc sa PROVENANCE sous le nom de son autrice —
/// « ton club », « tu la suis », « toi » — calculée par le serveur, la plus spécifique gagnant
/// quand une personne est les trois à la fois.
///
/// Les messages des pages de course arrivent dans un tableau à part et portent le NOM de leur
/// course : une recherche de partenaire qui débarquerait au milieu des sorties sans dire pour
/// quelle course ne voudrait rien dire. Leur carte mène à la page, où se tient la conversation.
struct WallView: View {
    @Environment(AppState.self) private var appState

    @State private var page: WallPage?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var filtre: Filtre = .tout
    /// Le défilement sans fin. `finDuFil` s'allume quand le serveur dit que les deux sources
    /// sont épuisées ; `chargementEnPlus` empêche deux demandes de partir pour la même fin de
    /// liste — la dernière ligne peut réapparaître plusieurs fois pendant un défilement rapide.
    @State private var chargementEnPlus = false
    @State private var finDuFil = false

    // Ce que les cartes ouvrent.
    @State private var commentsFor: FeedItem?
    @State private var editing: FeedItem?
    @State private var reportTarget: ReportTarget?
    @State private var reportReason = ""
    @State private var pendingBlock: (id: String, name: String)?
    /// LE FIL EST UN ONGLET, DONC IL S'OUVRE AUSSI DÉCONNECTÉE.
    ///
    /// Tant qu'il était une carte du Profil, cette carte vivait DANS la branche
    /// `auth.isSignedIn` de cet écran : déconnectée, elle n'existait pas, et le fil était
    /// inatteignable. Un onglet, lui, est toujours là. Sans ce cas, taper « Fil » sans compte
    /// affichait « Impossible de charger le fil — 401 » : un message d'erreur pour une situation
    /// qui n'en est pas une.
    @State private var showSignIn = false
    /// L'annonce de course qu'on est en train de réécrire.
    @State private var annonceEnModification: WallRacePost?

    private var clubService: ClubService { ClubService(auth: appState.auth) }

    /// Les quatre portées, dans l'ordre où l'on s'en sert : tout d'abord, puis ce qu'on vient
    /// chercher précisément.
    private enum Filtre: String, CaseIterable, Identifiable {
        case tout, club, amis, courses
        var id: String { rawValue }
        var libelle: String {
            switch self {
            case .tout: return String(localized: "Tout")
            case .club: return String(localized: "Club")
            case .amis: return String(localized: "Amis")
            case .courses: return String(localized: "Courses")
            }
        }
    }

    /// Une entrée du fil : une sortie, ou un message de course. Deux formes, une seule liste
    /// triée — c'est l'entrelacement par date qui fait qu'il se lit comme un fil et non comme
    /// deux listes cousues.
    private enum Entree: Identifiable {
        case sortie(FeedItem)
        case course(WallRacePost)

        var id: String {
            switch self {
            case .sortie(let item): return "s-\(item.id)"
            case .course(let post): return "c-\(post.id)"
            }
        }

        var date: Date {
            switch self {
            case .sortie(let item): return item.createdAt
            case .course(let post): return post.createdAt
            }
        }
    }

    private var entrees: [Entree] {
        guard let page else { return [] }
        let sorties = page.items.map(Entree.sortie)
        let courses = filtre == .club || filtre == .amis ? [] : page.racePosts.map(Entree.course)
        return (sorties + courses).sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            // La feuille REMONTE sur le haut de page d'un rayon de coin : le noir passe derrière ses
            // coins arrondis.
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
        .task { if page == nil, appState.auth.isSignedIn { await charger() } }
        .refreshable { if appState.auth.isSignedIn { await charger() } }
        .onChange(of: appState.auth.isSignedIn) { _, connectee in
            if connectee { Task { await charger() } }
        }
        .sheet(isPresented: $showSignIn) { SignInView().hzFeuille(detents: [.large]) }
        .sheet(item: $annonceEnModification) { post in
            EditTextPostSheet(titreDeLaFeuille: String(localized: "Modifier l'annonce"),
                              texteInitial: post.text) { texte in
                try await clubService.updateRacePost(postId: post.id, text: texte)
                await MainActor.run {
                    if let i = page?.racePosts.firstIndex(where: { $0.id == post.id }) {
                        page?.racePosts[i].text = texte
                    }
                }
            }
            .hzFeuille(detents: [.medium, .large], gereSonBas: true)
        }
        .onChange(of: filtre) { _, _ in
            finDuFil = false
            Task { await charger() }
        }
        .sheet(item: $commentsFor) { item in
            ActivityCommentsSheet(
                activityId: item.id,
                currentUserId: appState.auth.currentUser?.id,
                clubService: clubService,
                onCommentPosted: { Task { await charger() } },
                onReport: { commentaire in
                    reportTarget = ReportTarget(targetType: "comment", targetId: commentaire.id,
                                                displayName: commentaire.nomComplet)
                },
                onBlock: { commentaire in pendingBlock = (commentaire.userId, commentaire.name) }
            )
            .hzFeuille(detents: [.medium, .large], gereSonBas: true)
        }
        .sheet(item: $editing) { item in
            EditActivitySheet(item: item, onSaved: { Task { await charger() } })
                .hzFeuille(detents: [.large], gereSonBas: true)
        }
        .alert("Signaler", isPresented: Binding(
            get: { reportTarget != nil },
            set: { if !$0 { reportTarget = nil } }
        )) {
            TextField("Pourquoi ?", text: $reportReason)
            Button("Envoyer") { signaler() }
            Button("Annuler", role: .cancel) { reportTarget = nil; reportReason = "" }
        } message: {
            Text("Ce signalement sera examiné. Merci de préciser ce qui pose problème.")
        }
        .alert("Bloquer cette personne ?", isPresented: Binding(
            get: { pendingBlock != nil },
            set: { if !$0 { pendingBlock = nil } }
        )) {
            Button("Bloquer", role: .destructive) { bloquer() }
            Button("Annuler", role: .cancel) { pendingBlock = nil }
        } message: {
            Text("Vous ne verrez plus rien l'un de l'autre, nulle part dans l'app.")
        }
    }

    // MARK: - Le haut, sur le noir

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(String(localized: "Club"))
                    .hzAffichage(.titreDEcran)
                    .foregroundStyle(HZCouleur.blanc)
                Spacer(minLength: 0)
                if appState.auth.isSignedIn, club != nil {
                    // « Inviter » mène au club, où se trouve le lien à partager.
                    HZBoutonPilule(libelle: String(localized: "Inviter"), hauteur: .petite,
                                   fond: HZCouleur.blanc, couleur: HZCouleur.noir) {
                        appState.go(.club)
                    }
                }
            }
            .padding(.horizontal, HZEspace.marge)

            if appState.auth.isSignedIn {
                carteDuClub
                    .padding(.horizontal, HZEspace.marge)
                    .padding(.top, HZFil.sousLEntete)
                filtres
                    .padding(.horizontal, HZEspace.marge)
                    .padding(.top, HZFil.sousLaCarteDeClub)
            }
        }
        .padding(.top, HZEspace.haut)
        // Le noir se prolonge SOUS les filtres : c'est lui qui est derrière les coins arrondis de
        // la feuille.
        .padding(.bottom, HZFil.sousLesFiltres + HZRayon.feuille)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HZCouleur.noir)
    }

    /// Le club de la coureuse, tel que le dernier chargement l'a rapporté. Nil tant qu'elle n'en a
    /// pas, ou qu'elle n'a pas encore ouvert l'écran du club.
    private var club: ClubInfo? { appState.cachedClubBoard?.club }

    /// La prochaine sortie du club, la plus proche dans le temps.
    private var prochaineSortie: ClubEvent? {
        appState.cachedClubBoard?.events?
            .filter { $0.startsAt > Demonstration.maintenant }
            .min { $0.startsAt < $1.startsAt }
    }

    @ViewBuilder private var carteDuClub: some View {
        if let club {
            HZCarteDeClub(
                membres: Pluriel.choisir(club.memberCount,
                                         String(localized: "\(club.memberCount) membre"),
                                         String(localized: "\(club.memberCount) membres")),
                nom: club.name,
                prochaineSortie: prochaineSortie.map {
                    String(localized: "Prochaine sortie \($0.startsAt.formatted(.dateTime.weekday(.wide).hour()))")
                },
                boutonDeSortie: prochaineSortie.map {
                    $0.goingByMe ? String(localized: "Tu y vas") : String(localized: "J'y vais")
                },
                actionDeSortie: { if let sortie = prochaineSortie { Task { await repondre(sortie) } } },
                ouvrir: { appState.go(.club) })
        } else {
            // Pas (encore) de club : la carte le dit et mène à l'écran où l'on en trouve un, c'est-à-dire
            // la découverte des clubs d'Explorer (les clubs à rejoindre, la recherche par nom, l'entrée
            // par un code). Elle ouvrait la page du club, vide pour qui n'en a pas.
            HZCarteDeClub(membres: String(localized: "Pas encore de club"),
                          nom: String(localized: "Rejoins un club"),
                          ouvrir: { appState.ouvrirExplorer(.clubs) })
        }
    }

    private var filtres: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HZEspace.entrePilules) {
                ForEach(Filtre.allCases) { valeur in
                    HZFiltre(libelle: valeur.libelle, actif: filtre == valeur) { filtre = valeur }
                }
            }
        }
    }

    // MARK: - La feuille

    private var feuille: some View {
        HZFeuille {
            // CE QUE L'ON VOIT SANS COMPTE, ET CE QUE L'ON NE VOIT PAS.
            //
            // Les filtres partent avec le fil : « Tout / Club / Amis / Courses » posés au-dessus
            // d'une invitation à se connecter proposeraient de restreindre quatre listes vides.
            if !appState.auth.isSignedIn {
                invitationAConnexion
            } else if isLoading {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, HZFil.enAttente)
            } else if let loadError {
                phrase(String(localized: "Impossible de charger le fil : \(loadError)."))
            } else if entrees.isEmpty {
                phrase(messageDuVide, titre: filtre == .tout
                       ? String(localized: "Rien pour l'instant")
                       : String(localized: "Rien sous ce filtre"))
            } else {
                LazyVStack(alignment: .leading, spacing: HZFil.ecartEntreSorties) {
                    ForEach(Array(entrees.enumerated()), id: \.element.id) { index, entree in
                        Group {
                            switch entree {
                            case .sortie(let item): sortie(item)
                            case .course(let post): carteDeCourse(post)
                            }
                        }
                        // TROIS AVANT LA FIN, PAS À LA FIN. Déclencher sur la dernière ligne fait
                        // toucher le bas avant que la suite n'arrive : le fil s'arrête une demi-
                        // seconde à chaque page.
                        .onAppear {
                            if index >= entrees.count - HZFil.entreesAvantLaFin { Task { await chargerLaSuite() } }
                        }
                    }
                    if chargementEnPlus {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, HZEspace.entreSections)
                    }
                }
            }
            Color.clear.frame(height: HZFil.basDePage)
        }
        .frame(minHeight: HZFil.hauteurMiniDeLaFeuille, alignment: .top)
    }

    /// Une phrase sur la surface claire : une erreur, un vide.
    private func phrase(_ texte: String, titre: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            if let titre {
                Text(titre)
                    .hzAffichage(.section)
                    .foregroundStyle(HZCouleur.encre)
            }
            Text(texte)
                .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Une porte, pas un mur : dire ce qu'il y a derrière plutôt que ce qui manque. Rien n'est
    /// retenu en otage au passage, puisque applaudir, commenter et suivre demandent de toute façon
    /// un compte.
    private var invitationAConnexion: some View {
        VStack(alignment: .leading, spacing: HZEspace.groupe) {
            phrase(String(localized: "Connecte-toi pour voir les sorties de ton club, celles des gens que tu suis et ce qui se dit sur tes courses."),
                   titre: String(localized: "Le fil se remplit à plusieurs"))
            HZBoutonPilule(libelle: String(localized: "Se connecter"), etendu: true) { showSignIn = true }
        }
    }

    // MARK: - Une sortie

    /// Une sortie du fil : le rendu est partagé (`FeedSortieView`), les actions restent à l'écran qui
    /// les porte.
    private func sortie(_ item: FeedItem) -> some View {
        FeedSortieView(item: item,
                       estLaMienne: item.source == "moi",
                       applaudir: { Task { await applaudir(item) } },
                       commenter: { commentsFor = item },
                       modifier: { editing = item },
                       supprimer: { Task { await supprimer(item) } },
                       signaler: {
                           reportTarget = ReportTarget(targetType: "activity", targetId: item.id,
                                                       displayName: item.nomComplet)
                       },
                       bloquer: { pendingBlock = (item.userId, item.name) })
    }

    // MARK: - Une annonce de course dans le fil

    /// Elle dit DE QUELLE COURSE il s'agit — sans ça, « je cherche quelqu'un à 4:45 » arrivant au
    /// milieu des sorties ne voudrait rien dire — et elle mène à la page, où se tient la
    /// conversation. Deux cibles distinctes : un geste de tape DANS un bouton est avalé par lui, donc
    /// l'applaudissement n'est pas posé sur le bouton qui ouvre la page.
    private func carteDeCourse(_ post: WallRacePost) -> some View {
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            HStack(spacing: 0) {
                Button(action: {
                    appState.openRacesTabOnNextVisit = true
                    appState.go(.club)
                }) {
                    HStack(spacing: HZEspace.entreCommandes) {
                        HZIcone(dessin: .drapeau, cote: HZFil.coteDuDrapeau, couleur: HZCouleur.encre)
                            .frame(width: HZFil.disqueDuDrapeau, height: HZFil.disqueDuDrapeau)
                            .background(HZCouleur.blanc, in: Circle())
                        VStack(alignment: .leading, spacing: 0) {
                            Text(post.author.nomComplet)
                                .hzTexte(.c16, .gras)
                                .foregroundStyle(HZCouleur.encre)
                            Text(post.raceName)
                                .hzTexte(.c13, .medium)
                                .foregroundStyle(HZCouleur.secondaireSurClair)
                        }
                        .lineLimit(1)
                        Spacer(minLength: 0)
                        HZPilule(texte: genreLisible(post.kind), style: .etiquetteGrasse,
                                 fond: HZCouleur.encre)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Voir la page de \(post.raceName)"))
                menuDeLAnnonce(post)
            }
            Text(post.text)
                .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(post.closed ? HZCouleur.secondaireSurClair : HZCouleur.encre)
                .strikethrough(post.closed, color: HZCouleur.secondaireSurClair)
                .lineLimit(HZFil.lignesDUneAnnonce)
                .fixedSize(horizontal: false, vertical: true)
            // Applaudir SANS quitter le fil : obliger à ouvrir la page de la course pour répondre
            // « lu, et oui » coûte plus cher que la réponse elle-même.
            HStack {
                Button(action: { Task { await applaudirLaCourse(post) } }) {
                    HStack(spacing: HZBoutonPilule.ecart) {
                        HZIcone(dessin: .coeur, cote: HZFil.coteDuBravo,
                                couleur: post.kudoedByMe ? HZCouleur.accent : HZCouleur.encre)
                        Text(post.kudos > 0 ? "\(post.kudos)" : String(localized: "Bravo"))
                            .hzTexte(.c14, .gras)
                            .foregroundStyle(HZCouleur.encre)
                    }
                    .padding(.horizontal, HZHauteurDeBouton.moyenne.marge)
                    .frame(height: HZHauteurDeBouton.moyenne.rawValue)
                    .background(HZCouleur.blanc, in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(post.kudoedByMe ? "Retirer ton applaudissement" : "Applaudir ce message")
                .accessibilityValue("\(post.kudos)")
                Spacer(minLength: 0)
            }
        }
        .padding(HZEspace.groupe)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HZCouleur.surfaceClaire,
                    in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
    }

    /// MODIFIER OU SUPPRIMER SON ANNONCE, depuis le fil où on la relit. `WallRacePost` ne porte pas
    /// d'`isMine` : la comparaison d'identifiants fait le même travail sans rien changer au
    /// protocole.
    @ViewBuilder
    private func menuDeLAnnonce(_ post: WallRacePost) -> some View {
        if post.author.id == appState.auth.currentUser?.id, !post.closed {
            Menu {
                Button("Modifier cette annonce") { annonceEnModification = post }
                Button("Supprimer cette annonce", role: .destructive) {
                    Task { await supprimerLAnnonce(post) }
                }
            } label: {
                HZIcone(dessin: .options, cote: HZFil.coteDuBravo, couleur: HZCouleur.secondaireSurClair)
                    .frame(width: HZBoutonRond.zoneTactile, height: HZBoutonRond.zoneTactile)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Gérer cette annonce")
        }
    }

    /// Supprime, ou CLÔT quand le serveur répond qu'on y a répondu.
    ///
    /// Le 409 n'est pas une panne : `race_posts.parent_id` porte `ON DELETE CASCADE`, donc effacer
    /// une annonce à laquelle deux personnes ont répondu emporterait leurs deux messages. Le serveur
    /// refuse, et le bon repli est celui qui existait déjà — l'annonce se barre, la conversation
    /// garde son point de départ.
    private func supprimerLAnnonce(_ post: WallRacePost) async {
        do {
            try await clubService.deleteRacePost(postId: post.id)
            await MainActor.run { page?.racePosts.removeAll { $0.id == post.id } }
        } catch ClubService.ErreurDeSuppression.aDesReponses {
            try? await clubService.closeRacePost(postId: post.id)
            await MainActor.run {
                if let i = page?.racePosts.firstIndex(where: { $0.id == post.id }) {
                    page?.racePosts[i].closed = true
                }
            }
        } catch {
            // Silencieux : la liste n'a pas bougé, donc rien ne ment à l'écran.
        }
    }

    private func genreLisible(_ genre: String) -> String {
        switch genre {
        case "partner": return String(localized: "Partenaire")
        case "bib_offer": return String(localized: "Je cède")
        case "bib_wanted": return String(localized: "Je cherche")
        default: return String(localized: "Message")
        }
    }

    // MARK: - Le vide

    /// Le vide le plus utile dit QUOI FAIRE, et ce n'est pas la même chose selon le filtre.
    private var messageDuVide: String {
        switch filtre {
        case .club: return String(localized: "Personne de ton club n'a encore publié.")
        case .amis: return String(localized: "Suis des coureurs et leurs sorties arriveront ici.")
        case .courses: return String(localized: "Prépare une course et ce qui s'y dit arrivera ici.")
        case .tout: return String(localized: "Rejoins un club, suis des coureurs, prépare une course : tout atterrira ici.")
        }
    }

    // MARK: - Répondre à la prochaine sortie du club

    private func repondre(_ sortie: ClubEvent) async {
        do {
            let reponse = try await clubService.toggleEventRsvp(eventId: sortie.id)
            if let i = appState.cachedClubBoard?.events?.firstIndex(where: { $0.id == sortie.id }) {
                appState.cachedClubBoard?.events?[i].goingByMe = reponse.going
                appState.cachedClubBoard?.events?[i].going = reponse.count
            }
            Haptics.impact(.light)
        } catch {
            appState.toast(String(localized: "Impossible de répondre. Réessaie."))
        }
    }

    // MARK: - Chargement et actions

    private func charger() async {
        loadError = nil
        // En démonstration, le cache est tout — même raison qu'au Club, au Profil et sur la page
        // de quelqu'un : pas de serveur en face d'un simulateur.
        if Demonstration.enCours {
            page = appState.cachedWall
            isLoading = false
            return
        }
        do {
            // Le club s'affiche en tête du fil : sans lui en cache (premier lancement, avant d'avoir
            // ouvert l'écran du club), on va le chercher.
            if appState.cachedClubBoard == nil, let tableau = try? await clubService.fetchBoard() {
                appState.cachedClubBoard = tableau
            }
            let recue = try await clubService.fetchWall(scope: filtre.rawValue)
            page = recue
            finDuFil = recue.fin ?? false
        } catch {
            loadError = PanneReseau.motif(pour: error)
        }
        isLoading = false
    }

    /// LA PAGE SUIVANTE.
    ///
    /// Elle part de la date de la dernière entrée AFFICHÉE — pas de la dernière sortie ni du
    /// dernier message de course pris séparément : les deux listes sont entrelacées à l'écran,
    /// et c'est cet entrelacement qui dit où l'on en est.
    private func chargerLaSuite() async {
        guard !chargementEnPlus, !finDuFil, !isLoading, !Demonstration.enCours,
              let derniere = entrees.last?.date else { return }
        chargementEnPlus = true
        defer { chargementEnPlus = false }
        do {
            let suite = try await clubService.fetchWall(scope: filtre.rawValue, avant: derniere)
            // Le serveur filtre déjà par date stricte, mais une entrée déjà présente coûterait
            // un doublon visible et un identifiant répété dans le `ForEach` : on s'en assure ici.
            let connues = Set((page?.items ?? []).map(\.id))
            let connuesCourses = Set((page?.racePosts ?? []).map(\.id))
            let nouvelles = suite.items.filter { !connues.contains($0.id) }
            let nouvellesCourses = suite.racePosts.filter { !connuesCourses.contains($0.id) }
            page?.items.append(contentsOf: nouvelles)
            page?.racePosts.append(contentsOf: nouvellesCourses)
            // CE QUI S'EST AJOUTÉ, PAS CE QUI EST ARRIVÉ.
            //
            // Un serveur qui ne connaît pas encore `before` rend la MÊME première page : cinquante
            // sorties, toutes déjà là. Conclure sur `suite.items.isEmpty` la déclarerait pleine et
            // la dernière ligne redemanderait cette page à chaque réapparition, indéfiniment.
            // Zéro entrée ajoutée veut dire la même chose dans les deux cas : il n'y a plus rien
            // après, ou le serveur ne sait pas aller plus loin. Dans les deux, on s'arrête.
            //
            // Zéro ajout l'emporte même sur un `fin: false` du serveur : si le curseur ne fait
            // plus avancer la liste, redemander ne la fera pas avancer non plus.
            finDuFil = (nouvelles.isEmpty && nouvellesCourses.isEmpty) || (suite.fin ?? false)
        } catch {
            // Silencieux, et c'est voulu : la page déjà affichée reste juste. Une bannière
            // d'erreur en bas d'un fil qu'on fait défiler rapidement serait du bruit pour une
            // panne que le prochain geste réessaiera de toute façon.
        }
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

    private func applaudirLaCourse(_ post: WallRacePost) async {
        guard let index = page?.racePosts.firstIndex(where: { $0.id == post.id }) else { return }
        do {
            let reponse = try await clubService.toggleRacePostKudos(postId: post.id)
            page?.racePosts[index].kudoedByMe = reponse.kudoed
            page?.racePosts[index].kudos = reponse.kudos
            Haptics.impact(.light)
        } catch {
            appState.toast(String(localized: "Impossible d'applaudir. Réessaie."))
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

    private func signaler() {
        guard let cible = reportTarget else { return }
        let raison = reportReason.trimmingCharacters(in: .whitespacesAndNewlines)
        reportTarget = nil
        reportReason = ""
        guard !raison.isEmpty else { return }
        Task {
            try? await clubService.report(targetType: cible.targetType, targetId: cible.targetId, reason: raison)
            appState.toast(String(localized: "Signalement envoyé"))
        }
    }

    private func bloquer() {
        guard let cible = pendingBlock else { return }
        pendingBlock = nil
        Task {
            do {
                try await clubService.blockUser(userId: cible.id)
                await charger()
            } catch {
                appState.toast(String(localized: "Impossible de bloquer cette personne."))
            }
        }
    }
}
