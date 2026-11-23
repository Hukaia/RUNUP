import SwiftUI

/// Race/objective detail — mirrors `RaceScreen` in screensB.jsx. Title/date/pace/prep are all
/// dynamic, computed from the real profile state (race target, `PaceModel`, `AdaptivePlanEngine`)
/// instead of a fixed 10K pacing table shown regardless of the actual goal or distance.
///
/// Une page à feuille : le haut noir porte l'objectif, la date et trois mesures ; la feuille blanche
/// porte la préparation et la stratégie du jour J. Les trois feuilles « Jour J » s'ouvrent d'ici.
struct RaceGoalView: View {
    @Environment(AppState.self) private var appState
    private var profile: UserProfile { appState.profile }
    @State private var jourJOuvert = false
    @State private var jourJTriathlonOuvert = false
    @State private var jourJDuathlonOuvert = false

    private var shape: AdaptivePlanEngine.ProgramShape {
        AdaptivePlanEngine.ProgramShape.compute(goal: profile.goalId, raceDate: profile.raceDate, from: profile.programStartDate ?? .now)
    }

    private var formatDuTriathlon: TriathlonFormat? {
        profile.triathlonFormat.flatMap(TriathlonFormat.init(rawValue:))
    }

    private var formatDuDuathlon: DuathlonFormat? {
        profile.duathlonFormat.flatMap(DuathlonFormat.init(rawValue:))
    }

    /// Le temps visé d'un triathlon, en minutes.
    ///
    /// Lu ICI et pas par `PaceModel.parseChronoSeconds` : celui-là décide de l'unité d'après la
    /// DISTANCE de course, et un triathlon n'en a pas — `raceDistance` est nil pour cet objectif.
    /// Il aurait donc lu « 2:35 » comme deux minutes trente-cinq.
    ///
    /// Le format est toujours « H:MM », celui des quatre jeux de temps de finisseur. Tout le
    /// reste — « finir », un texte libre mal formé — rend zéro, et l'écran se tait au lieu
    /// d'afficher des totaux calculés sur rien.
    private var minutesVisees: Int {
        guard let chrono = profile.raceChrono else { return 0 }
        let bouts = chrono.split(separator: ":").compactMap { Int($0) }
        guard bouts.count == HZCourse.boutsDUnChrono, bouts[0] >= 0, (0..<HZCourse.minutesParHeure).contains(bouts[1]) else { return 0 }
        return bouts[0] * HZCourse.minutesParHeure + bouts[1]
    }

    /// L'allure cible qu'implique le temps visé sur la distance visée, ou `nil` si l'un des deux
    /// manque — un objectif de progression, de poids, de reprise ou de santé n'a pas de chrono.
    ///
    /// Le repli, lui, est `allureDePrediction` ci-dessous.
    private var racePaceSecPerKm: Double? {
        guard let chrono = profile.raceChrono,
              let km = profile.effectiveRaceDistanceKm,
              let totalSeconds = PaceModel.parseChronoSeconds(chrono, distance: profile.raceDistance),
              km > 0
        else { return nil }
        return totalSeconds / km
    }

    /// L'allure sur laquelle se rabattre sans temps visé : celle que le VDOT du profil prédit
    /// POUR CETTE DISTANCE-LÀ.
    ///
    /// # LE REPLI ÉTAIT L'ALLURE DE SEUIL, ET IL NE L'EST PLUS
    ///
    /// Le repli prenait `zones.thresholdSecPerKm` quelle que soit la course. Ça tenait à peu près
    /// tant que le plan posait lui-même seuil = allure du 10 km : sur un 10 km, le repli était
    /// l'allure du 10 km. Sur un semi, c'était déjà trop rapide, et sur un marathon beaucoup trop
    /// — le tableau d'allure proposait un rythme de course d'une heure sur quarante-deux
    /// kilomètres, et la ligne « Relance » cinq secondes plus vite encore.
    ///
    /// Depuis que le seuil est l'allure d'une course d'environ 67 minutes (voir `Vdot`), le repli
    /// serait franchement faux. La prédiction par distance répond à la bonne question, avec le
    /// nombre dont le plan tire déjà ses allures.
    private var allureDePrediction: Double {
        Vdot.allureDeCourse(vdot: PaceModel.zones(for: profile).vdot,
                            km: profile.effectiveRaceDistanceKm ?? HZCourse.kilometresParDefaut)
    }

