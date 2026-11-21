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
struct ExplorerView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openURL) private var openURL

    @State private var filtre: Filtre = .pourToi
    @State private var itineraires: [SharedRoute] = []
    @State private var courses: [RaceEvent] = []
    @State private var clubs: [ClubSearchResult] = []
    @State private var enChargement = true
    @State private var panne: String?
    @State private var itineraireOuvert: SharedRoute?
    @State private var courseOuverte: RaceEvent?
    @State private var position = LocationPermission()

    private enum Filtre: CaseIterable, Identifiable {
        case pourToi, route, trail, hyrox, clubs
        var id: Self { self }
        var libelle: String {
            switch self {
            case .pourToi: return String(localized: "Pour toi")
            case .route: return String(localized: "Route")
            case .trail: return String(localized: "Trail")
            case .hyrox: return String(localized: "HYROX")
            case .clubs: return String(localized: "Clubs")
            }
        }
    }

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
        }
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
                listeDItineraires
            case .trail:
                listeDeCourses(courses.filter { $0.discipline == "trail" },
                               vide: String(localized: "Aucune course de trail à venir pour l'instant."))
            case .hyrox:
                listeDeCourses(courses.filter { $0.discipline == "hyrox" },
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
                                        distance: course.distanceKm.map { Distances.valeur($0) } ?? "—",
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

    private func listeDeCourses(_ liste: [RaceEvent], vide: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if liste.isEmpty {
                message(panne.map { String(localized: "Impossible de charger les courses : \($0).") } ?? vide)
            }
            ForEach(Array(liste.enumerated()), id: \.element.id) { index, course in
                Button { courseOuverte = course } label: {
                    HZLigneDeListe(titre: course.name, sousTitre: ligneDeCourse(course),
                                   marge: HZMesuresDeLigne.margeDeDestination, filet: index < liste.count - 1) {
                        HZIcone(dessin: .drapeau, cote: HZProfil.coteDeLIconeDeDestination, couleur: HZCouleur.encre)
                            .frame(width: HZProfil.disqueDeDestination, height: HZProfil.disqueDeDestination)
                            .background(HZCouleur.surfaceClaire, in: Circle())
                    } queue: {
                        HZChevron()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func ligneDeCourse(_ course: RaceEvent) -> String {
        [course.dateLisible, course.sousTitre].filter { !$0.isEmpty }.joined(separator: " · ")
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

    @ViewBuilder private var listeDeClubs: some View {
        if clubs.isEmpty {
            message(String(localized: "Aucun club à te proposer pour l'instant. Cherche le tien par son nom depuis le Club."))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(clubs.enumerated()), id: \.element.id) { index, club in
                    Button { appState.go(.club) } label: {
                        HZLigneDeListe(titre: club.name, sousTitre: ligneDeClub(club),
                                       marge: HZMesuresDeLigne.margeDeDestination, filet: index < clubs.count - 1) {
                            HZIcone(dessin: .groupe, cote: HZProfil.coteDeLIconeDeDestination, couleur: HZCouleur.encre)
                                .frame(width: HZProfil.disqueDeDestination, height: HZProfil.disqueDeDestination)
                                .background(HZCouleur.surfaceClaire, in: Circle())
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

    private func ligneDeClub(_ club: ClubSearchResult) -> String {
        let membres = Pluriel.choisir(club.memberCount,
                                      String(localized: "\(club.memberCount) membre"),
                                      String(localized: "\(club.memberCount) membres"))
        return [club.city, membres].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
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
            clubs = appState.cachedSuggestedClubs ?? []
            enChargement = false
            return
        }
        // Les courses et les clubs ensemble : ils s'affichent ensemble.
        async let suggeres = service.suggestedClubs()
        do {
            courses = try await service.upcomingRaces()
        } catch {
            panne = PanneReseau.motif(pour: error)
        }
        clubs = await suggeres
        enChargement = false
        await chargerLesItineraires()
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
