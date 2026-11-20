import SwiftUI
import MapKit
import UIKit

/// L'ÉCRAN DE COURSE, refait d'après le canvas « Run » : la carte en haut avec trois commandes, et
/// dessous un panneau noir qui porte les blocs de la séance, l'allure, trois mesures et les
/// trois commandes du pouce.
///
/// Il reste noir dans les deux thèmes, comme avant : on le lit dehors, en courant, en plein soleil.
/// Rien ne change à ce qu'il fait : la vraie carte et le vrai tracé, le GPS et ses bandeaux, le coach
/// vocal, le décompte de départ, la confirmation avant de terminer, la pause. Le modèle de vue n'est pas
/// touché, sauf une lecture : le nombre de répétitions, pour les barres.
///
/// Ce que le canvas change dans la hiérarchie : l'ALLURE devient le grand chiffre (100), le temps et la
/// distance passent en mesures de 28, et les calories cèdent la place au cardio. L'allure cible, qui
/// dominait avant, devient « Cible » à droite de l'allure.
struct LiveRunView: View {
    @Environment(AppState.self) private var appState
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showStopConfirm = false
    /// Un instantané du tracé, reconstruit toutes les cinq positions et non à chacune : MapKit
    /// retesselle tout le tableau à chaque mise à jour, et le coût monterait avec la sortie.
    @State private var displayedRoute: [CLLocationCoordinate2D] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Armé à l'apparition, pour que le point d'enregistrement respire. Voir `pointEnDirect`.
    @State private var pulse = false
    @Environment(\.openURL) private var openURL
    @Environment(SubscriptionService.self) private var subscriptions

    private var vm: LiveRunViewModel? { appState.liveRun }

