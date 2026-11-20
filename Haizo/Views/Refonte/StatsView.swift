import SwiftUI
import SwiftData

/// LES STATS, refaites à partir des composants de la refonte (`Stats.dc.html`).
///
/// Un titre et « Historique » sur le noir ; sous eux, le grand total de kilomètres de la période
/// choisie, et les quatre périodes ; puis la feuille blanche : quatre chiffres, l'allure moyenne et
/// sa courbe, les records, les temps possibles, « Mes routes ». Rien de ce que le canvas montre
/// (« 118 », « 6:17 », « 17 parcours ») n'est écrit ici : tout se calcule sur l'historique des
/// courses, par les mêmes modèles qu'avant (`PaceModel`, `SemaineComparable`, `TrainingLoad`).
///
/// # LA PÉRIODE COMMANDE LE HAUT, ET LA COURBE
///
/// Dans le canvas, « 4 sem. » est sélectionné sous un total « Depuis le 11 octobre » : le total, le
/// nombre de sorties, le temps cumulé et la courbe disent la MÊME fenêtre. Ils disaient l'inverse
/// avant (totaux sur toute l'histoire, courbe sur la fenêtre) ; un sélecteur qui ne commande qu'une
/// partie de ce qu'il surplombe apprend à ne plus lui faire confiance. « Cette semaine » et « Série
/// en cours » restent des états au présent : la période ne les change pas.
///
/// # CE QUE LE CANVAS NE DESSINE PAS, ET QUI RESTE
///
/// - **Vélo** : ses propres totaux, à part et jamais mélangés à ceux de la course à pied — tant qu'il
///   y a eu au moins une sortie à vélo.
/// - **Charge d'entraînement** (Haizo Plus) : huit semaines de barres et leur zone.
/// - **L'état vide** : sans une seule sortie, une phrase dit ce que l'écran affichera.
/// - **La précision sous les temps possibles** : « estimation basée sur ton profil » et l'écart avec
///   l'objectif de course.
///
/// # CE QUE LE CANVAS DESSINE ET QUI CHANGE
///
/// Le dépliage « Voir l'analyse approfondie » disparaît : les records et les temps possibles sont
/// dans la page, comme dans le canvas. Les temps possibles restent réservés à Haizo Plus (un aperçu
/// estompé et le verrou), comme avant. « Cette semaine » reste un bouton : il ouvre le bilan de la
/// semaine.
struct StatsView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \RunRecord.date, order: .reverse) private var runs: [RunRecord]
    @State private var selectedRange: StatsRange = .month

    /// Le nombre de courses qui ont un tracé — MÉMORISÉ, parce que le compter DÉCODE les tracés.
    ///
    /// `route` n'est pas un tableau en mémoire mais un attribut encodé par SwiftData : chaque
    /// lecture le décode, et compter les tracés non vides les lit TOUS. Cent cinquante courses
    /// représentent environ 375 000 positions, décodées à chaque passe de `body` si c'était une
    /// propriété calculée. `runs.count` comme clé : un tracé est écrit une fois, à l'enregistrement,
    /// et ne change jamais ensuite.
    @State private var nombreDeParcoursTraces = 0
    private var profile: UserProfile { appState.profile }

    /// Les fenêtres du haut de page et de la courbe d'allure.
    private typealias StatsRange = HZPeriode

    // MARK: - La page

    var body: some View {
        ScrollView {
            // La feuille REMONTE sur le haut de page d'un rayon de coin : le noir passe derrière ses
            // coins arrondis.
            VStack(alignment: .leading, spacing: -HZRayon.feuille) {
                hautDePage
                feuille
            }
        }
        .scrollIndicators(.hidden)
        // Deux moitiés de fond : le noir en haut, le blanc en bas.
        .background {
            VStack(spacing: 0) {
                HZCouleur.noir
                HZCouleur.blanc
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea(edges: .top)
        .statusBarHidden()
        .task(id: runs.count) {
            nombreDeParcoursTraces = runs.reduce(into: 0) { total, run in
                if run.route.count > 1 { total += 1 }
            }
        }
    }

    // MARK: - Le haut, sur le noir

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(String(localized: "Stats"))
                    .hzAffichage(.titreDEcran)
                    .foregroundStyle(HZCouleur.blanc)
                Spacer(minLength: 0)
                HZBoutonPilule(libelle: String(localized: "Historique"), suite: .chevron, hauteur: .petite,
                               graisse: .semi, fond: HZCouleur.surfaceSombre,
                               ecart: HZBoutonPilule.ecartDeSuite) {
                    appState.go(.history)
                }
            }
            .padding(.horizontal, HZEspace.marge)

            VStack(alignment: .leading, spacing: 0) {
                Text(depuisLe)
                    .hzTexte(.c15, .semi)
                    .foregroundStyle(HZCouleur.secondaireSurSombre)
                Text(verbatim: kilometresDeLaPeriode)
                    .hzAffichage(.total)
                    .hzVedette()
                    .padding(.leading, -HZStats.debordDuTotal)
                    .minimumScaleFactor(HZStats.reductionDuTotal)
                Text(Pluriel.choisir(Int(totalDeLaPeriodeKm.rounded()),
                                     String(localized: "kilomètre couru"),
                                     String(localized: "kilomètres courus")))
                    .hzTexte(.c20, .gras)
                    .padding(.top, HZStats.sousLeTotal)
            }
            .foregroundStyle(HZCouleur.blanc)
            .padding(.horizontal, HZEspace.margeDeTitre)
            .padding(.top, HZStats.sousLeTitre)

            HStack(spacing: HZEspace.entrePilules) {
                ForEach(StatsRange.allCases) { periode in
                    HZFiltre(libelle: periode.libelle, actif: selectedRange == periode,
                             margeVerticale: HZFiltre.margeDePeriode) {
                        Haptics.selection()
                        selectedRange = periode
                    }
                }
            }
            .padding(.horizontal, HZEspace.margeDeTitre)
            .padding(.top, HZStats.sousLeLibelle)
        }
        .padding(.top, HZEspace.haut)
        // Le noir se prolonge SOUS les périodes : c'est lui qui est derrière les coins arrondis de
        // la feuille, qui remonte d'un rayon.
        .padding(.bottom, HZStats.sousLesPeriodes + HZRayon.feuille)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HZCouleur.noir)
    }

    // MARK: - Les données de la période

    /// Le début de la fenêtre choisie. Sur l'horloge de la scène : cet écran est photographié.
    private var debutDeLaPeriode: Date {
        Calendar.current.date(byAdding: .day, value: -selectedRange.days,
                              to: Demonstration.maintenant) ?? .distantPast
    }

    /// Les sorties À PIED de la fenêtre — route et trail. Les tuiles du haut parlent du même
    /// ensemble : « 42 km · 15 sorties » décrivait deux ensembles différents quand l'une comptait
    /// le vélo et pas l'autre.
    private var sortiesDeLaPeriode: [RunRecord] { runs.onFoot.filter { debutDeLaPeriode < $0.date } }

    private var totalDeLaPeriodeKm: Double {
        sortiesDeLaPeriode.reduce(0) { $0 + $1.distanceKm }
    }

    private var tempsDeLaPeriodeSecondes: Int {
        sortiesDeLaPeriode.reduce(0) { $0 + $1.durationSeconds }
    }

    private var kilometresDeLaPeriode: String {
        String(format: "%.0f", locale: Locale.current, totalDeLaPeriodeKm)
    }

    /// « Depuis le 11 octobre » : la date suit la langue de l'appareil.
    private var depuisLe: String {
        let jour = debutDeLaPeriode.formatted(.dateTime.day().month(.wide))
        return String(localized: "Depuis le \(jour)")
    }

    // MARK: - La feuille

    private var feuille: some View {
        HZFeuille {
            if runs.isEmpty {
                HZBandeauDuCoach(texte: String(localized: "Dès ta première sortie, cet écran affichera ton allure moyenne, ta charge d'entraînement et tes records — calculés sur tes courses, pas sur des moyennes."))
            } else {
                chiffres
                if !bikeRuns.isEmpty { velo }
                allure
                records
            }
            PlusSection(feature: .predictions) { tempsPossibles }
                .padding(.top, HZEspace.entreSections)
            mesRoutes
                .padding(.top, HZStats.apresLesTemps)
            if !runs.isEmpty {
                PlusSection(feature: .trainingLoad) { charge }
                    .padding(.top, HZEspace.entreSections)
            }
            Color.clear.frame(height: HZStats.basDePage)
        }
        .frame(minHeight: HZStats.hauteurMiniDeLaFeuille, alignment: .top)
    }

    /// Les quatre chiffres : sorties et temps de la période, la semaine en cours, la série.
    private var chiffres: some View {
        VStack(spacing: HZEspace.entreTuiles) {
            HStack(spacing: HZEspace.entreTuiles) {
                HZTuileChiffre(libelle: String(localized: "Sorties"), valeur: "\(sortiesDeLaPeriode.count)")
                HZTuileChiffre(libelle: String(localized: "Temps cumulé"),
                               valeur: PaceModel.formatTotalDuration(tempsDeLaPeriodeSecondes))
            }
            HStack(spacing: HZEspace.entreTuiles) {
                // « Cette semaine » ouvre le bilan de la semaine : même bouton qu'avant, dans la
                // même tuile que les autres chiffres.
                Button { appState.go(.weeklyRecap) } label: {
                    HZTuileChiffre(libelle: String(localized: "Cette semaine"),
                                   valeur: String(localized: "\(kilometresDeLaSemaine) km"))
                }
                .buttonStyle(.plain)
                HZTuileChiffre(libelle: String(localized: "Série en cours"),
                               valeur: String(localized: "\(profile.streak) j"), sombre: true)
            }
        }
    }

    /// « 5,3 », ou « 0 » : une semaine vide ne s'écrit pas « 0,0 ».
    private var kilometresDeLaSemaine: String {
        thisWeekKm == 0 ? "0" : String(format: "%.1f", locale: Locale.current, thisWeekKm)
    }

    // MARK: - Vélo

    /// SES PROPRES TOTAUX, à côté et jamais mélangés à ceux de la course à pied. N'apparaît QUE s'il y
    /// a eu au moins une sortie à vélo : une section de zéros est pire qu'une section absente.
    private var velo: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZTitreDeSection(titre: String(localized: "Vélo"))
                .padding(.top, HZEspace.entreSections)
            VStack(spacing: HZEspace.entreTuiles) {
                HStack(spacing: HZEspace.entreTuiles) {
                    HZTuileChiffre(libelle: String(localized: "Distance"),
                                   valeur: String(localized: "\(String(format: "%.0f", locale: Locale.current, bikeDistanceKm)) km"))
                    HZTuileChiffre(libelle: String(localized: "Sorties"), valeur: "\(bikeRuns.count)")
                }
                HStack(spacing: HZEspace.entreTuiles) {
                    HZTuileChiffre(libelle: String(localized: "Temps cumulé"),
                                   valeur: PaceModel.formatTotalDuration(bikeDurationSeconds))
                    // La VITESSE, pas l'allure — « 2:30/km » à vélo est juste et illisible.
                    HZTuileChiffre(libelle: String(localized: "Vitesse moyenne"),
                                   valeur: String(localized: "\(bikeAverageSpeed) km/h"))
                }
            }
            .padding(.top, HZEspace.sousUnTitre)
        }
    }

    // MARK: - L'allure moyenne

    @ViewBuilder private var allure: some View {
        HZTitreDeSection(titre: String(localized: "Allure moyenne"))
            .padding(.top, HZEspace.entreSections)
        Group {
            if let recentAvgPace, recentPacesSecPerKm.count >= HZStats.pointsMinimumDeCourbe {
                HZCarteDAllure(allure: PaceModel.formatDuration(recentAvgPace), ecart: ecartDAllure(recentAvgPace),
                               valeurs: formeDeLaCourbe, record: recordPointIndex,
                               pireAllure: pireAllure, meilleureAllure: meilleureAllure)
            } else {
                // « Vide » a deux sens très différents : jamais couru, ou rien couru CETTE période.
                // Dire « termine quelques courses » à quelqu'un qui en a cinquante derrière lui,
                // parce qu'il regarde les 7 derniers jours, donne tort à l'app.
                Text(recentAvgPace == nil && runs.isEmpty
                     ? String(localized: "Termine quelques courses pour voir ton allure évoluer ici.")
                     : String(localized: "Pas assez de courses sur cette période — essaie une fenêtre plus large."))
                    .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, HZEspace.groupe)
                    .padding(.vertical, HZEspace.tuile)
                    .background(HZCouleur.surfaceClaire,
                                in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
            }
        }
        .padding(.top, HZEspace.sousUnTitre)
    }

    /// Les allures de la fenêtre ramenées entre 0 (la plus rapide, en haut) et 1 (la plus lente).
    private var formeDeLaCourbe: [Double] {
        let allures = recentPacesSecPerKm
        guard let rapide = allures.min(), let lente = allures.max() else { return [] }
        let etendue = max(1, lente - rapide)
        return allures.map { ($0 - rapide) / etendue }
    }

    /// « 12 s plus vite » : l'écart avec la fenêtre précédente de même durée. La flèche d'avant
    /// portait le sens ; le mot le porte maintenant. Rien en dessous d'une seconde.
    private func ecartDAllure(_ allure: Double) -> String? {
        guard let previousAvgPace else { return nil }
        let secondes = Int((previousAvgPace - allure).rounded())
        if secondes > 0 { return String(localized: "\(secondes) s plus vite") }
        if secondes < 0 { return String(localized: "\(-secondes) s plus lent") }
        return nil
    }

    private var pireAllure: String? {
        guard let lente = recentPacesSecPerKm.max(), lente != recentPacesSecPerKm.min() else { return nil }
        return String(localized: "Plus lente \(PaceModel.formatDuration(lente))")
    }

    private var meilleureAllure: String? {
        bestPaceSecPerKm.map { String(localized: "Record \(PaceModel.formatDuration($0))") }
    }

    // MARK: - Les records

    @ViewBuilder private var records: some View {
        HZTitreDeSection(titre: String(localized: "Records"))
            .padding(.top, HZEspace.entreSections)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HZEspace.entreTuiles) {
                HZTuile(libelle: String(localized: "Plus longue, km"),
                        valeur: longestRun.map { String(format: "%.1f", locale: Locale.current, $0.distanceKm) } ?? "—",
                        format: .record, fond: HZCouleur.surfaceSombre,
                        encreDuLibelle: HZCouleur.blanc, graisseDuLibelle: .semi)
                HZTuile(libelle: String(localized: "Meilleure allure"),
                        valeur: bestPaceSecPerKm.map { PaceModel.formatDuration($0) } ?? "—",
                        format: .record, fond: HZCouleur.noir,
                        encreDuLibelle: HZCouleur.secondaireSurSombre)
                HZTuile(libelle: String(localized: "Meilleure semaine, km"),
                        valeur: bestWeekKm > 0 ? String(format: "%.0f", locale: Locale.current, bestWeekKm) : "—",
                        format: .record, fond: HZIntensite.longue.couleur)
            }
        }
        .padding(.trailing, -HZEspace.marge)
        .padding(.top, HZEspace.sousUnTitre)
    }

    // MARK: - Tes temps possibles

    private struct DistancePrevue {
        let libelle: String
        let km: Double
    }

    /// Un marathonien ne voyait jamais de prédiction de marathon : le 5 km cède sa place dès que la
    /// distance de l'objectif est assez longue pour qu'il ne soit plus le bout utile de la série.
    private var distancesPrevues: [DistancePrevue] {
        let semi = DistancePrevue(libelle: String(localized: "Semi-marathon"), km: HZStats.kilometresParSemi)
        let dix = DistancePrevue(libelle: String(localized: "10 km"), km: HZStats.dixKm)
        if let km = profile.effectiveRaceDistanceKm, km >= HZStats.seuilDuMarathon {
            return [dix, semi, DistancePrevue(libelle: String(localized: "Marathon"), km: HZStats.kilometresParMarathon)]
        }
        return [DistancePrevue(libelle: String(localized: "5 km"), km: HZStats.cinqKm), dix, semi]
    }

    private var tempsPossibles: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZTitreDeSection(titre: String(localized: "Tes temps possibles"))
            VStack(spacing: 0) {
                ForEach(distancesPrevues, id: \.libelle) { distance in
                    HZLigneDeTemps(distance: distance.libelle,
                                   temps: PaceModel.formatDuration(predictedSeconds(forKm: distance.km)),
                                   filet: distance.km != distancesPrevues.last?.km)
                }
            }
            .padding(.top, HZStats.sousLaSection)
            if bestRecentPerformance == nil {
                Text(String(localized: "Estimation basée sur ton profil — termine une course pour une prédiction plus précise."))
                    .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)
            } else if profile.goalId == .race,
                      let raceKm = profile.effectiveRaceDistanceKm,
                      let chrono = profile.raceChrono,
                      let targetSeconds = PaceModel.parseChronoSeconds(chrono, distance: profile.raceDistance) {
                phraseDObjectif(objectif: profile.goalDisplay,
                                secondes: targetSeconds - predictedSeconds(forKm: raceKm),
                                couleur: HZCouleur.encre)
                    .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Mes routes

    private var mesRoutes: some View {
        HZCarteDeLien(dessin: .itineraire, titre: String(localized: "Mes routes"),
                      precision: nombreDeParcoursTraces > 0
                          ? Pluriel.choisir(nombreDeParcoursTraces,
                                            String(localized: "\(nombreDeParcoursTraces) parcours enregistré"),
                                            String(localized: "\(nombreDeParcoursTraces) parcours enregistrés"))
                          : String(localized: "Dès ta 1re course trackée")) {
            appState.go(.heatmap)
        }
    }

    // MARK: - La charge d'entraînement (Haizo Plus)

    private var charge: some View {
        let barres = weeklyDistances
        let maximum = max(barres.max() ?? 1, 1)
        let derniere = barres.count - 1
        return VStack(alignment: .leading, spacing: 0) {
            HZTitreDeSection(titre: String(localized: "Charge d'entraînement"))
            if let ratio = acuteChronicRatio(barres) {
                Text(String(localized: "Sur 8 semaines · \(String(localized: String.LocalizationValue(loadZoneLabel(ratio))))"))
                    .hzTexte(.c13, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
            }
            HStack(alignment: .bottom, spacing: HZStats.ecartDesBarres) {
                ForEach(barres.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: HZStats.rayonDUneBarre, style: .circular)
                        .fill(i == derniere ? HZCouleur.accent : HZCouleur.filetGroupe)
                        .frame(height: max(HZStats.hauteurMiniDUneBarre, barres[i] / maximum * HZStats.hauteurDesBarres))
                        .frame(maxWidth: .infinity)
                        // Aucune valeur par semaine n'était lue, et « cette semaine » (la dernière
                        // barre) ne se distinguait que par la couleur.
                        .accessibilityLabel(libelleDeSemaine(i, derniere: derniere))
                        .accessibilityValue("\(String(format: "%.1f", locale: Locale.current, barres[i])) km")
                }
            }
            .frame(height: HZStats.hauteurDesBarres, alignment: .bottom)
            .padding(.top, HZEspace.sousUnTitre)
            HStack {
                Text(String(localized: "S-7"))
                Spacer(minLength: 0)
                Text(String(localized: "Cette sem."))
            }
            .hzTexte(.c13, .semi)
            .foregroundStyle(HZCouleur.secondaireSurClair)
            .padding(.top, HZStats.sousLaCourbe)
        }
    }

    /// « Cette semaine », ou « Il y a 3 semaines » pour la barre `i`.
    private func libelleDeSemaine(_ i: Int, derniere: Int) -> String {
        if i == derniere { return String(localized: "Cette semaine") }
        let ecart = derniere - i
        return Pluriel.choisir(ecart, String(localized: "Il y a \(ecart) semaine"),
                               String(localized: "Il y a \(ecart) semaines"))
    }

    // MARK: - Ce que la page calcule

    private var bikeRuns: [RunRecord] { runs.only(.bike) }
    private var bikeDistanceKm: Double { bikeRuns.reduce(0) { $0 + $1.distanceKm } }
    private var bikeDurationSeconds: Int { bikeRuns.reduce(0) { $0 + $1.durationSeconds } }
    private var bikeElevationM: Int { bikeRuns.reduce(0) { $0 + $1.elevationGainM } }

    /// La vitesse moyenne de TOUTES les sorties réunies, et non la moyenne des vitesses.
    ///
    /// Les deux ne donnent pas le même nombre, et seule la première veut dire quelque chose : une
    /// moyenne de vitesses pèse une sortie de dix minutes autant qu'une de trois heures. Ici, les
    /// kilomètres sont rapportés aux heures qu'ils ont vraiment coûté.
    ///
    /// Elle passe par `TimeFormat.vitesse` plutôt que par sa propre division : la conversion
    /// secondes-par-km → km/h est écrite une seule fois dans l'app, et l'écran de course en direct
    /// lit la même.
    private var bikeAverageSpeed: String {
        guard bikeDistanceKm > 0, bikeDurationSeconds > 0 else { return "—" }
        return TimeFormat.vitesse(secondesParKm: Double(bikeDurationSeconds) / bikeDistanceKm)
    }


    /// Runs inside `selectedRange`, oldest first — chart reads left-to-right as time moving
    /// forward, same order the fixed "last 8 runs" version always used.
    private var chartRuns: [RunRecord] {
        return runs.filter { $0.date >= debutDeLaPeriode }.sorted { $0.date < $1.date }
    }

    private var recentPacesSecPerKm: [Double] {
        chartRuns.only(.run).compactMap { PaceModel.parseSecPerKm($0.avgPace) }
    }

    /// Index of the chart point that's her all-time best pace (same ≥1 km floor `bestPaceSecPerKm`
    /// already uses below) — nil when that run isn't inside the currently selected window, so an
    /// old PR from a year ago doesn't get flagged on a "7 jours" chart that never plots it.
    private var recordPointIndex: Int? {
        guard let best = bestPaceSecPerKm else { return nil }
        return recentPacesSecPerKm.firstIndex(where: { abs($0 - best) < HZStats.ecartDeRecord })
    }

    /// L'allure moyenne SUR LA FENÊTRE CHOISIE.
    ///
    /// Elle était figée sur les cinq dernières courses, quelle que soit la position du sélecteur
    /// posé juste au-dessus. Passer de « 7J » à « 1A » redessinait la courbe et laissait le
    /// chiffre héros — celui qu'on lit en premier, à 44 pt — sur les mêmes cinq courses. Un
    /// contrôle qui semble commander la carte n'en commandait que la moitié : c'est le genre de
    /// détail qui apprend à ne plus faire confiance à ce qu'on lit.
    private var recentAvgPace: Double? {
        average(of: recentPacesSecPerKm)
    }

    /// La même moyenne sur la fenêtre PRÉCÉDENTE de même durée : « les 4 semaines d'avant »
    /// quand on regarde 4 semaines. Comparer une fenêtre à un nombre fixe de courses ferait dire
    /// à la flèche n'importe quoi dès qu'on change d'échelle.
    private var previousAvgPace: Double? {
        let start = debutDeLaPeriode
        guard let previousStart = Calendar.current.date(byAdding: .day, value: -selectedRange.days, to: start)
        else { return nil }
        let window = runs.filter { $0.date >= previousStart && $0.date < start }
        return average(of: window.only(.run).compactMap { PaceModel.parseSecPerKm($0.avgPace) })
    }

    private func average(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }


    private var longestRun: RunRecord? { runs.onFoot.max(by: { $0.distanceKm < $1.distanceKm }) }

    private var bestPaceSecPerKm: Double? {
        runs.compactMap { run -> Double? in
            guard run.distanceKm >= 1 else { return nil }
            return PaceModel.parseSecPerKm(run.avgPace)
        }.min()
    }

    /// Best single calendar week, across all of history — not just the 8-week window `loadCard`
    /// charts, so an older peak still shows up here.
    private var bestWeekKm: Double {
        // Monday-first weeks via the engine's own range — `Calendar.current` weeks start on the
        // device region's day (Sunday on en-US), which made this disagree with the week card.
        var weekTotals: [Date: Double] = [:]
        for run in runs {
            weekTotals[AdaptivePlanEngine.currentWeekRange(from: run.date).lowerBound, default: 0] += run.distanceKm
        }
        return weekTotals.values.max() ?? 0
    }


    /// The fastest real run of at least 2km, if any — the most credible reference to project
    /// race times from. Sans historique, `predictedSeconds(forKm:)` repart du VDOT du profil,
    /// celui dont le plan tire déjà ses allures.
    private var bestRecentPerformance: (km: Double, secPerKm: Double)? {
        let candidates = runs.prefix(HZStats.sortiesRetenuesPourUnePrediction).compactMap { run -> (Double, Double)? in
            guard run.distanceKm >= HZStats.distanceMinimaleDUnePrediction, let pace = PaceModel.parseSecPerKm(run.avgPace) else { return nil }
            return (run.distanceKm, pace)
        }
        return candidates.min(by: { $0.1 < $1.1 }).map { (km: $0.0, secPerKm: $0.1) }
    }



    /// « Objectif 42 km → **12″ à gagner** sur ton objectif. », le gras teinté.
    ///
    /// Le gras vient du Markdown de la chaîne traduite, pas d'un `Text` recollé : c'est ce qui
    /// permet à la phrase de rester entière au catalogue. SwiftUI rend `**…**` en gras de la
    /// police courante tout seul ; la COULEUR, elle, n'existe pas en Markdown — on la pose sur le
    /// seul passage que le Markdown a marqué comme fort.
    private func phraseDObjectif(objectif: String, secondes: Double, couleur: Color) -> Text {
        // La couleur de base est posée DANS la chaîne, pas par un `.foregroundColor` sur le
        // `Text` : laquelle des deux l'emporterait sur un passage déjà teinté n'est pas une
        // question qu'on a envie de se poser depuis une capture d'écran.
        let brut = secondes >= 0
            ? String(localized: "Objectif \(objectif) → **en avance de \(Int(secondes))″** sur ton objectif.")
            : String(localized: "Objectif \(objectif) → **\(Int(-secondes))″ à gagner** sur ton objectif.")
        guard var phrase = try? AttributedString(markdown: brut) else {
            // Markdown illisible (une étoile orpheline dans une traduction) : la phrase passe
            // telle quelle, sans gras. Mieux vaut sans relief que pas de phrase.
            var repli = AttributedString(brut)
            repli.foregroundColor = HZCouleur.secondaireSurClair
            return Text(repli)
        }
        phrase.foregroundColor = HZCouleur.secondaireSurClair
        let passagesForts = phrase.runs.filter {
            $0.inlinePresentationIntent?.contains(.stronglyEmphasized) == true
        }.map(\.range)
        for passage in passagesForts {
            phrase[passage].foregroundColor = couleur
        }
        return Text(phrase)
    }

    /// Le temps prédit sur une distance, depuis la meilleure course réelle — ou, sans historique,
    /// depuis le VDOT du profil.
    ///
    /// # LE REPLI DISAIT UNE CHOSE FAUSSE
    ///
    /// Il prenait l'allure de SEUIL du plan et la projetait « depuis 10 km » — deux propriétés
    /// séparées, `predictionReferenceSecPerKm` et `predictionReferenceKm`, dont l'une se replie
    /// sur le seuil et l'autre sur dix. L'allure de seuil n'est pas l'allure d'un 10 km : chez
    /// Daniels, c'est celle d'une course d'environ 67 minutes. Le couple tenait à peu près tant
    /// que le plan posait lui-même seuil = allure du 10 km, c'est-à-dire tant qu'il se trompait
    /// de la même façon. Il ne tient plus, et il ne tenait que par cette coïncidence.
    ///
    /// Le VDOT du profil répond directement à la question, sans paire de référence à faire
    /// coïncider — et c'est le MÊME nombre dont le plan tire ses allures, donc la prédiction et
    /// le plan ne peuvent plus s'écarter.
    private func predictedSeconds(forKm targetKm: Double) -> Double {
        if let perf = bestRecentPerformance {
            return PaceModel.projectedPace(fromSecPerKm: perf.secPerKm, fromKm: perf.km, toKm: targetKm) * targetKm
        }
        return Vdot.allureDeCourse(vdot: PaceModel.zones(for: profile).vdot, km: targetKm) * targetKm
    }


    private var thisWeekRuns: [RunRecord] {
        let range = AdaptivePlanEngine.currentWeekRange()
        return runs.filter { range.contains($0.date) }
    }

    /// Cette semaine et la semaine passée AU MÊME POINT — voir `SemaineComparable`.
    ///
    /// `thisWeekKm` et `lastWeekKm` existaient séparément ici, et la seconde comptait une semaine
    /// ENTIÈRE pendant que la première comptait une semaine en cours. La soustraction des deux
    /// n'avait donc pas de sens avant le dimanche soir.
    private var semaine: (cette: Double, passee: Double) {
        SemaineComparable.kilometres(runs)
    }

    private var thisWeekKm: Double { semaine.cette }

    private var lastWeekKm: Double { semaine.passee }


    private var weeklyDistances: [Double] {
        // Same Monday-first anchoring as `bestWeekKm` — see comment there.
        let cal = Calendar.current
        var weekTotals: [Date: Double] = [:]
        for run in runs {
            weekTotals[AdaptivePlanEngine.currentWeekRange(from: run.date).lowerBound, default: 0] += run.distanceKm
        }
        let thisWeekStart = AdaptivePlanEngine.currentWeekRange().lowerBound
        return (0..<HZStats.semainesDeCharge).reversed().compactMap { offset in
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -offset, to: thisWeekStart) else { return nil }
            return weekTotals[weekStart] ?? 0
        }
    }

    /// Acute (this week) vs. chronic (last 4 weeks' average) training load — a standard, real
    /// workload-ratio calculation (values around 0.8–1.3 are typically considered a "sweet spot";
    /// consistently above ~1.5 is a common overload signal). Deliberately built from the SAME
    /// Monday-anchored week buckets `weeklyDistances` plots as bars below it — a rolling
    /// 7-day/28-day window anchored on `.now` disagreed with those calendar-week bars mid-week
    /// (the printed ratio could visually contradict what the bars showed).
    /// Le calcul et ses seuils vivent dans `TrainingLoad`, sous test : c'est un marqueur de
    /// blessure, et il n'était vérifiable qu'en accumulant huit semaines de vraies courses.
    ///
    /// Les semaines sont passées EN ARGUMENT et non relues : `weeklyDistances` fait un tour de
    /// calendrier par course — `currentWeekRange` par relevé — et cette carte le demandait trois
    /// fois par passe de `body`, pour les mêmes huit nombres. Elle le demande une fois.
    private func acuteChronicRatio(_ semaines: [Double]) -> Double? {
        TrainingLoad.acuteChronicRatio(weeklyKm: semaines)
    }

    /// La CLÉ, pas une chaîne traduite : `StatChip` la passe à `LocalizedStringKey` et s'en
    /// charge. Deux des trois libellés arrivaient ici déjà traduits, donc traduits deux fois.
    private func loadZoneLabel(_ ratio: Double) -> String {
        TrainingLoad.zone(for: ratio).labelKey
    }
}
