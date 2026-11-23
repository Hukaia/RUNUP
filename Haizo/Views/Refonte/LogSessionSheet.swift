import SwiftUI

/// Enregistrer une séance faite hors de l'app — renfo, tapis, ou simple oubli d'appuyer sur
/// « démarrer ».
///
/// Elle demande la distance et la durée au lieu de les déduire. L'ancienne version validait la
/// séance d'un seul geste et calculait une distance depuis la durée prévue et l'allure cible : ça
/// donnait un « 5,2 km à 5:30/km » d'apparence précise pour une sortie qui avait pu se courir à
/// n'importe quelle allure, et ce chiffre inventé remontait ensuite dans les stats, dans le fil du
/// club et dans l'adaptation du programme. Corrigé une première fois en mettant zéro — honnête,
/// mais une séance qui ne compte aucun kilomètre n'est pas plus juste. Deux champs règlent les
/// deux.
///
/// La durée arrive pré-remplie avec celle du plan : c'est presque toujours la bonne, et la corriger
/// coûte deux frappes. La distance reste vide, parce qu'aucune valeur par défaut n'y serait vraie.
struct LogSessionSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var distanceText = ""
    @State private var durationText = ""
    @FocusState private var focus: Field?

    private enum Field { case distance, duration }

    private var session: WorkoutSession { appState.profile.todaySession }

    private var durationMinutes: Int? {
        let value = Int(durationText.trimmingCharacters(in: .whitespaces))
        guard let value, value > 0, value <= HZJournee.dureeMaximaleDUneSeance else { return nil }
        return value
    }

    /// Virgule ET point acceptés : le clavier décimal français propose une virgule, et refuser
    /// « 5,2 » sur un clavier qui vient de la proposer serait absurde.
    private var distanceKm: Double {
        let normalised = distanceText.replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Double(normalised), value > 0, value <= HZJournee.distanceMaximaleDUneSeance else { return 0 }
        return value
    }

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Séance déjà faite")) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    HZPhrase(texte: String(localized: "Enregistre-la comme si tu venais de la faire."),
                             titre: session.displayTitle)

                    // Les deux champs sont dans une même pile : `focus` désigne celui qui reçoit
                    // le clavier à l'ouverture.
                    VStack(alignment: .leading, spacing: HZEspace.groupe) {
                        HZChampDeTexte(titre: "\(String(localized: "Durée")) (\(HZJournee.uniteDeDuree))",
                                       invite: "\(session.durationMinutes)",
                                       texte: $durationText, clavier: .decimalPad)
                            .focused($focus, equals: .duration)
                        HZChampDeTexte(titre: "\(String(localized: "Distance")) (\(HZJournee.uniteDeDistance))",
                                       // « Facultatif », et non un tiret : collé au curseur, le tiret
                                       // dessinait un signe sans nom au milieu du champ.
                                       invite: String(localized: "Facultatif"),
                                       texte: $distanceText, clavier: .decimalPad)
                            .focused($focus, equals: .distance)
                    }

                    // Dit avant de valider : une séance de renfo n'a pas de distance, et laisser
                    // le champ vide doit être un choix visiblement permis plutôt qu'un oubli.
                    Text("La distance est facultative : laisse-la vide pour une séance de renforcement ou un tapis sans compteur.")
                        .hzParagraphe(.c13, .medium, interligne: HZBandeauDuCoach.interligne)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, HZEspace.marge)
            }
            // Le geste pour lequel cette feuille est ouverte, épinglé en bas.
            .safeAreaInset(edge: .bottom, spacing: 0) { pied }
        }
        .onAppear {
            durationText = "\(session.durationMinutes)"
            focus = .distance
        }
    }

    private var pied: some View {
        HZBoutonPilule(libelle: String(localized: "Enregistrer la séance"), etendu: true, action: validate)
            .opacity(durationMinutes == nil ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
            .disabled(durationMinutes == nil)
            .padding(.horizontal, HZEspace.marge)
            .padding(.top, HZEspace.entreCommandes)
            .padding(.bottom, HZHub.basDeFeuille)
            .frame(maxWidth: .infinity)
            .background(HZCouleur.blanc)
    }

    private func validate() {
        guard let minutes = durationMinutes else { return }
        appState.markTodaySessionDone(distanceKm: distanceKm, durationMinutes: minutes)
        dismiss()
    }
}
