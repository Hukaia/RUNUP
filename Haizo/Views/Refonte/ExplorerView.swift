import SwiftUI
import CoreLocation

/// EXPLORER, d'après le canvas « Explorer » : où courir et quoi courir, sans rien avoir à taper.
///
/// Un champ qui ouvre la carte de recherche, cinq filtres, l'itinéraire le plus gardé autour de soi en
/// vedette, et les courses qui approchent. Rien de nouveau côté données : ce sont les itinéraires que
/// d'autres ont publiés (`fetchRoutesNearby`), les courses les plus suivies (`upcomingRaces`) et les clubs
/// qu'on peut rejoindre (`suggestedClubs`), les mêmes appels que les écrans du hub du Club, qui restent
/// la porte vers la carte, les pages de course et les clubs.
///
/// Honnête quand il n'y a rien : sans localisation, pas d'itinéraire en vedette (et un lien vers les
/// Réglages si elle a été refusée) ; sans réseau, le motif réel de la panne.
///
/// LE FILTRE CLUBS est la découverte des clubs : une carte en aplat de couleur par club (son nom, sa
/// ville, ses membres, et dans une pilule comment on y entre — Ouvert, Sur demande, Sur code), un
/// champ pour en chercher un par son nom, et l'entrée « avec un code » pour un club sur code, qui ne
/// se trouve nulle part ailleurs. Toucher une carte ouvre la fiche du club (`ClubFicheView`).
/// Les filtres d'Explorer. Hors de la vue parce que l'accueil les nomme aussi : ses catégories
/// ouvrent Explorer sur le filtre correspondant (`AppState.ouvrirExplorer`).
///
/// « ROUTE » LISTE DES COURSES SUR ROUTE, comme « Trail » et « HYROX » listent les leurs. Il listait
/// des itinéraires : trois filtres voisins, deux sortes de contenu, et rien pour le dire. Les
/// itinéraires ont leur propre filtre, qui porte leur nom. Décision de Charlotte, 23 novembre.
enum FiltreDExplorer: CaseIterable, Identifiable {
    case pourToi, route, trail, hyrox, itineraires, clubs
    var id: Self { self }
    var libelle: String {
        switch self {
        case .pourToi: return String(localized: "Pour toi")
        case .route: return String(localized: "Route")
        case .trail: return String(localized: "Trail")
        case .hyrox: return String(localized: "HYROX")
        case .itineraires: return String(localized: "Itinéraires")
        case .clubs: return String(localized: "Clubs")
        }
    }
}

