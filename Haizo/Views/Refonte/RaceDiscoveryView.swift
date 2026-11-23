import SwiftUI

/// « Qui d'autre court le marathon de Paris ? »
///
/// La porte d'entrée des pages de course : celles qu'on prépare, celles qui approchent, et un
/// champ pour trouver les autres — par le nom, la ville ou le pays. L'app sème les grandes courses
/// du monde, dont chaque caractéristique a été relevée chez l'organisateur, et tout le reste est
/// créé par les coureurs eux-mêmes, au moment où ils en ont besoin. Une page de course n'a pas à
/// exister avant que quelqu'un la prépare.
/// LES COURSES : des pilules de filtre en haut, puis des affiches colorées — la distance en très grand,
/// le nom et ce qu'on en sait dessous. C'est « Courses à venir » d'Explorer, en grille.
struct RaceDiscoveryView: View {
    @Environment(AppState.self) private var appState

    @State private var mine: [RaceEvent] = []
    @State private var upcoming: [RaceEvent] = []
    @State private var query = ""
    @State private var results: [RaceEvent] = []
    @State private var searchEnCours = false
    /// La recherche a échoué (réseau, serveur, session). Sans ce relevé, une panne s'affichait
    /// « Aucune course à venir ne porte ce nom », ce qui est faux et pousse à créer un doublon.
    @State private var recherchePanne: String?
    @State private var searchTask: Task<Void, Never>?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var ouverte: RaceEvent?
    @State private var creationPresentee = false
    @State private var filtre: Filtre = .tout
    /// Le type d'épreuve montré : `nil` pour tous. Le serveur filtre la liste « Ça approche », qui est
    /// limitée aux plus proches ; mes courses, peu nombreuses, se filtrent ici.
    @State private var epreuve: Epreuve?

    /// Ce qu'on montre : tout, ce que je prépare, ce qui approche.
    private enum Filtre: CaseIterable, Identifiable {
        case tout, miennes, aVenir
        var id: Self { self }
        var libelle: String {
            switch self {
            case .tout: return String(localized: "Toutes")
            case .miennes: return String(localized: "Je prépare")
            case .aVenir: return String(localized: "Ça approche")
            }
        }
    }

    /// Les types d'épreuve qu'on peut isoler. Les clefs sont celles du serveur (`discipline`).
    private enum Epreuve: CaseIterable, Identifiable {
        case route, trail, hyrox, triathlon
        var id: Self { self }
        var clef: String {
            switch self {
            case .route: return "run"
            case .trail: return "trail"
            case .hyrox: return "hyrox"
            case .triathlon: return "triathlon"
            }
        }
        var libelle: String {
            switch self {
            case .route: return String(localized: "Route")
            case .trail: return String(localized: "Trail")
            case .hyrox: return String(localized: "Hyrox")
            case .triathlon: return String(localized: "Triathlon")
            }
        }
    }

    private var clubService: ClubService { ClubService(auth: appState.auth) }

    /// Le serveur filtre déjà `upcoming`, mais un serveur plus ancien ignore le paramètre : refiltrer
    /// ici coûte une boucle et rend la liste juste dans les deux cas.
    private func retenues(_ courses: [RaceEvent]) -> [RaceEvent] {
        guard let epreuve else { return courses }
        return courses.filter { $0.discipline == epreuve.clef }
    }

    private var recherche: String { query.trimmingCharacters(in: .whitespaces) }
    private var enRecherche: Bool { recherche.count >= HZHub.lettresPourChercher }

    private let colonnes = Array(repeating: GridItem(.flexible(), spacing: HZEspace.entreTuiles, alignment: .top),
                                 count: HZHub.colonnesDAffiches)

    var body: some View {
        HZPage {
            hautDePage
        } contenu: {
            feuille
        }
        .onChange(of: query) { _, nouveau in chercher(nouveau) }
        .onChange(of: epreuve) { _, _ in Task { await charger() } }
        .fullScreenCover(item: $ouverte) { course in
            RacePageView(race: course) { Task { await charger() } }
                .toastDeModale()
        }
        .sheet(isPresented: $creationPresentee) {
            CreateRaceSheet(nomPropose: recherche) { creee in
                creationPresentee = false
                query = ""
                Task {
                    try? await Task.sleep(for: .milliseconds(HZHub.attenteApresFermeture))
                    ouverte = creee
                    await charger()
                }
            }
            .hzFeuille(detents: [.large], gereSonBas: true)
        }
        .task {
            if isLoading { await charger() }
            #if DEBUG
            if CaptureSeed.courseDemandee { ouverte = appState.cachedRacePage?.race }
            #endif
        }
        .refreshable { await charger() }
    }

