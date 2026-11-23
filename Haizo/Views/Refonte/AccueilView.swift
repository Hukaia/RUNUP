import SwiftData
import SwiftUI

/// L'ACCUEIL, refait à partir des composants de la refonte.
///
/// Le canvas dessine un mardi, une séance de fractionné, un coach qui a vu qu'on avait mal dormi.
/// Rien de cela n'est écrit ici : chaque texte vient des vraies données — la séance du jour, les
/// jours du plan, les sorties enregistrées — par `AccueilModele`, qui décide de ce qu'on affiche
/// et de ce qu'on tait. Cette vue pose.
///
/// # LES ÉTATS QUE LE CANVAS NE DESSINE PAS
///
/// - **Jour de repos** : « Off », et le nom du repos. Le canvas montre ce même « Off » sur la
///   carte du plan.
/// - **Séance faite** : la pilule dit « Fait », comme celle de la carte du plan.
/// - **Le plan prévoyait du repos et on court quand même** : « Libre ».
/// - **Plan verrouillé** (Haizo Plus) : pas de semaine, pas de séance, pas de « Déplacer » ni de
///   « Semaine » ; une course libre, le coach, et l'offre en bas de feuille. L'offre garde pour
///   l'instant son ancien habillage : c'est l'un des écrans que le canvas ne dessine pas, et la
///   méthode veut qu'il soit habillé avec les mêmes composants puis montré avant d'être validé.
/// - **Récupération et choix** : ces deux phases ont leurs propres écrans, qui ne sont pas encore
///   refaits.
///
/// # CE QUE LE CANVAS RETIRE DE L'ACCUEIL
///
/// L'anneau des objectifs du jour, la carte de la semaine du programme, la ligne « demain », les
/// premiers jalons, et le bouton « + » qui ajoute une séance déjà faite. Ils ne sont plus sur cet
/// écran ; leurs destinations existent toujours. Voir PROGRESS.md.
struct AccueilView: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionService.self) private var subscriptions
    @Query(filter: #Predicate<AppNotification> { !$0.read }) private var nonLues: [AppNotification]
    @Query private var courses: [RunRecord]
    @State private var sortieOuverte: RunRecord?

    init() {
        let limite = Calendar.current.date(byAdding: .weekOfYear, value: -HZAccueil.semainesDHistorique,
                                           to: .now) ?? .distantPast
        _courses = Query(filter: #Predicate<RunRecord> { $0.date >= limite },
                         sort: \RunRecord.date, order: .reverse)
    }

    private var profile: UserProfile { appState.profile }
    private var planDebloque: Bool { subscriptions.unlocks(.adaptivePlan) }

    var body: some View {
        Group {
            switch planDebloque ? profile.programPhase : .active {
            case .recovery: RecoveryView()
            case .choice: ChoiceView()
            default: page
            }
        }
    }

    // MARK: - La page

    private var page: some View {
        ScrollView {
            // La feuille REMONTE sur le haut de page d'un rayon de coin : l'accent passe derrière
            // ses coins arrondis (ils étaient blancs sur du blanc).
            VStack(alignment: .leading, spacing: -HZRayon.feuille) {
                hautDePage
                feuille
            }
        }
        .scrollIndicators(.hidden)
        // Deux moitiés de fond : le noir en haut, le blanc en bas. Un défilement qui dépasse son
        // bord — vers le haut comme vers le bas — montre alors la couleur de ce qui s'y trouve.
        .background {
            VStack(spacing: 0) {
                HZCouleur.noir
                HZCouleur.blanc
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea(edges: .top)
        .statusBarHidden()
        .sheet(item: $sortieOuverte) { course in
            RecapView(historicalRun: course)
        }
    }

    // MARK: - Le haut, sur le noir

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            entete
            if let jours = semaine {
                semaineEnPoints(jours)
            }
            seance
            actions
        }
        .padding(.top, HZEspace.haut)
        .padding(.bottom, HZRayon.feuille)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HZCouleur.noir)
    }

    private var entete: some View {
        HStack(spacing: HZEspace.entreCommandes) {
            HZAvatar(initiales: AccueilModele.initiales(prenom: profile.name, nom: profile.lastName),
                     nom: String(localized: "Profil"), fond: HZCouleur.surfaceSombre) {
                appState.go(.profile)
            }
            // LA RECHERCHE MÈNE À EXPLORER, où la même question (« Où cours-tu aujourd'hui ? ») est
            // posée au-dessus des itinéraires, des courses et des clubs. Elle ouvrait la page du
            // club : un raccourci provisoire d'avant l'écran Explorer, resté en place comme celui
            // des cinq catégories plus bas.
            HZAmorceDeRecherche(invite: String(localized: "Où cours-tu aujourd'hui ?"),
                                fond: HZCouleur.surfaceSombre) {
                appState.go(.explorer)
            }
            HZBoutonRond(dessin: .cloche, nom: libelleDesNotifications, fond: HZCouleur.surfaceSombre) {
                appState.openNotifications()
            }
        }
        .padding(.horizontal, HZEspace.marge)
    }

    private var libelleDesNotifications: String {
        nonLues.isEmpty
            ? String(localized: "Notifications")
            : String(localized: "Notifications, \(nonLues.count)")
    }

    // MARK: - La semaine

    private var indexDuJour: Int {
        (Calendar.current.component(.weekday, from: Demonstration.maintenant) + HZAccueil.decalageDuLundi)
            % HZAccueil.joursParSemaine
    }

    /// Sept jours, ou rien : sans plan (verrouillé, ou pas encore généré) il n'y a pas de semaine à
    /// montrer, et sept points éteints diraient « sept jours de repos ».
    private var semaine: [(initiale: String, etat: HZEtatDeJour)]? {
        guard planDebloque, profile.weekSessions.count == HZAccueil.joursParSemaine,
              profile.weekSessions.contains(where: { ($0.session?.durationMinutes ?? 0) > 0 })
        else { return nil }
        let etats = AccueilModele.etatsDeLaSemaine(jours: profile.weekSessions, aujourdHui: indexDuJour)
        let symboles = Calendar.current.veryShortStandaloneWeekdaySymbols
        guard symboles.count == HZAccueil.joursParSemaine else { return nil }
        return etats.enumerated().map { indice, etat in
            (initiale: symboles[(indice + 1) % HZAccueil.joursParSemaine], etat: etat)
        }
    }

    private func semaineEnPoints(_ jours: [(initiale: String, etat: HZEtatDeJour)]) -> some View {
        Button {
            appState.go(.plan)
        } label: {
            HZSemaineEnPoints(jours: jours, encre: HZCouleur.secondaireSurSombre,
                              pointDeRepos: HZCouleur.pointEteint)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Voir la semaine"))
        .padding(.horizontal, HZEspace.marge)
        .padding(.top, HZAccueil.sousLesCommandes)
    }

    // MARK: - La séance du jour

    private var heroDuJour: AccueilModele.Hero {
        AccueilModele.hero(session: profile.todaySession,
                           estUnJourDeRepos: profile.isRestDayToday,
                           faiteAujourdhui: profile.seanceDoneToday,
                           titreDeLaCourseLibre: String(localized: "Course libre"))
    }

    private var seance: some View {
        let hero = heroDuJour
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(AccueilModele.dateDuJour(Demonstration.maintenant))
                    .hzTexte(.c15, .gras)
                    .foregroundStyle(HZCouleur.secondaireSurSombre)
                Spacer(minLength: 0)
                HZPilule(texte: hero.faite ? String(localized: "Fait") : String(localized: "Aujourd'hui"),
                         fond: HZCouleur.surfaceSombre)
            }
            if let prefixe = hero.prefixe {
                Text(prefixe)
                    .hzAffichage(.prefixeDeSeance)
                    .padding(.top, HZAccueil.sousLaDate)
            }
            Text(texte(du: hero.nombre))
                .hzAffichage(.seance)
                .hzVedette()
                .minimumScaleFactor(HZAccueil.reductionDuNombre)
                .padding(.leading, -HZAccueil.debordDuNombre)
            Text(hero.titre)
                .hzTexte(.c20, .gras)
                .padding(.top, HZAccueil.sousLeNombre)
            if !hero.mesures.isEmpty {
                HZPilule(texte: hero.mesures.map(texte(de:)).joined(separator: " · "), style: .chiffres,
                         fond: HZCouleur.surfaceSombre)
                    .padding(.top, HZAccueil.sousLeNom)
            }
        }
        .foregroundStyle(HZCouleur.blanc)
        .padding(.horizontal, HZEspace.margeDeTitre)
        .padding(.top, HZAccueil.sousLaSemaine)
        .contentShape(Rectangle())
        .onTapGesture { appState.openSessionDetail() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private func texte(du nombre: AccueilModele.Nombre) -> String {
        switch nombre {
        case .valeur(let valeur): return valeur
        case .repos: return String(localized: "Off")
        case .libre: return String(localized: "Libre")
        }
    }

    private func texte(de mesure: AccueilModele.Mesure) -> String {
        switch mesure {
        case .minutes(let minutes): return String(localized: "\(minutes) min")
        case .allure(let allure): return allure + HZAccueil.uniteDAllure
        case .zone(let zone): return zone
        }
    }

    // MARK: - Les quatre actions

    private var actions: some View {
        HStack(spacing: 0) {
            HZAction(dessin: .lecture, libelle: String(localized: "Démarrer"), pleine: true,
                     cote: HZAction.coteDeLecture, encreDuLibelle: HZCouleur.blanc) {
                appState.startRun()
            }
            if planDebloque && appState.peutDeplacerUneSeance {
                HZAction(dessin: .deplacer, libelle: String(localized: "Déplacer"),
                         fondDeLaPastille: HZCouleur.surfaceSombre, encreDuLibelle: HZCouleur.blanc) {
                    appState.openMoveSession()
                }
            }
            HZAction(dessin: .bulle, libelle: String(localized: "Coach"),
                     fondDeLaPastille: HZCouleur.surfaceSombre, encreDuLibelle: HZCouleur.blanc) {
                appState.go(.coach)
            }
            if planDebloque {
                HZAction(dessin: .calendrier, libelle: String(localized: "Semaine"),
                         fondDeLaPastille: HZCouleur.surfaceSombre, encreDuLibelle: HZCouleur.blanc) {
                    appState.go(.plan)
                }
            }
        }
        .padding(.horizontal, HZEspace.groupe)
        .padding(.top, HZAccueil.sousLaSeance)
        .padding(.bottom, HZAccueil.sousLesActions)
    }

    // MARK: - La feuille

    private var feuille: some View {
        HZFeuille(retrait: .ample) {
            if let texte = texteDuCoach {
                HZBandeauDuCoach(texte: texte)
            }
            if !prochaines.isEmpty { laSuite }
            explorer
            dernieresSorties
            if !planDebloque {
                PlusLockCard(feature: .adaptivePlan, showsFreeReminder: false)
                    .padding(.top, HZEspace.entreSections)
            }
            Color.clear.frame(height: HZAccueil.basDePage)
        }
        .frame(minHeight: HZAccueil.hauteurMiniDeLaFeuille, alignment: .top)
    }

    /// Ce que dit le coach de la séance du jour : l'ajustement qu'il y a fait s'il y en a un, sinon
    /// la raison d'être de la séance. Rien, s'il n'a rien à dire — la place reste libre plutôt que
    /// de montrer un bandeau vide.
    private var texteDuCoach: String? {
        let session = profile.todaySession
        // « NIVEAU 2 » SEUL NE DIT RIEN. La carte affichait l'étiquette de l'ajustement telle quelle,
        // deux mots dans un bandeau du coach. Elle dit maintenant la même phrase que la fiche de
        // la séance : qui a ajusté, à quoi, et d'après quoi.
        // Seulement pour l'étiquette de niveau : un allègement du coach arrive déjà en phrase entière
        // (« Tu as peu dormi… »), et s'affiche tel quel.
        if let ajustement = session.adjustment {
            if ajustement == String(localized: "Niveau \(profile.weekTier)") {
                // L'étiquette ne se coupe pas : « Niveau » en fin de ligne et « 2 » seul à la suivante,
                // c'est ce que la première capture de cette phrase montrait. Les guillemets non plus.
                // ET LA PHRASE EST PLUS COURTE QUE CELLE DE LA FICHE : une fois l'étiquette insécable,
                // la phrase entière prenait trois lignes au lieu de deux, et ces 19 points repoussaient
                // les libellés des catégories derrière la barre flottante sur un écran de 6,1 pouces.
                let insecable = HZAccueil.espaceInsecable
                let etiquette = ajustement.replacingOccurrences(of: " ", with: insecable)
                return String(localized: "Semaine ajustée à « \(etiquette) » d'après ta forme de la semaine passée.")
                    .replacingOccurrences(of: "« ", with: "«" + insecable)
                    .replacingOccurrences(of: " »", with: insecable + "»")
            }
            return String(localized: String.LocalizationValue(ajustement))
        }
        return PourquoiCetteSeance.phrase(pour: profile, session: session,
                                          estUnJourDeRepos: profile.isRestDayToday)
    }

    // MARK: - La suite

    private var prochaines: [AccueilModele.Prochaine] {
        guard planDebloque else { return [] }
        return AccueilModele.prochaines(jours: profile.weekSessions, aujourdHui: indexDuJour,
                                        nomsDesJours: DayStatus.fullNames)
    }

    private var laSuite: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZTitreDeSection(titre: String(localized: "La suite"), lien: String(localized: "Ma semaine")) {
                appState.go(.plan)
            }
            .padding(.top, HZEspace.entreSections)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: HZEspace.entreTuiles) {
                    ForEach(prochaines) { prochaine in
                        Button {
                            // Le Plan s'ouvre sur LE JOUR TOUCHÉ. Il s'ouvrait sur aujourd'hui :
                            // on touchait « jeudi » et il fallait le rechercher dans la rangée.
                            appState.ouvrirLePlan(sur: prochaine.id)
                        } label: {
                            tuile(prochaine)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.trailing, -HZEspace.marge)
            .padding(.top, HZEspace.sousUnTitre)
        }
    }

    private func tuile(_ prochaine: AccueilModele.Prochaine) -> some View {
        let intensite = AccueilModele.intensite(de: prochaine.famille)
        return HZTuileLegendee(
            libelle: prochaine.jour,
            valeur: prochaine.duree,
            titre: prochaine.titre,
            precision: precision(de: prochaine),
            fond: intensite?.couleur ?? HZCouleur.surfaceSombre,
            encreDuLibelle: HZCouleur.blanc,
            graisseDuLibelle: .semi)
    }

    private func precision(de prochaine: AccueilModele.Prochaine) -> String {
        let famille = libelle(de: prochaine.famille)
        return prochaine.zone.isEmpty ? famille : famille + " · " + prochaine.zone
    }

    private func libelle(de famille: SessionFamily) -> String {
        switch famille {
        case .rest: return String(localized: "Repos")
        case .recovery: return String(localized: "Récupération")
        case .endurance: return String(localized: "Endurance")
        case .longRun: return String(localized: "Sortie longue")
        case .tempo: return String(localized: "Seuil")
        case .intervals: return String(localized: "Fractionné")
        case .functional: return String(localized: "Renforcement")
        }
    }

    // MARK: - Explorer

    private var explorer: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZTitreDeSection(titre: String(localized: "Explorer"))
                .padding(.top, HZAccueil.avantUneSectionBasse)
            // CHAQUE CATÉGORIE MÈNE À CE QU'ELLE NOMME. Les cinq menaient au hub du Club, un raccourci
            // provisoire d'avant l'écran Explorer, resté en place : « HYROX » ouvrait la page d'un club.
            // Route, Trail, HYROX et Clubs ouvrent Explorer sur leur filtre ; Courses ouvre la liste des
            // courses, celle que « Tout voir » ouvre déjà depuis Explorer.
            HStack(spacing: 0) {
                HZCategorie(dessin: .route, libelle: String(localized: "Route")) { appState.ouvrirExplorer(.route) }
                HZCategorie(dessin: .relief, libelle: String(localized: "Trail")) { appState.ouvrirExplorer(.trail) }
                HZCategorie(dessin: .haltere, libelle: String(localized: "HYROX")) { appState.ouvrirExplorer(.hyrox) }
                HZCategorie(dessin: .groupe, libelle: String(localized: "Clubs")) { appState.ouvrirExplorer(.clubs) }
                HZCategorie(dessin: .drapeau, libelle: String(localized: "Courses")) {
                    appState.openRacesTabOnNextVisit = true
                    appState.go(.club)
                }
            }
            .padding(.top, HZEspace.sousUnTitre)
        }
    }

    // MARK: - Dernières sorties

    private var dernieres: [RunRecord] {
        Array(courses.prefix(HZAccueil.sortiesAffichees))
    }

    private var dernieresSorties: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZTitreDeSection(titre: String(localized: "Dernières sorties"),
                             lien: String(localized: "Tout voir")) {
                // L'historique, et non les Stats : « Tout voir » sous deux sorties promet la liste
                // des sorties. Son retour ramène ici (`AppState.retour`).
                appState.go(.history)
            }
            .padding(.top, HZAccueil.avantUneSectionBasse)
            if dernieres.isEmpty {
                Text(String(localized: "Tes sorties apparaîtront ici."))
                    .hzTexte(.c14, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .padding(.top, HZEspace.sousUnTitre)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(dernieres) { course in
                        ligne(course, derniere: course.persistentModelID == dernieres.last?.persistentModelID)
                    }
                }
                .padding(.top, HZAccueil.sousLeTitreDesSorties)
            }
        }
    }

    private func ligne(_ course: RunRecord, derniere: Bool) -> some View {
        Button {
            sortieOuverte = course
        } label: {
            HZLigneDeListe(titre: course.titreAffiche,
                           sousTitre: AccueilModele.dateCourte(course.date),
                           filet: !derniere) {
                HZVignette {
                    HZMiniatureDeSortie(points: course.route.map { (lat: $0.lat, lng: $0.lng) })
                }
            } queue: {
                HZValeurDeLigne(valeur: String(format: "%.1f km", locale: .current, course.distanceKm),
                                precision: precision(de: course))
            }
        }
        .buttonStyle(.plain)
    }

    /// L'allure d'une course à pied, la durée pour le reste : une sortie de vélo n'a pas d'allure
    /// au kilomètre, et « — /km » serait faux.
    private func precision(de course: RunRecord) -> String {
        if course.discipline.rythme == .allureParKm,
           let allure = AccueilModele.allureValide(course.avgPace) {
            return allure + HZAccueil.uniteDAllure
        }
        return PaceModel.formatDuration(Double(course.durationSeconds))
    }
}
