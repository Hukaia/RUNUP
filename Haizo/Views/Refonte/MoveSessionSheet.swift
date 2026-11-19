import SwiftUI

/// Déplacer une séance de la semaine en cours vers un autre jour.
///
/// Deux étapes plutôt qu'une poignée de glissement : on choisit la séance, puis le jour. Le
/// glisser-déposer sur sept lignes hautes de cinquante points serait plus élégant à décrire et
/// nettement plus difficile à réussir du pouce, dans un écran qui défile déjà verticalement.
///
/// L'écran d'arrivée montre ce qui occupe chaque jour, parce que « mercredi » ne veut rien dire
/// tant qu'on ne sait pas ce qu'il y a mercredi. Et il signale les jours qui colleraient deux
/// séances exigeantes dos à dos — sans les interdire : quelqu'un qui ne peut pas courir jeudi ne
/// peut pas courir jeudi, et lui refuser le déplacement le renverrait à « Refaire un programme »,
/// c'est-à-dire au problème qu'on est en train de résoudre.
struct MoveSessionSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var picked: Int?

    private var profile: UserProfile { appState.profile }

    // Types explicites : un ternaire de deux littéraux se résout en `String`, et seules les
    // `String(localized:)` passent par le catalogue de traduction.
    private var title: String {
        picked == nil ? String(localized: "Déplacer une séance") : String(localized: "Vers quel jour ?")
    }

    private static let dayNames: [String] = [
        String(localized: "Lundi"), String(localized: "Mardi"), String(localized: "Mercredi"),
        String(localized: "Jeudi"), String(localized: "Vendredi"), String(localized: "Samedi"),
        String(localized: "Dimanche"),
    ]

    var body: some View {
        HZFeuilleModale(titre: title) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
                    if let picked {
                        destinationStep(for: picked)
                    } else {
                        sourceStep
                    }
                }
                .padding(.horizontal, HZEspace.marge)
            }
        }
    }

    // MARK: Étape 1 — quelle séance

    private var sourceStep: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(Array(movableDays.enumerated()), id: \.element.id) { rang, day in
                Button {
                    Haptics.selection()
                    picked = day.weekday
                } label: {
                    dayCard(weekday: day.weekday, session: day.session, warns: false, chevron: true,
                            derniere: rang == movableDays.count - 1)
                }
                .buttonStyle(.plain)
            }

            if movableDays.isEmpty {
                HZPhrase(texte: String(localized: "Aucune séance à déplacer cette semaine."))
            }

            // Une séance faite ne bouge pas : elle a eu lieu ce jour-là. Le dire ici évite de
            // chercher pourquoi la séance de mardi n'apparaît pas dans la liste.
            if profile.weekSessions.contains(where: { $0.completed }) {
                HZPhrase(texte: String(localized: "Les séances déjà faites ne se déplacent pas."))
                    .padding(.top, HZEspace.entreCommandes)
            }
        }
    }

    private var movableDays: [PlannedDay] {
        profile.weekSessions.filter { ($0.session?.durationMinutes ?? 0) > 0 && !$0.completed }
    }

    // MARK: Étape 2 — vers quel jour

    private func destinationStep(for from: Int) -> some View {
        let destinations = SessionMove.destinations(in: profile.weekSessions, from: from)
        return VStack(alignment: .leading, spacing: 0) {
            HZBoutonPilule(libelle: String(localized: "Retour"), dessin: .retour, hauteur: .petite,
                           fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre) { picked = nil }
                .padding(.bottom, HZEspace.entrePilules)

            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(destinations.enumerated()), id: \.element.id) { rang, destination in
                    Button {
                        if appState.moveSession(from: from, to: destination.weekday) { dismiss() }
                    } label: {
                        dayCard(weekday: destination.weekday, session: destination.occupant,
                                warns: destination.warns, chevron: false,
                                derniere: rang == destinations.count - 1)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Dite ici, au moment du choix, et pas seulement sur l'écran d'où l'on vient : c'est
            // l'instant où l'on croit régler la chose pour de bon.
            HZPhrase(texte: String(localized: "Ne vaut que pour cette semaine. Les suivantes suivent tes jours de course."))
                .padding(.top, HZEspace.entreCommandes)

            if destinations.contains(where: \.warns) {
                HZPhrase(texte: String(localized: "Le triangle marque les jours qui placeraient deux séances exigeantes l'une après l'autre. C'est permis, mais c'est ainsi qu'on se blesse."))
                    .padding(.top, HZEspace.entreCommandes)
            }
        }
    }

    // MARK: La ligne d'un jour

    private func dayCard(weekday: Int, session: WorkoutSession?, warns: Bool, chevron: Bool,
                         derniere: Bool) -> some View {
        let family = session?.family ?? .rest
        let barre = AccueilModele.intensite(de: family)?.couleur ?? HZCouleur.accent
        return HZLigneDeListe(titre: Self.dayNames[weekday],
                              sousTitre: session?.displayTitle ?? String(localized: "Libre"),
                              filet: !derniere) {
            RoundedRectangle(cornerRadius: HZJournee.rayonDeLaBarre, style: .circular)
                .fill(session == nil ? HZCouleur.filetGroupe : barre)
                .frame(width: HZJournee.largeurDeLaBarre, height: HZJournee.hauteurDeLaBarreDeJour)
        } queue: {
            if warns {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(HZPolice.texte(.c16, .semi))
                    .foregroundStyle(HZCouleur.encre)
                    .accessibilityLabel(String(localized: "Deux séances exigeantes à la suite"))
            }
            if chevron {
                HZChevron()
            }
        }
        .frame(minHeight: HZBoutonRond.zoneTactile)
        .contentShape(Rectangle())
    }
}
