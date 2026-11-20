import ActivityKit
import WidgetKit
import SwiftUI

/// Lock Screen + Dynamic Island UI for an in-progress run (`RunActivityAttributes`, updated live
/// from `LiveRunViewModel`). Same reasoning as `DailyGoalsWidget` for not reusing
/// `Haizo/DesignSystem`: this runs in the widget extension's own process, so it can't read the
/// live `ThemeStore`/accent color anyway — fixed dark + the brand rose (`WG.rose`), a system
/// surface outside her in-app theme choice.
///
/// Dans la DA de l'app (`WG`, voir `WidgetStyle.swift`) : noir franc, Archivo, des gris opaques
/// pour les textes secondaires, des libellés en casse de phrase, l'accent en touches (le titre,
/// l'état, la barre) — comme le panneau de la séance en direct. La barre avance vers la *durée
/// prévue* de la séance : le seul vrai « où j'en suis » qu'une `WorkoutSession` suive (il n'y a
/// pas d'objectif de distance à montrer honnêtement ; les séances sont à durée).
struct RunActivityWidget: Widget {
    private static let accent = WG.rose
    private static let bg = WG.noirFranc

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(TimeFormat.distance(km: context.state.distanceKm))
                            .font(WG.police(WG.Corps.grandChiffre))
                            .tracking(WG.serre(WG.Corps.grandChiffre))
                            .foregroundColor(WG.blanc)
                        Text(verbatim: "km").font(WG.police(WG.Corps.etiquette, .semi)).foregroundColor(WG.secondaireSurSombre)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.paceLabel)
                            .font(WG.police(WG.Corps.chiffreDeCourse))
                            .tracking(WG.serre(WG.Corps.chiffreDeCourse))
                            .foregroundColor(WG.blanc)
                        Text(verbatim: context.attributes.discipline.rythmeUnite).font(WG.police(WG.Corps.etiquette, .semi)).foregroundColor(WG.secondaireSurSombre)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 6) {
                        Image(systemName: statusIcon(context.state))
                        Text(context.attributes.sessionTitle).font(WG.police(WG.Corps.texte, .semi)).lineLimit(1).minimumScaleFactor(0.7)
                        Spacer()
                        elapsedText(context.state)
                            .font(WG.police(WG.Corps.valeur))
                            .monospacedDigit()
                    }
                    .foregroundColor(WG.blanc)
                }
            } compactLeading: {
                Image(systemName: "figure.run").foregroundColor(Self.accent)
            } compactTrailing: {
                elapsedText(context.state)
                    .font(WG.police(WG.Corps.valeur))
                    .monospacedDigit()
                    .foregroundColor(WG.blanc)
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "figure.run").foregroundColor(Self.accent)
            }
            .keylineTint(Self.accent)
        }
    }

    private func lockScreenView(context: ActivityViewContext<RunActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Run")
                    .font(WG.police(WG.Corps.chiffre))
                    .tracking(WG.serre(WG.Corps.chiffre))
                    .foregroundColor(Self.accent)
                Spacer()
                HStack(spacing: 6) {
                    Text(context.attributes.sessionTitle)
                        .font(WG.police(WG.Corps.texte, .semi))
                        .foregroundColor(WG.secondaireSurSombre)
                        .lineLimit(1)
                    statusBadge(context.state)
                }
            }

            HStack {
                metric(value: TimeFormat.distance(km: context.state.distanceKm), label: "km")
                Spacer(minLength: 8)
                // « Allure » était écrit en dur, sous un chiffre qui est des kilomètres-heure dès
                // qu'on roule. `Discipline` décide, et c'est la même décision que l'écran de
                // course prend — elle vit dans `Shared`, que cette extension compile aussi.
                metric(value: context.state.paceLabel, label: context.attributes.discipline.rythmeLabel)
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    elapsedText(context.state)
                        .font(WG.police(WG.Corps.chronoLive))
                        .tracking(WG.serre(WG.Corps.chronoLive))
                        .foregroundColor(WG.blanc)
                    Text("Temps").font(WG.police(WG.Corps.etiquette, .semi)).foregroundColor(WG.secondaireSurSombre)
                }
            }

            if context.attributes.plannedDurationMinutes > 0 {
                let plannedSeconds = Double(context.attributes.plannedDurationMinutes * 60)
                let fraction = max(0, min(1, context.state.elapsedSeconds / plannedSeconds))
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Séance").font(WG.police(WG.Corps.etiquette, .semi)).foregroundColor(WG.secondaireSurSombre)
                        Spacer()
                        Text("\(context.attributes.plannedDurationMinutes) min prévues")
                            .font(WG.police(WG.Corps.etiquette, .semi)).foregroundColor(WG.secondaireSurSombre)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(WG.filetSombre)
                            Capsule().fill(Self.accent).frame(width: geo.size.width * fraction)
                        }
                    }
                    .frame(height: 5)
                }
            }
        }
        .padding(18)
        .activityBackgroundTint(Self.bg)
        .activitySystemActionForegroundColor(WG.blanc)
    }

    private func metric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(WG.police(WG.Corps.chronoLive))
                .tracking(WG.serre(WG.Corps.chronoLive))
                .foregroundColor(WG.blanc)
            // Sans `LocalizedStringKey`, ces libellés restent français pour tout le monde.
            Text(LocalizedStringKey(label)).font(WG.police(WG.Corps.etiquette, .semi)).foregroundColor(WG.secondaireSurSombre)
        }
    }

    private func statusBadge(_ state: RunActivityAttributes.ContentState) -> some View {
        Image(systemName: statusIcon(state))
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(state.isPaused ? WG.secondaireSurSombre : Self.accent)
    }

    private func statusIcon(_ state: RunActivityAttributes.ContentState) -> String {
        if state.isEnded { return "checkmark.circle.fill" }
        return state.isPaused ? "pause.circle.fill" : "figure.run"
    }

    /// Self-ticking chrono while running (`Text(timerInterval:)` updates every second with zero
    /// pushes from the app — the state only carries the reference date); frozen static label when
    /// paused/ended, which is exactly when the clock shouldn't move.
    @ViewBuilder
    private func elapsedText(_ state: RunActivityAttributes.ContentState) -> some View {
        if let reference = state.timerReference, !state.isPaused, !state.isEnded {
            Text(timerInterval: reference...Date.distantFuture, countsDown: false)
        } else {
            Text(TimeFormat.horloge(state.elapsedSeconds))
        }
    }

}