    private var targetPaceLabel: String {
        PaceModel.formatDuration(racePaceSecPerKm ?? allureDePrediction)
    }

    /// Splits the real goal distance into 3-4 pacing phases around the real target pace, instead
    /// of a fixed "1-3 / 4-8 / 9 / 10 km @ 4:52.../4:20" table that only ever made sense for a 10K.
    private var pacingPlan: [(String, String, String)] {
        let km = profile.effectiveRaceDistanceKm ?? HZCourse.kilometresParDefaut
        let base = racePaceSecPerKm ?? allureDePrediction
        let totalKm = max(HZCourse.kilometresMinimauxDuTableau, Int(km.rounded()))
        let startEnd = max(1, Int((Double(totalKm) * HZCourse.partDuDepart).rounded()))
        let cruiseEnd = min(totalKm - 1, max(startEnd + 1, Int((Double(totalKm) * HZCourse.partDeLaCroisiere).rounded())))

        func rangeLabel(_ a: Int, _ b: Int) -> String { a == b ? "\(a) km" : "\(a)-\(b) km" }

        var plan: [(String, String, String)] = [
            (rangeLabel(1, startEnd), String(localized: "Départ contrôlé"), PaceModel.formatDuration(base + HZCourse.retardDuDepart)),
            (rangeLabel(startEnd + 1, cruiseEnd), String(localized: "Rythme cible"), PaceModel.formatDuration(base))
        ]
        if cruiseEnd + 1 < totalKm {
            plan.append((rangeLabel(cruiseEnd + 1, totalKm - 1), String(localized: "Relance"), PaceModel.formatDuration(max(HZCourse.allureMinimale, base - HZCourse.gainDeLaRelance))))
        }
        plan.append((rangeLabel(totalKm, totalKm), String(localized: "Sprint final"), PaceModel.formatDuration(max(HZCourse.allureMinimale, base - HZCourse.gainDuSprint))))
        return plan
    }

    /// La stratégie du jour J des formats qui n'ont PAS de tableau d'allure au kilomètre, ou nil
    /// pour une course de route — qui, elle, en a un vrai.
    ///
    /// Deux formats la prennent, pour la même raison et pas pour la même : un HYROX n'est pas une
    /// course continue, et un ultra-trail n'a pas d'allure cible. Dans les deux cas, un découpage
    /// « 1-20 km / 21-75 km / 76-99 km / Sprint final » serait un tableau d'une fausse précision
    /// sur une épreuve qui ne se court pas comme ça. « Sprint final » au centième kilomètre d'un
    /// 100 miles est même l'inverse d'un conseil.
    private var strategieStructurelle: [(String, String)]? {
        switch profile.goalId {
        case .hyrox: return hyroxStrategy
        case .ultraTrail: return ultraStrategy
        default: return nil
        }
    }

    /// Ce qui décide d'un ultra, et aucune de ces quatre lignes n'est une allure.
    private var ultraStrategy: [(String, String)] {
        [
            (String(localized: "Les deux premières heures"), String(localized: "plus lentement que ton envie : en ultra personne ne gagne au départ, beaucoup y perdent")),
            (String(localized: "Les montées"), String(localized: "marche les raides : au-delà d'une certaine pente, marcher coûte moins et va aussi vite. Ce n'est pas un renoncement, c'est la technique")),
            (String(localized: "Les descentes"), String(localized: "elles décident de l'état de tes quadriceps à mi-course : se retenir tôt est ce qui rend la fin possible")),
            (String(localized: "Manger et boire"), String(localized: "à chaque ravitaillement, pas quand le corps réclame : quand il réclame, il est déjà trop tard"))
        ]
    }

