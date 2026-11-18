import SwiftUI
import SwiftData
import UIKit

/// Real Strava connect/disconnect + "import my history" — the only data source here backed by a
/// real OAuth handshake (see `StravaService`) rather than a native framework (HealthKit) or a
/// stub ("Bientôt"). A separate view (not inlined in `dataSourcesCard`) since it owns real
/// async state — connection status, an in-flight import, its own error messages.
struct StravaConnectionRow: View {
    var auth: AuthService

    @Environment(\.modelContext) private var modelContext
    // Le profil, pour recalculer la série après un import : `recomputeStreak` l'écrit. Cette
    // rangée vit dans les réglages, sous `SettingsView`, donc l'état de l'app est déjà là.
    @Environment(AppState.self) private var appState
    @State private var isConnected = false
    @State private var isLoading = false
    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var importedCount: Int?

    private var stravaService: StravaService { StravaService(auth: auth) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // UNE PASTILLE, PAS UN SYMBOLE — ET UN ORANGE ÉCRIT EN DUR, EXPRÈS.
                //
                // Le 🟠 n'était pas de la décoration : il identifiait Strava par sa couleur. Un
                // symbole SF perdrait ce repère, et aucune teinte de notre palette ne convient —
                // ce 0xFC4C02 est l'orange de Strava, pas le nôtre. Le poser dans `RUColor`
                // laisserait croire qu'il nous appartient et qu'il peut suivre un thème.
                Circle()
                    .fill(Color(hex: 0xFC4C02))
                    .frame(width: 14, height: 14)
                    .accessibilityHidden(true)
                Text(verbatim: "Strava").font(RUFont.sans(.emphasis, weight: .medium)).foregroundColor(RUColor.textPrimary)
                Spacer()
                if !auth.isSignedIn {
                    Text("Nécessite un compte").font(RUFont.sans(.small)).foregroundColor(RUColor.text3)
                } else if isLoading {
                    ProgressView().tint(RUColor.rose)
                } else if isConnected {
                    Button("Déconnecter") { Task { await disconnect() } }
                        .font(RUFont.sans(.body, weight: .semibold)).foregroundColor(RUColor.text3)
                } else {
                    Button("Connecter") { Task { await connect() } }
                        .font(RUFont.sans(.body, weight: .semibold)).foregroundColor(RUColor.rose2)
                }
            }

            if isConnected {
                Button(action: { Task { await importHistory() } }) {
                    HStack(spacing: 6) {
                        if isImporting { ProgressView().tint(RUColor.text2) }
                        Text(isImporting ? "Import en cours…" : "Importer mon historique Strava")
                    }
                    .font(RUFont.sans(.body, weight: .semibold))
                    .foregroundColor(RUColor.text2)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .disabled(isImporting)
            }

            if let importedCount {
                // Le « s » recollé n'était pas seulement faux hors du français : la clé
                // cherchée au catalogue était « %lld course%@ importée%@. », et les traductions
                // devaient donc porter le même bricolage. Deux clés entières à la place.
                Text(importedCount == 0
                     ? String(localized: "Rien de nouveau à importer.")
                     : Pluriel.choisir(importedCount,
                                       String(localized: "\(importedCount) course importée."),
                                       String(localized: "\(importedCount) courses importées.")))
                    .font(RUFont.sans(.small)).foregroundColor(RUColor.rose)
            }
            if let errorMessage {
                Text(errorMessage).font(RUFont.sans(.small)).foregroundColor(RUColor.rose)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 14)
        .task {
            if auth.isSignedIn { await refreshStatus() }
        }
    }

    private func refreshStatus() async {
        isConnected = (try? await stravaService.status()) ?? false
    }

    private func connect() async {
        isLoading = true
        errorMessage = nil
        do {
            try await stravaService.connect()
            isConnected = true
        } catch StravaServiceError.notConfigured {
            errorMessage = String(localized: "Strava n'est pas encore configuré côté serveur.")
        } catch StravaServiceError.cancelled {
            // Silently ignored — she just closed the Strava sheet without finishing.
        } catch {
            errorMessage = String(localized: "Connexion à Strava impossible, réessaie.")
        }
        isLoading = false
    }

    private func disconnect() async {
        isLoading = true
        errorMessage = nil
        do {
            try await stravaService.disconnect()
            isConnected = false
            importedCount = nil
        } catch {
            errorMessage = String(localized: "Impossible de déconnecter Strava, réessaie.")
        }
        isLoading = false
    }

