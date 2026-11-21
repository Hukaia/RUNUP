import SwiftUI

/// Bottom sheet reached by tapping the home hero card. Mirrors `SessionDetailSheet` in screensC.jsx.
struct SessionDetailSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var moved = false

    private var session: WorkoutSession { appState.profile.todaySession }

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

    private var detailDeLaCourseCompromise: String {
        allure != nil
            ? String(localized: "\(session.pace) /km entre les blocs · \(session.zone) · enchaîne course et mouvement, sans repos complet")
            : String(localized: "\(session.zone) · enchaîne course et mouvement, sans repos complet")
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

        // UNE SÉANCE DE FAMILLE NE MONTRE QUE SES DEUX STATIONS. Afficher les huit sur une séance
        // qui en travaille deux ferait lire une liste dont six lignes ne concernent pas le jour.
        if let kind, let famille = ChargesHyrox.FamilleDeStations.pour(kind) {
            return [(String(localized: "\(session.durationMinutes)′ · deux stations"),
                     String(localized: "\(session.zone) · à charge de course, technique avant charge"),
                     HZCouleur.accent)]
                + stations(famille.rangs)
        }

        switch kind {
        case .hyroxCompromisedRun3, .hyroxCompromisedRun6, .hyroxCompromisedRunLight2:
            return [
                warmup,
                (String(localized: "\(intervalDescription) + fonctionnel"),
                 detailDeLaCourseCompromise,
                 HZCouleur.accent),
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

    private var entete: some View {
        HStack(alignment: .center, spacing: HZEspace.entreCommandes) {
            Text(isRestDay ? String(localized: "Aujourd'hui") : String(localized: "Séance clé"))
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
                HStack(spacing: HZEspace.entreCommandes) {
                    HZBoutonPilule(libelle: String(localized: "Déplacer à demain"), hauteur: .moyenne,
                                   fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre,
                                   etendu: true, action: deplacerADemain)
                    HZBoutonPilule(libelle: String(localized: "Démarrer"), dessin: .lecture,
                                   hauteur: .moyenne, etendu: true,
                                   cote: HZBoutonPilule.coteDeLecture, action: demarrer)
                }
            }
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
            appState.toast(String(localized: "Impossible de déplacer cette séance : dernier jour de la semaine."))
        }
    }

    private func demarrer() {
        dismiss()
        appState.startRun()
    }
}
