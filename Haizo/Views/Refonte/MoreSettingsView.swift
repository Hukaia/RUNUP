import SwiftUI
import UIKit
import ActivityKit

/// « Plus de réglages » — la feuille qu'ouvre la dernière ligne de `SettingsView` : Course, Apple
/// Watch, Programme, Santé & blessures, Cycle, Confidentialité, Inviter, Compte, Mes données, Aide.
/// Des réglages réels qu'elle a demandé à garder, mais qu'on ne touche pas assez souvent pour
/// qu'ils méritent de la place sur la page qu'on ouvre le plus.
///
/// Même famille que `SettingsView` : des groupes de lignes sur la surface claire, un titre gris
/// au-dessus de chacun, des interrupteurs noirs. Les mêmes valeurs sont écrites aux mêmes endroits
/// qu'avant : seul ce qu'on voit a changé.
struct MoreSettingsView: View {
    /// L'ancre que la capture du cycle vise. Nommée une fois : la poser et la viser sont deux
    /// endroits différents, et une chaîne écrite deux fois finit par diverger.
    static let ancreDuCycle = "bloc-du-cycle"

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(AppState.self) private var appState
    private var profile: UserProfile { appState.profile }
    private var clubService: ClubService { ClubService(auth: appState.auth) }

    @State private var ficheAdminOuverte = false
    @State private var showDeleteAccountConfirm = false
    @State private var isDeletingAccount = false
    @State private var firstNameText = ""
    @State private var usernameText = ""
    @State private var lastNameText = ""
    @State private var isSavingIdentity = false
    @State private var identityError: String?
    /// L'interrupteur « Activités en direct » du téléphone, suivi en continu — voir
    /// `ecranVerrouille`.
    @State private var activitesEnDirectActives = ActivityAuthorizationInfo().areActivitiesEnabled

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Plus de réglages")) {
            ScrollView {
                // # LA CAPTURE DU CYCLE NOMME SA DESTINATION, ELLE NE COMPTE PLUS LES GESTES
                //
                // Le bloc du cycle est une carte du milieu de cet écran, et la seule image qui le
                // montre y arrivait par trois glissements en coordonnées : selon la langue, les
                // cartes précédentes sont plus ou moins longues, donc trois gestes tombaient à
                // trois endroits. Une fonctionnalité dont l'unique image dépend de la longueur des
                // textes qui la précèdent n'est pas photographiée, elle est tirée au sort.
                //
                // `ScrollViewReader` ne rouvre PAS le piège que `CapturesUITests` documente : ce
                // qui avait tué le premier essai, c'était d'interroger l'arbre d'accessibilité
                // DEPUIS LE TEST. Ici le défilement se décide dans l'app, qui connaît ses propres
                // vues, et le test ne demande rien.
                ScrollViewReader { defileur in
                    sections
                        // Rien en production : `cycleDemande` lit un argument de lancement qui
                        // n'existe que sous la capture, et le bloc est compilé hors des versions
                        // publiées.
                        #if DEBUG
                        .onAppear {
                            guard CaptureSeed.cycleDemande else { return }
                            DispatchQueue.main.asyncAfter(deadline: .now() + HZCompte.attenteAvantLeDefilement) {
                                defileur.scrollTo(Self.ancreDuCycle, anchor: .center)
                            }
                        }
                        #endif
                }
            }
            .scrollIndicators(.hidden)
        }
        // `task(id:)` et non `onAppear` : `currentUser` arrive du serveur, et il peut très bien
        // n'être pas encore là quand cette feuille s'ouvre. Rempli une seule fois à
        // l'apparition, le champ « Pseudo » restait alors VIDE alors que le compte en a un —
        // et « Enregistrer » envoyait cette chaîne vide, ce qui effaçait le pseudo. Une perte
        // de donnée silencieuse, déclenchée par un geste qui prétendait sauvegarder.
        .task(id: appState.auth.currentUser?.id) {
            // Le prénom du COMPTE, pas celui du profil local : ce sont deux choses, et c'est
            // précisément quand elles divergent que ce champ sert. Si le compte a été rangé
            // sous « Coureur » faute de nom transmis par Apple, on propose le prénom donné à
            // l'inscription — un appui sur « Enregistrer » et la recherche le retrouve.
            let duCompte = appState.auth.currentUser?.name ?? ""
            let localement = appState.profile.name.trimmingCharacters(in: .whitespaces)
            firstNameText = (duCompte.isEmpty || duCompte == AuthService.nomParDefaut) && !localement.isEmpty
                ? localement
                : duCompte
            usernameText = appState.auth.currentUser?.username ?? ""
            // Même repli que pour le prénom : le nom de l'inscription quand le compte n'en
            // a pas. Un compte créé avant que l'inscription ne le demande n'en a aucun.
            let nomDuCompte = appState.auth.currentUser?.lastName ?? ""
            let nomLocal = appState.profile.lastName.trimmingCharacters(in: .whitespaces)
            lastNameText = nomDuCompte.isEmpty ? nomLocal : nomDuCompte
        }
        .sheet(isPresented: $ficheAdminOuverte) {
            AdminSheet().hzFeuille(detents: [.large])
        }
    }

    /// Les groupes, dans l'ordre de la page. Chacun est une vue à part : le type-checker de Swift
    /// ne tiendrait pas un corps de cette taille d'un seul tenant.
    private var sections: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreSections) {
            course
            watch
            programme
            blessure

            if profile.sex == "female" {
                cycle.id(Self.ancreDuCycle)
            }

            confidentialite

            if appState.auth.isSignedIn {
                invitation
                compte
            }

            // LA FICHE DE LA MAISON, ET PRESQUE UNIQUEMENT POUR LA MAISON.
            //
            // La condition était `isAdmin` seul, et c'était un cercle fermé : la fiche existe
            // pour afficher l'ADRESSE QUE LE SERVEUR VOIT — la seule à inscrire dans
            // `RUNUP_ADMIN_EMAILS`, parce que « Se connecter avec Apple » peut l'avoir créée sous
            // un `…@privaterelay.appleid.com` que personne ne devine. Mais on ne pouvait l'ouvrir
            // qu'une fois déjà dans la liste. Deux de ses trois états — « aucune liste » et « pas
            // dans la liste » — étaient donc inatteignables, y compris celui qui explique quoi
            // faire.
            //
            // Seconde condition : tant qu'AUCUNE liste n'existe côté serveur. Cette fenêtre se
            // referme d'elle-même à la minute où la variable est posée, et elle est sans danger
            // pendant qu'elle dure — la fiche ne commande rien, elle lit.
            //
            // « Pas dans la liste » reste inatteignable depuis ici, et c'est voulu : à ce
            // moment-là une liste existe, et personne hors de la maison n'a à lire comment on y
            // entre. L'adresse que le serveur voit est affichée dans « Compte », pour tout le monde.
            if appState.auth.currentUser?.isAdmin == true
                || appState.auth.currentUser?.adminListConfigured == false {
                maison
            }

            // LE FILET SOUS LES DONNÉES. Voir `Haizo/Services/Sauvegarde.swift` : rien d'autre ne
            // garde la conversation avec le coach, les ressentis, les chaussures, la série ou le
            // programme en cours — Apple Santé n'a que les courses.
            HZGroupeDeReglages(titre: String(localized: "Mes données")) {
                CarteDeSauvegarde()
            }

            aide
        }
        .padding(.horizontal, HZEspace.marge)
        .padding(.bottom, HZReglages.basDePage)
    }

    // MARK: - Course

    private var course: some View {
        HZGroupeDeReglages(titre: String(localized: "Course")) {
            MoreSettingsLigne(titre: String(localized: "Pause automatique aux arrêts"),
                              precision: String(localized: "Met la course en pause si tu t'arrêtes, reprend toute seule.")) {
                interrupteur(Binding(get: { profile.autoPauseEnabled }, set: { profile.autoPauseEnabled = $0 }))
                    .accessibilityLabel("Pause automatique aux arrêts")
            }
            MoreSettingsLigne(titre: String(localized: "Consignes vocales"),
                              precision: String(localized: "Annonce chaque répétition et chaque récupération, et prévient si tu t'écartes de ton allure cible.")) {
                interrupteur(Binding(get: { profile.paceAlertsEnabled }, set: { profile.paceAlertsEnabled = $0 }))
                    .accessibilityLabel("Consignes vocales pendant la séance")
            }
            ecranVerrouille
        }
        // `activityEnablementUpdates` ET NON UNE LECTURE AU MONTAGE. Cette ligne existe pour
        // qu'elle aille rallumer l'interrupteur, donc elle est lue juste avant qu'il change —
        // elle revient des Réglages dans la même session, et un état lu une seule fois resterait
        // faux sous ses yeux, à l'endroit précis qui vient de lui demander d'agir.
        .task {
            for await actives in ActivityAuthorizationInfo().activityEnablementUpdates {
                activitesEnDirectActives = actives
            }
        }
    }

    private func interrupteur(_ valeur: Binding<Bool>) -> some View {
        Toggle("", isOn: valeur)
            .labelsHidden()
            .toggleStyle(HZStyleDInterrupteur())
    }

    /// L'AFFICHAGE SUR L'ÉCRAN VERROUILLÉ : UNE LIGNE D'ÉTAT, PAS UNE BASCULE.
    ///
    /// L'interrupteur n'est pas à nous. iOS le tient, dans Réglages → Haizo → Activités en
    /// direct, et aucune API ne le change depuis l'app. Une bascule ici promettrait de le faire
    /// et n'y arriverait pas : la pire des deux options, parce qu'elle a l'air de marcher.
    ///
    /// La ligne dit donc ce qui est vrai, et quand c'est éteint elle ouvre l'endroit où ça se
    /// rallume. C'est le pendant durable du bandeau de l'écran de course, qui s'efface au bout de
    /// quarante-cinq secondes : un message qui ne dure pas peut se manquer, et celui-ci se trouve
    /// quand on le cherche.
    ///
    /// UN BOUTON QUAND IL Y A QUELQUE CHOSE À OUVRIR, UNE LIGNE SINON — ET PAS UN BOUTON
    /// DÉSACTIVÉ : SwiftUI grise le contenu d'un bouton désactivé, donc l'état NORMAL de cette
    /// ligne — l'affichage fonctionne — serait le seul à paraître éteint.
    @ViewBuilder
    private var ecranVerrouille: some View {
        if activitesEnDirectActives {
            ecranVerrouilleContenu
        } else {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            } label: {
                ecranVerrouilleContenu
            }
            .buttonStyle(.plain)
        }
    }

    private var ecranVerrouilleContenu: some View {
        MoreSettingsLigne(titre: String(localized: "Course sur l'écran verrouillé"),
                          precision: legendeEcranVerrouille, filet: false) {
            if !activitesEnDirectActives {
                HZChevron()
            }
        }
        .contentShape(Rectangle())
    }

    /// Les deux phrases sont des `String(localized:)` dans un membre à part : un littéral à
    /// l'intérieur d'un ternaire étalé échappe à `ci_scripts/check_strings.py`.
    private var legendeEcranVerrouille: String {
        activitesEnDirectActives
            ? String(localized: "Le chrono et la distance restent visibles, téléphone verrouillé.")
            : String(localized: "Coupé dans les Réglages du téléphone. Touche pour l'activer.")
    }

    // MARK: - Apple Watch

    /// Ce que la montre affiche pendant une course.
    ///
    /// Le réglage se prend ICI et pas sur la montre : elle n'a pas de clavier, et personne ne
    /// configure son affichage en courant. Il voyage ensuite par le canal qui pousse déjà la
    /// séance du jour — d'où l'appel à `publishWidgetSnapshot()` à chaque changement, qui est le
    /// point d'entrée existant de cette synchro.
    private var watch: some View {
        let layout = profile.watchRunLayout ?? .standard
        return HZGroupeDeReglages(titre: String(localized: "Apple Watch")) {
            MoreSettingsBloc(titre: String(localized: "Le grand chiffre"),
                             precision: String(localized: "Celui que tu lis sans t'arrêter de courir.")) {
                choixDuGrandChiffre(layout)
            }
            MoreSettingsLigne(titre: String(localized: "Les trois petits"),
                              precision: String(localized: "Sous le grand, de gauche à droite."),
                              filet: false) {
                EmptyView()
            }
            ForEach(Array(layout.secondary.enumerated()), id: \.offset) { index, metric in
                emplacement(index, metric: metric, layout: layout)
            }
            Text("La barre de progression suit toujours la durée de la séance, quel que soit le grand chiffre — c'est le seul objectif qu'une séance porte.")
                .hzParagraphe(.c13, .medium, interligne: HZReglages.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, HZReglages.margeDUneLigneALaPrecision)
        }
    }

    private func choixDuGrandChiffre(_ layout: WatchRunLayout) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HZEspace.entrePilules) {
                ForEach(RunMetric.allCases, id: \.self) { metric in
                    MoreSettingsPastille(libelle: String(localized: String.LocalizationValue(metric.nameKey)),
                                         choisie: layout.hero == metric) {
                        setWatchLayout(hero: metric, secondary: layout.secondary)
                    }
                }
            }
        }
    }

    private func emplacement(_ index: Int, metric: RunMetric, layout: WatchRunLayout) -> some View {
        MoreSettingsLigne(titre: slotLabel(index)) {
            Menu {
                // Le héros n'est pas proposé : il est déjà affiché en grand au-dessus, et le voir
                // deux fois sur un écran de 198 points est le genre de réglage qu'on prend par
                // erreur et qu'on ne comprend qu'en courant.
                ForEach(RunMetric.allCases.filter { $0 != layout.hero }, id: \.self) { candidate in
                    Button {
                        var next = layout.secondary
                        if index < next.count { next[index] = candidate }
                        setWatchLayout(hero: layout.hero, secondary: next)
                    } label: {
                        Text(LocalizedStringKey(candidate.nameKey))
                    }
                }
            } label: {
                HStack(spacing: HZEspace.entrePilules) {
                    Text(LocalizedStringKey(metric.nameKey))
                        .hzTexte(.c16, .semi)
                        .foregroundStyle(HZCouleur.encre)
                    HZChevron()
                        .rotationEffect(.degrees(HZHub.quartDeTour))
                }
                .frame(minHeight: HZBoutonRond.zoneTactile)
                .contentShape(Rectangle())
            }
            .accessibilityLabel(Text(slotLabel(index)))
        }
    }

    private func slotLabel(_ index: Int) -> String {
        switch index {
        case 0: return String(localized: "1ᵉ")
        case 1: return String(localized: "2ᵉ")
        default: return String(localized: "3ᵉ")
        }
    }

    /// Passe toujours par `sanitized` : c'est ce qui garantit qu'aucun geste de cet écran — y
    /// compris choisir comme héros un chiffre déjà présent en bas — ne produise un affichage où
    /// le même nombre apparaît deux fois.
    private func setWatchLayout(hero: RunMetric, secondary: [RunMetric]) {
        profile.watchRunLayout = WatchRunLayout.sanitized(hero: hero, secondary: secondary)
        appState.publishWidgetSnapshot()
        Haptics.selection()
    }

    // MARK: - Programme

    private var programme: some View {
        // Les deux dernières lignes sont conditionnelles : le filet ne sépare que ce qui suit.
        let courseLibre = profile.programPhase != .freerun
        let terminer = profile.programPhase == .active
        return HZGroupeDeReglages(titre: String(localized: "Programme")) {
            plusDestination(String(localized: "Voir mon objectif")) { dismiss(); appState.go(.race) }
            plusDestination(String(localized: "Modifier jours & objectif")) { dismiss(); appState.openProgramSettings() }
            // Ouvre le même assistant que `ChoiceView` propose à la fin d'un programme : il ne
            // touche qu'à l'objectif, la distance, l'allure et les jours, et garde le reste (nom,
            // blessures, cycle…). L'ancien « Refaire l'onboarding » redemandait tout pour changer
            // un plan d'entraînement.
            plusDestination(String(localized: "Refaire un programme"), filet: courseLibre || terminer) {
                dismiss()
                appState.newGoalWizardPresented = true
            }
            if courseLibre {
                // La voie directe vers `.freerun` : avant, la seule porte était « Terminer le
                // programme », puis plusieurs jours de récupération, puis un écran « Choix » qui
                // l'offrait enfin — ce qui ressemble à une app qui impose du repos pour qu'on
                // puisse courir librement.
                plusDestination(String(localized: "Passer en mode course libre"), filet: terminer) {
                    AdaptivePlanEngine.chooseFreeRun(profile)
                    appState.toast(String(localized: "Mode course libre activé — suggestions sans objectif de perf"))
                    dismiss()
                }
            }
            if terminer {
                plusDestination(String(localized: "Terminer le programme"), filet: false) {
                    AdaptivePlanEngine.endProgram(profile)
                    appState.toast(String(localized: "Programme terminé · récupération en cours"))
                    dismiss()
                }
            }
        }
    }

    /// Une ligne qui mène quelque part : son titre, un chevron, et toute la largeur est tactile —
    /// avant, seuls l'icône, le libellé et le chevron répondaient, et le vide entre eux traversait.
    private func plusDestination(_ titre: String, precision: String? = nil, filet: Bool = true,
                                 action: @escaping () -> Void) -> some View {
        Button(action: action) { plusLigneDeDestination(titre, precision: precision, filet: filet) }
            .buttonStyle(.plain)
    }

    private func plusLigneDeDestination(_ titre: String, precision: String? = nil,
                                        filet: Bool = true) -> some View {
        MoreSettingsLigne(titre: titre, precision: precision, hauteur: HZReglages.hauteurDeDestination,
                          filet: filet) {
            HZChevron()
        }
        .contentShape(Rectangle())
    }

    // MARK: - Santé & blessures

    /// La blessure ne se demandait qu'une fois, à l'inscription — sans retour possible, une
    /// blessure qui guérit (ou une nouvelle) ne pouvait jamais mettre à jour le plan que
    /// `AdaptivePlanEngine.adjustForWellbeing` recalcule chaque semaine depuis ce champ.
    private var blessure: some View {
        HZGroupeDeReglages(titre: String(localized: "Santé & blessures")) {
            MoreSettingsBloc(titre: String(localized: "Une douleur ou blessure à surveiller ?"),
                             precision: String(localized: "Le coach adapte tes séances de fractionné/VMA en conséquence, chaque semaine."),
                             filet: false) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: HZEspace.entrePilules) {
                        ForEach(zonesDeDouleur, id: \.id) { zone in
                            MoreSettingsPastille(libelle: zone.libelle,
                                                 choisie: (profile.injuryArea ?? "none") == zone.id) {
                                profile.injuryArea = zone.id
                            }
                        }
                    }
                }
            }
        }
    }

    private var zonesDeDouleur: [(id: String, libelle: String)] {
        [("none", String(localized: "Aucune")), ("knee", String(localized: "Genou")),
         ("ankle", String(localized: "Cheville")), ("back", String(localized: "Dos")),
         ("other", String(localized: "Autre"))]
    }

    // MARK: - Cycle

    /// Visible seulement quand `profile.sex == "female"` — le suivi se règle après l'inscription
    /// (ou se change plus tard) au lieu de n'avoir qu'une chance, à l'inscription.
    /// `AdaptivePlanEngine.adjustForWellbeing` lit `profile.cyclePhase` directement : modifier ces
    /// champs change aussitôt le plan de la semaine suivante, comme n'importe quel réglage du
    /// programme.
    private var cycle: some View {
        HZGroupeDeReglages(titre: String(localized: "Cycle")) {
            MoreSettingsLigne(titre: String(localized: "Suivi du cycle"), filet: profile.cycleTrackingEnabled) {
                interrupteur(Binding(
                    get: { profile.cycleTrackingEnabled },
                    set: { on in
                        profile.cycleTrackingEnabled = on
                        if on && profile.lastPeriodStartDate == nil { profile.lastPeriodStartDate = .now }
                    }))
                    .accessibilityLabel("Suivi du cycle")
            }
            if profile.cycleTrackingEnabled {
                reglagesDuCycle
            }
        }
    }

    @ViewBuilder private var reglagesDuCycle: some View {
        MoreSettingsLigne(titre: String(localized: "Date des dernières règles")) {
            DatePicker(
                String(localized: "Date des dernières règles"),
                selection: Binding(get: { profile.lastPeriodStartDate ?? .now },
                                   set: { profile.lastPeriodStartDate = $0 }),
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .tint(HZCouleur.encre)
        }

        // LE CONSENTEMENT DE TRANSMISSION, distinct du suivi et décoché d'avance.
        //
        // Le suivi ci-dessus adapte le plan SUR L'APPAREIL — rien ne sort. Cette case-ci autorise
        // l'envoi de la phase estimée au coach, donc à un service tiers. Ce sont deux décisions
        // différentes et elles étaient prises par une seule bascule, qui n'annonçait que la
        // première. Le destinataire est NOMMÉ : une phrase qui dit « partager avec le coach » sans
        // dire que le coach est un service extérieur ne demande pas grand-chose.
        MoreSettingsLigne(titre: String(localized: "Partager ma phase avec le coach"),
                          precision: String(localized: "Ta phase estimée est alors envoyée au service qui fait tourner le coach, pour qu'il adapte son ton. Sans ça, ton programme continue de s'adapter exactement pareil — le calcul se fait sur ton téléphone.")) {
            interrupteur(Binding(get: { profile.shareCyclePhaseWithCoach },
                                 set: { profile.shareCyclePhaseWithCoach = $0 }))
                .accessibilityLabel("Partager ma phase de cycle avec le coach")
        }

        MoreSettingsLigne(titre: String(localized: "Durée moyenne du cycle")) {
            HZCompteur(
                valeur: String(localized: "\(profile.averageCycleLengthDays) jours"),
                nomDuMoins: String(localized: "Cycle plus court"), nomDuPlus: String(localized: "Cycle plus long"),
                moins: { profile.averageCycleLengthDays = max(HZCompte.cycleMin, profile.averageCycleLengthDays - HZCompte.pasDuCycle) },
                plus: { profile.averageCycleLengthDays = min(HZCompte.cycleMax, profile.averageCycleLengthDays + HZCompte.pasDuCycle) })
        }

        reancrerLeCycle
    }

    /// « Mes règles ont commencé aujourd'hui » — la seule chose qu'on observe vraiment, et dont
    /// tout le reste se déduit.
    ///
    /// Sans ce bouton, corriger un cycle décalé demandait d'ouvrir le sélecteur de date et de
    /// trouver le bon jour. Or l'écart se reporte d'un cycle au suivant : au bout de trois mois
    /// l'app annonce une phase lutéale à quelqu'un qui a ses règles, et adapte le programme sur
    /// cette erreur.
    private var reancrerLeCycle: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            HZBoutonPilule(libelle: String(localized: "Mes règles ont commencé aujourd'hui"),
                           hauteur: .moyenne, etendu: true) {
                let updated = CycleTracking.recordingPeriodStart(
                    lastStart: profile.lastPeriodStartDate,
                    averageLength: profile.averageCycleLengthDays,
                    newStart: .now
                )
                profile.lastPeriodStartDate = updated.lastStart
                profile.averageCycleLengthDays = updated.averageLength
                Haptics.success()
                appState.toast(String(localized: "Cycle réancré sur aujourd'hui"))
            }
            if let phase = profile.cyclePhase {
                // La phase en toutes lettres : le canvas ne lui donne ni teinte ni fond, et
                // l'écran n'en invente pas — on n'affiche jamais deux phases à la fois, donc la
                // couleur ne distinguerait rien que le mot ne dise déjà.
                Text("Phase actuelle estimée : \(cyclePhaseLabel(phase))")
                    .hzParagraphe(.c14, .semi, interligne: HZReglages.interligne)
                    .foregroundStyle(HZCouleur.encre)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, HZEspace.tuile)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cyclePhaseLabel(_ phase: UserProfile.CyclePhase) -> String {
        switch phase {
        // Composé dans `Text("Phase actuelle estimée : \(…)")` en tant qu'argument — il faut donc
        // que la valeur soit déjà traduite en sortant d'ici.
        case .menstrual: return String(localized: "menstruelle")
        case .follicular: return String(localized: "folliculaire")
        case .ovulation: return String(localized: "ovulatoire")
        case .luteal: return String(localized: "lutéale")
        }
    }

    // MARK: - Confidentialité

    /// LE CONSENTEMENT AUX STATISTIQUES, RÉVOCABLE ICI.
    ///
    /// L'audit du 9 novembre 2026 : « Aucun écran ne présente un consentement explicite et
    /// révocable aux statistiques d'usage. La politique les décrit ; l'app ne les propose pas à
    /// refuser. » La question est posée à l'inscription (`StatistiquesStepView`) ; cette ligne est
    /// la seconde moitié — révocable, sinon ce n'est pas un consentement.
    ///
    /// Un retrait JETTE ce qui était gardé et n'enregistre plus rien : voir
    /// `Analytics.consentir`.
    private var confidentialite: some View {
        HZGroupeDeReglages(titre: String(localized: "Confidentialité")) {
            MoreSettingsLigne(titre: String(localized: "Statistiques d'usage"),
                              precision: String(localized: "Douze moments du parcours — l'app s'ouvre, une étape est franchie, une course démarre. Jamais ce que tu écris, jamais ta position, jamais rien d'Apple Santé. Si tu refuses, aucune statistique n'est envoyée et ce qui était gardé est effacé."),
                              filet: false) {
                interrupteur(Binding(
                    get: { Analytics.shared.consentement == .accepte },
                    set: { Analytics.shared.consentir($0 ? .accepte : .refuse) }))
                    .accessibilityLabel("Partager les statistiques d'usage")
            }
        }
    }

    // MARK: - Inviter

    /// Le partage système, et rien d'autre : un message qui se suffit à lui-même dans un SMS
    /// comme dans un mail. La phrase d'invitation est la même partout.
    private var invitation: some View {
        HZGroupeDeReglages(titre: String(localized: "Inviter un ami")) {
            VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
                Text("Ton club se remplit plus vite à deux.")
                    .hzParagraphe(.c13, .medium, interligne: HZReglages.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)
                ShareLink(item: String(localized: "Rejoins-moi sur Haizo, mon appli de coaching running : https://runup-nu.vercel.app")) {
                    Text("Inviter un ami")
                        .hzTexte(HZHauteurDeBouton.moyenne.corps, .gras)
                        .foregroundStyle(HZCouleur.blanc)
                        .padding(.horizontal, HZHauteurDeBouton.moyenne.marge)
                        .frame(maxWidth: .infinity)
                        .frame(height: HZHauteurDeBouton.moyenne.rawValue)
                        .background(HZCouleur.encre, in: Capsule())
                        .contentShape(Capsule())
                }
            }
            .padding(.vertical, HZEspace.tuile)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Compte

    /// Un vrai compte, relié au serveur du Club (voir `AuthService`) — avec la suppression, exigée
    /// par la règle 5.1.1(v) de l'App Store dès qu'une app propose d'en créer un.
    private var compte: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreSections) {
            HZGroupeDeReglages(titre: String(localized: "Compte")) {
                if let user = appState.auth.currentUser {
                    MoreSettingsLigne(
                        titre: Accord.selon(f: String(localized: "Connectée en tant que \(user.nomComplet)"),
                                            m: String(localized: "Connecté en tant que \(user.nomComplet)"))) {
                        EmptyView()
                    }
                    adresseDuCompte(user)
                }
                plusDestination(String(localized: "Se déconnecter")) { appState.auth.signOut(); dismiss() }
                supprimerLeCompte
            }
            identite
        }
        .confirmationDialog("Supprimer définitivement ton compte ?", isPresented: $showDeleteAccountConfirm, titleVisibility: .visible) {
            Button("Supprimer", role: .destructive) { Task { await deleteAccount() } }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Ton club, ton classement et ton fil d'activité seront définitivement supprimés du serveur. Cette action est irréversible.")
        }
    }

    /// L'ADRESSE DU COMPTE, TELLE QUE LE SERVEUR LA VOIT.
    ///
    /// Ce n'est pas un détail d'administration : avec « Se connecter avec Apple », on peut choisir
    /// de MASQUER son adresse, et le compte est alors créé sous un `…@privaterelay.appleid.com`
    /// que personne ne connaît. Deux téléphones, deux façons de se connecter, et on se retrouve
    /// avec deux comptes sans savoir lequel est lequel — c'est exactement ce qui est arrivé sur
    /// Hukaia.
    ///
    /// L'app ne la demande qu'à l'inscription et ne la remontre jamais. Elle est affichée ici
    /// parce que c'est la seule réponse à « sous quel compte suis-je ? », et sélectionnable parce
    /// qu'on a parfois besoin de la recopier.
    @ViewBuilder private func adresseDuCompte(_ user: AuthenticatedUser) -> some View {
        if let adresse = user.email, !adresse.isEmpty {
            VStack(spacing: 0) {
                Text(verbatim: adresse)
                    .hzParagraphe(.c14, .medium, interligne: HZReglages.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .textSelection(.enabled)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, HZReglages.margeDUneLigneALaPrecision)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Rectangle()
                    .fill(HZCouleur.filetGroupe)
                    .frame(height: HZMesuresDeLigne.filet)
            }
        }
    }

    private var supprimerLeCompte: some View {
        Button(action: { showDeleteAccountConfirm = true }) {
            MoreSettingsLigne(titre: String(localized: "Supprimer mon compte"),
                              hauteur: HZReglages.hauteurDeDestination, filet: false) {
                if isDeletingAccount { ProgressView().tint(HZCouleur.encre) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDeletingAccount)
    }

    /// Ni l'inscription ni l'ouverture du compte n'ont jamais demandé de pseudo ni de nom : la
    /// recherche de « Mes amis » ne peut pas retrouver « Léo » parmi plusieurs sans l'un des deux.
    /// Tous deux facultatifs, enregistrés ensemble d'un seul appui ; un pseudo déjà pris s'affiche
    /// ici même, plutôt qu'en échec générique.
    private var identite: some View {
        VStack(alignment: .leading, spacing: HZEspace.groupe) {
            // LE PRÉNOM EN PREMIER, ET IL N'EST PAS FACULTATIF.
            //
            // C'est celui que la recherche de « Mes amis » interroge, et c'est celui qui
            // s'affiche dans le fil et au classement. « Se connecter avec Apple » ne donne le nom
            // qu'à la toute première autorisation d'un identifiant Apple, donc une réinstallation
            // ou un second appareil créait un compte appelé « Coureur » — que personne ne pouvait
            // plus corriger depuis l'app.
            HZChampDeTexte(titre: String(localized: "Prénom"), invite: String(localized: "Prénom"),
                           texte: $firstNameText)
            HZChampDeTexte(titre: String(localized: "Pseudo (facultatif)"),
                           invite: String(localized: "Pseudo (facultatif)"),
                           texte: $usernameText, majuscules: .never)
                .autocorrectionDisabled()
            HZChampDeTexte(titre: String(localized: "Nom (facultatif)"),
                           invite: String(localized: "Nom (facultatif)"), texte: $lastNameText)
            if let identityError {
                Text(identityError)
                    .hzParagraphe(.c14, .semi, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.encre)
                    .padding(HZEspace.groupe)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HZCouleur.surfaceClaire,
                                in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
            }
            Text("Aide tes amis à te retrouver dans la recherche.")
                .hzParagraphe(.c13, .medium, interligne: HZReglages.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
            HZBoutonPilule(libelle: isSavingIdentity ? "…" : String(localized: "Enregistrer"),
                           hauteur: .moyenne, etendu: true) {
                Task { await saveIdentity() }
            }
            .disabled(isSavingIdentity)
        }
    }

    // MARK: - La maison

    private var maison: some View {
        HZGroupeDeReglages(titre: String(localized: "La maison")) {
            plusDestination(String(localized: "Fiche admin"),
                            precision: String(localized: "Le compte, ses droits, et ce que le serveur en dit"),
                            filet: false) {
                ficheAdminOuverte = true
            }
        }
    }

    // MARK: - Aide et retours

    /// Un lien `mailto:`, pas un serveur de retours : zéro infrastructure à tenir, et il marche avec
    /// le client mail réellement réglé sur le téléphone (contrairement à
    /// `MFMailComposeViewController`, qui ne part que si l'app Mail elle-même a un compte). La
    /// même adresse que le lien « nous contacter » de `ClubView`, pour que retours et
    /// signalements arrivent dans la même boîte.
    ///
    /// Le seul chemin vers un humain depuis les réglages. « Bêta » était juste tant que l'app se
    /// testait entre proches ; elle se vend maintenant par abonnement, et lire « Bêta » dans les
    /// réglages d'une app qu'on vient de payer, c'est lire « ce n'est pas fini ».
    private var aide: some View {
        HZGroupeDeReglages(titre: String(localized: "Aide et retours")) {
            Link(destination: feedbackMailURL) {
                plusLigneDeDestination(String(localized: "Nous écrire"),
                                       precision: String(localized: "Un bug, une idée, un truc qui t'a gênée — ça part par mail."),
                                       filet: false)
            }
            .buttonStyle(.plain)
        }
    }

    private var feedbackMailURL: URL {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let system = UIDevice.current.systemVersion
        let body = String(localized: "\n\n\n---\nCe qui suit aide juste au diagnostic :\nVersion \(version) (\(build)) · iOS \(system)")
        var components = URLComponents(string: "mailto:charlottegrudep@gmail.com")!
        components.queryItems = [
            // Le sujet portait « bêta » lui aussi. Il sert à trier les messages reçus : la
            // version et le build sont déjà dans le corps, ils suffisent à savoir d'où ça vient.
            URLQueryItem(name: "subject", value: "Haizo — retour utilisateur"),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url!
    }

    // MARK: - Ce que les boutons font

    private func saveIdentity() async {
        isSavingIdentity = true
        identityError = nil
        do {
            // Le prénom n'est envoyé que s'il est rempli : vide, il serait refusé par le
            // serveur (colonne `NOT NULL`) et ferait échouer l'enregistrement du pseudo et du
            // nom avec lui. Un champ laissé vide ne doit pas emporter les deux autres.
            let prenom = firstNameText.trimmingCharacters(in: .whitespaces)
            try await clubService.updateProfile(
                name: prenom.isEmpty ? nil : prenom,
                username: usernameText.trimmingCharacters(in: .whitespaces),
                lastName: lastNameText.trimmingCharacters(in: .whitespaces)
            )
            // Refreshes `currentUser` so the change is reflected immediately — search results and
            // future signup/profile screens all read from there, not from this sheet's own state.
            // `_ =` explicite : `refreshMe()` renvoie l'utilisateur rafraîchi, dont on n'a pas
            // besoin ici — c'est l'effet de bord sur `currentUser` qui nous intéresse.
            _ = try? await appState.auth.refreshMe()
            appState.toast(String(localized: "Profil mis à jour"))
        } catch ClubServiceError.badResponse(HZCompte.pseudoPris, _) {
            identityError = String(localized: "Ce pseudo est déjà pris.")
        } catch ClubServiceError.badResponse(HZCompte.pseudoInvalide, _) {
            identityError = String(localized: "Pseudo invalide — lettres minuscules, chiffres, underscore, 3 à 20 caractères.")
        } catch ClubServiceError.badResponse(HZCompte.nomRefuse, _) {
            identityError = String(localized: "Ce nom n'est pas autorisé — choisis-en un autre.")
        } catch {
            identityError = PanneReseau.phrase(pour: error)
        }
        isSavingIdentity = false
    }

    private func deleteAccount() async {
        isDeletingAccount = true
        do {
            try await appState.auth.deleteAccount()
            appState.toast(String(localized: "Compte supprimé"))
            dismiss()
        } catch {
            appState.toast(String(localized: "Impossible de supprimer le compte — réessaie."))
        }
        isDeletingAccount = false
    }
}

// MARK: - Les pièces de la feuille

/// Une ligne de groupe, comme `HZLigneDeReglage`, mais dont le titre passe à la ligne : dans une
/// feuille de cette largeur, « Pause automatique aux arrêts » face à un interrupteur ne tient pas
/// sur les plus petits téléphones, et une ligne de titre coupée ne dit plus ce qu'elle règle.
private struct MoreSettingsLigne<Queue: View>: View {
    let titre: String
    var precision: String? = nil
    var hauteur: CGFloat = HZReglages.hauteurDeLigne
    var filet: Bool = true
    @ViewBuilder var queue: () -> Queue

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: HZEspace.tuile) {
                VStack(alignment: .leading, spacing: HZReglages.entreTitreEtPrecision) {
                    Text(titre)
                        .hzParagraphe(.c16, .semi, interligne: HZReglages.interligne)
                        .foregroundStyle(HZCouleur.encre)
                        .fixedSize(horizontal: false, vertical: true)
                    if let precision {
                        Text(precision)
                            .hzParagraphe(.c13, .medium, interligne: HZReglages.interligne)
                            .foregroundStyle(HZCouleur.secondaireSurClair)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                queue()
            }
            .padding(.vertical, HZReglages.margeDUneLigneALaPrecision)
            .frame(minHeight: hauteur)
            if filet {
                Rectangle()
                    .fill(HZCouleur.filetGroupe)
                    .frame(height: HZMesuresDeLigne.filet)
            }
        }
    }
}

/// Un bloc de groupe pleine largeur : un titre, une précision, puis ce qu'on y choisit.
private struct MoreSettingsBloc<Contenu: View>: View {
    let titre: String
    var precision: String? = nil
    var filet: Bool = true
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
                Text(titre)
                    .hzParagraphe(.c16, .semi, interligne: HZReglages.interligne)
                    .foregroundStyle(HZCouleur.encre)
                    .fixedSize(horizontal: false, vertical: true)
                if let precision {
                    Text(precision)
                        .hzParagraphe(.c13, .medium, interligne: HZReglages.interligne)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                        .fixedSize(horizontal: false, vertical: true)
                }
                contenu()
            }
            .padding(.vertical, HZReglages.margeDUneLigneALaPrecision)
            .frame(maxWidth: .infinity, alignment: .leading)
            if filet {
                Rectangle()
                    .fill(HZCouleur.filetGroupe)
                    .frame(height: HZMesuresDeLigne.filet)
            }
        }
    }
}

/// Un choix dans une rangée, POSÉ SUR UN GROUPE GRIS : le choisi est noir, les autres blancs.
/// `HZFiltre` ne convient pas ici — ses pilules éteintes sont de la surface claire, c'est-à-dire
/// la couleur du groupe lui-même, donc invisibles.
private struct MoreSettingsPastille: View {
    let libelle: String
    let choisie: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(libelle)
                .hzTexte(.c14, .gras)
                .foregroundStyle(choisie ? HZCouleur.blanc : HZCouleur.encre)
                .lineLimit(1)
                .padding(.horizontal, HZFiltre.margeHorizontale)
                .padding(.vertical, HZFiltre.margeCourante)
                .background(choisie ? HZCouleur.encre : HZCouleur.blanc, in: Capsule())
                .frame(minHeight: HZBoutonRond.zoneTactile)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(choisie ? .isSelected : [])
    }
}