    /// Inserts each Strava run as a local `RunRecord` — deduped against `stravaActivityId`s
    /// already present, so importing again (to pick up newer Strava activity) never duplicates
    /// History. No XP/club post for these: they're historical, not a session just completed.
    private func importHistory() async {
        isImporting = true
        errorMessage = nil
        do {
            let runs = try await stravaService.importActivities()
            let existingIds = existingStravaIds()
            // LE SECOND GARDE-FOU, QUI MANQUAIT. Voir `HealthRunImport.estDejaLa`.
            //
            // `stravaActivityId` ne dédoublonne que ce qui vient de Strava. Une course
            // enregistrée par Haizo, ou importée d'Apple Santé, n'en porte aucun — et Haizo
            // écrit ses courses dans Santé pendant que Strava reçoit les mêmes sorties par la
            // montre. « Importer mon historique » réinsérait donc l'historique déjà présent.
            //
            // L'import Santé a ces deux garde-fous depuis toujours et les documente ; celui-ci
            // n'en avait qu'un.
            var deja = coursesDejaConnues(depuis: runs.map(\.date).min())
            var newCount = 0
            for run in runs where !existingIds.contains(run.stravaActivityId) {
                // La discipline n'est pas transmise par l'import Strava : on compare donc sur
                // `.run`, qui est ce que `RunRecord` écrira juste en dessous. Comparer sur une
                // discipline qu'on n'a pas serait pire que ne pas comparer.
                guard !HealthRunImport.estDejaLa(date: run.date, discipline: .run, deja: deja) else { continue }
                let record = RunRecord(
                    date: run.date,
                    title: run.title,
                    distanceKm: run.distanceKm,
                    durationSeconds: run.durationSeconds,
                    avgPace: PaceModel.paceText(run.distanceKm > 0 ? Double(run.durationSeconds) / run.distanceKm : 0),
                    avgHeartRate: run.avgHeartRate,
                    kcal: Int(run.distanceKm * 65),
                    elevationGainM: run.elevationGainM,
                    stravaActivityId: run.stravaActivityId
                )
                modelContext.insert(record)
                // Ajoutée à la liste tout de suite : deux activités Strava à trois minutes
                // d'écart dans le même lot sont la même sortie, et le `@Query` ne verra pas
                // l'insertion avant la fin de la boucle.
                deja.append(HealthRunImport.Deja(date: run.date, discipline: .run))
                newCount += 1
            }
            // LA SÉRIE SE RECALCULE APRÈS TOUT CHANGEMENT D'HISTORIQUE — c'est ce que dit le
            // commentaire de `recomputeStreak`, et c'est ce que font déjà la suppression d'une
            // course et la saisie manuelle. L'import Strava, lui, insérait N relevés sans jamais
            // l'appeler : elle importait son historique, la sortie du jour comprise, et son
            // compteur restait à sa valeur d'avant — puis bondissait des jours plus tard, à la
            // première suppression, sans qu'aucun geste ne l'explique.
            //
            // Les relevés existants sont relus ici plutôt que pris d'un `@Query` : celui-ci n'a
            // pas encore vu les insertions de la boucle. Même motif que les deux autres
            // appelants.
            if newCount > 0 {
                let tous = (try? modelContext.fetch(FetchDescriptor<RunRecord>())) ?? []
                AdaptivePlanEngine.recomputeStreak(profile: appState.profile, currentRuns: tous)
            }
            importedCount = newCount
        } catch {
            errorMessage = String(localized: "Import Strava impossible, réessaie.")
        }
        isImporting = false
    }

    /// Les sorties déjà en base sur la fenêtre que l'import couvre — date et discipline, rien
    /// d'autre.
    ///
    /// Bornée par la plus ancienne activité du lot : sans borne, le prédicat ramènerait tout
    /// l'historique, tracés GPS compris, pour n'en garder que deux champs par ligne. C'est le
    /// défaut que `existingStravaIds` a déjà corrigé juste en dessous, et il n'y a aucune raison
    /// de le réintroduire ici.
    private func coursesDejaConnues(depuis borne: Date?) -> [HealthRunImport.Deja] {
        guard let borne else { return [] }
        let descripteur = FetchDescriptor<RunRecord>(predicate: #Predicate { $0.date >= borne })
        let existantes = (try? modelContext.fetch(descripteur)) ?? []
        return existantes.map { HealthRunImport.Deja(date: $0.date, discipline: $0.discipline) }
    }

    /// Les identifiants Strava déjà connus, sans charger tout l'historique.
    ///
    /// Le descripteur était nu : SwiftData matérialisait CHAQUE relevé, tracé GPS compris —
    /// stocké en ligne, donc des dizaines de mégaoctets après quelques centaines de courses —
    /// pour n'en garder qu'un entier par ligne. Le prédicat ne ramène plus que les courses
    /// venues de Strava, les seules qui portent cet identifiant.
    private func existingStravaIds() -> Set<Int> {
        let descriptor = FetchDescriptor<RunRecord>(
            predicate: #Predicate { $0.stravaActivityId != nil })
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        return Set(existing.compactMap { $0.stravaActivityId })
    }
}