    // MARK: - Le haut, sur le noir

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZCommandesDuHaut(retour: { appState.retour(parDefaut: .profile) }) { EmptyView() }
            Text("Courses")
                .hzAffichage(.titreDEcran)
                .foregroundStyle(HZCouleur.blanc)
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZHub.sousLesCommandes)
            HZChampDeRecherche(invite: String(localized: "Nom de la course, sa ville ou son pays"), texte: $query,
                               surNoir: true, enRecherche: searchEnCours)
                .padding(.horizontal, HZEspace.marge)
                .padding(.top, HZHub.sousLaCarte)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HZEspace.entrePilules) {
                    ForEach(Filtre.allCases) { valeur in
                        HZFiltre(libelle: valeur.libelle, actif: filtre == valeur && !enRecherche) {
                            query = ""
                            filtre = valeur
                        }
                    }
                }
                .padding(.horizontal, HZEspace.marge)
            }
            .padding(.top, HZHub.sousLaCarte)
            // Le type d'épreuve, dans une seconde rangée : la première dit QUELLES courses (les miennes,
            // celles qui approchent), celle-ci dit DE QUEL genre.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: HZEspace.entrePilules) {
                    HZFiltre(libelle: String(localized: "Toutes les épreuves"), actif: epreuve == nil && !enRecherche) {
                        query = ""
                        epreuve = nil
                    }
                    ForEach(Epreuve.allCases) { valeur in
                        HZFiltre(libelle: valeur.libelle, actif: epreuve == valeur && !enRecherche) {
                            query = ""
                            epreuve = valeur
                        }
                    }
                }
                .padding(.horizontal, HZEspace.marge)
            }
            .padding(.top, HZEspace.entrePilules)
        }
    }

    // MARK: - La feuille

    @ViewBuilder private var feuille: some View {
        if isLoading {
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, HZFil.enAttente)
        } else if let loadError {
            HZPhrase(texte: String(localized: "Impossible de charger les courses : \(loadError)."))
        } else if enRecherche {
            resultats
        } else {
            let miennes = retenues(mine)
            let aVenir = retenues(upcoming)
            VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                if filtre != .aVenir, !miennes.isEmpty { section(titre: String(localized: "Je prépare"), courses: miennes) }
                if filtre != .miennes, !aVenir.isEmpty {
                    section(titre: String(localized: "Ça approche"), courses: aVenir)
                }
                if (filtre == .miennes && miennes.isEmpty) || (filtre == .aVenir && aVenir.isEmpty)
                    || (miennes.isEmpty && aVenir.isEmpty) {
                    videHonnete
                }
                boutonCreer
            }
        }
    }

    @ViewBuilder
    private var resultats: some View {
        if searchEnCours {
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, HZEspace.entreSections)
        } else if let recherchePanne {
            VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                HZPhrase(texte: recherchePanne)
                HZBoutonPilule(libelle: String(localized: "Réessayer"), hauteur: .petite,
                               fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre) {
                    chercher(query)
                }
            }
        } else if results.isEmpty {
            VStack(alignment: .leading, spacing: HZEspace.groupe) {
                HZPhrase(texte: String(localized: "Aucune course à venir ne porte ce nom."))
                boutonCreer
            }
        } else {
            VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                grille(results)
                boutonCreer
            }
        }
    }

    private func chercher(_ texte: String) {
        searchTask?.cancel()
        let propre = texte.trimmingCharacters(in: .whitespaces)
        guard propre.count >= HZHub.lettresPourChercher else {
            results = []
            searchEnCours = false
            recherchePanne = nil
            return
        }
        searchEnCours = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(HZHub.delaiDeRecherche))
            guard !Task.isCancelled else { return }
            do {
                let trouvees = try await clubService.searchRaces(query: propre)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    results = trouvees
                    recherchePanne = nil
                    searchEnCours = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                let phrase = PanneReseau.phrase(pour: error)
                await MainActor.run {
                    results = []
                    recherchePanne = phrase
                    searchEnCours = false
                }
            }
        }
    }

    // MARK: - Les affiches

    private func section(titre: String, courses: [RaceEvent]) -> some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: titre)
            grille(courses)
        }
    }

    private func grille(_ courses: [RaceEvent]) -> some View {
        LazyVGrid(columns: colonnes, alignment: .leading, spacing: HZEspace.entreSections) {
            ForEach(Array(courses.enumerated()), id: \.element.id) { index, course in
                HZTuileDeCourse(mois: mois(de: course),
                                distance: course.grandeEtiquette,
                                nom: course.name,
                                note: course.noteDAffiche,
                                couleur: HZIntensite.allCases[index % HZIntensite.allCases.count].couleur,
                                largeur: nil) { ouverte = course }
            }
        }
    }

    private func mois(de course: RaceEvent) -> String {
        guard let jour = course.jour else { return course.raceDate }
        return jour.formatted(Date.FormatStyle(timeZone: TimeZone(identifier: "UTC") ?? .gmt,
                                               capitalizationContext: .beginningOfSentence)
            .month(.wide))
    }

    private var videHonnete: some View {
        HZPhrase(texte: String(localized: "Cherche celle que tu prépares. Sur sa page tu verras qui la court aussi, à quelle allure, et où ils en sont de leur préparation."),
                 titre: String(localized: "Aucune course en vue"))
    }

    private var boutonCreer: some View {
        HZBoutonPilule(libelle: String(localized: "Ajouter une course"), hauteur: .grande, etendu: true) {
            creationPresentee = true
        }
    }

    private func charger() async {
        loadError = nil
        if Demonstration.enCours {
            mine = [appState.cachedRacePage?.race].compactMap { $0 }
            upcoming = []
            isLoading = false
            return
        }
        do {
            // Les deux listes ensemble : elles s'affichent ensemble, et les charger l'une après
            // l'autre ferait apparaître la page en deux temps.
            async let miennes = clubService.myRaces()
            async let aVenir = clubService.upcomingRaces(discipline: epreuve?.clef)
            mine = try await miennes
            upcoming = try await aVenir
        } catch {
            loadError = PanneReseau.motif(pour: error)
        }
        isLoading = false
    }
}
