import SwiftUI
import SwiftData

/// Social/club screen — a real, server-backed club (see `ClubService`, `api/clubs/*.js`,
/// `api/activities/*.js`), not `ClubMockData`: the leaderboard is computed from real members' XP,
/// the feed is real posted activities, kudos persist per-user. Requires a real account
/// (`AuthService`) — the rest of the app works fully offline, this is the one feature that
/// intrinsically needs one, so sign-in is gated here rather than forced at onboarding.
struct ClubView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \RunRecord.date, order: .reverse) private var runs: [RunRecord]

    /// LES DONNÉES DU CLUB ET LE RÉSEAU VIVENT À PART — voir `ClubStore`.
    ///
    /// Construit ici et non dans une `.task` : `@State` ne se laisse pas initialiser depuis
    /// l'environnement, mais il se laisse initialiser depuis un paramètre, et `SocialView` a
    /// l'environnement. Le magasin existe donc dès le premier rendu, ce qui évite d'avoir à
    /// répondre à « que se passe-t-il si une vue s'affiche avant que son magasin existe ».
    @State private var magasin: ClubStore

    /// `@MainActor` EXPLICITE, parce que `ClubStore` l'est et qu'un `init` de structure ne
    /// l'hérite pas forcément. Construire un objet isolé au fil principal depuis un contexte
    /// qui ne l'est pas est une erreur de compilation, pas un avertissement — et il n'y a pas
    /// de compilateur Swift ici pour la voir. Redondante si SwiftUI isole déjà `View`, et sans
    /// coût dans ce cas.
    @MainActor
    init(appState: AppState) {
        _magasin = State(initialValue: ClubStore(appState: appState))
        _mur = State(initialValue: MurDuClub())
    }

    /// L'APERÇU EST LE BON ONGLET POUR DE VRAIES GENS, ET LE MAUVAIS POUR UNE CAPTURE.
    ///
    /// Il montre les kilomètres du club cette semaine, le défi en cours et les sorties de
    /// groupe prévues — trois choses qu'un club inventé n'a pas, donc trois états vides sous
    /// une accroche qui parle du fil du club. Le fil, lui, est plein. Voir `Demonstration`.
    @State private var tab: Tab = Tab.auDemarrage
    // Starts true (not false) so the very first render — before `.task` below has had a chance to
    // run — reads as "checking for your club" rather than immediately flashing the create/join
    // form. `.id(appState.screen)` on the parent means a fresh ClubView (and fresh isLoading=true)
    // is created every time this tab is opened, so this covers every visit, not just the first.
    @State private var showSignIn = false
    @State private var newClubName = ""
    @State private var clubQuery = ""
    @State private var reportTarget: ReportTarget?
    @State private var pendingBlock: (userId: String, name: String)?
    @State private var showManagement = false

    /// LE MUR A SON PROPRE OBJET D'ÉTAT, et c'est ce qui l'a rendu découpable.
    ///
    /// Huit `@State` vivaient ici à plat : le brouillon, l'envoi en cours, la réponse en cours,
    /// les quatre feuilles du mur et le drapeau de révélation du fil. Les passer un par un à une
    /// vue sortie du fichier aurait fait huit liaisons à ne pas confondre. Voir `MurDuClub`.
    ///
    /// Construit dans l'`init` comme le magasin, et pour la raison écrite au-dessus de celui-ci :
    /// `MurDuClub` est `@MainActor`, et le construire depuis un contexte qui ne l'est pas est une
    /// ERREUR DE COMPILATION. L'`init` l'est explicitement ; une valeur par défaut posée ici
    /// dépendrait de ce que le compilateur déduit, et il n'y en a pas sous la main pour vérifier.
    @State private var mur: MurDuClub
    /// La sortie en cours de modification — la sienne uniquement, le serveur le vérifie de son côté.
    @State private var showLeaveConfirm = false
    @State private var showCreateEvent = false
    /// La sortie de groupe qu'on est en train de modifier. Non nil présente `CreateEventSheet`
    /// Le message du mur qu'on est en train de réécrire.
    /// My own feed activity pending delete confirmation (appui long → Supprimer).
    /// Drives the feed rows' staggered entrance — flipped once the first feed load lands, after
    /// which each row's own per-index delay takes over (same pattern as `RecapView`'s splits).

    /// Trois destinations, pas un mur (`.club-tabs` dans la maquette).
    ///
    /// L'écran empilait auparavant, AU-DESSUS de son sélecteur à deux positions : la carte de
    /// niveau, le pouls de la semaine, le défi, les sorties de groupe et la ligne d'adhésion. En
    /// clair, il fallait faire défiler cinq blocs avant d'atteindre le classement — et exactement
    /// les mêmes cinq avant d'atteindre le fil. Rien de tout cela n'était mauvais, c'était juste
    /// toujours là, quelle que soit la raison pour laquelle on ouvrait l'écran.
    ///
    /// C'est le seul endroit où j'ai vraiment restructuré un écran qui marchait, et c'est parce
    /// que le volume de contenu le justifie : ces cinq blocs représentent plus d'une hauteur
    /// d'écran à eux seuls. Ils forment un ensemble cohérent — « où en est le club en ce moment »
    /// — qui devient l'onglet Aperçu, pendant que Classement et Activité deviennent atteignables
    /// en un seul geste depuis le haut de la page.
    private enum Tab {
        case overview, board, feed

        /// L'onglet d'ouverture. En démonstration, le fil — le seul des trois qu'un club inventé
        /// remplit vraiment — sauf quand les captures en demandent un autre par `--onglet=`.
        static var auDemarrage: Tab {
            #if DEBUG
            switch CaptureSeed.ongletDuClub {
            case "apercu": return .overview
            case "classement": return .board
            case "activite": return .feed
            default: break
            }
            #endif
            return Demonstration.enCours ? .feed : .overview
        }
    }

    private var profile: UserProfile { appState.profile }
    private var auth: AuthService { appState.auth }
    private var clubService: ClubService { ClubService(auth: auth) }

    var body: some View {
        // `@Bindable` LE TEMPS DU CORPS : les feuilles et le badge se présentent par `item:`, qui veut
        // un `Binding`, et un objet `@Observable` n'en fournit pas directement.
        @Bindable var magasin = magasin
        @Bindable var mur = mur
        HZPage {
            hautDePage
        } contenu: {
            feuille
        }
        .task { await magasin.loadIfSignedIn(badges: badges) }
        .sheet(isPresented: $showManagement) { gestion.hzFeuille(detents: [.large]) }
        // Arrivée par le lien public d'un club : la recherche s'ouvre déjà remplie de son nom,
        // donc le bouton « Rejoindre » est à un geste. Le nom est consommé pour qu'un retour sur
        // l'onglet ne le réécrive pas par-dessus une recherche en cours.
        .onChange(of: appState.clubDepuisUnLien) { _, nom in
            guard let nom else { return }
            clubQuery = nom
            appState.clubDepuisUnLien = nil
        }
        .onAppear {
            if let nom = appState.clubDepuisUnLien {
                clubQuery = nom
                appState.clubDepuisUnLien = nil
            }
        }
        // Même temporisation que la recherche de personnes : on cherche À LA FRAPPE, mais on
        // n'envoie pas une requête par lettre.
        .onChange(of: clubQuery) { _, nouveau in magasin.chercherUnClub(nouveau) }
        .refreshable { await magasin.loadIfSignedIn(badges: badges) }
        .onChange(of: magasin.feed.count) { _, count in
            if count > 0 { mur.filDevoile = true }
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
                .hzFeuille(detents: [.large])
        }
        // ET « PROPOSER UNE SORTIE » NE FAISAIT RIEN SUR UN CLUB EN SOMMEIL.
        //
        // Deux boutons posent `showCreateEvent` : le « + » de la carte des sorties, et celui de
        // la carte qui propose de RÉVEILLER le club. Or ces deux cartes s'excluent —
        // `if clubEnSommeil { ClubWakeCard(…) } else { eventsCard }` — et la feuille était
        // accrochée à la seconde. Sur un club endormi, c'est-à-dire exactement le cas où cette
        // carte existe, taper « Proposer une sortie » posait l'état et n'ouvrait rien ; et la
        // feuille surgissait plus tard, sans qu'on l'ait demandée, le jour où le club se
        // réveillait et où `eventsCard` revenait à l'écran.
        //
        // LA RÈGLE, ET ELLE VAUT POUR LES DOUZE : une feuille se pose sur une vue qui est à
        // l'écran quand on la demande. Si le bouton et la feuille ne sont pas dans la même
        // branche, la feuille remonte au corps.
        .sheet(isPresented: $showCreateEvent) {
            CreateEventSheet { title, location, date, chaqueSemaine, groupes in
                try await magasin.creerLaSortie(title: title, location: location, startsAt: date,
                                                repeatsWeekly: chaqueSemaine, paceGroups: groupes)
            }
            .hzFeuille(detents: [.large], gereSonBas: true)
        }
        // LA FEUILLE D'ÉDITION D'UN MESSAGE DU MUR ÉTAIT ACCROCHÉE À `eventsCard`.
        //
        // C'est-à-dire à l'onglet APERÇU, alors que le bouton qui la déclenche — « Modifier ce
        // message », dans l'en-tête d'un message — est sur l'onglet ACTIVITÉ. Les trois onglets
        // s'excluent (`switch tab`), donc la vue qui portait la feuille n'était pas à l'écran
        // au moment où l'on demandait à l'ouvrir : taper « Modifier ce message » ne faisait
        // RIEN. Et pire que rien — l'état restait posé, et la feuille surgissait sans qu'on
        // l'ait demandée au moment où l'on passait sur l'Aperçu.
        //
        // Trouvé en relevant, pour chaque feuille du fichier, la vue qui la porte et celle qui
        // la déclenche. Sur douze, c'est la seule qui n'était pas chez elle. Elle rejoint ici
        // les deux autres feuilles du mur, sur le corps, qui est à l'écran quel que soit
        // l'onglet.
        .sheet(item: $mur.messageEnModification) { message in
            EditTextPostSheet(titreDeLaFeuille: String(localized: "Modifier le message"),
                              texteInitial: message.text) { texte in
                // Recousu sur place plutôt que rechargé : un message n'a qu'un texte, il ne
                // change ni de place ni de compteur. Recharger le mur entier pour une phrase
                // ferait clignoter la liste sous les doigts de qui vient de la corriger.
                try await magasin.modifierLeMessage(message, texte: texte)
            }
            .hzFeuille(detents: [.medium, .large], gereSonBas: true)
        }
        .sheet(item: $mur.editingActivity) { activity in
            EditActivitySheet(item: activity, onSaved: { Task { await magasin.loadFeed() } })
                .hzFeuille(detents: [.large], gereSonBas: true)
        }
        .sheet(item: $mur.commentsActivity) { activity in
            ActivityCommentsSheet(
                activityId: activity.id,
                currentUserId: auth.currentUser?.id,
                clubService: clubService,
                onCommentPosted: { magasin.bumpCommentsCount(activity.id) },
                onReport: { comment in
                    mur.commentsActivity = nil
                    Task {
                        try? await Task.sleep(for: .milliseconds(HZHub.attenteApresFermetureDeFeuille))
                        reportTarget = ReportTarget(targetType: "comment", targetId: comment.id, displayName: String(localized: "le commentaire de \(comment.nomComplet)"))
                    }
                },
                onBlock: { comment in
                    mur.commentsActivity = nil
                    Task {
                        try? await Task.sleep(for: .milliseconds(HZHub.attenteApresFermetureDeFeuille))
                        pendingBlock = (comment.userId, comment.name)
                    }
                }
            )
                .hzFeuille(detents: [.medium, .large], gereSonBas: true)
        }
        .onChange(of: auth.isSignedIn) { _, signedIn in
            if signedIn { Task { await magasin.loadIfSignedIn(badges: badges) } }
        }
        // Report reason picker — App Store guideline 1.2. `reportTarget` is set by the context
        // menus on leaderboard rows / feed items / the club itself.
        .confirmationDialog(
            "Signaler",
            isPresented: Binding(get: { reportTarget != nil }, set: { if !$0 { reportTarget = nil } }),
            presenting: reportTarget
        ) { target in
            Button("Contenu inapproprié") { Task { await magasin.submitReport(target, reason: "Contenu inapproprié") } }
            Button("Harcèlement") { Task { await magasin.submitReport(target, reason: "Harcèlement") } }
            Button("Spam") { Task { await magasin.submitReport(target, reason: "Spam") } }
            Button("Annuler", role: .cancel) {}
        } message: { target in
            Text("Pourquoi signales-tu \(target.displayName) ?")
        }
        // Quitter le club — le bouton vit maintenant dans la feuille de gestion, qui se ferme
        // avant de demander confirmation ; le dialogue doit donc être porté par une vue qui, elle,
        // reste à l'écran. `leaveClub()` garde son propre garde-fou contre le double appel.
        .confirmationDialog("Quitter le club ?", isPresented: $showLeaveConfirm, titleVisibility: .visible) {
            Button("Quitter", role: .destructive) { Task { await magasin.leaveClub() } }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Pour revenir, tu repasseras par la façon dont ce club accueille : un toucher, une demande ou un code.")
        }
        // Block confirmation — the other half of guideline 1.2, doesn't require leaving the club.
        .alert(
            "Bloquer \(pendingBlock?.name ?? "") ?",
            isPresented: Binding(get: { pendingBlock != nil }, set: { if !$0 { pendingBlock = nil } })
        ) {
            // Same synchronous capture as the delete alert below — the alert's dismissal nils
            // `pendingBlock` before an async Task body would read it (silent no-op otherwise).
            Button("Bloquer", role: .destructive) {
                if let target = pendingBlock {
                    Task { await magasin.confirmBlock(target.userId) }
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Tu ne verras plus son score ni ses activités, sans avoir à quitter le club.")
        }
        // Deleting my own feed post — permanent (kudos et commentaires partent avec), so it
        // confirms instead of firing straight from the context menu.
        .alert(
            "Supprimer cette activité ?",
            isPresented: Binding(get: { mur.pendingDeleteActivity != nil }, set: { if !$0 { mur.pendingDeleteActivity = nil } })
        ) {
            // The item is captured SYNCHRONOUSLY here: dismissing the alert nils
            // `pendingDeleteActivity` before an async Task body would get to read it, which made
            // the whole action a silent no-op.
            Button("Supprimer", role: .destructive) {
                if let item = mur.pendingDeleteActivity {
                    Task { await magasin.confirmDeleteActivity(item) }
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Elle disparaîtra du fil du club, avec ses applaudissements et commentaires. Tes XP restent acquis.")
        }
        .fullScreenCover(item: $magasin.unlockedBadge) { badge in
            BadgeUnlockedView(badge: badge, onDismiss: { magasin.unlockedBadge = nil })
        }
    }

    // MARK: - Le haut, sur le noir

    private var club: ClubInfo? { magasin.board.club }

    /// La prochaine sortie du club, la plus proche dans le temps.
    private var prochaineSortie: ClubEvent? {
        (magasin.board.events ?? [])
            .filter { $0.startsAt > Demonstration.maintenant }
            .min { $0.startsAt < $1.startsAt }
    }

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZCommandesDuHaut(retour: { appState.go(.profile) }) {
                if club != nil {
                    // Le nom du club est aussi l'entrée de « Gestion du club » (code d'invitation,
                    // membres, réglages) : la carte l'ouvre, et ce bouton la rend visible.
                    HZBoutonRond(dessin: .options, nom: String(localized: "Gérer le club"),
                                 fond: HZCouleur.surfaceSombre) { showManagement = true }
                }
            }
            if let club, auth.isSignedIn {
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
                    actionDeSortie: { if let sortie = prochaineSortie { magasin.toggleRsvp(sortie) } },
                    // Les sorties sont CONNUES (`events` n'est plus nil) et aucune n'est à venir :
                    // pas pendant le chargement, où « aucune » serait faux.
                    sansSortie: magasin.board.events != nil && prochaineSortie == nil
                        ? String(localized: "Aucune sortie prévue pour l'instant") : nil,
                    boutonSansSortie: club.isOwner == true ? String(localized: "Proposer une sortie") : nil,
                    actionSansSortie: { showCreateEvent = true },
                    ouvrir: { showManagement = true })
                    .padding(.horizontal, HZEspace.marge)
                    .padding(.top, HZHub.sousLesCommandes)
                onglets
                    .padding(.horizontal, HZEspace.marge)
                    .padding(.top, HZFil.sousLaCarteDeClub)
            } else {
                Text(auth.isSignedIn && !magasin.isLoading ? String(localized: "Rejoins un club")
                                                           : String(localized: "Club"))
                    .hzAffichage(.titreDEcran)
                    .foregroundStyle(HZCouleur.blanc)
                    .padding(.horizontal, HZEspace.margeDeTitre)
                    .padding(.top, HZHub.sousLesCommandes)
            }
        }
    }

    private var onglets: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HZEspace.entrePilules) {
                HZFiltre(libelle: String(localized: "Aperçu"), actif: tab == .overview) { choisir(.overview) }
                HZFiltre(libelle: String(localized: "Classement"), actif: tab == .board) { choisir(.board) }
                HZFiltre(libelle: String(localized: "Activité"), actif: tab == .feed) { choisir(.feed) }
            }
        }
    }

    private func choisir(_ onglet: Tab) {
        withAnimation(.easeInOut(duration: HZHub.dureeDeLOnglet)) { tab = onglet }
        if onglet == .feed && magasin.feed.isEmpty { Task { await magasin.loadFeed() } }
    }

    // MARK: - La feuille

    @ViewBuilder private var feuille: some View {
        if !auth.isSignedIn {
            invitationAConnexion
        } else if magasin.isLoading && club == nil {
            // Sans cette attente, les secondes que prend `loadIfSignedIn` se lisent comme « le
            // formulaire de création clignote, puis bascule sur le classement ».
            VStack(spacing: HZEspace.groupe) {
                ProgressView()
                Text("Chargement du club…")
                    .hzTexte(.c14, .semi)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, HZFil.enAttente)
        } else if club == nil {
            ClubSetupCard(magasin: magasin, newClubName: $newClubName, clubQuery: $clubQuery)
        } else {
            VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                switch tab {
                case .overview: overviewContent
                case .board:
                    ClubBoardSection(board: magasin.board, isLoading: magasin.isLoading,
                                     reportTarget: $reportTarget, pendingBlock: $pendingBlock)
                case .feed:
                    ClubWallView(magasin: magasin, mur: mur,
                                 reportTarget: $reportTarget, pendingBlock: $pendingBlock)
                }
            }
        }
        if let message = magasin.errorMessage {
            Text(message)
                .hzParagraphe(.c14, .semi, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.encre)
                .padding(HZEspace.groupe)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HZCouleur.surfaceClaire,
                            in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
                .padding(.top, HZEspace.entreCommandes)
        }
        if auth.isSignedIn {
            // Le contact publié, ici et pas seulement dans la politique de confidentialité :
            // App Store, règle 1.2.
            Link(destination: URL(string: "mailto:charlottegrudep@gmail.com")!) {
                Text("Signaler un problème ou nous contacter")
                    .hzTexte(.c13, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: HZBoutonRond.zoneTactile)
            }
            .padding(.top, HZEspace.entreCommandes)
        }
    }

    private var invitationAConnexion: some View {
        VStack(alignment: .leading, spacing: HZEspace.groupe) {
            HZPhrase(texte: String(localized: "Connecte-toi pour rejoindre un vrai club, avec un classement et un fil d'activité alimentés par de vraies personnes."),
                     titre: String(localized: "Le Club, c'est mieux à plusieurs"))
            HZBoutonPilule(libelle: String(localized: "Se connecter"), etendu: true) { showSignIn = true }
        }
    }

    /// La couverture du club : une bande, pas une photo — elle ne s'affiche que si quelqu'un en a
    /// posé une, un cadre gris en attente d'image dirait « il manque quelque chose ».
    @ViewBuilder private var banniere: some View {
        if let brut = club?.coverUrl, !brut.isEmpty, let url = URL(string: brut) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                HZCouleur.surfaceClaire
            }
            .aspectRatio(HZHub.rapportDeLaCouverture, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
            .accessibilityHidden(true)
        }
    }

    /// DES GENS ATTENDENT UNE RÉPONSE : le club est sur demande, et son propriétaire a des demandes à
    /// traiter. Une plaque en tête de l'aperçu qui ouvre la gestion, où elles sont — pas un compteur
    /// caché derrière le bouton des options. Rien ne s'affiche sans demande : un club qui n'en a pas
    /// n'a pas de plaque vide.
    @ViewBuilder private var demandesAttendues: some View {
        if club?.isOwner == true, let attente = club?.pendingRequests, attente > 0 {
            HZPlaque {
                Text(Pluriel.choisir(attente,
                                     String(localized: "\(attente) personne veut rejoindre le club"),
                                     String(localized: "\(attente) personnes veulent rejoindre le club")))
                    .hzAffichage(.section)
                    .foregroundStyle(HZCouleur.encre)
                    .fixedSize(horizontal: false, vertical: true)
                HZBoutonPilule(libelle: String(localized: "Voir les demandes"), hauteur: .petite) {
                    showManagement = true
                }
            }
        }
    }

    /// Rien n'est lancé : pas un kilomètre cette semaine, pas de défi, pas de sortie prévue.
    private var clubEnSommeil: Bool {
        (magasin.board.weekStats?.totalKm ?? 0) == 0
            && magasin.board.challenge == nil
            && (magasin.board.events ?? []).isEmpty
    }

    /// « Où en est le club en ce moment » : l'état collectif d'abord, puis ce qui appelle une action
    /// (les sorties), puis qui est là. Les trois sections du haut, quand elles sont vides, cèdent la
    /// place à UN bloc qui dit quoi faire : trois fois « rien » ne fait pas trois sections.
    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreSections) {
            demandesAttendues
            banniere
            if let texte = club?.description, !texte.isEmpty {
                Text(texte)
                    .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.encre)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if clubEnSommeil {
                if magasin.seuleDansSonClub {
                    ClubAloneCard(magasin: magasin)
                } else {
                    ClubWakeCard(showCreateEvent: $showCreateEvent, showManagement: $showManagement)
                }
            } else {
                ClubWeekPulseCard(magasin: magasin)
                ClubChallengeCard(magasin: magasin, showManagement: $showManagement)
                ClubEventsSection(magasin: magasin, badges: badges, showCreateEvent: $showCreateEvent)
            }
            ClubMembresSection(board: magasin.board)
            // La condition qui garde les pépites reste ICI : un `.task` posé sur une vue qui ne rend
            // rien est une question à laquelle personne ne répond avec certitude.
            if magasin.aDesPepites {
                ClubHighlightsSections(highlights: magasin.highlights)
            }
            ClubLevelCard(xpTotal: auth.currentUser?.xpTotal ?? 0)
        }
        .task { await magasin.chargerLesPepites() }
    }

    /// Mes badges. Le calcul vit dans `ClubBadgeEngine` (Haizo/Services) depuis que le profil
    /// les affiche aussi : deux écrans, une seule dérivation.
    private var badges: [ClubBadge] { ClubBadgeEngine.badges(runs: runs, profile: profile) }

    /// La feuille de gestion : le nom du club en est l'entrée.
    @ViewBuilder private var gestion: some View {
        if let club {
            ClubManagementView(
                club: club,
                members: magasin.board.leaderboard,
                challenge: magasin.board.challenge,
                onCreateChallenge: { title, targetKm, endDate in
                    try await magasin.createChallenge(title: title, targetKm: targetKm, endDate: endDate)
                },
                onReport: { member in
                    // Fermer la feuille d'abord, poser la cible une fois sa fermeture passée : les deux
                    // dans le même tour, et l'un des deux perd en silence.
                    showManagement = false
                    Task {
                        try? await Task.sleep(for: .milliseconds(HZHub.attenteApresFermetureDeFeuille))
                        reportTarget = ReportTarget(targetType: "user", targetId: member.id, displayName: member.nomComplet)
                    }
                },
                onBlock: { member in
                    showManagement = false
                    Task {
                        try? await Task.sleep(for: .milliseconds(HZHub.attenteApresFermetureDeFeuille))
                        pendingBlock = (member.id, member.name)
                    }
                },
                onUpdateBio: { bio in try await magasin.updateBio(bio) },
                onSetJoinMode: { try await magasin.reglerLeMode($0, badges: badges) },
                onSetClubProfile: { description, ville in
                    try await magasin.reglerLaFiche(description: description, ville: ville, badges: badges)
                },
                onSetClubCover: { try await magasin.reglerLaCouverture(dataURI: $0, badges: badges) },
                onSetMemberRole: { memberId, organisateur in
                    try await magasin.reglerLeRole(memberId: memberId, organisateur: organisateur, badges: badges)
                },
                demandes: magasin.demandes,
                demandesEnChargement: magasin.demandesEnChargement,
                demandesEnPanne: magasin.demandesEnPanne,
                onLoadRequests: { await magasin.chargerLesDemandes() },
                onRespondRequest: { demande, accepter in
                    try await magasin.repondreALaDemande(demande, accepter: accepter, badges: badges)
                },
                onReportClub: {
                    showManagement = false
                    Task {
                        try? await Task.sleep(for: .milliseconds(HZHub.attenteApresFermetureDeFeuille))
                        reportTarget = ReportTarget(targetType: "club", targetId: club.id, displayName: String(localized: "le club \(club.name)"))
                    }
                },
                onLeaveClub: {
                    showManagement = false
                    Task {
                        try? await Task.sleep(for: .milliseconds(HZHub.attenteApresFermetureDeFeuille))
                        showLeaveConfirm = true
                    }
                }
            )
        }
    }
}
