import SwiftUI
import SwiftData

/// Daily goals detail — mirrors `RingsScreen` in screensA.jsx, redefined around 3 distinct daily
/// behaviors (Séance du jour / Calories actives / Pas) instead of 3 measures of the same run.
/// Also a day BROWSER, not just today's snapshot: < > navigation re-queries Santé for steps/
/// calories on any past date (Santé keeps that data indefinitely — Haizo just never asked for a
/// day other than today before) and checks History for a run that day, so "Ta journée" reads
/// correctly for any date, not only the one you happened to open the app on.
struct RingsView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \RunRecord.date, order: .reverse) private var runs: [RunRecord]
    @State private var celebrationShown = false
    @State private var selectedDate: Date = .now
    @State private var historicalSteps: Double = 0
    @State private var historicalCalories: Double = 0
    @State private var isLoadingHistoricalDay = false

    private var p: UserProfile { appState.profile }
    private var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }

    private var remainingSteps: Int { max(0, Int(p.stepsGoal - p.stepsToday)) }
    private var remainingActiveCalories: Int { max(0, Int(p.activeCaloriesGoal - p.activeCaloriesToday)) }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "EEEE d MMMM"
        return f
    }()

    private var dayLabel: String {
        isToday ? String(localized: "Aujourd'hui") : Self.dayFormatter.string(from: selectedDate).capitalized
    }

    private var selectedWeekday: Int { (Calendar.current.component(.weekday, from: selectedDate) + HZAccueil.decalageDuLundi) % HZAccueil.joursParSemaine }

    /// Whether a real run exists on the selected date — the one honest way to say "séance faite"
    /// for a day that isn't today (`weekSessions.completed` only exists for the CURRENT week).
    private var hasRunOnSelectedDate: Bool {
        runs.contains { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    /// Today reads the live, already-tracked rest-day flag; any other date falls back to the
    /// stable weekly running-days pattern (see `UserProfile.isRunningDay`) since past weeks'
    /// exact plan isn't retained.
    private var isRunningDayForSelected: Bool {
        isToday ? !p.isRestDayToday : p.isRunningDay(weekday: selectedWeekday)
    }

    private var displaySteps: Double { isToday ? p.stepsToday : historicalSteps }
    private var displayCalories: Double { isToday ? p.activeCaloriesToday : historicalCalories }

    /// A real run on the selected date always wins over the guessed weekly pattern — otherwise a
    /// run logged on what `isRunningDayForSelected` guesses was a rest day (the guess is only a
    /// stable weekday pattern; the real plan for a past week isn't retained) would show that day
    /// as "Repos" with no session goal counted at all, contradicting History showing a real run.
    private var sessionDoneForSelected: Bool? {
        if hasRunOnSelectedDate { return true }
        // Aujourd'hui, le plan réel de la semaine est connu : `isRestDayToday` lit `weekSessions`.
        // Le deviner depuis le motif hebdomadaire — ce que fait `isRunningDayForSelected`, faute
        // de mieux pour une date passée — pouvait le contredire, et l'anneau, son dénominateur et
        // la ligne « Séance » se retrouvaient alors à répondre différemment à la même question.
        if isToday { return p.isRestDayToday ? nil : p.seanceDoneToday }
        return isRunningDayForSelected ? false : nil
    }

    /// UNE SEULE SOURCE POUR TOUT L'ÉCRAN, et c'est la correction.
    ///
    /// Il y avait un raccourci `if isToday { return p.dailyGoalsProgress }`. Il ne changeait rien
    /// aux pas ni aux calories — `displaySteps` et `displayCalories` rendent déjà exactement les
    /// mêmes valeurs aujourd'hui. Il changeait UNE chose : la réponse à « la séance est-elle
    /// faite ? ». Le raccourci lisait le drapeau du profil, le reste de l'écran lisait
    /// `sessionDoneForSelected`, qui commence par regarder s'il existe une course ce jour-là.
    ///
    /// Le même écran affichait donc, au même instant : « Faite ✓ » sur la ligne (drapeau ignoré),
    /// un arc plein sur l'anneau (même chemin), une barre VIDE juste en dessous (drapeau), et
    /// « 2 / 3 » au centre (drapeau). Quatre rendus, deux sources, une seule question.
    private var displayProgress: [Double] {
        UserProfile.dailyGoalsProgress(
            sessionDone: sessionDoneForSelected,
            steps: displaySteps, stepsGoal: p.stepsGoal,
            activeCalories: displayCalories, activeCaloriesGoal: p.activeCaloriesGoal
        )
    }
    /// Les objectifs en jeu ce jour-là — deux un jour de repos. L'anneau dessinait jusqu'ici
    /// trois arcs sous un « 2 / 3 » qui, lui, comptait juste : un des arcs ne pouvait pas se
    /// remplir, et rien ne le disait.
    private var displayGoals: [(slot: Int, progress: Double)] {
        UserProfile.dailyGoalSlots(
            sessionDone: sessionDoneForSelected,
            steps: displaySteps, stepsGoal: p.stepsGoal,
            activeCalories: displayCalories, activeCaloriesGoal: p.activeCaloriesGoal
        )
    }

    private var displayDone: Int { displayProgress.filter { $0 >= 1 }.count }
    private var displayTotal: Int { sessionDoneForSelected == nil ? HZJournee.objectifsUnJourDeRepos : HZJournee.objectifsUnJourDeSeance }

    /// The most useful thing to nudge about right now — first incomplete goal, in priority order.
    /// Only ever shown for today — nudging her about an already-past day makes no sense.
    private var coachNudge: String? {
        if !p.seanceDoneToday, p.todaySession.durationMinutes > 0 {
            return String(localized: "Ta séance du jour t'attend : \(p.todaySession.displayTitle) (\(p.todaySession.durationMinutes)′).")
        }
        if p.activeCaloriesToday < p.activeCaloriesGoal {
            return String(localized: "Encore \(remainingActiveCalories) kcal actives pour boucler l'objectif du jour.")
        }
        if p.stepsToday < p.stepsGoal {
            return String(localized: "Encore \(remainingSteps) pas pour boucler ton objectif — une petite marche ?")
        }
        return nil
    }

    var body: some View {
        HZPage {
            hautDePage
        } contenu: {
            feuille
        }
        .task(id: selectedDate) { await loadHistoricalDayIfNeeded() }
    }

    // MARK: - Le haut, sur le noir

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZCommandesDuHaut(retour: { appState.go(.home) }) { EmptyView() }
            VStack(alignment: .leading, spacing: 0) {
                Text(isToday ? String(localized: "Aujourd'hui") : String(localized: "Journée passée"))
                    .hzTexte(.c15, .semi)
                    .foregroundStyle(HZCouleur.secondaireSurSombre)
                Text("Ta journée")
                    .hzAffichage(.titreDEcran)
                    .foregroundStyle(HZCouleur.blanc)
            }
            .padding(.horizontal, HZEspace.margeDeTitre)
            .padding(.top, HZHub.sousLesCommandes)
            dayNavigator
                .padding(.horizontal, HZEspace.marge)
                .padding(.top, HZHub.sousLesCommandes)
            anneau
                .padding(.top, HZHub.sousLesCommandes)
        }
    }

    // # L'ANNEAU EST LE DESSIN DE CET ÉCRAN
    //
    // Le centre n'est pas une légende posée sur le dessin mais son MOYEU : il est au milieu de
    // l'anneau, et le compte vit DANS la forme.
    private var anneau: some View {
        ZStack {
            JourneeAnneau(progres: displayGoals.map(\.progress))
            VStack(spacing: 0) {
                Text("\(displayDone) / \(displayTotal)")
                    .hzAffichage(.chiffre)
                    .foregroundStyle(HZCouleur.blanc)
                Text("Bouclés")
                    .hzTexte(.c13, .semi)
                    .foregroundStyle(HZCouleur.secondaireSurSombre)
                    .lineLimit(1)
                    .minimumScaleFactor(HZAction.retraitDuLibelle)
            }
        }
        .opacity(isLoadingHistoricalDay ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
        .frame(maxWidth: .infinity)
        .animation(.easeOut(duration: HZJournee.dureeDuChargement), value: isLoadingHistoricalDay)
        // L'anneau est un graphique : sans ceci VoiceOver le sauterait en silence et lirait le
        // centre en deux arrêts détachés. La clé existait déjà au catalogue, traduite.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String(localized: "\(displayDone) sur \(displayTotal) objectifs bouclés")))
    }

    private var dayNavigator: some View {
        HStack(spacing: HZEspace.entreCommandes) {
            HZBoutonRond(dessin: .retour, nom: String(localized: "Jour précédent"),
                         fond: HZCouleur.surfaceSombre, trait: HZBoutonRond.traitDuRetour) {
                changeDay(by: -1)
            }

            Text(dayLabel)
                .hzTexte(.c17, .gras)
                .foregroundStyle(HZCouleur.blanc)
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(HZAction.retraitDuLibelle)

            HZBoutonRond(dessin: .chevron, nom: String(localized: "Jour suivant"),
                         fond: HZCouleur.surfaceSombre) {
                changeDay(by: 1)
            }
            .disabled(isToday)
            .opacity(isToday ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
        }
    }

    // MARK: - La feuille

    private var feuille: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            seanceRow
            // « kcal » reste un symbole d'unité.
            objectifRow(name: String(localized: "Calories actives"), value: displayCalories,
                        goal: p.activeCaloriesGoal, unit: HZJournee.uniteDEnergie)
            objectifRow(name: String(localized: "Pas"), value: displaySteps, goal: p.stepsGoal,
                        unit: String(localized: "pas"))
            if isToday {
                voixDuCoach
            }
        }
    }

    @ViewBuilder private var voixDuCoach: some View {
        if let coachNudge {
            HZBandeauDuCoach(texte: coachNudge)
        } else {
            // The one genuine celebration state on this screen (all 3 goals done) — a
            // spring scale-in gives it the "achievement unlocked" beat the static text
            // didn't have, matching the ring's own animate-on-appear fill above.
            HZPlaque {
                Text("Journée bouclée")
                    .hzAffichage(.section)
                    .foregroundStyle(HZCouleur.encre)
                Text("Tes \(p.dailyGoalsTotal) objectifs du jour atteints · +120 XP")
                    .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .scaleEffect(celebrationShown ? HZJournee.echelleFinale : HZJournee.echelleInitiale)
            .opacity(celebrationShown ? HZHub.opaciteNormale : 0)
            .onAppear {
                withAnimation(.spring(response: HZJournee.reponseDuRessort,
                                      dampingFraction: HZJournee.amortissementDuRessort)) { celebrationShown = true }
            }
        }
    }

    private func changeDay(by offset: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) else { return }
        guard newDate <= .now else { return }
        Haptics.selection()
        selectedDate = newDate
    }

    private func loadHistoricalDayIfNeeded() async {
        guard !isToday else { return }
        isLoadingHistoricalDay = true
        historicalSteps = 0
        historicalCalories = 0
        async let steps = appState.healthKit.steps(on: selectedDate)
        async let calories = appState.healthKit.activeCalories(on: selectedDate)
        let (s, c) = await (steps, calories)
        guard !Task.isCancelled else { return }
        historicalSteps = s
        historicalCalories = c
        isLoadingHistoricalDay = false
    }

    // MARK: - Les objectifs

    private var seanceRow: some View {
        let restDay = sessionDoneForSelected == nil
        let done = sessionDoneForSelected == true
        let etat = restDay ? String(localized: "Repos")
            : (done ? String(localized: "Faite ✓")
                    : (isToday ? String(localized: "À faire") : String(localized: "Non faite")))
        return HZPlaque {
            HStack(alignment: .firstTextBaseline, spacing: HZEspace.entreCommandes) {
                Text("Séance")
                    .hzTexte(.c16, .gras)
                    .foregroundStyle(HZCouleur.encre)
                Spacer(minLength: 0)
                Text(etat)
                    .hzTexte(.c14, .semi)
                    .foregroundStyle(done ? HZCouleur.encre : HZCouleur.secondaireSurClair)
            }
            if !restDay {
                HZJauge(fraction: displayProgress[0], couleur: HZCouleur.accent,
                        epaisseur: HZHub.epaisseurDeLaJaugeFine)
            }
        }
    }

    private func objectifRow(name: String, value: Double, goal: Double, unit: String) -> some View {
        HZPlaque {
            HStack(alignment: .firstTextBaseline, spacing: HZEspace.entreCommandes) {
                Text(name)
                    .hzTexte(.c16, .gras)
                    .foregroundStyle(HZCouleur.encre)
                Spacer(minLength: 0)
                (Text(formattedValue(value)).font(HZPolice.texte(.c14, .gras, tabulaire: true))
                    .foregroundStyle(HZCouleur.encre)
                    + Text(" / \(formattedValue(goal)) \(unit)").font(HZPolice.texte(.c14, .medium, tabulaire: true))
                    .foregroundStyle(HZCouleur.secondaireSurClair))
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HZJauge(fraction: goal == 0 ? 0 : value / goal, couleur: HZCouleur.accent,
                    epaisseur: HZHub.epaisseurDeLaJaugeFine)
        }
    }

    private func formattedValue(_ v: Double) -> String {
        v == v.rounded() ? "\(Int(v))" : String(format: "%.1f", locale: Locale.current, v)
    }
}