    /// Real structural race-day guidance for HYROX — no fake per-km split table (the format isn't
    /// a continuous run), but real pace/effort advice grounded in what actually determines a HYROX
    /// result: running under accumulated station fatigue, not raw running speed alone.
    private var hyroxStrategy: [(String, String)] {
        [
            (String(localized: "Segments course (8 × 1 km)"), String(localized: "vise \(targetPaceLabel) /km sur chaque segment, même sous fatigue : pas l'allure d'un 8 km isolé")),
            (String(localized: "Stations"), String(localized: "technique avant vitesse : un geste propre coûte moins cher qu'un geste rapide et cassé")),
            (String(localized: "Gestion globale"), String(localized: "les 4 premiers km + stations posent le rythme, les 4 derniers décident du chrono"))
        ]
    }

    /// Only goals that periodize toward a date have a real race day with a distance/chrono to
    /// pace against — for `.progress`/`.restart`/`.weight`/`.health` this screen used to show a
    /// "Jours" countdown to nothing, a fabricated "Allure" from `PaceModel`'s generic threshold,
    /// and a full race-day pacing table built on a hardcoded 10 km fallback (`?? 10` above) — all
    /// meaningless for a goal with no actual race.
    ///
    /// `periodiseVersUneDate` et non une liste écrite ici : cette ligne portait `== .race ||
    /// == .hyrox`, donc une préparation d'ultra-trail — qui a pourtant une date, une distance et
    /// un dossard — voyait le compte à rebours d'un objectif ouvert.
    private var hasRealRaceDay: Bool { profile.goalId.periodiseVersUneDate }

    /// Le dénivelé de la course, pour la troisième tuile d'un ultra.
    ///
    /// C'est LUI et non une allure. Pour un 100 km en vingt heures, « 12:00 /km » est un nombre
    /// juste et inutile : personne ne court un ultra à une allure cible, et l'afficher sous le
    /// mot ALLURE invite à la viser. Le D+ est ce qu'on relit avant de partir.
    private var deniveleLabel: String? {
        guard let d = profile.raceElevationGainM, d > 0 else { return nil }
        // L'unité est dans la VALEUR et non dans l'étiquette : « D+ » s'écrit pareil dans les
        // trois langues de l'app, donc l'étiquette n'a rien à traduire.
        return "\(d) m"
    }

    private var goalTitle: String {
        profile.goalDisplay.contains("·") ? String(profile.goalDisplay.split(separator: "·").first ?? "").trimmingCharacters(in: .whitespaces) : profile.goalDisplay
    }

    private var goalTarget: String {
        guard let part = profile.goalDisplay.split(separator: "·").last else { return profile.goalDisplay }
        return String(part).trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        HZPage {
            hautDePage
        } contenu: {
            feuille
        }
        .sheet(isPresented: $jourJOuvert) {
            UltraRaceDaySheet(tempsDeffortSecondes: AdaptivePlanEngine.tempsDeffortCourse(profile))
                .hzFeuille(detents: [.large])
        }
        .sheet(isPresented: $jourJTriathlonOuvert) {
            if let format = formatDuTriathlon {
                TriathlonRaceDaySheet(format: format, minutesVisees: minutesVisees)
                    .hzFeuille(detents: [.large])
            }
        }
        .sheet(isPresented: $jourJDuathlonOuvert) {
            if let format = formatDuDuathlon {
                DuathlonRaceDaySheet(format: format, minutesVisees: minutesVisees)
                    .hzFeuille(detents: [.large])
            }
        }
    }

