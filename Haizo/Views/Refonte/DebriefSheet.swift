import SwiftUI
import SwiftData
import StoreKit

/// RPE debrief bottom sheet — submitting this is the core adaptive-plan mechanic. Mirrors the
/// `debrief` sheet inside `RecapScreen` in screensA.jsx.
struct DebriefSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Query(filter: #Predicate<Shoe> { $0.retiredAt == nil }) private var activeShoes: [Shoe]
    @Query private var runs: [RunRecord]
    var run: RunRecord
    @State private var rpe: RPE = .justeBien
    @Environment(SubscriptionService.self) private var subscriptions
    private var planUnlocked: Bool { subscriptions.unlocks(.adaptivePlan) }

    /// The plan only ever re-adjusts at a week boundary (see `AdaptivePlanEngine.tierDelta`),
    /// never session-to-session — this used to say "Prochaine séance" (next session), implying
    /// tomorrow's plan would shift, when what's really true is the *next week's* plan reacts to
    /// this week's average RPE. Wording it any tighter than "semaine prochaine" would be a promise
    /// the engine doesn't keep.
    /// Was a single hardcoded line claiming the last split was always the fastest and "FC
    /// maîtrisée en Z4" — true or not, for every run. Now derived from `run.splits`'s real pace
    /// values (no HR-zone claim at all: there's no real per-user zone threshold to check FC
    /// against, so that part is dropped rather than kept as an unbacked guess).
    private var insightMessage: String {
        let paces = run.splits.compactMap(PaceModel.parseSecPerKm)
        guard paces.count > 1, let minPace = paces.min(), let maxPace = paces.max(), maxPace > minPace else {
            return String(localized: "Séance enregistrée. Bien joué.")
        }
        if paces.last == minPace {
            return String(localized: "Séance solide. Ton dernier kilomètre était ton plus rapide : tu avais encore du jus.")
        }
        if paces.first == minPace {
            return Accord.selon(f: String(localized: "Séance solide. Tu es partie fort et tu as tenu jusqu'au bout."),
                                m: String(localized: "Séance solide. Tu es parti fort et tu as tenu jusqu'au bout."))
        }
        return String(localized: "Séance solide. Allure plutôt régulière du début à la fin.")
    }

    private var impactLines: [(String, String, String)] {
        // A second run validated the same day (a different device, or just a second session)
        // doesn't get its own streak day — `applyDebrief`'s own gapDays == 0 branch already
        // no-ops the increment in that case. `seanceDoneToday` is set by the very same call that
        // sets `lastStreakDate`, so it's a reliable read of "did a debrief already land today?"
        // taken here, before this tap's own debrief has run.
        let alreadyCountedToday = appState.profile.seanceDoneToday
        let nextStreak = alreadyCountedToday ? appState.profile.streak : appState.profile.streak + 1
        // Phrased as a tendency ("compte pour...") — the tier really moves on the WEEK's average
        // RPE at the boundary, so a flat promise ("relevée d'un palier") from one single tap
        // could contradict what actually happens after two harder sessions the same week.
        let nextWeekLabel = String(localized: "Semaine prochaine : ")
        let streakLine = ("flame.fill", String(localized: "Série en cours : "), String(localized: "jour \(nextStreak)"))
        // Sans abonnement il n'y a pas de programme à ajuster : promettre que la semaine
        // prochaine sera relevée ou allégée serait une promesse sur quelque chose d'invisible et
        // d'inexistant. Le ressenti reste demandé — il est enregistré avec la course et servira le
        // jour où un programme existe — mais la carte ne parle plus que de ce qui est vrai.
        guard planUnlocked else { return [streakLine] }
        switch rpe {
        case .facile, .justeBien:
            return [("arrow.up.right", nextWeekLabel, String(localized: "compte pour relever l'intensité")), streakLine]
        case .dur:
            return [("equal", nextWeekLabel, String(localized: "compte pour garder ce niveau")), streakLine]
        case .tropDur:
            return [("arrow.down.right", nextWeekLabel, String(localized: "compte pour alléger la charge")), streakLine]
        }
    }

    var body: some View {
        // La question est le titre de la feuille ; la phrase du coach en est le sous-titre.
        HZFeuilleModale(titre: String(localized: "Comment tu te sens ?")) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Bilan · \(run.title)")
                        .hzParagraphe(.c13, .semi, interligne: HZBandeauDuCoach.interligne)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                        .fixedSize(horizontal: false, vertical: true)
                    // Cette phrase est le SOUS-TITRE de la question : elle se lit comme telle, sur
                    // la même marge que tout le reste.
                    HZPhrase(texte: insightMessage)
                        .padding(.top, HZEspace.entrePilules)
                    effort
                    impact
                }
                .padding(.horizontal, HZEspace.marge)
            }
            // Le geste principal de la feuille sort du défilement : le système le place au-dessus
            // de l'indicateur d'accueil, et le contenu qui défile s'arrête juste avant lui.
            .safeAreaInset(edge: .bottom, spacing: 0) { boutonDeValidation }
        }
    }

    // MARK: - L'effort ressenti

    private var effort: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZTitreDeSection(titre: String(localized: "L'effort ressenti"))
                .padding(.top, HZEspace.entreSections)
            // Les quatre mots sont ordonnés, du plus dur au plus facile : l'ordre des lignes est
            // celui de l'échelle. La ligne choisie est annoncée comme telle à VoiceOver
            // (`HZReponse` porte le trait), parce que c'est la mécanique centrale du plan adaptatif.
            VStack(spacing: HZEspace.entreCommandes) {
                ForEach(RPE.allCases) { opt in
                    HZReponse(titre: opt.label, choisie: rpe == opt) { rpe = opt }
                }
            }
            .padding(.top, HZEspace.sousUnTitre)
        }
    }

    // MARK: - Ce que ça change

    private var impact: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZTitreDeSection(titre: planUnlocked ? String(localized: "Impact sur ton programme")
                                                 : String(localized: "Ce que ça change"))
                .padding(.top, HZEspace.entreSections)
            HZPlaque {
                LazyVStack(alignment: .leading, spacing: HZEspace.groupe) {
                    ForEach(impactLines.indices, id: \.self) { i in
                        ligneDImpact(impactLines[i])
                    }
                }
            }
            .padding(.top, HZEspace.sousUnTitre)
        }
    }

    /// Un symbole, plus un emoji : une flèche qui monte, un signe égal, une flèche qui descend.
    /// Les trois états de l'intensité de la semaine prochaine sont ORDONNÉS.
    private func ligneDImpact(_ ligne: (String, String, String)) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: HZEspace.entreCommandes) {
            Image(systemName: ligne.0)
                .font(HZPolice.texte(.c15, .semi))
                .foregroundStyle(HZCouleur.encre)
                .frame(width: HZJournee.largeurDeLIcone)
                .accessibilityHidden(true)
            (Text(ligne.1).font(HZPolice.texte(.c15, .medium)).foregroundStyle(HZCouleur.secondaireSurClair)
                + Text(ligne.2).font(HZPolice.texte(.c15, .gras)).foregroundStyle(HZCouleur.encre))
                .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Valider

    /// « Mettre à jour le programme » ne se dit qu'à qui en a un qui s'adapte : sans l'abonnement,
    /// ou en course libre, le bouton et le message annonçaient une mise à jour que la personne ne
    /// pouvait voir nulle part.
    private var aUnProgrammeQuiSAdapte: Bool {
        subscriptions.unlocks(.adaptivePlan) && appState.profile.programPhase == .active
    }

    private var boutonDeValidation: some View {
        HZBoutonPilule(libelle: aUnProgrammeQuiSAdapte ? String(localized: "Valider et mettre à jour")
                                                      : String(localized: "Valider"),
                       etendu: true, action: valider)
            .padding(.horizontal, HZEspace.marge)
            .padding(.top, HZEspace.entreCommandes)
            .padding(.bottom, HZHub.basDeFeuille)
            .frame(maxWidth: .infinity)
            .background(HZCouleur.blanc)
    }

    private func valider() {
        // Blocks a double-tap (or reopening this sheet for a run already validated)
        // from crediting XP/streak/club-feed a second time for the same run —
        // `run.modelContext == nil` below only ever guarded the INSERT, not a second
        // run through the reward logic on a record already inserted.
        guard run.debriefedAt == nil else { dismiss(); return }
        run.debriefedAt = .now
        // A GPS run is inserted by `endLiveRun` (it really happened, validated or
        // not); a manual "FAIT" run reaches here NOT yet inserted, so a dismissed
        // sheet leaves no phantom record — it only becomes real on this tap.
        if run.modelContext == nil {
            appState.modelContext.insert(run)
        }
        // Auto-attaches whichever pair is set as default in `ShoesView` — asking her
        // to pick a shoe on every single run here would clutter the one screen that
        // matters most (the RPE debrief); a wrong pick is a rare enough edge case to
        // just fix from History/ShoesView instead of designing a picker into this flow.
        if let shoeID = appState.profile.defaultShoeID, let shoe = activeShoes.first(where: { $0.id == shoeID }) {
            run.shoeID = shoeID
            // `runs` may or may not already include this exact run (GPS runs are
            // inserted earlier by `endLiveRun`, manual ones aren't yet) — excluding it
            // by identity and adding `run.distanceKm` back by hand sidesteps that
            // instead of risking a double count.
            let kmBefore = shoe.totalKm(runs: runs.filter { $0 !== run })
            let kmAfter = kmBefore + run.distanceKm
            if kmBefore < shoe.alertThresholdKm, kmAfter >= shoe.alertThresholdKm {
                appState.notify(icon: "shoe.fill", colorHex: AppNotification.avertissement, title: String(localized: "\(shoe.name) en fin de vie"), text: String(localized: "Cette paire dépasse \(Int(shoe.alertThresholdKm)) km. Pense à la changer bientôt."))
            }
        }
        AdaptivePlanEngine.applyDebrief(rpe: rpe, run: run, profile: appState.profile)
        let distance = String(format: "%.1f", locale: Locale.current, run.distanceKm)
        // A distance-less séance (HYROX/renfo logged without GPS) shouldn't read
        // "a couru 0,0 km" in the club feed.
        let feedText = run.distanceKm > HZJournee.distanceMiniMesuree
            ? String(localized: "a couru \(distance) km · \(run.title)")
            : String(localized: "a fait sa séance · \(run.title)")
        // Les vraies mesures de la sortie partent avec le post : c'est ce qui permet à
        // la carte du fil d'afficher KM / ALLURE / TEMPS au lieu d'une seule phrase.
        // Chaque champ n'est joint que s'il a été réellement mesuré — une séance sans
        // GPS n'envoie ni distance, ni allure, ni dénivelé, et sa carte n'affichera
        // simplement pas ces colonnes.
        let hasDistance = run.distanceKm > HZJournee.distanceMiniMesuree
        let metrics = ActivityMetrics(
            distanceKm: hasDistance ? run.distanceKm : nil,
            durationSeconds: run.durationSeconds > 0 ? run.durationSeconds : nil,
            avgPace: hasDistance && PaceModel.parseSecPerKm(run.avgPace) != nil ? run.avgPace : nil,
            elevationGainM: run.elevationGainM > 0 ? run.elevationGainM : nil,
            isPersonalRecord: RunRecord.beatsPersonalRecord(run, history: runs),
            // De quoi DÉROULER la sortie chez les autres, et pas seulement la
            // résumer : ses kilomètres un par un, son cœur, ses calories. Ils
            // existaient déjà sur l'appareil et n'en sortaient jamais.
            splits: run.splits,
            avgHeartRate: run.avgHeartRate > 0 ? run.avgHeartRate : nil,
            kcal: run.kcal > 0 ? run.kcal : nil
        )
        // `contentKey` accompagne la phrase sans la remplacer : le serveur garde `text` pour la
        // notification push, qu'il compose lui-même et sans connaître la langue de qui la
        // reçoit, tandis que le fil se refabrique la phrase chez sa lectrice. Absent pour
        // une séance hors plan — il n'y a alors aucun type de séance à nommer.
        appState.postClubActivity(type: "run", text: feedText, xpEarned: HZJournee.xpDUneSeance, contentKey: run.sessionKind?.rawValue, discipline: run.discipline.rawValue, metrics: metrics, route: run.route)
        // Deliberately here rather than in `AppState.endLiveRun` — this tap is where a
        // run actually becomes real on every path into it (GPS, "FAIT", a run handed
        // back by the Watch), and it's the tap that credits XP/streak/plan adaptation.
        // Anything earlier would count a stopped-but-never-validated run as completed,
        // and would miss the two non-GPS paths entirely.
        Analytics.shared.trackOnce(.firstRunCompleted)
        Analytics.shared.track(.runCompleted, [
            "distance_km": .double((run.distanceKm * HZJournee.dixiemes).rounded() / HZJournee.dixiemes),
            "duration_min": .int(run.durationSeconds / HZJournee.secondesParMinute),
            // `RPE`'s own raw value, which is ordinal by construction (0 = trop dur →
            // 3 = facile) — an average over it is meaningful, where the French display
            // label would have been both unaverageable and free to change with copy.
            "rpe": .int(rpe.rawValue),
            "streak": .int(appState.profile.streak),
        ])
        // Every completed session earns its own bell entry — before this, the only
        // notify() call sites were the rare same-day 3-goals bonus, a club kudos/
        // comment, or a weekly plan update, so a solo runner who just isn't hitting
        // that exact daily combo would never see anything land in the bell at all.
        appState.notify(icon: "checkmark.circle.fill", colorHex: AppNotification.accent, title: String(localized: "Séance terminée"), text: run.distanceKm > HZJournee.distanceMiniMesuree ? "\(run.title) · \(distance) km · +120 XP" : "\(run.title) · +120 XP")
        // This single tap awards XP, updates the streak, and possibly a daily-goals
        // bonus — the app's core adaptive-plan mechanic — but had zero haptic feedback,
        // the same as tapping a settings toggle. A success tap here, and a stronger one
        // on the two branches below that are genuine celebration moments.
        Haptics.success()
        let streak = appState.profile.streak
        if AdaptivePlanEngine.streakMilestones.contains(streak) {
            // Le palier SUIVANT plutôt qu'un « continue comme ça ! ». Le fait — la série
            // — est déjà dans le titre ; le texte doit apprendre quelque chose.
            let suite = AdaptivePlanEngine.palierSuivant(apres: streak)
                .map { String(localized: "Prochain palier : \($0) jours.") }
                ?? String(localized: "Un an de suite. Il n'y a pas de palier au-delà.")
            appState.notify(icon: "flame.fill", colorHex: AppNotification.accent, title: String(localized: "Série de \(streak) jours"), text: suite)
            Haptics.impact(.heavy)
        }
        if AdaptivePlanEngine.checkDailyGoalsBonus(appState.profile) {
            appState.postClubActivity(type: "badge", text: String(localized: "a bouclé ses 3 objectifs du jour"), xpEarned: HZJournee.xpDUneSeance, contentKey: "daily_goals")
            appState.notify(icon: "sparkles", colorHex: AppNotification.accent, title: String(localized: "Journée bouclée"), text: String(localized: "Tes 3 objectifs du jour sont faits : +120 XP."))
            NotificationService.shared.postImmediateNotification(title: String(localized: "Journée bouclée"), body: String(localized: "Tes 3 objectifs du jour sont faits : +120 XP."))
            Haptics.impact(.heavy)
        }
        // Today's session is done — an evening reminder for it would be stale now.
        NotificationService.shared.rescheduleDailyReminder(for: appState.profile)
        appState.publishWidgetSnapshot()
        appState.toast(aUnProgrammeQuiSAdapte
                       ? String(localized: "Programme mis à jour · +120 XP")
                       : String(localized: "Séance validée · +120 XP"))
        // Ask for a rating right after a run that felt good, not on a fixed schedule —
        // `shouldRequestReview` also caps this to real milestones and a 90-day cooldown.
        if appState.shouldRequestReview(rpe: rpe) {
            appState.recordReviewPromptShown()
            requestReview()
            // `requestReview()` only hands the request to the window scene — presenting
            // it is async and risks getting silently dropped if this sheet dismisses and
            // navigates away in the same synchronous burst, which is exactly what used
            // to happen right here. Give it a beat to actually attach before tearing
            // down the presenting context.
            Task {
                try? await Task.sleep(for: .milliseconds(HZJournee.attenteAvantLaFermeture))
                await MainActor.run {
                    dismiss()
                    appState.go(.rings)
                }
            }
        } else {
            dismiss()
            appState.go(.rings)
        }
    }
}
