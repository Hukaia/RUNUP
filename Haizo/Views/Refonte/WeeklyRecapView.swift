import SwiftUI
import SwiftData

/// A dedicated "your week" moment — Strava's weekly email, but a full native screen reachable from
/// tapping the Sunday-evening local notification (`NotificationService.scheduleWeeklyRecapReminder`)
/// or the "Cette semaine" card in `StatsView`. `StatsView.weekCard` already surfaces this week's km
/// inline among many other trend cards; this exists because a recurring re-engagement push needs
/// somewhere worth actually opening — a real recap, not just a redirect back into the Stats tab.
/// Visual structure modeled on the "BILAN · ta semaine" reference (Haizo 4.0 mockup, concept A ·
/// Midnight Rose): a colored 2×2 stat grid instead of one oversized hero number, a volume-per-day
/// bar chart, and a real personal-record callout — same 3 real metrics (km/séances/temps actif/
/// série) as before, no new data invented to match the mockup's own (different) stat set.
struct WeeklyRecapView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \RunRecord.date, order: .reverse) private var allRuns: [RunRecord]
    @State private var chartRevealed = false
    private var profile: UserProfile { appState.profile }

    private var bilan: BilanDeLaSemaine {
        BilanDeLaSemaine(historique: allRuns, semaine: AdaptivePlanEngine.currentWeekRange())
    }

    private var weekDateRangeLabel: String {
        let start = bilan.semaine.lowerBound
        let end = Calendar.current.date(byAdding: .day, value: HZRecap.joursAvantLaFin, to: start) ?? start
        return "\(start.formatted(.dateTime.day().locale(Locale.current)))-\(end.formatted(.dateTime.day().month(.wide).locale(Locale.current)))"
    }

    private var todayWeekdayIndex: Int { WidgetWeekDay.rangDuJour(Demonstration.maintenant) }

    private var recordAffiche: (label: String, value: String)? {
        switch bilan.record {
        case nil:
            return nil
        case .allure(let secParKm, let km):
            return (String(localized: "Nouveau record d'allure"),
                    String(localized: "\(PaceModel.formatDuration(secParKm))/km sur \(String(format: "%.1f", locale: Locale.current, km)) km"))
        case .distance(let km):
            return (String(localized: "Nouveau record de distance"),
                    String(format: "%.1f km", locale: Locale.current, km))
        }
    }

    var body: some View {
        HZPage {
            hautDePage
        } contenu: {
            feuille
        }
        .onAppear {
            if bilan.estLaMeilleureSemaine || bilan.record != nil { Haptics.success() }
        }
    }

    // MARK: - Le haut, sur le noir

    private var hautDePage: some View {
        let kilometres = bilan.kilometres
        return VStack(alignment: .leading, spacing: 0) {
            HZCommandesDuHaut(retour: { appState.retour(parDefaut: .stats) }) { EmptyView() }
            VStack(alignment: .leading, spacing: 0) {
                Text(bilan.estLaMeilleureSemaine ? "Ta meilleure semaine" : "Bilan de la semaine")
                    .hzAffichage(.titreDEcran)
                    .foregroundStyle(HZCouleur.blanc)
                Text("Semaine \(profile.weekNumber) · \(weekDateRangeLabel)")
                    .hzTexte(.c15, .semi)
                    .foregroundStyle(HZCouleur.secondaireSurSombre)
                Text(verbatim: String(format: "%.1f", locale: Locale.current, kilometres))
                    .hzAffichage(.total)
                    .hzVedette()
                    .lineLimit(1)
                    .padding(.leading, -HZStats.debordDuTotal)
                    .minimumScaleFactor(HZStats.reductionDuTotal)
                HStack(spacing: HZEspace.entreCommandes) {
                    Text("kilomètres cette semaine")
                        .hzTexte(.c20, .gras)
                        .foregroundStyle(HZCouleur.blanc)
                        .lineLimit(1)
                        .minimumScaleFactor(HZStats.reductionDuTotal)
                    if let ecart = ecartAvecLaSemainePrecedente {
                        HZPilule(texte: ecart, style: .etiquetteGrasse)
                    }
                }
                .padding(.top, HZStats.sousLeTotal)
            }
            .padding(.horizontal, HZEspace.margeDeTitre)
            .padding(.top, HZHub.sousLesCommandes)
            barresDesJours
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZStats.sousLeLibelle)
        }
    }

    /// « ▲ 3,2 km » : l'écart avec la semaine d'avant, seulement s'il y a une semaine d'avant.
    private var ecartAvecLaSemainePrecedente: String? {
        guard bilan.kilometresSemainePrecedente > 0 else { return nil }
        let ecart = bilan.kilometres - bilan.kilometresSemainePrecedente
        let valeur = String(format: "%.1f", locale: Locale.current, abs(ecart))
        return ecart >= 0 ? "▲ \(valeur) km" : "▼ \(valeur) km"
    }

    /// Les sept jours : une barre par jour, haute de ses kilomètres, de la couleur de l'intensité de
    /// la sortie du jour. Une sortie sans couleur dans le canvas (seuil, fractionné, renforcement) est
    /// peinte à l'accent, comme sur l'accueil ; un jour sans sortie est un trait éteint.
    private var barresDesJours: some View {
        let barres = bilan.kilometresParJour
        let maximum = max(barres.max() ?? 1, 1)
        return VStack(spacing: HZEspace.entrePilules) {
            HStack(alignment: .bottom, spacing: HZStats.ecartDesBarres) {
                ForEach(barres.indices, id: \.self) { i in
                    RoundedRectangle(cornerRadius: HZStats.rayonDUneBarre, style: .circular)
                        .fill(barres[i] > 0 ? couleurDuJour(i) : HZCouleur.pointEteint)
                        .frame(height: chartRevealed ? max(HZStats.hauteurMiniDUneBarre, barres[i] / maximum * HZStats.hauteurDesBarres)
                                                     : HZStats.hauteurMiniDUneBarre)
                        .frame(maxWidth: .infinity)
                        .animation(reduceMotion ? nil : .easeOut(duration: HZRecap.dureeDesBarres)
                            .delay(Double(i) * HZRecap.decalageDesBarres), value: chartRevealed)
                        .accessibilityLabel(i == todayWeekdayIndex ? String(localized: "\(DayStatus.fullNames[i]), aujourd'hui") : DayStatus.fullNames[i])
                        .accessibilityValue("\(String(format: "%.1f", locale: Locale.current, barres[i])) km")
                }
            }
            .frame(height: HZStats.hauteurDesBarres, alignment: .bottom)
            .onAppear { chartRevealed = true }
            HStack(spacing: HZStats.ecartDesBarres) {
                ForEach(DayStatus.letters.indices, id: \.self) { i in
                    Text(DayStatus.letters[i])
                        .hzTexte(.c12, .gras)
                        .foregroundStyle(i == todayWeekdayIndex ? HZCouleur.blanc : HZCouleur.secondaireSurSombre)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    /// La couleur du jour : celle de l'intensité de sa plus longue sortie, sur le noir.
    private func couleurDuJour(_ jour: Int) -> Color {
        let sorties = bilan.seances.onFoot.filter { WidgetWeekDay.rangDuJour($0.date) == jour }
        guard let plusLongue = sorties.max(by: { $0.distanceKm < $1.distanceKm }),
              let famille = plusLongue.sessionKind?.family,
              let intensite = AccueilModele.intensite(de: famille) else { return HZCouleur.accent }
        return intensite.point
    }

    // MARK: - La feuille

    private var feuille: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreSections) {
            tuiles
            if let recordAffiche { recordCard(recordAffiche) }
            HZBandeauDuCoach(texte: motDuCoach)
            if !bilan.seances.isEmpty { courses }
            ShareLink(item: texteDePartage) {
                HStack(spacing: HZBoutonPilule.ecart) {
                    HZIcone(dessin: .partager, cote: HZBoutonPilule.coteDeLecture, couleur: HZCouleur.blanc)
                    Text("Partager")
                        .hzTexte(HZHauteurDeBouton.grande.corps, .gras)
                        .foregroundStyle(HZCouleur.blanc)
                }
                .frame(maxWidth: .infinity)
                .frame(height: HZHauteurDeBouton.grande.rawValue)
                .background(HZCouleur.encre, in: Capsule())
                .contentShape(Capsule())
            }
        }
    }

    private var tuiles: some View {
        VStack(spacing: HZEspace.entreTuiles) {
            HStack(spacing: HZEspace.entreTuiles) {
                HZTuileChiffre(libelle: String(localized: "Séances"), valeur: "\(bilan.nombreDeSeances)")
                HZTuileChiffre(libelle: String(localized: "Temps actif"),
                               valeur: PaceModel.formatTotalDuration(bilan.secondesActives))
            }
            HStack(spacing: HZEspace.entreTuiles) {
                HZTuileChiffre(libelle: String(localized: "Allure moyenne"),
                               valeur: bilan.allureMoyenneSecParKm.map { "\(PaceModel.formatDuration($0))/km" } ?? "—")
                HZTuileChiffre(libelle: String(localized: "Série"), valeur: "\(profile.streak) \(String(localized: "j"))",
                               sombre: true)
            }
        }
    }

    /// Ce que la semaine dit, et rien de plus que ce qu'elle dit : son rang, son écart avec la
    /// précédente, ou son absence.
    private var motDuCoach: String {
        if bilan.nombreDeSeances == 0 {
            return String(localized: "Pas encore de course cette semaine. Tu as le temps.")
        }
        if bilan.estLaMeilleureSemaine {
            return String(localized: "C'est ta meilleure semaine : \(String(format: "%.1f", locale: Locale.current, bilan.kilometres)) km.")
        }
        let ecart = bilan.kilometres - bilan.kilometresSemainePrecedente
        let valeur = String(format: "%.1f", locale: Locale.current, abs(ecart))
        if bilan.kilometresSemainePrecedente <= 0 {
            return String(localized: "Une première semaine à garder : \(String(format: "%.1f", locale: Locale.current, bilan.kilometres)) km.")
        }
        return ecart >= 0 ? String(localized: "\(valeur) km de plus que la semaine dernière.")
                          : String(localized: "\(valeur) km de moins que la semaine dernière : une semaine plus légère.")
    }

    private var texteDePartage: String {
        String(localized: "Ma semaine sur Haizo : \(String(format: "%.1f", locale: Locale.current, bilan.kilometres)) km.")
    }

    private func recordCard(_ record: (label: String, value: String)) -> some View {
        HZPlaque {
            HStack(spacing: HZEspace.entreTuiles) {
                HZIcone(dessin: .trophee, cote: HZResume.coteDuTrophee, couleur: HZCouleur.blanc)
                    .frame(width: HZResume.disqueDuTrophee, height: HZResume.disqueDuTrophee)
                    .background(HZCouleur.encre, in: Circle())
                VStack(alignment: .leading, spacing: 0) {
                    Text(record.label).hzTexte(.c15, .gras).foregroundStyle(HZCouleur.encre)
                    Text(record.value).hzTexte(.c13, .medium).foregroundStyle(HZCouleur.secondaireSurClair)
                }
                .lineLimit(HZFil.lignesDuCommentaire)
                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.label), \(record.value)")
    }

    // MARK: - Les courses de la semaine

    private var courses: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Courses de la semaine"))
            LazyVStack(spacing: 0) {
                ForEach(Array(bilan.seances.enumerated()), id: \.element.persistentModelID) { index, run in
                    HZLigneDeListe(titre: run.titreAffiche,
                                   sousTitre: run.date.formatted(.dateTime.weekday(.wide).day().month().locale(Locale.current)),
                                   filet: index < bilan.seances.count - 1) {
                        HZVignette {
                            HZMiniatureDeSortie(points: run.route.map { (lat: $0.lat, lng: $0.lng) })
                        }
                    } queue: {
                        HZValeurDeLigne(valeur: String(format: "%.2f km", locale: Locale.current, run.distanceKm),
                                        precision: rythmeAffiche(run))
                    }
                }
            }
        }
    }

    private func rythmeAffiche(_ run: RunRecord) -> String {
        guard let secParKm = PaceModel.parseSecPerKm(run.avgPace), secParKm > 0 else { return "" }
        return TimeFormat.rythmeEcrit(run.discipline, secondesParKm: secParKm)
    }
}
