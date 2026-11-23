import SwiftUI

/// Bottom sheet reached by tapping the home hero card. Mirrors `SessionDetailSheet` in screensC.jsx.
struct SessionDetailSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionService.self) private var subscriptions
    @State private var moved = false
    /// « SÉANCE DÉJÀ FAITE » AVAIT PERDU SA PORTE. La feuille qui note une séance faite sans GPS
    /// (tapis, renfo, montre oubliée) existe toujours, mais plus rien ne l'ouvrait dans l'app
    /// livrée : son seul appelant était un drapeau de capture. Elle s'ouvre d'ici, sous les deux
    /// boutons de la séance, tant que la séance du jour n'est pas faite.
    @State private var journalOuvert = false

    /// « Déplacer à demain » ne s'affiche que s'il peut réussir.
    ///
    /// Il était là tout le temps, et répondait « dernier jour de la semaine » un jour de repos, sur
    /// une séance déjà faite ou en course libre : un bouton qui échoue en donnant une fausse raison.
    /// Les quatre conditions sont celles que le moteur vérifie (`moveTodaySessionToTomorrow`), plus
    /// l'abonnement, comme le « Déplacer » de l'accueil.
    private var peutDeplacerADemain: Bool {
        let profil = appState.profile
        return subscriptions.unlocks(.adaptivePlan)
            && appState.peutDeplacerUneSeance
            && !profil.isRestDayToday
            && !profil.seanceDoneToday
            && AdaptivePlanEngine.currentWeekdayIndex() < HZHub.dernierJourDeLaSemaine
    }

    private var session: WorkoutSession {
        #if DEBUG
        // Capture : `--hyrox=<kind>` fait lire à la feuille CETTE séance. Voir `CaptureSeed.seanceHyroxDemandee`.
        if let demandee = CaptureSeed.seanceHyroxDemandee { return demandee }
        #endif
        return appState.profile.todaySession
    }

    /// L'allure de la séance, si c'EN est une. Une séance de natation, de vélo ou de marche en
    /// côte a « — » : écrire « — /km » serait écrire quelque chose de faux. Même règle que
    /// l'accueil (`AccueilModele.allureValide`) : pas d'allure, pas de mesure.
    private var allure: String? { AccueilModele.allureValide(session.pace) }

    /// « 45′ · 4:22 /km · Z2 », ou « 45′ · Z2 » quand la séance n'a pas d'allure.
    private var courseContinue: String {
        if allure != nil {
            return String(localized: "\(session.durationMinutes)′ · \(session.pace) /km · \(session.zone)")
        }
        return String(localized: "\(session.durationMinutes)′ · \(session.zone)")
    }

    /// The real archetype titles from `AdaptivePlanEngine` fall into 3 shapes — a footing/sortie
    /// longue IS an easy continuous effort throughout (no separate warmup/cooldown block at a
    /// different pace makes sense there), a tempo run is one sustained threshold effort, and only
    /// a "Fractionné"/"Rappel d'allure" session is actually structured as reps + recovery. Every
    /// session used to show the same "warmup + N×800m + cooldown" regardless of which of these it
    /// actually was.
    private var steps: [(String, String, Color)] {
        // `session.title` reste EN FRANÇAIS en permanence : c'est l'identifiant interne d'archétype
        // sur lequel les tests ci-dessous classent la séance. Seul l'affichage passe par
        // `displayTitle`. Ne pas localiser ni toucher à cette classification.
        let title = session.title.lowercased()
        // La barre d'une étape prend l'intensité de cette étape : `recuperation` pour
        // l'échauffement et le retour au calme (leur place dans la liste les distingue), l'accent
        // pour le bloc de travail, le gris pour une consigne de logistique.
        let warmup = (String(localized: "Échauffement"), String(localized: "10-15′ · Z2 · footing relâché"), HZIntensite.recuperation.couleur)
        let cooldown = (String(localized: "Retour au calme"), String(localized: "5-10′ · Z1 · marche + étirements"), HZIntensite.recuperation.couleur)

        // HYROX sessions are structurally different from a running-only week — a "compromised
        // running" block or a functional circuit isn't a warmup/interval/cooldown shape at all,
        // so this branches before the running-only logic below ever gets a chance to mislabel it
        // as a generic "Course continue".
        if appState.profile.goalId == .hyrox {
            return hyroxSteps(kind: session.kind, warmup: warmup, cooldown: cooldown)
        }

        // Les séances d'ultra, de même, ne sont pas des séances de route : une côte où l'on MARCHE
        // et une descente répétée tomberaient toutes deux dans « Course continue », avec une
        // allure cible qui ne veut rien dire sur l'une ni sur l'autre.
        //
        // Et contrairement à la branche HYROX juste au-dessus, ce classement-ci lit `kind` et non
        // le titre : les `kind` sont arrivés avec les séances d'ultra, et c'est l'identité
        // indépendante de la langue. Classer par sous-chaîne française quand un champ dédié
        // existe, c'est reconduire une faiblesse qu'on n'est plus obligé de porter.
        if appState.profile.goalId == .ultraTrail, let kind = session.kind {
            return ultraSteps(kind: kind, warmup: warmup, cooldown: cooldown)
        }

        if session.isIntervalSession {
            return [
                warmup,
                (intervalDescription, detailDesIntervalles, HZCouleur.accent),
                cooldown
            ]
        }
        if title.contains("tempo") {
            return [
                warmup,
                (String(localized: "Bloc tempo"), blocTempo, HZCouleur.accent),
                cooldown
            ]
        }
        // Footing / sortie longue / sortie courte / découverte / récup — the whole run is the
        // target effort, not a warmup building up to something else.
        return [(String(localized: "Course continue"), courseContinue, HZCouleur.accent)]
    }

    /// La durée du bloc de travail d'un tempo : la séance moins son échauffement et son retour
    /// au calme, sans descendre sous le minimum d'un vrai bloc.
    private var minutesDeBloc: Int {
        max(HZJournee.minutesMiniDUnBloc, session.durationMinutes - HZJournee.minutesDEchauffementEtDeRetour)
    }

    private var detailDesIntervalles: String {
        allure != nil
            ? String(localized: "\(session.pace) /km · \(session.zone) · récupération entre chaque")
            : String(localized: "\(session.zone) · récupération entre chaque")
    }

    private func detailDuTempoSled(_ sled: String) -> String {
        allure != nil
            ? String(localized: "\(minutesDeBloc)′ · \(session.pace) /km · \(session.zone) · allure seuil entrecoupée de \(sled)")
            : String(localized: "\(minutesDeBloc)′ · \(session.zone) · allure seuil entrecoupée de \(sled)")
    }

    private var blocTempo: String {
        allure != nil
            ? String(localized: "\(minutesDeBloc)′ · \(session.pace) /km · \(session.zone) · effort soutenu et continu")
            : String(localized: "\(minutesDeBloc)′ · \(session.zone) · effort soutenu et continu")
    }


    /// Ce que la séance dit de ses chiffres, en une ligne : un point de départ, que la coureuse allège
    /// si le geste se dégrade, et qu'elle ne dépasse pas. Le programme est construit sur des mesures
    /// (voir `ProgrammeHyrox`), pas recopié d'un protocole officiel : HYROX n'en publie pas.
    private var valeursDeDepart: String {
        String(localized: "ces volumes sont un point de départ : allège d'un tour ou d'un cran de charge si le geste se dégrade, et ne dépasse pas ce qui est écrit")
    }

    /// Le découpage des séances HYROX, par `kind`.
    ///
    /// # DEUX CHOSES QUE CETTE FONCTION FAISAIT MAL
    ///
    /// Elle aiguillait sur des SOUS-CHAÎNES DE TITRE — « compromise », « simulation », « tempo » —
    /// alors que son voisin `ultraSteps` lit le `kind`, et que le commentaire de l'appelant disait
    /// déjà pourquoi : « Classer par sous-chaîne française quand un champ dédié existe, c'est
    /// reconduire une faiblesse qu'on n'est plus obligé de porter. »
    ///
    /// Et cette faiblesse avait une conséquence vivante : un FOOTING HYROX ne contient aucun des
    /// trois mots cherchés. Il tombait donc dans le repli et s'affichait « Circuit fonctionnel ·
    /// stations enchaînées, technique avant charge » — la description d'un circuit de musculation
    /// sur une sortie en endurance. Rien ne plantait, et l'écran disait le contraire de la séance.
    ///
    /// # LES CHARGES SONT CELLES DE SA DIVISION
    ///
    /// Elles s'affichent ICI et pas dans le sous-titre de la séance, pour une raison mécanique :
    /// `displaySubtitle` lit `kind.subtitleKey`, une clé STATIQUE du catalogue, et jette le
    /// sous-titre composé par l'archétype. Les archétypes HYROX interpolaient pourtant
    /// « charge standard » / « charge renforcée » dans le leur depuis le début — du texte qui
    /// n'a jamais atteint un écran. Cet écran-ci a le profil, donc la division, donc les kilos.
    ///
    /// Division inconnue — un profil d'avant les quatre divisions officielles — et les stations
    /// sont nommées sans charge. On ne devine pas si elle pousse 102 ou 202 kg.
    private func hyroxSteps(kind: SessionKind?, warmup: (String, String, Color),
                            cooldown: (String, String, Color)) -> [(String, String, Color)] {
        let charges = appState.profile.hyroxDivision
            .flatMap { HyroxDivision(rawValue: $0) }?.charges

        /// Les stations, avec leur charge quand on la connaît. `rangs` les restreint à une
        /// famille ; sans lui, les huit dans l'ordre de la course.
        func stations(_ rangs: [Int]? = nil) -> [(String, String, Color)] {
            guard let charges else {
                return [(String(localized: "Les huit stations"),
                         String(localized: "choisis ta division pour voir tes charges"),
                         HZCouleur.secondaireSurClair)]
            }
            let toutes = charges.stations
            let choisies = rangs?.compactMap { toutes.indices.contains($0) ? toutes[$0] : nil }
                ?? toutes
            return choisies.map { ($0.nom, $0.prescription, HZCouleur.accent) }
        }

        // UNE SÉANCE DE STATION NE MONTRE QUE SA STATION : sa distance et sa charge pour la division,
        // la séance à faire (séries, distance, repos, intensité), le geste tel que le juge le valide.
        // Afficher les huit sur une séance qui en travaille une ferait lire une liste dont sept
        // lignes ne concernent pas le jour.
        let phase = session.phaseHyrox ?? .base
        let palier = session.palierHyrox ?? 0
        if let kind, let station = ProgrammeHyrox.Station.pour(kind) {
            let ligne = charges.flatMap { charges -> (String, String, Color)? in
                let toutes = charges.stations
                guard toutes.indices.contains(station.rang) else { return nil }
                return (toutes[station.rang].nom, toutes[station.rang].prescription, HZCouleur.accent)
            } ?? (station.nom, String(localized: "choisis ta division pour voir ta charge"),
                  HZCouleur.secondaireSurClair)
            return [
                warmup,
                (String(localized: "La séance"), station.format(phase: phase, palier: palier).texte, HZCouleur.accent),
                (String(localized: "À l'épreuve"), "\(ligne.0) · \(ligne.1)", HZCouleur.secondaireSurClair),
                (String(localized: "Le geste validé"), station.standard, HZCouleur.secondaireSurClair),
                (String(localized: "Comment l'ajuster"), valeursDeDepart, HZCouleur.secondaireSurClair),
                cooldown
            ]
        }

        // LE TRAVAIL COMPLÉMENTAIRE : les gestes, ce qui les relie à l'épreuve, et leur volume.
        if let kind, let travail = ProgrammeHyrox.TravailComplementaire.pour(kind) {
            // LA PHRASE DE PRUDENCE EST À LA FIN, sous son propre titre. Elle était posée sous
            // « 35′ · travail complémentaire », où elle se lisait comme la description de la séance.
            let gestes = travail.gestes(phase: phase.estFacile ? .base : .specifique)
            return [(String(localized: "\(session.durationMinutes)′ · travail complémentaire"),
                     String(localized: "\(gestes.count) gestes, dans l'ordre · la technique avant la charge"),
                     HZCouleur.accent)]
                + gestes.map {
                    ($0.nom, "\($0.intention) · \($0.prescription.texte)", HZCouleur.secondaireSurClair)
                }
                // « Allège d'un tour » ne veut rien dire ici : cette séance n'a pas de tours, elle a des séries.
                + [(String(localized: "Comment l'ajuster"),
                    String(localized: "ces volumes sont un point de départ : allège d'une série ou d'un cran de charge si le geste se dégrade, et ne dépasse pas ce qui est écrit"),
                    HZCouleur.secondaireSurClair)]
        }

        // UN PLAN ENREGISTRÉ AVANT LES SÉANCES PAR STATION peut porter l'ancienne séance de deux
        // stations : elle s'affiche comme avant, ses deux stations et leurs charges.
        if let kind, let famille = ChargesHyrox.FamilleDeStations.enregistree(kind) {
            return [(String(localized: "\(session.durationMinutes)′ · deux stations"),
                     String(localized: "\(session.zone) · à charge de course, technique avant charge"),
                     HZCouleur.accent)]
                + stations(famille.rangs)
        }

        switch kind {
        case .hyroxIntervalles:
            // DES KILOMÈTRES AU SEUIL. La récupération est celle que porte la séance, en mètres : c'est
            // elle que l'écran de course guide.
            let reps = session.intervals?.reps ?? ProgrammeHyrox.repetitionsDesIntervalles(phase: phase, palier: palier)
            let recup = session.intervals?.recoveryMeters ?? ProgrammeHyrox.recuperationDesIntervallesM
            let detail = allure != nil
                ? String(localized: "\(session.pace) /km · allure seuil, soutenue mais tenable · \(recup) m en trottinant entre chaque")
                : String(localized: "allure seuil, soutenue mais tenable · \(recup) m en trottinant entre chaque")
            return [
                warmup,
                (String(localized: "\(reps) × 1 km"), detail, HZCouleur.accent),
                (String(localized: "Pourquoi"),
                 String(localized: "la course fait plus de la moitié du temps d'un HYROX : c'est la séance qui la rend plus rapide, dans l'unité de l'épreuve"),
                 HZCouleur.secondaireSurClair),
                cooldown
            ]

        case .hyroxCourseCompromise, .hyroxSimulation:
            // UN TOUR PAR STATION, DANS L'ORDRE DE L'ÉPREUVE. Les stations, la part de chacune et la charge
            // viennent du palier de la semaine (voir `ProgrammeHyrox.courseCompromise`) : la séance ne
            // répète pas toujours les trois premières stations à la charge de course.
            let seance = ProgrammeHyrox.courseCompromise(phase: phase, palier: palier,
                                                         simulation: kind == .hyroxSimulation)
            let stationsDuJour = Array(seance.stations.prefix(session.intervals?.reps ?? seance.tours))
            let lignes: [(String, String, Color)] = stationsDuJour.enumerated().map { rang, station in
                var apres = station.texte(seance.part)
                // Les kilos ne s'écrivent que quand ce sont ceux de l'épreuve : aux deux tiers, la
                // ligne « Les charges » le dit une fois pour toutes.
                if seance.intensite == .chargeDeCourse, let kilos = charges?.charge(de: station) {
                    apres += " · \(kilos)"
                }
                let suite = allure != nil
                    ? String(localized: "\(session.pace) /km, puis \(apres)")
                    : String(localized: "puis \(apres)")
                return (String(localized: "Tour \(rang + 1) · 1 km + \(station.nom)"), suite, HZCouleur.accent)
            }
            var fin: [(String, String, Color)] = []
            if seance.estLaSimulation {
                fin.append((String(localized: "L'intention"),
                            String(localized: "une répétition générale, pas un chrono : pars moins vite que tu n'en as envie, et note où tu perds du temps"),
                            HZCouleur.secondaireSurClair))
            } else if seance.intensite == .deuxTiers {
                fin.append((String(localized: "Les charges"),
                            String(localized: "sleds, kettlebells et sac aux deux tiers de ta charge de course : ici, c'est repartir en courant qui se travaille"),
                            HZCouleur.secondaireSurClair))
            }
            return [warmup] + lignes + fin + [
                (String(localized: "Comment l'ajuster"), valeursDeDepart, HZCouleur.secondaireSurClair),
                cooldown
            ]

        case .hyroxCompromisedRun3, .hyroxCompromisedRun6, .hyroxCompromisedRunLight2:
            // UN TOUR PAR STATION, DANS L'ORDRE DE L'ÉPREUVE : 1 km de course, puis la station. Trois tours,
            // c'est le SkiErg, le sled push et le sled pull ; six, c'est jusqu'au farmers carry ; deux (la
            // semaine de décharge), le SkiErg et le sled push.
            let tours = session.intervals?.reps ?? ChargesHyrox.Format.segmentsDeCourse
            let dansLOrdre = Array(ProgrammeHyrox.Station.allCases.prefix(tours))
            let lignes: [(String, String, Color)] = dansLOrdre.map { etape in
                let apres: String
                if let charges, charges.stations.indices.contains(etape.rang) {
                    apres = charges.stations[etape.rang].prescription
                } else {
                    apres = String(localized: "choisis ta division pour voir ta charge")
                }
                let suite = allure != nil
                    ? String(localized: "\(session.pace) /km, puis \(apres)")
                    : String(localized: "puis \(apres)")
                return (String(localized: "Tour \(etape.rang + 1) · 1 km + \(etape.nom)"), suite, HZCouleur.accent)
            }
            return [warmup] + lignes + [
                (String(localized: "Comment l'ajuster"), valeursDeDepart, HZCouleur.secondaireSurClair),
                cooldown
            ]

        case .hyroxLightSimulation:
            return [warmup,
                    (String(localized: "\(ChargesHyrox.Format.segmentsDeCourse) × \(ChargesHyrox.Format.courseParSegmentM) m + \(ChargesHyrox.Format.segmentsDeCourse) stations"),
                     String(localized: "format complet HYROX · \(session.zone) · gère l'effort sur l'ensemble, pas juste la course"),
                     HZCouleur.accent)]
                + stations() + [cooldown]

        case .hyroxTempoSled:
            let sled = charges.map {
                String(localized: "sled push \($0.sledPushKg) kg, sled pull \($0.sledPullKg) kg")
            } ?? String(localized: "sled push et sled pull")
            return [
                warmup,
                (String(localized: "Tempo + sled"),
                 detailDuTempoSled(sled),
                 HZCouleur.accent),
                cooldown
            ]

        // LES FOOTINGS SONT DES COURSES, et c'est ce que l'écran doit dire. Ils tombaient dans le
        // repli « circuit fonctionnel » faute d'être reconnus.
        // `tempoRun` EST DANS CETTE LISTE, et il fallait y penser : le bloc spécifique HYROX
        // prescrit maintenant un vrai tempo de course, avec le type générique. Sans cette ligne,
        // il tombait dans le repli « circuit fonctionnel » — le défaut que les footings viennent
        // de subir, reconduit le jour même par la séance que je venais d'ajouter.
        case .hyroxBaseFooting, .hyroxMaintenanceFooting, .hyroxRecoveryFooting, .tempoRun:
            return [(String(localized: "Course continue"), courseContinue, HZCouleur.accent)]

        // Les circuits et les rappels techniques : la séance EST les huit stations. Un échauffement
        // et un retour au calme de coureuse n'ont pas de sens dessus — la préparation du mouvement
        // fait partie du circuit.
        default:
            return [(String(localized: "Circuit fonctionnel"),
                     String(localized: "\(session.durationMinutes)′ · \(session.zone) · stations enchaînées, technique avant charge"),
                     HZCouleur.accent)]
                + stations()
        }
    }

    /// Le découpage des séances d'ultra, par `kind`.
    ///
    /// Trois d'entre elles n'ont AUCUN équivalent sur route, et c'est pour ça qu'elles existent :
    /// la côte où marcher est la technique, la descente qui prépare les quadriceps du jour J, et
    /// le second jour d'un enchaînement, qui se court précisément sur des jambes déjà entamées.
    ///
    /// Les sorties longues portent en plus la consigne de ravitaillement — et elles la portent ICI
    /// parce que c'est l'écran qu'on lit avant de partir. Dire « teste ton alimentation en sortie
    /// longue » dans un écran d'objectif qu'on ouvre une fois, c'est ne pas le dire.
    private func ultraSteps(kind: SessionKind, warmup: (String, String, Color),
                            cooldown: (String, String, Color)) -> [(String, String, Color)] {
        let ravitaillement = (
            String(localized: "Ravitaillement"),
            String(localized: "une prise toutes les \(UltraRaceDay.minutesEntreDeuxPrises) min, à la montre : c'est la séance où tu testes ce que tu mangeras le jour J"),
            // GRIS, et pas une intensité : le ravitaillement n'est pas un effort. C'est une
            // consigne de logistique posée au milieu d'étapes qui, elles, se courent.
            HZCouleur.secondaireSurClair
        )

        switch kind {
        case .ultraHillRepeats:
            return [
                warmup,
                (String(localized: "Côtes de 3 à 5 min"), String(localized: "\(session.zone) · marche dès que la pente l'impose : en ultra c'est la technique, pas un échec"), HZCouleur.accent),
                cooldown
            ]
        case .ultraDescentWork:
            return [
                warmup,
                (String(localized: "Descentes répétées"), String(localized: "monte tranquille, descends en contrôle · ce sont tes quadriceps qu'on prépare, pas un chrono"), HZCouleur.accent),
                cooldown
            ]
        case .ultraPowerHike:
            return [(String(localized: "Marche rapide en côte"), String(localized: "\(session.durationMinutes)′ · le cardio doit monter autant qu'en courant · tes bâtons si tu en auras le jour J"), HZCouleur.accent)]
        case .ultraNightRun:
            return [(String(localized: "À la frontale"), String(localized: "\(session.durationMinutes)′ · en terrain, avec LES DEUX frontales du jour J · le faisceau écrase le relief, tu iras moins vite"), HZCouleur.accent)]
        case .ultraLongRun, .ultraSpecificLongRun, .easedLongRun:
            return [
                (String(localized: "Temps debout"), String(localized: "\(session.durationMinutes)′ · \(session.zone) · c'est la durée qui compte, pas la distance"), HZCouleur.accent),
                ravitaillement
            ]
        case .ultraBackToBackDay1:
            return [
                (String(localized: "Temps debout"), String(localized: "\(session.durationMinutes)′ · \(session.zone) · demain tu repars dessus, donc garde-en"), HZCouleur.accent),
                ravitaillement
            ]
        case .ultraBackToBackDay2:
            return [
                (String(localized: "Sur les jambes de la veille"), String(localized: "\(session.durationMinutes)′ · \(session.zone) · c'est la seconde moitié de ta course, en répétition, et elle doit être inconfortable"), HZCouleur.accent),
                ravitaillement
            ]
        default:
            // Footings d'endurance, d'entretien, rappel de terrain, récup : tout l'effort est la
            // cible, il n'y a pas de bloc à distinguer.
            return [(String(localized: "Course continue"), courseContinue, HZCouleur.accent)]
        }
    }

    /// Pulls the exact "N × distance" straight from the archetype's own title (e.g. "5 × 500 m",
    /// "6 × 800 m", "3 × 1 km") instead of assuming every interval session is 800m repeats.
    private var intervalDescription: String {
        // L'expression régulière porte sur le titre français interne : ne pas y toucher. Seul le
        // repli, qui est du texte affiché, passe par le catalogue.
        if let range = session.title.range(of: #"\d+\s*×\s*\d+\s?(m|km)"#, options: .regularExpression) {
            return String(session.title[range])
        }
        return String(localized: "Fractionné")
    }

    private var isRestDay: Bool { session.durationMinutes == 0 }

    var body: some View {
        // Le titre de la feuille est celui de la séance ; « Séance clé » ou « Aujourd'hui » passe
        // en légende juste dessous.
        HZFeuilleModale(titre: session.displayTitle) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    entete
                    if isRestDay {
                        HZPhrase(texte: session.displaySubtitle)
                            .padding(.top, HZEspace.sousUnTitre)
                    } else {
                        mesures
                        structure
                        explicationDeLAjustement
                    }
                }
                .padding(.horizontal, HZEspace.marge)
            }
            // LE PIED DE LA FEUILLE EST ÉPINGLÉ, Y COMPRIS SA BRANCHE « DÉPLACÉE ».
            //
            // Les deux états partent ensemble : « Déplacer à demain / Démarrer », et la confirmation
            // qui les remplace une fois la séance déplacée. Épingler seulement le premier aurait
            // fait disparaître la barre d'un coup au moment où l'on déplace.
            .safeAreaInset(edge: .bottom, spacing: 0) { pied }
        }
    }

    // MARK: - Le haut

    /// « Séance clé » pour une séance de qualité ou la séance longue, « Séance du jour » pour le reste.
    /// Elle l'écrivait sur TOUTES les séances, y compris un footing ou un travail de mobilité : un mot
    /// qui ne distingue plus rien ne dit plus rien.
    private var legende: String {
        if isRestDay { return String(localized: "Aujourd'hui") }
        switch session.role {
        case .speed, .longRun: return String(localized: "Séance clé")
        case .easy, .none: return String(localized: "Séance du jour")
        }
    }

    private var entete: some View {
        HStack(alignment: .center, spacing: HZEspace.entreCommandes) {
            Text(legende)
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)
            Spacer(minLength: 0)
            if let adj = session.adjustment {
                HZPilule(texte: adj, fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre)
            }
        }
    }

    // MARK: - Les mesures

    /// Durée et allure côte à côte, la zone dessous : « Allure cible » ne tient pas dans un tiers
    /// de la largeur en français. Sans allure (natation, vélo), la durée et la zone se partagent
    /// la rangée.
    private var mesures: some View {
        VStack(spacing: HZEspace.entreTuiles) {
            HStack(spacing: HZEspace.entreTuiles) {
                HZTuileChiffre(libelle: String(localized: "Durée"), valeur: "\(session.durationMinutes)′",
                               format: .resume)
                if let allure {
                    HZTuileChiffre(libelle: String(localized: "Allure cible"),
                                   valeur: allure + HZAccueil.uniteDAllure, format: .resume)
                } else {
                    HZTuileChiffre(libelle: String(localized: "Zone"), valeur: session.zone, format: .resume)
                }
            }
            if allure != nil {
                HZTuileChiffre(libelle: String(localized: "Zone"), valeur: session.zone, format: .resume)
            }
        }
        .padding(.top, HZEspace.sousUnTitre)
    }

    // MARK: - La structure

    private var structure: some View {
        let etapes = steps
        return VStack(alignment: .leading, spacing: 0) {
            HZTitreDeSection(titre: String(localized: "Structure de la séance"))
                .padding(.top, HZEspace.entreSections)
            VStack(spacing: HZEspace.entrePilules) {
                ForEach(etapes.indices, id: \.self) { i in
                    etape(etapes[i])
                }
            }
            .padding(.top, HZEspace.sousUnTitre)
        }
    }

    private func etape(_ pas: (String, String, Color)) -> some View {
        HStack(spacing: HZEspace.entreCommandes) {
            RoundedRectangle(cornerRadius: HZJournee.rayonDeLaBarre, style: .circular)
                .fill(pas.2)
                .frame(width: HZJournee.largeurDeLaBarre)
            VStack(alignment: .leading, spacing: HZJournee.entreTitreEtDetail) {
                Text(pas.0)
                    .hzParagraphe(.c15, .gras, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.encre)
                Text(pas.1)
                    .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(HZEspace.tuile)
        .background(HZCouleur.surfaceClaire,
                    in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
        .accessibilityElement(children: .combine)
    }

    // MARK: - L'ajustement

    @ViewBuilder private var explicationDeLAjustement: some View {
        if let adj = session.adjustment {
            // Two different mechanisms can set this same field (see `WorkoutSession.
            // adjustment`) — a week-boundary tier bump/ease from LAST week's average
            // RPE ("Niveau X"), or a same-day reactive lightening from TODAY's sleep/
            // yesterday's RPE (`AdaptivePlanEngine.applySameDayAdjustmentIfNeeded`,
            // always prefixed "Allégée"). Explaining the tier-change copy on a same-day
            // reason (or vice versa) would just be wrong about why this looks different.
            HZPlaque {
                if adj.hasPrefix("Allégée") {
                    HZPhrase(texte: String(localized: "Cette séance a été allégée aujourd'hui d'après ta forme du jour. La semaine reprend son cours normal demain."))
                } else {
                    HZPhrase(texte: String(localized: "Le coach a ajusté cette semaine à « \(adj) » d'après ta forme la semaine dernière."))
                }
            }
            .padding(.top, HZEspace.entreSections)
        }
    }

    // MARK: - Le pied

    @ViewBuilder private var pied: some View {
        Group {
            if moved {
                Text(String(localized: "Séance déplacée à demain ✓"))
                    .hzTexte(.c16, .semi)
                    .foregroundStyle(HZCouleur.encre)
                    .frame(maxWidth: .infinity)
                    .frame(height: HZHauteurDeBouton.grande.rawValue)
                    .background(HZCouleur.surfaceClaire, in: Capsule())
            } else {
                VStack(spacing: HZEspace.entrePilules) {
                    HStack(spacing: HZEspace.entreCommandes) {
                        if peutDeplacerADemain {
                            HZBoutonPilule(libelle: String(localized: "Déplacer à demain"), hauteur: .moyenne,
                                           fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre,
                                           etendu: true, action: deplacerADemain)
                        }
                        HZBoutonPilule(libelle: String(localized: "Démarrer"), dessin: .lecture,
                                       hauteur: .moyenne, etendu: true,
                                       cote: HZBoutonPilule.coteDeLecture, action: demarrer)
                    }
                    if !appState.profile.seanceDoneToday {
                        Button(action: { journalOuvert = true }) {
                            Text("Je l'ai déjà faite")
                                .hzTexte(.c14, .semi)
                                .foregroundStyle(HZCouleur.secondaireSurClair)
                                .frame(maxWidth: .infinity, minHeight: HZBoutonRond.zoneTactile)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Note la séance sans passer par le GPS")
                    }
                }
            }
        }
        .sheet(isPresented: $journalOuvert, onDismiss: {
            // Notée : la fiche de la séance n'a plus rien à proposer, on revient à l'écran.
            if appState.profile.seanceDoneToday { dismiss() }
        }) {
            LogSessionSheet()
                .hzFeuille(detents: [.medium], gereSonBas: true)
        }
        .padding(.horizontal, HZEspace.marge)
        .padding(.top, HZEspace.entreCommandes)
        .padding(.bottom, HZHub.basDeFeuille)
        .frame(maxWidth: .infinity)
        .background(HZCouleur.blanc)
    }

    private func deplacerADemain() {
        // Really swaps today/tomorrow in the plan — this used to only set
        // the local `moved` flag and claim success without touching
        // `weekSessions` at all.
        if AdaptivePlanEngine.moveTodaySessionToTomorrow(appState.profile) {
            moved = true
            appState.publishWidgetSnapshot()
            appState.toast(String(localized: "Séance déplacée à demain"))
        } else {
            // Le bouton ne s'affiche plus quand le déplacement est impossible ; s'il échoue quand
            // même, on ne prétend pas en connaître la raison.
            appState.toast(String(localized: "Cette séance n'a pas pu être déplacée."))
        }
    }

    private func demarrer() {
        dismiss()
        appState.startRun()
    }
}
