import ActivityKit
import WidgetKit
import SwiftUI

/// Lock Screen + Dynamic Island UI for an in-progress run (`RunActivityAttributes`, updated live
/// from `LiveRunViewModel`). Same reasoning as `DailyGoalsWidget` for not reusing
/// `Haizo/DesignSystem`: this runs in the widget extension's own process, so it can't read the
/// live `ThemeStore`/accent color anyway — fixed dark + the brand rose (`WG.rose`), a system
/// surface outside her in-app theme choice.
///
/// # L'ÉCRAN VERROUILLÉ : UN CHIFFRE, UNE BARRE, DEUX TUILES
///
/// C'est l'écran de course de l'app, à l'échelle d'une carte : le chrono domine, dans la FONTE
/// D'AFFICHAGE de l'app (Archivo 800, largeur 125 %, comme ses gros chiffres), une barre pleine
/// largeur avance vers la durée prévue, la distance et l'allure sont posées côte à côte dans deux
/// tuiles `surfaceSombre`, et l'accent n'est qu'une touche : le point d'état et le remplissage de
/// la barre. Noir franc, des gris opaques, aucun dégradé, aucune ombre.
///
/// C'est la « carte 2 » de la maquette, que Charlotte a choisie le 22 novembre. Elle a un coût : la
/// pile verticale est haute, et iOS coupe une carte d'écran verrouillé vers 160 points. Les marges
/// et le corps du chrono (`chronoAffichage`) ont été resserrés pour qu'elle en mesure moins de 158 ;
/// `WidgetRenduTests` REFUSE toute carte plus haute, sur chaque état. La première version, en deux
/// colonnes (chrono et barre à gauche, tuiles à droite), mesurait 138 : elle tenait sans effort et
/// a été remplacée par celle-ci.
///
/// La barre vient de `elapsedSeconds`, que l'app republie toutes les ~5 secondes : sur 40 minutes
/// et 300 points, elle avance d'un huitième de point par seconde, ce qui ne se voit pas. Un
/// `ProgressView(timerInterval:)` la ferait avancer seul, mais en gris système et sans jeton de
/// rail ; le gain n'existe pas à l'œil, la perte est la cohérence.
///
/// Trois états : en direct (point d'accent), en pause (point éteint, chrono et barre en gris),
/// terminée (coche d'accent, « Sortie terminée »). La barre se masque quand la séance n'a pas de
/// durée prévue : il n'y a alors rien d'honnête à mesurer.
struct RunActivityWidget: Widget {
    private static let accent = WG.rose
    private static let bg = WG.noirFranc

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunActivityAttributes.self) { context in
            ecranVerrouille(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                // Le chrono et l'état à gauche, les deux mesures à droite — la même répartition
                // que l'écran verrouillé, repliée pour tenir de part et d'autre de la caméra.
                DynamicIslandExpandedRegion(.leading) {
                    ileGauche(state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ileDroite(attributes: context.attributes, state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ileBas(attributes: context.attributes, state: context.state)
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

    // MARK: L'île

    // Ces trois régions et l'écran verrouillé reçoivent leurs données en paramètres, et non un
    // `ActivityViewContext` : le contexte ne se fabrique pas hors d'ActivityKit, et le rendu en
    // image (`HaizoWidgetTests`) ne pouvait donc pas les photographier.

    func ileGauche(state: RunActivityAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            elapsedText(state)
                .font(WG.police(WG.Corps.chronoPetit))
                .tracking(WG.serre(WG.Corps.chronoPetit))
                .monospacedDigit()
                .foregroundColor(chronoColor(state))
                .lineLimit(1)
                .minimumScaleFactor(WG.Forme.reductionDuChrono)
            statut(state)
        }
    }

    func ileDroite(attributes: RunActivityAttributes,
                   state: RunActivityAttributes.ContentState) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            mesure(TimeFormat.distance(km: state.distanceKm), "km", taille: WG.Corps.chiffre)
            mesure(state.paceLabel, attributes.discipline.rythmeUnite, taille: WG.Corps.chiffre)
        }
    }

    func ileBas(attributes: RunActivityAttributes,
                state: RunActivityAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: WG.Forme.ecart - 2) {
            barre(attributes: attributes, state: state)
            Text(attributes.sessionTitle)
                .font(WG.police(WG.Corps.legende, .semi))
                .foregroundColor(WG.secondaireSurSombre)
                .lineLimit(1)
        }
    }

    // MARK: L'écran verrouillé

    func ecranVerrouille(attributes: RunActivityAttributes,
                         state: RunActivityAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: WG.Forme.ecartDeLaCarte) {
            HStack {
                statut(state)
                Spacer(minLength: WG.Forme.ecart)
                Text(attributes.sessionTitle)
                    .font(WG.police(WG.Corps.legende, .semi))
                    .foregroundColor(WG.secondaireSurSombre)
                    .lineLimit(1)
            }

            // Le chrono tient sur sa ligne : « 1:24:18 » rétrécit plutôt que de passer à la ligne.
            elapsedText(state)
                .font(WG.affichage(WG.Corps.chronoAffichage))
                .tracking(WG.serre(WG.Corps.chronoAffichage))
                .monospacedDigit()
                .foregroundColor(chronoColor(state))
                .lineLimit(1)
                .minimumScaleFactor(WG.Forme.reductionDuChrono)
                .frame(maxWidth: .infinity, alignment: .leading)

            barre(attributes: attributes, state: state)

            HStack(spacing: WG.Forme.ecart) {
                tuile(TimeFormat.distance(km: state.distanceKm), "km")
                // « Allure » était écrit en dur, sous un chiffre qui est des kilomètres-heure
                // dès qu'on roule. `Discipline` décide — la même décision que l'écran de
                // course prend, dans `Shared`, que cette extension compile aussi.
                tuile(state.paceLabel, attributes.discipline.rythmeUnite)
            }
        }
        .padding(.horizontal, WG.Forme.margeHorizontale)
        .padding(.vertical, WG.Forme.margeVerticaleSerree)
        .activityBackgroundTint(Self.bg)
        .activitySystemActionForegroundColor(WG.blanc)
    }

    /// Une mesure dans sa tuile : le chiffre, et l'unité à côté, en gris. Une surface posée sur le
    /// noir, comme les tuiles de l'app.
    private func tuile(_ valeur: String, _ unite: String) -> some View {
        mesure(valeur, unite, taille: WG.Corps.valeurDeTuile)
            .padding(.horizontal, WG.Forme.tuileHorizontale)
            .padding(.vertical, WG.Forme.tuileVerticale)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WG.surfaceSombre, in: RoundedRectangle(cornerRadius: WG.Forme.rayonDeTuile,
                                                                style: .continuous))
    }

    private func mesure(_ valeur: String, _ unite: String, taille: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(valeur)
                .font(WG.police(taille))
                .tracking(WG.serre(taille))
                .monospacedDigit()
                .foregroundColor(WG.blanc)
                .lineLimit(1)
                .minimumScaleFactor(WG.Forme.reductionDuChrono)
            Text(verbatim: unite)
                .font(WG.police(WG.Corps.legende, .semi))
                .foregroundColor(WG.secondaireSurSombre)
                .lineLimit(1)
        }
    }

    /// L'état : un point d'accent allumé, éteint en pause, ou la coche de la fin, et un mot en
    /// casse de phrase.
    private func statut(_ state: RunActivityAttributes.ContentState) -> some View {
        HStack(spacing: 6) {
            if state.isEnded {
                Image(systemName: statusIcon(state))
                    .font(.system(size: WG.Corps.legende, weight: .semibold))
                    .foregroundColor(Self.accent)
            } else {
                Circle()
                    .fill(state.isPaused ? WG.pointEteintSombre : Self.accent)
                    .frame(width: WG.Forme.pointDEtat, height: WG.Forme.pointDEtat)
            }
            Text(libelle(state))
                .font(WG.police(WG.Corps.legende, .semi))
                .foregroundColor(WG.secondaireSurSombre)
        }
    }

    private func libelle(_ state: RunActivityAttributes.ContentState) -> String {
        if state.isEnded { return String(localized: "Sortie terminée") }
        return state.isPaused ? String(localized: "En pause") : String(localized: "En direct")
    }

    /// Le chrono s'éteint en pause : il est figé, et un chiffre blanc qui ne bouge pas se lirait
    /// comme un chiffre vivant.
    private func chronoColor(_ state: RunActivityAttributes.ContentState) -> Color {
        state.isPaused ? WG.secondaireSurSombre : WG.blanc
    }

    /// La barre vers la durée prévue, et cette durée à droite. Absente quand la séance n'en a pas.
    @ViewBuilder
    private func barre(attributes: RunActivityAttributes,
                       state: RunActivityAttributes.ContentState) -> some View {
        let prevues = attributes.plannedDurationMinutes
        if prevues > 0 {
            let fraction = max(0, min(1, state.elapsedSeconds / Double(prevues * 60)))
            HStack(spacing: WG.Forme.ecart) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(WG.filetSombre)
                        Capsule()
                            .fill(state.isPaused ? WG.secondaireSurSombre : Self.accent)
                            .frame(width: geo.size.width * fraction)
                    }
                }
                .frame(height: WG.Forme.hauteurDeBarre)
                Text("\(prevues) min")
                    .font(WG.police(WG.Corps.legende, .semi))
                    .foregroundColor(WG.secondaireSurSombre)
                    .lineLimit(1)
            }
        } else {
            EmptyView()
        }
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