struct ExplorerView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL

    @State private var filtre: Filtre = .pourToi
    @State private var itineraires: [SharedRoute] = []
    @State private var courses: [RaceEvent] = []
    /// Les courses de trail et de HYROX, demandées au serveur À PART : « Courses à venir » ne garde que les
    /// plus proches, et un trail de juin n'y figure pas tant que dix marathons le précèdent.
    @State private var coursesDeRoute: [RaceEvent] = []
    @State private var coursesDeTrail: [RaceEvent] = []
    @State private var coursesHyrox: [RaceEvent] = []
    @State private var clubs: [ClubSearchResult] = []
    /// Pourquoi les clubs proposés n'ont pas pu être chargés, ou nil. Distinct d'une liste vide :
    /// « aucun club à te proposer » et « impossible de charger » ne se disent pas pareil.
    @State private var panneDesClubs: String?
    @State private var rechercheDeClub = ""
    @State private var clubsTrouves: [ClubSearchResult] = []
    @State private var rechercheEnCours = false
    @State private var panneDeRecherche: String?
    @State private var tacheDeRecherche: Task<Void, Never>?
    @State private var ficheOuverte: ClubFicheOuverte?
    @State private var codeOuvert = false
    @State private var enChargement = true
    @State private var panne: String?
    @State private var itineraireOuvert: SharedRoute?
    @State private var courseOuverte: RaceEvent?
    @State private var position = LocationPermission()

    private typealias Filtre = FiltreDExplorer

    private var service: ClubService { ClubService(auth: appState.auth) }

    // MARK: - La page

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HZChampDExploration(question: String(localized: "Où cours-tu aujourd'hui ?"),
                                    precision: String(localized: "Autour de toi · toutes distances")) {
                    appState.openRoutesTabOnNextVisit = true
                    appState.go(.club)
                }
                filtres
                    .padding(.top, HZExplorer.sousLeChamp)
                contenu
                    .padding(.top, HZExplorer.sousLesFiltres)
            }
            .padding(.horizontal, HZEspace.marge)
            .padding(.top, HZEspace.haut)
            .padding(.bottom, HZExplorer.basDePage)
        }
        .scrollIndicators(.hidden)
        .background(HZCouleur.blanc)
        .ignoresSafeArea(edges: .top)
        .statusBarHidden()
        // LE FILTRE DEMANDÉ PAR L'ACCUEIL, lu une fois à l'arrivée puis effacé : une intention de
        // navigation à usage unique, comme `openRacesTabOnNextVisit`. À l'apparition et non dans une
        // tâche : l'écran ne doit pas s'afficher sur « Pour toi » avant de changer de filtre.
        .onAppear {
            if let demande = appState.filtreDExplorerAuProchainPassage {
                filtre = demande
                appState.filtreDExplorerAuProchainPassage = nil
            }
        }
        .task { await charger() }
        .task {
            // Pas en démonstration : la question du système recouvrirait l'écran photographié, et il n'y
            // a pas de position à trouver dans un simulateur de captures.
            guard !Demonstration.enCours else { return }
            position.requestIfNeeded()
            position.requestPosition()
        }
        // Dès qu'on sait où elle est, ou qu'elle vient d'accorder l'autorisation.
        .onChange(of: position.status) { _, _ in position.requestPosition() }
        .onChange(of: position.coordinate?.latitude) { _, _ in Task { await chargerLesItineraires() } }
        .refreshable { await charger() }
        .sheet(item: $itineraireOuvert) { route in
            RouteDetailSheet(route: route) { mise in
                if let index = itineraires.firstIndex(where: { $0.id == mise.id }) { itineraires[index] = mise }
            }
            .hzFeuille(detents: [.medium, .large])
        }
        // PLEIN ÉCRAN, comme depuis la liste des courses : la page d'une course est une destination,
        // pas une parenthèse.
        .fullScreenCover(item: $courseOuverte) { course in
            RacePageView(race: course) { Task { await charger() } }
                .toastDeModale()
        }
        // La fiche d'un club, et l'entrée par un code : deux feuilles, portées par le corps (qui est à
        // l'écran quel que soit le filtre) et non par la liste, qui n'existe que sous « Clubs ».
        .sheet(item: $ficheOuverte) { fiche in
            ClubFicheView(depart: fiche, onRejoint: apresAdhesion)
                .hzFeuille(detents: [.large])
        }
        .sheet(isPresented: $codeOuvert) {
            ClubCodeSheet(onRejoint: apresAdhesion)
                .hzFeuille(detents: [.large])
        }
        .onChange(of: rechercheDeClub) { _, nouveau in chercherUnClub(nouveau) }
    }

    private var filtres: some View {
        // Les filtres défilent au-delà de la marge, comme sur le canvas : le dernier peut sortir de
        // l'écran sans être coupé net.
        ScrollView(.horizontal) {
            HStack(spacing: HZEspace.entrePilules) {
                ForEach(Filtre.allCases) { option in
                    HZFiltre(libelle: option.libelle, actif: filtre == option, fond: .clair) {
                        Haptics.selection()
                        filtre = option
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -HZEspace.marge)
        .contentMargins(.horizontal, HZEspace.marge, for: .scrollContent)
    }

    // MARK: - Ce que chaque filtre montre

    @ViewBuilder private var contenu: some View {
        if enChargement {
            ProgressView()
                .tint(HZCouleur.encre)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HZExplorer.attente)
        } else {
            switch filtre {
            case .pourToi:
                pourToi
            case .route:
                listeDeCourses(coursesDeRoute,
                               vide: String(localized: "Aucune course sur route à venir pour l'instant."))
            case .itineraires:
                listeDItineraires
            case .trail:
                listeDeCourses(coursesDeTrail,
                               vide: String(localized: "Aucune course de trail à venir pour l'instant."))
            case .hyrox:
                listeDeCourses(coursesHyrox,
                               vide: String(localized: "Aucune course HYROX à venir pour l'instant."))
            case .clubs:
                listeDeClubs
            }
        }
    }

    @ViewBuilder private var pourToi: some View {
        if let vedette = itineraires.first {
            carteEnVedette(vedette)
        } else {
            invitationALaPosition
        }
        if !courses.isEmpty {
            sectionDesCourses
                .padding(.top, HZEspace.entreSections - HZExplorer.sousLaCarte)
        } else if let panne {
            message(String(localized: "Impossible de charger les courses : \(panne)."))
                .padding(.top, HZEspace.entreSections)
        }
    }

    // MARK: L'itinéraire en vedette

    private func carteEnVedette(_ route: SharedRoute) -> some View {
        let points = route.drawableCoordinates.map { (lat: $0.latitude, lng: $0.longitude) }
        return VStack(alignment: .leading, spacing: 0) {
            HZCarteDItineraire(distance: route.distanceKm.map { Distances.km($0) } ?? "—",
                               pastille: distanceJusquA(route),
                               trace: HZMiniatureDeSortie.normaliser(points) ?? [],
                               nom: route.name) { itineraireOuvert = route }
            HStack(alignment: .firstTextBaseline) {
                Text(route.name).hzTexte(.c17, .gras)
                Spacer(minLength: 0)
                if let elevation = route.elevationGainM {
                    Text(elevation > 0 ? String(localized: "\(elevation) m D+") : String(localized: "Plat"))
                        .hzTexte(.c14, .semi)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                }
            }
            .foregroundStyle(HZCouleur.encre)
            .padding(.top, HZExplorer.sousLaCarte)
            if route.savesCount > 0 {
                Text(Pluriel.choisir(route.savesCount,
                                     String(localized: "Gardé par \(route.savesCount) coureur Haizo"),
                                     String(localized: "Gardé par \(route.savesCount) coureurs Haizo")))
                    .hzTexte(.c14, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .padding(.top, HZExplorer.sousLeNomDeLaCarte)
            }
        }
    }

    /// « À 400 m de toi » : la distance entre elle et le départ de l'itinéraire, quand on sait où elle est.
    private func distanceJusquA(_ route: SharedRoute) -> String? {
        guard let coordonnee = position.coordinate else { return nil }
        let metres = CLLocation(latitude: coordonnee.latitude, longitude: coordonnee.longitude)
            .distance(from: CLLocation(latitude: route.startLat, longitude: route.startLng))
        if metres < HZExplorer.metresDansUnKilometre {
            return String(localized: "À \(Int(metres.rounded())) m de toi")
        }
        return String(localized: "À \(Distances.km(metres / HZExplorer.metresDansUnKilometre)) de toi")
    }

    /// Sans position, pas d'itinéraire à proposer : on le dit, et on dit quoi faire.
    @ViewBuilder private var invitationALaPosition: some View {
        if position.isRefused {
            HZBoutonPilule(libelle: String(localized: "Localisation refusée · Activer"), dessin: nil,
                           hauteur: .petite, fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre) {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
        } else if position.releveEchoue {
            VStack(alignment: .leading, spacing: 0) {
                message(String(localized: "On n'a pas réussi à savoir où tu es. Sans position, pas d'itinéraire autour de toi."))
                HZBoutonPilule(libelle: String(localized: "Réessayer"), hauteur: .petite,
                               fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre) {
                    position.requestPosition()
                }
            }
        } else if position.coordinate == nil {
            message(String(localized: "On cherche où tu es pour te proposer des itinéraires autour de toi."))
        } else {
            message(Accord.selon(
                f: String(localized: "Personne n'a encore partagé d'itinéraire par ici. Publie le tien après ta prochaine sortie et tu seras la première."),
                m: String(localized: "Personne n'a encore partagé d'itinéraire par ici. Publie le tien après ta prochaine sortie et tu seras le premier.")))
        }
    }

    // MARK: Les courses

    private var sectionDesCourses: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZTitreDeSection(titre: String(localized: "Courses à venir"), lien: String(localized: "Tout voir")) {
                appState.openRacesTabOnNextVisit = true
                appState.go(.club)
            }
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: HZExplorer.entreLesTuiles) {
                    ForEach(Array(courses.prefix(HZExplorer.itinerairesRetenus).enumerated()), id: \.element.id) { index, course in
                        HZTuileDeCourse(mois: mois(de: course),
                                        distance: course.grandeEtiquette,
                                        nom: course.name,
                                        note: noteDeCourse(course),
                                        couleur: couleur(index)) { courseOuverte = course }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -HZEspace.marge)
            .contentMargins(.horizontal, HZEspace.marge, for: .scrollContent)
            .padding(.top, HZExplorer.sousLesCourses)
        }
    }

    /// Les trois couleurs des tuiles de course : celles de la palette d'intensité, l'une après l'autre.
    private func couleur(_ index: Int) -> Color {
        let palette = HZIntensite.allCases
        return palette[index % palette.count].couleur
    }

    private func mois(de course: RaceEvent) -> String {
        guard let jour = course.jour else { return course.raceDate }
        return jour.formatted(Date.FormatStyle(timeZone: TimeZone(identifier: "UTC") ?? .gmt,
                                               capitalizationContext: .beginningOfSentence)
            .month(.wide))
    }

    private func noteDeCourse(_ course: RaceEvent) -> String? {
        guard let suiveurs = course.followerCount, suiveurs > 0 else { return nil }
        return Pluriel.choisir(suiveurs,
                               String(localized: "\(suiveurs) coureur la prépare"),
                               String(localized: "\(suiveurs) coureurs la préparent"))
    }

    /// LES COURSES D'UNE DISCIPLINE, EN AFFICHES sur deux colonnes : les mêmes tuiles de couleur que
    /// « Courses à venir » et que la liste des courses. C'était une liste de lignes grises, la seule
    /// d'Explorer à ne rien montrer ; depuis que l'accueil y mène (catégories Trail et HYROX), c'est
    /// la première chose qu'on voit en arrivant.
    private func listeDeCourses(_ liste: [RaceEvent], vide: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if liste.isEmpty {
                message(panne.map { String(localized: "Impossible de charger les courses : \($0).") } ?? vide)
                // UNE SUITE, PAS UN MUR. « Aucune course HYROX à venir » laissait la personne devant
                // une phrase, alors que l'accueil venait de l'envoyer ici. La liste de toutes les
                // courses a la recherche et « Ajouter une course » : c'est là qu'on la trouve ou qu'on
                // la crée.
                if panne == nil {
                    HZBoutonPilule(libelle: String(localized: "Chercher ou ajouter une course"), hauteur: .petite,
                                   fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre) {
                        appState.openRacesTabOnNextVisit = true
                        appState.go(.club)
                    }
                    .padding(.top, HZEspace.entreCommandes)
                }
            }
            LazyVGrid(columns: colonnesDAffiches, alignment: .leading, spacing: HZEspace.entreSections) {
                ForEach(Array(liste.enumerated()), id: \.element.id) { index, course in
                    HZTuileDeCourse(mois: mois(de: course),
                                    distance: course.grandeEtiquette,
                                    nom: course.name,
                                    note: course.noteDAffiche,
                                    couleur: couleur(index),
                                    largeur: nil) { courseOuverte = course }
                }
            }
        }
    }

    private var colonnesDAffiches: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: HZEspace.entreTuiles, alignment: .top),
              count: HZHub.colonnesDAffiches)
    }

    // MARK: Les itinéraires, les clubs

    @ViewBuilder private var listeDItineraires: some View {
        if itineraires.isEmpty {
            invitationALaPosition
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(itineraires.enumerated()), id: \.element.id) { index, route in
                    Button { itineraireOuvert = route } label: {
                        HZLigneDeListe(titre: route.name, sousTitre: route.subtitleLine,
                                       marge: HZMesuresDeLigne.margeDeSortie, filet: index < itineraires.count - 1) {
                            HZVignette {
                                HZMiniatureDeSortie(points: route.drawableCoordinates.map { (lat: $0.latitude, lng: $0.longitude) })
                            }
                        } queue: {
                            HZChevron()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: La découverte des clubs

    private var rechercheDeClubActive: Bool {
        rechercheDeClub.trimmingCharacters(in: .whitespaces).count >= HZExplorer.caracteresMinimumDeRecherche
    }

    private var listeDeClubs: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZChampDeRecherche(invite: String(localized: "Chercher un club par son nom"),
                               texte: $rechercheDeClub, enRecherche: rechercheEnCours)
            if rechercheDeClubActive {
                resultatsDeRecherche
            } else {
                clubsProposes
            }
            // L'entrée d'un club sur code : il n'est dans aucune liste, on y arrive avec son code.
            ClubLigneDuCode { codeOuvert = true }
                .padding(.top, HZEspace.entreTuiles)
        }
    }

    /// Ce que la recherche a trouvé : des cartes, ou une phrase qui dit pourquoi il n'y en a pas.
    @ViewBuilder private var resultatsDeRecherche: some View {
        if let panneDeRecherche {
            message(panneDeRecherche)
        } else if !rechercheEnCours && clubsTrouves.isEmpty {
            message(String(localized: "Aucun club ne porte ce nom. Un club sur code ne se trouve pas ainsi : entre son code."))
        } else {
            cartesDeClubs(clubsTrouves)
        }
    }

    /// Les clubs proposés sans rien taper : ceux qui bougent. Une panne se dit et se relance ; une liste
    /// vide dit quoi faire.
    @ViewBuilder private var clubsProposes: some View {
        if let panneDesClubs {
            VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                message(String(localized: "Impossible de charger les clubs : \(panneDesClubs)."))
                HZBoutonPilule(libelle: String(localized: "Réessayer"), hauteur: .petite,
                               fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre) {
                    Task { await rechargerLesClubs() }
                }
            }
        } else if clubs.isEmpty {
            message(String(localized: "Aucun club à te proposer pour l'instant. Cherche le tien par son nom, ou entre son code."))
        } else {
            HZTitreDeSection(titre: String(localized: "Clubs à rejoindre"))
                .padding(.top, HZClubs.sousLaRecherche)
            cartesDeClubs(clubs)
        }
    }

    private func cartesDeClubs(_ liste: [ClubSearchResult]) -> some View {
        LazyVStack(spacing: HZEspace.entreTuiles) {
            ForEach(liste) { club in
                HZCarteDeDecouverte(nom: club.name,
                                    detail: ClubLigne.detail(ville: club.city, membres: club.memberCount),
                                    mode: club.mode, demandeEnvoyee: club.requestPending == true,
                                    couleur: HZIntensite.pourClub(id: club.id).couleur) {
                    ficheOuverte = ClubFicheOuverte(club)
                }
            }
        }
    }

    /// La recherche par nom, à la frappe mais pas à chaque lettre : la même temporisation que la
    /// recherche du Club.
    private func chercherUnClub(_ texte: String) {
        tacheDeRecherche?.cancel()
        let propre = texte.trimmingCharacters(in: .whitespaces)
        guard propre.count >= HZExplorer.caracteresMinimumDeRecherche else {
            clubsTrouves = []
            panneDeRecherche = nil
            rechercheEnCours = false
            return
        }
        rechercheEnCours = true
        panneDeRecherche = nil
        tacheDeRecherche = Task {
            try? await Task.sleep(for: .milliseconds(HZExplorer.attenteAvantLaRecherche))
            guard !Task.isCancelled else { return }
            do {
                let trouves = try await service.searchClubs(query: propre)
                guard !Task.isCancelled else { return }
                clubsTrouves = trouves
            } catch {
                guard !Task.isCancelled else { return }
                clubsTrouves = []
                panneDeRecherche = ClubAdhesionErreur.phrase(pour: error)
            }
            rechercheEnCours = false
        }
    }

    /// Une adhésion faite depuis une fiche : on va dans le club, qui se relit.
    private func apresAdhesion() async {
        Analytics.shared.track(.clubJoined)
        appState.cachedClubBoard = nil
        appState.go(.club)
    }

    private func message(_ texte: String) -> some View {
        Text(texte)
            .hzParagraphe(.c14, .medium, interligne: HZLive.interligne)
            .foregroundStyle(HZCouleur.secondaireSurClair)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, HZEspace.groupe)
    }

    // MARK: - Chargement

    private func charger() async {
        panne = nil
        // EN DÉMONSTRATION, LE CACHE EST TOUT : il n'y a pas de serveur en face d'un simulateur, et les
        // trois appels prendraient un 401. `CaptureSeed` a tout posé.
        if Demonstration.enCours {
            itineraires = appState.cachedExplorerRoutes ?? []
            courses = appState.cachedUpcomingRaces ?? []
            coursesDeRoute = courses.filter { $0.discipline == "run" }
            coursesDeTrail = courses.filter { $0.discipline == "trail" }
            coursesHyrox = courses.filter { $0.discipline == "hyrox" }
            clubs = appState.cachedSuggestedClubs ?? []
            enChargement = false
            return
        }
        // Les courses et les clubs ensemble : ils s'affichent ensemble.
        async let suggeres = resultatDesClubs()
        do {
            courses = try await service.upcomingRaces()
        } catch {
            panne = PanneReseau.motif(pour: error)
        }
        // Un échec ici n'est pas une panne de l'écran : la liste du filtre reste vide et dit « aucune
        // course », ce que « Courses à venir » ne contredit pas. Le serveur filtre ; s'il ignore le
        // paramètre (version plus ancienne), le tri sur l'appareil rend la liste juste quand même.
        coursesDeRoute = ((try? await service.upcomingRaces(discipline: "run")) ?? courses)
            .filter { $0.discipline == "run" }
        coursesDeTrail = ((try? await service.upcomingRaces(discipline: "trail")) ?? courses)
            .filter { $0.discipline == "trail" }
        coursesHyrox = ((try? await service.upcomingRaces(discipline: "hyrox")) ?? courses)
            .filter { $0.discipline == "hyrox" }
        adopter(await suggeres)
        enChargement = false
        await chargerLesItineraires()
    }

    /// Les clubs proposés, en `Result` : la CAUSE d'un échec compte, parce que « aucun club à te
    /// proposer » et « impossible de charger les clubs » demandent deux phrases.
    private func resultatDesClubs() async -> Result<[ClubSearchResult], Error> {
        do { return .success(try await service.fetchSuggestedClubs()) } catch { return .failure(error) }
    }

    private func adopter(_ resultat: Result<[ClubSearchResult], Error>) {
        switch resultat {
        case .success(let proposes):
            clubs = proposes
            panneDesClubs = nil
        case .failure(let erreur):
            clubs = []
            panneDesClubs = PanneReseau.motif(pour: erreur)
        }
    }

    private func rechargerLesClubs() async {
        panneDesClubs = nil
        adopter(await resultatDesClubs())
    }

    /// Les itinéraires autour d'elle, les plus gardés d'abord : enregistrer un itinéraire veut dire
    /// « j'ai l'intention de le courir », là où un « j'aime » ne coûte rien.
    private func chargerLesItineraires() async {
        guard !Demonstration.enCours, let coordonnee = position.coordinate else { return }
        let demi = HZExplorer.demiCote
        let trouves = try? await service.fetchRoutesNearby(
            minLat: coordonnee.latitude - demi, maxLat: coordonnee.latitude + demi,
            minLng: coordonnee.longitude - demi, maxLng: coordonnee.longitude + demi)
        itineraires = (trouves ?? itineraires).sorted { $0.savesCount > $1.savesCount }
    }
}