    // MARK: - Le haut, sur le noir

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZCommandesDuHaut(retour: { appState.retour(parDefaut: .profile) }) { EmptyView() }
            Text("Ton objectif")
                .hzTexte(.c15, .semi)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZHub.sousLesCommandes)
            Text(goalTitle)
                .hzAffichage(.titreDEcran)
                .foregroundStyle(HZCouleur.blanc)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, HZEspace.margeDeTitre)
            Text(dateLine)
                .hzTexte(.c15, .semi)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
                .minimumScaleFactor(HZCourse.reductionDeLaDate)
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZPlan.sousLeTitre)
            mesuresDuHaut
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZCourse.sousLaDate)
        }
    }

    /// Trois mesures. Avec une course : les jours qui restent, la cible, le dénivelé ou l'allure.
    /// Sans : la semaine, la cible, la série. La première est à l'accent, comme la tuile mise en
    /// avant de l'ancien écran.
    private var mesuresDuHaut: some View {
        HStack(alignment: .top, spacing: HZEspace.entreCommandes) {
            if hasRealRaceDay {
                objectifMesure(profile.daysUntilRace.map(String.init) ?? "—",
                               Pluriel.choisir(profile.daysUntilRace ?? HZCourse.nombreDeRepliPourLePluriel,
                                               String(localized: "Jour"),
                                               String(localized: "Jours")),
                               accent: true)
                objectifMesure(goalTarget, String(localized: "Objectif"))
                if let deniveleLabel {
                    objectifMesure(deniveleLabel, String(localized: "D+"))
                } else {
                    objectifMesure(targetPaceLabel, String(localized: "Allure"))
                }
            } else {
                objectifMesure("\(profile.weekNumber)", String(localized: "Semaine"), accent: true)
                objectifMesure(goalTarget, String(localized: "Objectif"))
                objectifMesure("\(profile.streak)", String(localized: "Série"))
            }
        }
    }

    /// Une valeur qui rétrécit plutôt que de se couper (« Sous 1h30 », un chrono libre dans un tiers
    /// d'écran), et ce qu'elle mesure dessous.
    private func objectifMesure(_ valeur: String, _ libelle: String, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: valeur)
                .hzAffichage(.mesure)
                .foregroundStyle(accent ? HZCouleur.accent : HZCouleur.blanc)
                .lineLimit(1)
                .minimumScaleFactor(HZCourse.reductionDUneMesure)
            Text(libelle)
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - La feuille

    private var feuille: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreSections) {
            if hasRealRaceDay { porteDeLaCommunaute }
            // LA FORME DU PLAN SE VEND, ET ELLE ÉTAIT DONNÉE ICI. L'accueil supprime la carte du
            // programme sans abonnement, le Plan floute sa forme derrière un `PlusSection` — et cet
            // écran, atteignable en permanence depuis la pastille d'objectif du Profil, affichait en
            // clair « Semaine 4/16 », la barre de progression et Base / Spécifique / Affûtage avec
            // l'état réel de chaque bloc. C'est mot pour mot ce que l'argumentaire vend. Ce qui reste
            // libre : le titre de l'objectif, la date et les trois mesures. La séance du jour reste
            // gratuite, la FORME du plan se vend.
            PlusSection(feature: .adaptivePlan, teaserHeight: HZCourse.hauteurDeLApercu) {
                preparation
            }
            piedDeLaFeuille
        }
    }

    // CET ÉCRAN SAVAIT QUE TU PRÉPARES UNE COURSE ET NE TE DISAIT PAS QUE D'AUTRES LA PRÉPARENT
    // AUSSI. La page de la course est l'endroit où l'on trouve quelqu'un à son allure, où l'on voit
    // où en sont les autres, et où un dossard se cède.
    private var porteDeLaCommunaute: some View {
        objectifPorte(String(localized: "Qui court la même course ?"),
                      String(localized: "Trouve quelqu'un à ton allure, vois où en sont les autres"),
                      dessin: .groupe) {
            appState.openRacesTabOnNextVisit = true
            appState.go(.club)
        }
    }

    /// Une porte : un disque, ce qu'elle ouvre, et ce qu'on y trouve. Le titre et la précision sont
    /// des paragraphes — « Ravitaillement, matériel, la nuit » ne tient pas sur une ligne à côté d'un
    /// disque et d'un chevron.
    private func objectifPorte(_ titre: String, _ precision: String, dessin: HZDessin,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: HZEspace.entreTuiles) {
                HZIcone(dessin: dessin, cote: HZProfil.coteDeLIconeDeDestination, couleur: HZCouleur.encre)
                    .frame(width: HZProfil.disqueDeDestination, height: HZProfil.disqueDeDestination)
                    .background(HZCouleur.blanc, in: Circle())
                VStack(alignment: .leading, spacing: HZReglages.entreTitreEtPrecision) {
                    Text(titre)
                        .hzParagraphe(.c16, .gras, interligne: HZBandeauDuCoach.interligne)
                        .foregroundStyle(HZCouleur.encre)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(precision)
                        .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HZChevron()
            }
            .padding(HZEspace.groupe)
            .background(HZCouleur.surfaceClaire,
                        in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - La préparation

    private var preparation: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Préparation"))
            HZPlaque { preparationContenu }
        }
    }

    @ViewBuilder private var preparationContenu: some View {
        if let total = shape.totalWeeks {
            Text(String(localized: "Semaine \(min(profile.weekNumber, total))/\(total)"))
                .hzTexte(.c15, .gras, tabulaire: true)
                .foregroundStyle(HZCouleur.encre)
            HZJauge(fraction: Double(profile.weekNumber) / Double(total))
            HStack(spacing: HZEspace.entrePilules) {
                objectifPhase(String(localized: "Base"), state: phaseState(endWeek: shape.baseWeeks))
                Spacer(minLength: 0)
                objectifPhase(String(localized: "Spécifique"),
                              state: phaseState(endWeek: shape.baseWeeks + shape.specificWeeks))
                Spacer(minLength: 0)
                objectifPhase(String(localized: "Affûtage"), state: phaseState(endWeek: total))
            }
        } else {
            Text("Programme ouvert, sans date de fin fixe.")
                .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Le pied de la feuille : où tu en es, ou la stratégie du jour J

    /// A per-km pacing table with a "Sprint final" phase only makes sense for a continuous
    /// road-race distance — HYROX alternates running with functional stations, so it gets its own
    /// honest, structural strategy instead of a fake per-km split table over a format that isn't a
    /// straight run.
    @ViewBuilder private var piedDeLaFeuille: some View {
        if !hasRealRaceDay {
            VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                HZTitreDeSection(titre: String(localized: "Où tu en es"))
                Text(LocalizedStringKey(progressSummary))
                    .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else if let strategie = strategieStructurelle {
            strategieStructuree(strategie)
        } else if profile.goalId == .triathlon || profile.goalId == .duathlon {
            // NI TABLEAU D'ALLURE, NI « SPRINT FINAL ». Un triathlon et un duathlon tombaient dans
            // la branche des courses sur route : un découpage au kilomètre, bâti sur 10 km par
            // défaut faute de distance de course à pied, pour une épreuve qui se nage et se roule.
            // Un tableau faux d'apparence précise. Et leurs feuilles « Jour J » (ravitaillement,
            // transitions), écrites et testées, n'étaient rendues nulle part : la seule branche
            // qui dessine `portesDuJourJ` était celle du HYROX et de l'ultra.
            portesDuJourJ
        } else {
            strategieDAllure
        }
    }

    private func strategieStructuree(_ strategie: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: HZEspace.entreSections) {
            VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                HZTitreDeSection(titre: String(localized: "Stratégie · jour J"))
                LazyVStack(spacing: 0) {
                    ForEach(strategie.indices, id: \.self) { i in
                        objectifConseil(strategie[i].0, strategie[i].1, filet: i < strategie.count - 1)
                    }
                }
            }
            portesDuJourJ
        }
    }

    /// Un conseil : ce dont il s'agit en gras, ce qu'il faut en faire dessous. Un filet le sépare du
    /// suivant.
    private func objectifConseil(_ titre: String, _ texte: String, filet: Bool) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: HZReglages.entreTitreEtPrecision) {
                Text(titre)
                    .hzParagraphe(.c16, .gras, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.encre)
                    .fixedSize(horizontal: false, vertical: true)
                Text(texte)
                    .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, HZMesuresDeLigne.margeDeSortie)
            .frame(maxWidth: .infinity, alignment: .leading)
            if filet {
                Rectangle()
                    .fill(HZCouleur.filetFeuille)
                    .frame(height: HZMesuresDeLigne.filet)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// Les trois portes du jour J. L'ultra, le triathlon et le duathlon se perdent au ventre, au
    /// contrôle du sac, en transition, et aucune de ces questions n'est posée par le plan : il dit
    /// quoi faire cette semaine, rien de la JOURNÉE.
    @ViewBuilder private var portesDuJourJ: some View {
        if profile.goalId == .ultraTrail {
            objectifPorte(String(localized: "Ravitaillement, matériel, la nuit"),
                          String(localized: "Ce que le plan ne te dit pas, et qui décide autant"),
                          dessin: .drapeau) { jourJOuvert = true }
        }
        if profile.goalId == .triathlon, let format = formatDuTriathlon {
            objectifPorte(String(localized: "Ravitaillement, transitions, combinaison"),
                          String(localized: "Ce que le plan ne te dit pas, et qui décide autant"),
                          dessin: .drapeau) { jourJTriathlonOuvert = true }
                .accessibilityHint(Text(format.resume))
        }
        if profile.goalId == .duathlon, let format = formatDuDuathlon {
            objectifPorte(String(localized: "Départ, ravitaillement, transitions"),
                          String(localized: "Ce que le plan ne te dit pas, et qui décide autant"),
                          dessin: .drapeau) { jourJDuathlonOuvert = true }
                .accessibilityHint(Text(format.resume))
        }
    }

    private var strategieDAllure: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Stratégie d'allure · jour J"))
            LazyVStack(spacing: 0) {
                ForEach(pacingPlan.indices, id: \.self) { i in
                    HZLigneDeListe(titre: pacingPlan[i].1, sousTitre: pacingPlan[i].0, graisse: .gras,
                                   filet: i < pacingPlan.count - 1) {
                        EmptyView()
                    } queue: {
                        HZValeurDeLigne(valeur: pacingPlan[i].2, precision: HZAccueil.uniteDAllure)
                    }
                }
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "EEEE d MMMM"
        return f
    }()

    private var progressSummary: String {
        switch profile.goalId {
        case .weight: return "Pas de date fixe pour ce genre d'objectif : le programme ajuste ton volume semaine après semaine pour que la charge reste tenable dans la durée."
        case .health: return "Pas de course à préparer ici : le coach cale un rythme régulier, adapté à ta forme du jour, pour construire l'habitude sur la durée."
        case .restart: return "Reprise en douceur : le programme remonte le volume progressivement pour éviter la blessure, avant de repartir sur un rythme plus soutenu."
        default: return "Objectif ouvert, sans date de fin fixe : le programme continue de progresser semaine après semaine selon ta forme."
        }
    }

    private var dateLine: String {
        guard let date = profile.raceDate else { return String(localized: "Date à définir") }
        return Self.dateFormatter.string(from: date)
    }

    private enum PhaseState { case done, current, upcoming }

    /// A phase reads "done" once the program has moved past its last week, "current" while the
    /// program is inside it, "upcoming" otherwise — replaces a fixed "Base ✓ / Spécifique ● /
    /// Affûtage" that never actually reflected which block the program was in.
    private func phaseState(endWeek: Int) -> PhaseState {
        if profile.weekNumber > endWeek { return .done }
        let block = AdaptivePlanEngine.trainingBlock(forWeek: profile.weekNumber, shape: shape)
        let isCurrent = (block == .base && endWeek == shape.baseWeeks)
            || (block == .specifique && endWeek == shape.baseWeeks + shape.specificWeeks)
            || (block == .affutage && endWeek == (shape.totalWeeks ?? endWeek))
        return isCurrent ? .current : .upcoming
    }

    private func objectifPhase(_ nom: String, state: PhaseState) -> some View {
        let suffixe: String
        switch state {
        case .done: suffixe = " ✓"
        case .current: suffixe = " ●"
        case .upcoming: suffixe = ""
        }
        return Text(verbatim: nom + suffixe)
            .hzTexte(.c13, state == .current ? .gras : .medium)
            .foregroundStyle(state == .current ? HZCouleur.encre : HZCouleur.secondaireSurClair)
    }
}
