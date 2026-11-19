import SwiftUI

/// Modifier les jours de course et l'objectif écrit à la main. Même geste, même enregistrement
/// qu'avant : seule la présentation change.
struct ProgramSettingsSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var days: Set<Int> = []
    @State private var goal: String = ""

    /// Le minimum exigé par l'objectif en cours. Voir `GoalType.joursMinimumParSemaine`.
    private var minimumJours: Int { appState.profile.goalId.joursMinimumParSemaine }

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Modifier mon programme")) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    joursDeCourse
                    HZChampDeTexte(titre: String(localized: "Objectif"),
                                   invite: String(localized: "Objectif"), texte: $goal)
                    Text("Le coach recalcule tes prochaines séances dès l'enregistrement.")
                        .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, HZEspace.marge)
                // Un titre sur deux lignes ne doit pas coller à ce qu'il coiffe.
                .padding(.top, HZEspace.entreCommandes)
            }
            .scrollIndicators(.hidden)
        }
        // Le geste pour lequel cette feuille est ouverte, épinglé en bas.
        .safeAreaInset(edge: .bottom) { enregistrer }
        .onAppear {
            days = Set(appState.profile.runningDays)
            goal = appState.profile.goalDisplay
        }
    }

    // MARK: - Les sept jours

    /// Sept cases de la largeur qui reste, au plus serré que permet la cible tactile de 44 points
    /// sur le plus petit téléphone pris en charge.
    private var joursDeCourse: some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            Text("Jours de course")
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)
            HStack(spacing: HZCompte.ecartDesJours) {
                ForEach(DayStatus.letters.indices, id: \.self) { i in
                    jour(i)
                }
            }
        }
    }

    private func jour(_ i: Int) -> some View {
        let on = days.contains(i)
        return Button(action: { if on { days.remove(i) } else { days.insert(i) } }) {
            Text(DayStatus.letters[i])
                .hzTexte(.c15, .gras)
                .foregroundStyle(on ? HZCouleur.blanc : HZCouleur.encre)
                .frame(maxWidth: .infinity)
                .frame(height: HZBoutonRond.zoneTactile)
                .background(on ? HZCouleur.encre : HZCouleur.surfaceClaire,
                            in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Sans nom, VoiceOver lirait une lettre seule (« L », « M », « M »…), sans le jour ni l'état.
        .accessibilityLabel(DayStatus.fullNames[i])
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: - Enregistrer

    private var enregistrer: some View {
        // Le minimum vient de l'objectif EN COURS : réduire un plan de triathlon à deux jours par
        // cet écran-là aurait contourné la règle posée à l'inscription, et produit une semaine à
        // laquelle il manque une discipline.
        let valide = days.count >= minimumJours
        return HZBoutonPilule(libelle: String(localized: "Enregistrer"), etendu: true) {
            appState.profile.runningDays = Array(days)
            appState.profile.goalDisplay = goal
            // Rend vraie la phrase ci-dessus : la semaine est recalculée autour des nouveaux jours
            // tout de suite, au lieu d'attendre la prochaine frontière de semaine.
            AdaptivePlanEngine.applyProgramSettingsChange(appState.profile)
            appState.publishWidgetSnapshot()
            appState.toast(String(localized: "Programme mis à jour"))
            dismiss()
        }
        .opacity(valide ? HZHub.opaciteNormale : HZHub.opaciteEteinte)
        .disabled(!valide)
        .padding(.horizontal, HZEspace.marge)
        .padding(.top, HZEspace.entreCommandes)
        .padding(.bottom, HZHub.basDeFeuille)
        .background(HZCouleur.blanc)
    }
}
