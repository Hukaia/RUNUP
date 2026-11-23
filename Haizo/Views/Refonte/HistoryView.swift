import SwiftUI
import SwiftData

/// Run history — mirrors `HistoryScreen` in screensC.jsx. Uses a real `@Query` over `RunRecord`
/// so newly completed runs appear automatically ahead of older ones (newest-first).
struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RunRecord.date, order: .reverse) private var runs: [RunRecord]
    @State private var showAddRun = false
    @State private var pendingDelete: RunRecord?
    @State private var selectedRun: RunRecord?
    @State private var connexionOuverte = false

    /// Un mois de sorties : son titre, ses kilomètres, ses lignes.
    private struct Mois: Identifiable {
        let id: String
        let debut: Date
        var kilometres: Double
        var sorties: [RunRecord]
    }

    /// Les sorties groupées par mois, du plus récent au plus ancien : l'ordre de `runs`.
    private var mois: [Mois] {
        var groupes: [Mois] = []
        for run in runs {
            let composantes = Calendar.current.dateComponents([.year, .month], from: run.date)
            let identifiant = "\(composantes.year ?? 0)-\(composantes.month ?? 0)"
            if let index = groupes.firstIndex(where: { $0.id == identifiant }) {
                groupes[index].kilometres += run.distanceKm
                groupes[index].sorties.append(run)
            } else {
                groupes.append(Mois(id: identifiant, debut: Calendar.current.date(from: composantes) ?? run.date,
                                    kilometres: run.distanceKm, sorties: [run]))
            }
        }
        return groupes
    }

    var body: some View {
        HZPage {
            hautDePage
        } contenu: {
            feuille
        }
        .sheet(isPresented: $showAddRun) { AddRunSheet().hzFeuille(detents: [.large]) }
        .sheet(item: $selectedRun) { run in RecapView(historicalRun: run).hzFeuille(detents: [.large], gereSonBas: true) }
        .alert(
            "Supprimer cette course ?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
        ) {
            Button("Supprimer", role: .destructive) {
                if let run = pendingDelete {
                    // A deleted run that was today's "séance faite" shouldn't leave the daily
                    // goals gauge claiming it's done with nothing left backing it — but only when
                    // NO other run today remains (deleting a second short jog must not un-check a
                    // séance the morning's real run still backs).
                    let otherRunToday = runs.contains {
                        $0 !== run && Calendar.current.isDateInToday($0.date)
                    }
                    if Calendar.current.isDateInToday(run.date) && !otherRunToday {
                        AdaptivePlanEngine.undoTodaySessionCompletion(appState.profile)
                    }
                    // `runs` won't reflect the deletion until the next @Query update cycle, so
                    // the remaining set is computed by hand rather than read back immediately.
                    AdaptivePlanEngine.recomputeStreak(profile: appState.profile, currentRuns: runs.filter { $0 !== run })
                    modelContext.delete(run)
                    Haptics.warning()
                }
                pendingDelete = nil
            }
            Button("Annuler", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("Cette action est définitive.")
        }
    }


    // MARK: - Le haut, sur le noir

    private var hautDePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            HZCommandesDuHaut(retour: { appState.retour(parDefaut: .stats) }) {
                HZBoutonPilule(libelle: String(localized: "Ajouter"), hauteur: .petite,
                               fond: HZCouleur.blanc, couleur: HZCouleur.noir) { showAddRun = true }
                    .accessibilityLabel(String(localized: "Ajouter une séance"))
            }
            Text("Historique")
                .hzAffichage(.titreDEcran)
                .foregroundStyle(HZCouleur.blanc)
                .padding(.horizontal, HZEspace.margeDeTitre)
                .padding(.top, HZHub.sousLesCommandes)
            Text(Pluriel.choisir(runs.count,
                                 String(localized: "\(runs.count) sortie"),
                                 String(localized: "\(runs.count) sorties")))
                .hzTexte(.c15, .semi)
                .foregroundStyle(HZCouleur.secondaireSurSombre)
                .padding(.horizontal, HZEspace.margeDeTitre)
        }
    }

    // MARK: - La feuille

    private var feuille: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreSections) {
            if appState.pendingActivityCount > 0 { pendingSyncBanner }
            if runs.isEmpty {
                HZPhrase(texte: String(localized: "Termine une sortie, ou ajoutes-en une à la main : l'historique se remplit tout seul ensuite."),
                         titre: String(localized: "Pas encore de course"))
            }
            LazyVStack(alignment: .leading, spacing: HZEspace.entreSections) {
                ForEach(mois) { groupe in
                    VStack(alignment: .leading, spacing: 0) {
                        enTeteDuMois(groupe)
                        ForEach(Array(groupe.sorties.enumerated()), id: \.element.persistentModelID) { index, run in
                            ligne(run, derniere: index == groupe.sorties.count - 1)
                        }
                    }
                }
            }
        }
    }

    /// Le nom du mois en titre d'affichage, ses kilomètres à droite. L'année n'est écrite que pour un
    /// mois d'une autre année : « Novembre » dit tout de ce mois-ci.
    private func enTeteDuMois(_ groupe: Mois) -> some View {
        let memeAnnee = Calendar.current.isDate(groupe.debut, equalTo: .now, toGranularity: .year)
        let style = Date.FormatStyle(capitalizationContext: .beginningOfSentence)
        return HStack(alignment: .firstTextBaseline) {
            Text(memeAnnee ? groupe.debut.formatted(style.month(.wide))
                           : groupe.debut.formatted(style.month(.wide).year()))
                .hzAffichage(.section)
                .foregroundStyle(HZCouleur.encre)
            Spacer(minLength: HZEspace.entreCommandes)
            Text(Distances.km(groupe.kilometres))
                .hzTexte(.c15, .semi, tabulaire: true)
                .foregroundStyle(HZCouleur.secondaireSurClair)
        }
        .padding(.bottom, HZEspace.entrePilules)
    }

    /// Une sortie, comme sur l'accueil : sa vignette, son titre, sa date ; sa distance et son allure à
    /// droite. Supprimer et exporter passent par l'appui long.
    private func ligne(_ run: RunRecord, derniere: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { selectedRun = run } label: {
                HZLigneDeListe(titre: run.titreAffiche, sousTitre: AccueilModele.dateCourte(run.date),
                               filet: !derniere || ressentiManquant(run)) {
                    HZVignette {
                        HZMiniatureDeSortie(points: run.route.map { (lat: $0.lat, lng: $0.lng) })
                    }
                } queue: {
                    HZValeurDeLigne(valeur: String(format: "%.1f km", locale: Locale.current, run.distanceKm),
                                    precision: precision(de: run))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(runAccessibilityLabel(run))
            if ressentiManquant(run) {
                HZBoutonPilule(libelle: String(localized: "Ressenti manquant"), hauteur: .petite,
                               fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre) {
                    appState.pendingDebriefs.append(run)
                }
                .padding(.vertical, HZEspace.entrePilules)
            }
        }
        .contextMenu {
            if let url = GPXExporter.fileURL(for: run) {
                ShareLink(item: url) { Text("Exporter en GPX") }
            }
            Button("Supprimer", role: .destructive) { pendingDelete = run }
        }
    }

    private func ressentiManquant(_ run: RunRecord) -> Bool {
        run.debriefedAt == nil && AdaptivePlanEngine.currentWeekRange().contains(run.date)
    }

    /// L'allure d'une course à pied, la durée pour le reste.
    private func precision(de run: RunRecord) -> String {
        if run.discipline.rythme == .allureParKm, let allure = AccueilModele.allureValide(run.avgPace) {
            return allure + HZAccueil.uniteDAllure
        }
        return PaceModel.formatDuration(Double(run.durationSeconds))
    }

    private var raisonDeLAttente: String {
        switch appState.pendingActivityBlocker {
        case .session:
            return String(localized: "Elles restent sur ton téléphone, rien n'est perdu, mais ta session a expiré : reconnecte-toi pour les publier.")
        case .serveur:
            return String(localized: "Elles restent sur ton téléphone, rien n'est perdu. Haizo ne répond pas, nouvelle tentative plus tard.")
        case .reseau, .none:
            return String(localized: "Elles restent sur ton téléphone, rien n'est perdu. Nouvelle tentative automatique bientôt.")
        }
    }

    /// Les courses pas encore parties au club : ce qu'il s'est passé, et le bouton pour réessayer.
    private var pendingSyncBanner: some View {
        HZPlaque {
            Text(Pluriel.choisir(appState.pendingActivityCount,
                 String(localized: "\(appState.pendingActivityCount) course pas encore synchronisée"),
                 String(localized: "\(appState.pendingActivityCount) courses pas encore synchronisées")))
                .hzTexte(.c16, .gras)
                .foregroundStyle(HZCouleur.encre)
            Text(raisonDeLAttente)
                .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
            // LE BOUTON SUIT LA CAUSE. Quand la session a expiré, la phrase disait « reconnecte-toi »
            // au-dessus d'un bouton « Réessayer maintenant » qui ne pouvait pas réussir : rejouer
            // l'envoi sans session échoue de la même façon. Il propose ce que la phrase demande.
            if appState.pendingActivityBlocker == .session || !appState.auth.isSignedIn {
                HZBoutonPilule(libelle: String(localized: "Se connecter"), hauteur: .petite) {
                    Haptics.selection()
                    connexionOuverte = true
                }
            } else {
                HZBoutonPilule(libelle: String(localized: "Réessayer maintenant"), hauteur: .petite) {
                    Haptics.selection()
                    appState.retryPendingClubActivities()
                    appState.toast(String(localized: "Nouvelle tentative en cours"))
                }
            }
        }
        .sheet(isPresented: $connexionOuverte, onDismiss: { appState.retryPendingClubActivities() }) {
            SignInView().hzFeuille(detents: [.large])
        }
    }

    private func runAccessibilityLabel(_ run: RunRecord) -> String {
        var parts: [String] = [
            run.date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale.current)),
            run.titreAffiche,
            String(localized: "\(String(format: "%.1f", locale: Locale.current, run.distanceKm)) kilomètres"),
            String(localized: "durée \(PaceModel.formatDuration(Double(run.durationSeconds)))"),
            String(localized: "allure moyenne \(run.avgPace) par kilomètre")
        ]
        if run.avgHeartRate > 0 { parts.append(String(localized: "fréquence cardiaque moyenne \(run.avgHeartRate)")) }
        return parts.joined(separator: ", ")
    }
}