    var body: some View {
        VStack(spacing: -HZRayon.feuille) {
            carte
            panneau
        }
        .background(HZCouleur.noirFranc.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .statusBarHidden()
        .overlay {
            // LE DÉCOMPTE, PAR-DESSUS TOUT LE RESTE. Voir `LiveRunViewModel.demarrer`.
            if let reste = vm?.decompte {
                voileDeDepart(reste)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: HZLive.reponseDuRessort, dampingFraction: HZLive.amortissement),
                   value: topBannerText)
        .animation(.spring(response: HZLive.reponseDuRessort, dampingFraction: HZLive.amortissement),
                   value: vm?.gpsState)
        // Sans ça la transition du bandeau ne joue pas : une transition ne s'exécute que si la mutation
        // qui la déclenche est animée.
        .animation(HZMouvement.ecran, value: messageEcranVerrouilleVisible)
        .onChange(of: vm?.gpsState) { _, state in
            // Un seul buzz quand le signal se dégrade, pas à chaque image où il reste dégradé : elle
            // court, elle ne regarde pas l'écran, et l'avertissement est inutile s'il arrive en silence.
            // Pas pendant l'accrochage : c'est l'état normal des premières secondes de chaque course, et
            // faire vibrer le téléphone pour dire « tout se passe comme prévu » apprend à ignorer les
            // alertes.
            if state == .unstable || state == .denied { Haptics.warning() }
        }
    }

    // MARK: - Le décompte

    /// Trois, deux, un.
    ///
    /// Il COUVRE l'écran au lieu de se poser dans un coin : les commandes en dessous (mettre en
    /// pause, terminer) ne veulent rien dire sur une course qui n'a pas commencé, et un appui sur
    /// « Terminer » pendant le décompte enregistrerait une sortie de zéro seconde. Un appui n'importe
    /// où le saute : trois secondes imposées à chaque départ, sans moyen de les passer, c'est la
    /// fonctionnalité qu'on finit par détester.
    private func voileDeDepart(_ reste: Int) -> some View {
        Button { vm?.lancerMaintenant() } label: {
            ZStack {
                Rectangle().fill(HZCouleur.noirFranc)
                VStack(spacing: HZLive.sousLeDecompte) {
                    Text("\(reste)")
                        .hzAffichage(.direct)
                        .hzVedette()
                        // Chaque chiffre entre en grandissant et sort en s'effaçant : un décompte, et
                        // non un texte qui se remplace.
                        .transition(reduceMotion ? .opacity
                                    : .scale(scale: HZLive.echelleDuDecompte).combined(with: .opacity))
                        .id(reste)
                    Text("Appuie pour partir tout de suite")
                        .hzTexte(.c14, .medium)
                        .foregroundStyle(HZCouleur.secondaireSurSombre)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .ignoresSafeArea()
        .animation(reduceMotion ? nil : .spring(response: HZLive.reponseDuDecompte, dampingFraction: HZLive.amortissementDuDecompte),
                   value: reste)
        // MODAL, ET PAS SEULEMENT OPAQUE AU DOIGT : VoiceOver navigue l'arbre, pas le toucher. Sans ce
        // trait, PAUSE et TERMINER restent atteignables au balayage pendant le décompte, et une
        // coureuse aveugle pourrait enregistrer une sortie de zéro seconde.
        .accessibilityAddTraits(.isModal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Départ dans \(reste)"))
        .accessibilityHint(String(localized: "Appuie pour partir tout de suite"))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - La carte

    /// La voix du coach prend la place des consignes écrites : « je t'écoute… » puis la transcription,
    /// puis la vraie réponse pendant qu'elle se lit, et le reste du temps les consignes de la séance.
    private var topBannerText: String? {
        if let vc = vm?.voiceCoach {
            // Les échecs passent ici aussi : une permission de micro refusée laissait le toucher sans
            // aucun effet visible.
            if vc.state == .idle, let error = vc.lastError { return error }
            switch vc.state {
            case .listening: return vc.partialTranscript.isEmpty ? String(localized: "Je t'écoute…") : vc.partialTranscript
            case .thinking: return "…"
            case .speaking: return vc.lastReply
            case .idle: break
            }
        }
        return vm?.coachCue
    }

    private var carte: some View {
        mapLayer
            .frame(maxWidth: .infinity, minHeight: HZLive.carteMinimale, maxHeight: HZLive.carte)
            .overlay(alignment: .top) {
                VStack(spacing: HZEspace.entreCommandes) {
                    commandesDeLaCarte
                    avertissements
                }
                .padding(.top, HZEspace.haut)
                .padding(.horizontal, HZEspace.marge)
            }
    }

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            if displayedRoute.count > 1 {
                MapPolyline(coordinates: displayedRoute)
                    .stroke(HZCouleur.accent, style: StrokeStyle(lineWidth: HZLive.traitDuTrace, lineCap: .round, lineJoin: .round))
            }
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControls { }
        // Décorative pour VoiceOver : la distance et l'allure se lisent déjà dans le panneau.
        .accessibilityHidden(true)
        // MapKit ne sait pas ajouter un point à un tracé existant : chaque mise à jour retesselle un
        // tableau neuf, et le faire à chaque position ferait monter le coût de l'écran où les images
        // perdues se voient le plus. Toutes les cinq positions (~5 s) ; le point de l'utilisatrice, lui,
        // se met à jour à chaque tick.
        .onChange(of: vm?.location.route.count ?? 0) { _, newCount in
            let shouldUpdate = (displayedRoute.isEmpty && newCount > 1)
                || newCount - displayedRoute.count >= HZLive.positionsEntreDeuxMisesAJour
                || newCount < displayedRoute.count
            guard shouldUpdate else { return }
            displayedRoute = vm?.location.route ?? []
        }
    }

    private var commandesDeLaCarte: some View {
        HStack {
            HZBoutonRond(dessin: .reduire, nom: String(localized: "Réduire"), diametre: .outil,
                         fond: HZCouleur.noir) { appState.go(.home) }
            Spacer(minLength: 0)
            HStack(spacing: HZLive.entrePointEtEtat) {
                pointEnDirect
                Text(libelleEtat)
                    .hzTexte(.c14, .gras)
                    .foregroundStyle(HZCouleur.blanc)
            }
            .padding(.horizontal, HZEspace.groupe)
            .frame(height: HZDiametre.outil.rawValue)
            .background(HZCouleur.noir, in: Capsule())
            Spacer(minLength: 0)
            HZBoutonRond(dessin: .recentrer, nom: String(localized: "Recentrer la carte"), diametre: .outil,
                         fond: HZCouleur.noir) {
                cameraPosition = .userLocation(fallback: .automatic)
            }
        }
    }

    /// L'état de la séance, dans la pastille du haut. La course ne se nomme pas : « En direct » seul,
    /// parce que c'est le cas ordinaire. Les autres se nomment, parce que l'écran est le même et que
    /// rien d'autre, à cet endroit, ne distingue une sortie vélo d'un footing.
    ///
    /// La nage ne peut pas arriver ici (elle ne se démarre pas depuis le téléphone, voir
    /// `Discipline.seDemarreDepuisLeTelephone`) ; son libellé est écrit quand même, et il est vrai.
    private var libelleEtat: LocalizedStringKey {
        if vm?.isAutoPaused == true { return "Pause auto" }
        if vm?.isPaused == true { return "En pause" }
        switch vm?.discipline ?? .run {
        case .run: return "En direct"
        case .bike: return "Vélo · en direct"
        case .trail: return "Trail · en direct"
        case .swim: return "Nage · en direct"
        }
    }

    /// Le seul mouvement perpétuel de l'écran, et le seul qui porte une information : il respire parce
    /// que son battement DIT quelque chose, l'enregistrement tourne. Il s'arrête net en pause : l'arrêt
    /// du battement est alors la deuxième preuve, non textuelle, que le chrono est figé.
    private var pointEnDirect: some View {
        let beating = pulse && vm?.isPaused != true && !reduceMotion
        return Circle().fill(HZCouleur.accent)
            .frame(width: HZLive.pointEnDirect, height: HZLive.pointEnDirect)
            .scaleEffect(beating ? HZLive.grossissementDuPoint : HZLive.echelleAuRepos)
            .opacity(beating ? HZLive.opaciteDuPoint : HZLive.opaciteAuRepos)
            .animation(beating ? .easeInOut(duration: HZLive.dureeDuBattement).repeatForever(autoreverses: true)
                               : HZMouvement.chiffre,
                       value: beating)
            .onAppear { pulse = true }
            .accessibilityHidden(true)
    }

    // MARK: - Les avertissements

    /// Le GPS passe devant, et le second message s'efface tout seul : le GPS parle de la course
    /// elle-même, qui est en train de ne pas être enregistrée ; l'écran verrouillé parle d'un confort.
    @ViewBuilder private var avertissements: some View {
        if let state = vm?.gpsState, state != .ok {
            gpsBanner(state)
                .transition(.move(edge: .top).combined(with: .opacity))
        } else if messageEcranVerrouilleVisible, let raison = vm?.raisonSansActiviteEnDirect {
            activiteEnDirectBanner(raison)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
        if let text = topBannerText {
            coachBubble(text)
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
        }
    }

    /// Trois messages, parce qu'il y a trois situations qu'une distance restée à 0,00 rendait
    /// identiques : le GPS accroche encore, le signal est instable, l'autorisation est refusée.
    @ViewBuilder
    private func gpsBanner(_ state: LiveRunViewModel.GPSState) -> some View {
        switch state {
        case .denied:
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            } label: {
                bannerBody(icon: "location.slash.fill",
                           text: "Localisation refusée — ouvrir les Réglages")
            }
            .buttonStyle(.plain)
        case .searching:
            bannerBody(icon: "location.magnifyingglass",
                       text: "Recherche du signal GPS…")
        case .unstable:
            bannerBody(icon: "exclamationmark.triangle.fill",
                       text: "Signal GPS instable — position estimée")
        case .ok:
            EmptyView()
        }
    }

    /// Le bandeau de l'écran verrouillé est-il encore à l'écran ? Un seul endroit décide, parce que la
    /// condition sert deux fois : pour afficher, et pour animer.
    private var messageEcranVerrouilleVisible: Bool {
        guard let vm, vm.raisonSansActiviteEnDirect != nil else { return false }
        return vm.elapsedSeconds < HZLive.secondesDuMessageEcranVerrouille
    }

    /// Deux situations, deux messages, et une seule des deux mène quelque part : l'interrupteur des
    /// Réglages se rallume en deux touches, donc le bandeau est un bouton. Un refus d'ActivityKit ne
    /// se répare pas depuis les Réglages : y envoyer la coureuse serait lui faire chercher une case
    /// qui n'existe pas.
    @ViewBuilder
    private func activiteEnDirectBanner(_ raison: LiveRunViewModel.RaisonSansActiviteEnDirect) -> some View {
        switch raison {
        case .desactiveeDansLesReglages:
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            } label: {
                bannerBody(icon: "lock.slash",
                           text: "Rien sur l'écran verrouillé — ouvrir les Réglages")
            }
            .buttonStyle(.plain)
        case .refuseeParLeSysteme:
            bannerBody(icon: "exclamationmark.triangle.fill",
                       text: "Écran verrouillé indisponible pour cette course")
        }
    }

    /// `LocalizedStringKey` ET NON `String` : `Text(uneVariableString)` ne consulte jamais le
    /// catalogue. Les avertissements GPS sortaient en français en anglais et en espagnol alors
    /// qu'ils sont traduits depuis le début.
    private func bannerBody(icon: String, text: LocalizedStringKey) -> some View {
        HStack(spacing: HZEspace.entrePilules) {
            Image(systemName: icon)
                .font(HZPolice.texte(.c15, .semi))
            Text(text)
                .hzParagraphe(.c14, .semi, interligne: HZLive.interligne)
                // La hauteur vient du texte : un message d'état tronqué est un message qui ment.
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(HZCouleur.blanc)
        .padding(.horizontal, HZEspace.tuile)
        .padding(.vertical, HZEspace.entreCommandes)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HZCouleur.noir, in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
    }

    private func coachBubble(_ text: String) -> some View {
        HStack(spacing: HZEspace.entreTuiles) {
            Image(systemName: "speaker.wave.2.fill")
                .font(HZPolice.texte(.c15, .semi))
                .foregroundStyle(HZCouleur.encreSurAccent)
                .frame(width: HZLive.disqueDuCoach, height: HZLive.disqueDuCoach)
                .background(HZCouleur.accent, in: Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text("Coach · en direct")
                    .hzTexte(.c13, .gras)
                    .foregroundStyle(HZCouleur.accent)
                Text(text)
                    .hzParagraphe(.c14, .medium, interligne: HZLive.interligne)
                    .foregroundStyle(HZCouleur.blanc)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(HZEspace.tuile)
        .background(HZCouleur.noir, in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
        // L'icône, le surtitre et la ligne du coach étaient trois arrêts séparés.
        .accessibilityElement(children: .combine)
    }

    // MARK: - Le panneau

    private var panneau: some View {
        VStack(alignment: .leading, spacing: 0) {
            blocs
            allure
            mesures
            Spacer(minLength: HZLive.entreMesuresEtCommandes)
            commandes
        }
        .padding(.horizontal, HZEspace.margeDeTitre)
        .padding(.top, HZLive.hautDuPanneau)
        // Le contenu s'arrête au-dessus de la barre de geste, que SwiftUI donne : la pause, 88 de
        // diamètre, ne doit pas se trouver à cheval sur la zone où un glissement vers le haut appartient
        // au système. C'est le seul geste de l'écran qu'on fait sans regarder.
        .padding(.bottom, HZLive.basDuPanneau)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: HZRayon.feuille, topTrailingRadius: HZRayon.feuille,
                                   style: .circular)
                .fill(HZCouleur.noirFranc)
                .ignoresSafeArea(edges: .bottom)
        }
        .foregroundStyle(HZCouleur.blanc)
    }

    // MARK: Les blocs de la séance

    /// Une barre par répétition : les faites en blanc, la courante remplie de l'accent selon sa
    /// progression réelle, les autres éteintes. Rien sur une séance continue : il n'y a pas de bloc à
    /// compter, et on n'en invente pas.
    @ViewBuilder private var blocs: some View {
        if let total = vm?.repetitionsPrevues, total > 0, let segment = vm?.currentSegment {
            let (faites, courante) = Self.avancement(segment, sur: total)
            VStack(alignment: .leading, spacing: HZLive.sousLesBarres) {
                HStack(spacing: HZLive.entreLesBarres) {
                    ForEach(0..<total, id: \.self) { index in
                        barre(index, faites: faites, courante: courante)
                    }
                }
                HStack {
                    if let libelle = vm?.segmentLabel { Text(libelle) }
                    Spacer(minLength: 0)
                    if let reste = vm?.segmentRemainingLabel {
                        Text("Encore \(reste)")
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(HZMouvement.respecter(reduceMotion, HZMouvement.chiffre), value: reste)
                    }
                }
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
            }
            .padding(.bottom, HZLive.sousLesBlocs)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibleInstruction)
        }
    }

    /// Combien de blocs sont faits, et lequel est en cours (0 pour le premier), d'après la machine à
    /// segments : l'échauffement n'en a fait aucun, la récupération n'en a pas en cours, le retour au
    /// calme les a tous faits.
    private static func avancement(_ segment: LiveRunViewModel.IntervalSegment, sur total: Int) -> (faites: Int, courante: Int?) {
        switch segment {
        case .warmup: return (0, nil)
        case .rep(let n): return (min(max(n - 1, 0), total), min(max(n - 1, 0), total - 1))
        case .recovery(let n): return (min(max(n, 0), total), nil)
        case .cooldown: return (total, nil)
        }
    }

    private func barre(_ index: Int, faites: Int, courante: Int?) -> some View {
        let faite = index < faites
        return Capsule()
            .fill(faite ? HZCouleur.blanc : HZCouleur.filetSombre)
            .frame(height: HZLive.hauteurDesBarres)
            .overlay(alignment: .leading) {
                if index == courante, let progress = vm?.segmentProgress {
                    GeometryReader { geo in
                        Capsule().fill(HZCouleur.accent)
                            .frame(width: geo.size.width * min(max(progress, 0), HZLive.progressionPleine))
                    }
                    .animation(HZMouvement.respecter(reduceMotion, HZMouvement.glisse), value: progress)
                }
            }
            .clipShape(Capsule())
            .accessibilityHidden(true)
    }

    /// Ce que la consigne dit à voix haute, à la lettre, y compris le segment et son restant, que les
    /// barres ne disent pas.
    private var accessibleInstruction: String {
        let pace = appState.profile.todaySession.pace
        guard let segment = vm?.segmentLabel else {
            return String(localized: "Consigne, allure cible \(pace) par kilomètre")
        }
        // « allure cible » quand c'est la consigne de l'instant, « cible » quand ce n'est que
        // l'objectif de la séance : la distinction que l'accent fait à l'écran ne se voit pas à
        // l'écoute.
        let effort = vm?.isTargetEffortNow ?? true
        guard let remaining = vm?.segmentRemainingLabel else {
            return effort
                ? String(localized: "\(segment), allure cible \(pace) par kilomètre")
                : String(localized: "\(segment), cible \(pace) par kilomètre")
        }
        return effort
            ? String(localized: "\(segment), reste \(remaining), allure cible \(pace) par kilomètre")
            : String(localized: "\(segment), reste \(remaining), cible \(pace) par kilomètre")
    }

    // MARK: L'allure

    /// A-t-elle une cible à montrer ? Rien à vélo (la séance du jour est une séance de course), rien
    /// sans allure au plan (HYROX, course libre).
    private var hasInstruction: Bool {
        guard vm?.suitLePlan ?? true else { return false }
        let pace = appState.profile.todaySession.pace
        return !pace.isEmpty && pace != "—" && pace != "--:--"
    }

    /// L'ALLURE, ET CE QU'ELLE VAUT.
    ///
    /// C'est l'allure des trente dernières secondes, pas la moyenne de la sortie : passé la vingtième
    /// minute la moyenne ne bouge plus de quelques secondes même quand on change franchement de rythme,
    /// et le seul nombre censé dire comment on court maintenant ne le disait plus. Le libellé dit
    /// ALLURE tant qu'on tient la cible, puis le verbe que le coach prononce au même instant,
    /// ACCÉLÈRE ou RALENTIS : un mot et pas seulement la couleur, parce que la couleur ne se lit pas
    /// à bout de souffle avec le soleil dessus.
    private var allure: some View {
        let standing = vm?.paceStanding ?? .unknown
        let derive = standing == .tooSlow || standing == .tooFast
        let libelle: String
        switch standing {
        case .tooSlow: libelle = String(localized: "Accélère")
        case .tooFast: libelle = String(localized: "Ralentis")
        case .onTarget, .unknown: libelle = vm?.rythmeLibelle ?? String(localized: "Allure")
        }
        let valeur = vm?.rythmeRecent ?? "--:--"
        // Le NOM d'un côté, le CHIFFRE de l'autre : VoiceOver ne relit que la valeur.
        let nomParle = vm?.discipline.seLitEnAllure ?? true
            ? String(localized: "Allure")
            : String(localized: "Vitesse")
        let valeurParlee: String
        switch standing {
        case .tooSlow: valeurParlee = String(localized: "\(valeur) par kilomètre, accélère")
        case .tooFast: valeurParlee = String(localized: "\(valeur) par kilomètre, ralentis")
        case .onTarget, .unknown:
            valeurParlee = vm?.discipline.seLitEnAllure ?? true
                ? String(localized: "\(valeur) par kilomètre")
                : String(localized: "\(valeur) kilomètres par heure")
        }
        return HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Text(libelle)
                    .hzTexte(.c15, .semi)
                    .foregroundStyle(derive ? HZCouleur.accent : HZCouleur.secondaireSurSombre)
                Text(verbatim: valeur)
                    .hzAffichage(.direct)
                    // Pas encore de lecture (« --:-- ») : les traits à cette taille sont de gros blocs, qui
                    // attirent l'œil vers ce qui n'est pas une mesure. Ils s'éteignent jusqu'au premier chiffre.
                    .foregroundStyle(valeur.contains(where: \.isNumber) ? HZCouleur.accent : HZCouleur.pointEteint)
                    .lineLimit(1)
                    .minimumScaleFactor(HZLive.reductionDeLAllure)
                    .padding(.leading, -HZLive.debordDeLAllure)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(HZMouvement.respecter(reduceMotion, HZMouvement.chiffre), value: valeur)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(nomParle)
            .accessibilityValue(valeurParlee)
            .accessibilityAddTraits(.updatesFrequently)
            Spacer(minLength: 0)
            if hasInstruction {
                VStack(alignment: .trailing, spacing: HZLive.entreCibleEtValeur) {
                    Text("Cible")
                        .hzTexte(.c13, .semi)
                        .foregroundStyle(HZCouleur.secondaireSurSombre)
                    Text(verbatim: appState.profile.todaySession.pace)
                        .hzAffichage(.chiffreDeLigne)
                }
                .padding(.bottom, HZLive.sousLaCible)
                .accessibilityHidden(true)
            }
        }
    }

    // MARK: Les trois mesures

    private var mesures: some View {
        HStack(alignment: .top, spacing: 0) {
            mesure(PaceModel.formatDuration(vm?.elapsedSeconds ?? 0), String(localized: "Temps"))
            mesure(String(format: "%.2f", locale: Locale.current, vm?.distanceKm ?? 0), String(localized: "Kilomètres"))
            // Pas de capteur en direct, pas de vraie lecture : « -- » plutôt qu'un chiffre fabriqué.
            mesure(vm?.heartRate.map { "\($0)" } ?? "--", libelleDuCardio)
        }
        .padding(.top, HZLive.sousLeFiletDesMesures)
        .overlay(alignment: .top) {
            Rectangle().fill(HZCouleur.filetSombre).frame(height: HZMesuresDeLigne.filet)
        }
        .padding(.top, HZLive.sousLAllure)
    }

    private var libelleDuCardio: String {
        let zone = appState.profile.todaySession.zone
        return zone.isEmpty || zone == "—" ? String(localized: "Cardio") : String(localized: "Cardio · \(zone)")
    }

    private func mesure(_ valeur: String, _ libelle: String) -> some View {
        VStack(alignment: .leading, spacing: HZLive.entreCibleEtValeur) {
            Text(verbatim: valeur)
                .hzAffichage(.chiffreDuDirect)
                .lineLimit(1)
                .minimumScaleFactor(HZLive.reductionDeLAllure)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(HZMouvement.respecter(reduceMotion, HZMouvement.chiffre), value: valeur)
            Text(libelle)
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Le libellé nomme la mesure, la valeur porte le chiffre : VoiceOver ne relit que la valeur,
        // sans quoi il annonce celle du moment où on l'a touchée, et jamais la suivante.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(libelle)
        .accessibilityValue(valeur)
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: Les commandes

    private var commandes: some View {
        HStack(spacing: HZLive.entreCommandes) {
            Button(action: {
                Haptics.impact(.heavy)
                showStopConfirm = true
            }) {
                RoundedRectangle(cornerRadius: HZLive.rayonDuCarre, style: .circular)
                    .fill(HZCouleur.blanc)
                    .frame(width: HZLive.coteDuCarre, height: HZLive.coteDuCarre)
                    .frame(width: HZDiametre.controle.rawValue, height: HZDiametre.controle.rawValue)
                    .background(HZCouleur.surfaceSombre, in: Circle())
            }
            .buttonStyle(HZStyleDAppui())
            .accessibilityLabel(String(localized: "Terminer"))
            // Un bouton à côté de la pause terminait la séance, irréversiblement, d'un seul toucher :
            // un faux pas en pleine course la tuait.
            .confirmationDialog("Terminer la course ?", isPresented: $showStopConfirm, titleVisibility: .visible) {
                Button("Terminer", role: .destructive) { _ = appState.endLiveRun() }
                Button("Continuer à courir", role: .cancel) {}
            }

            Button(action: {
                Haptics.impact(.medium)
                vm?.togglePause()
            }) {
                Group {
                    if vm?.isPaused == true {
                        HZIcone(dessin: .lecture, cote: HZLive.coteDeLaLecture, couleur: HZCouleur.noirFranc)
                    } else {
                        HStack(spacing: HZLive.ecartDesBarresDePause) {
                            ForEach(0..<HZLive.barresDePause, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: HZLive.rayonDesBarresDePause, style: .circular)
                                    .fill(HZCouleur.noirFranc)
                                    .frame(width: HZLive.largeurDeBarreDePause, height: HZLive.hauteurDeBarreDePause)
                            }
                        }
                    }
                }
                .frame(width: HZDiametre.principal.rawValue, height: HZDiametre.principal.rawValue)
                .background(HZCouleur.blanc, in: Circle())
            }
            .buttonStyle(HZStyleDAppui())
            .accessibilityLabel(vm?.isPaused == true ? "Reprendre" : "Mettre en pause")

            boutonDuCoach
        }
        .frame(maxWidth: .infinity)
    }

    /// Le micro : un toucher pour poser une question à voix haute, un second pour arrêter et envoyer,
    /// et la vraie réponse parlée (voir `VoiceCoachController`).
    ///
    /// Verrouillé, le bouton reste à sa place avec un petit cadenas : le retirer serait la seule option
    /// qui n'apprend rien, on ne peut pas vouloir ce qu'on n'a jamais vu. Et en pleine course, un bouton
    /// est la seule forme qu'un verrou puisse prendre.
    private var boutonDuCoach: some View {
        let state = vm?.voiceCoach?.state ?? .idle
        let locked = !subscriptions.unlocks(.voiceCoach)
        return Button(action: {
            if locked { appState.plusPrompt = .voiceCoach } else { handleMicTap() }
        }) {
            Group {
                switch state {
                case .idle:
                    HZIcone(dessin: .micro, cote: HZLive.coteDuMicro, couleur: HZCouleur.blanc)
                case .listening:
                    Image(systemName: "waveform").font(HZPolice.texte(.c20, .semi))
                case .thinking:
                    ProgressView().tint(HZCouleur.blanc)
                case .speaking:
                    Image(systemName: "speaker.wave.2.fill").font(HZPolice.texte(.c20, .semi))
                }
            }
            .foregroundStyle(HZCouleur.blanc)
            .frame(width: HZDiametre.controle.rawValue, height: HZDiametre.controle.rawValue)
            .background(state == .listening ? HZCouleur.accent : HZCouleur.surfaceSombre, in: Circle())
            .overlay(alignment: .bottomTrailing) {
                if locked {
                    Image(systemName: "lock.fill")
                        .font(HZPolice.texte(.c12, .gras))
                        .foregroundStyle(HZCouleur.blanc)
                        .padding(HZLive.margeDuCadenas)
                        .background(HZCouleur.noirFranc, in: Circle())
                }
            }
        }
        .buttonStyle(HZStyleDAppui())
        .disabled(!locked && (state == .thinking || state == .speaking))
        .accessibilityLabel(locked ? "Le coach vocal fait partie de Haizo Plus"
                                   : (state == .listening ? "Arrêter et envoyer" : "Parler au coach"))
    }

    private func handleMicTap() {
        guard let voiceCoach = vm?.voiceCoach else { return }
        Task {
            if voiceCoach.state == .idle {
                guard await voiceCoach.requestAuthorization() else {
                    voiceCoach.reportAuthorizationDenied()
                    return
                }
            }
            voiceCoach.toggle()
        }
    }
}