/// L'ANNEAU DES OBJECTIFS DU JOUR : un seul anneau, partagé en autant d'arcs que d'objectifs en jeu
/// (trois, ou deux un jour de repos), avec un écart entre eux. Mono-accent : ce qui sépare les
/// objectifs, ce sont les écarts et l'ordre, et les lignes dessous qui les nomment.
///
/// Il se remplit à l'ouverture de la page, sauf si le réglage « Réduire les animations » est actif.
/// La géométrie des arcs est celle que le widget partage (`RingSegmentGeometry`).
private struct JourneeAnneau: View {
    let progres: [Double]
    @State private var affiche: [Double]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(progres: [Double]) {
        self.progres = progres
        _affiche = State(initialValue: progres.map { _ in 0 })
    }

    var body: some View {
        ZStack {
            ForEach(Array(progres.enumerated()), id: \.offset) { rang, _ in
                arc(rang)
            }
        }
        // Un cercle se trace à partir de trois heures : on le tourne pour que le premier arc parte
        // de midi, dans le sens des aiguilles d'une montre.
        .rotationEffect(.degrees(-HZHub.quartDeTour))
        .padding(HZJournee.traitDeLAnneau / HZHub.moitie)
        .frame(width: HZJournee.coteDeLAnneau, height: HZJournee.coteDeLAnneau)
        .onAppear { affiche = progres }
        .onChange(of: progres) { _, nouveau in affiche = nouveau }
    }

    private func arc(_ rang: Int) -> some View {
        let segment = RingSegmentGeometry.segment(at: rang, count: progres.count)
        let fait = HZHub.borner(rang < affiche.count ? affiche[rang] : 0)
        let fin = segment.trimStart + (segment.trimEnd - segment.trimStart) * fait
        let trait = StrokeStyle(lineWidth: HZJournee.traitDeLAnneau, lineCap: .round)
        return ZStack {
            // La piste : la longueur totale du segment, en gris neutre. Une piste teintée de
            // l'accent se lisait comme un anneau plein.
            Circle()
                .trim(from: segment.trimStart, to: segment.trimEnd)
                .stroke(HZCouleur.filetSombre, style: trait)
            Circle()
                .trim(from: segment.trimStart, to: fin)
                .stroke(HZCouleur.accent, style: trait)
                .animation(reduceMotion ? nil : .easeOut(duration: HZJournee.dureeDeLAnneau), value: fait)
        }
    }
}
