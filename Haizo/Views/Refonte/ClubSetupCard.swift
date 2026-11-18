import SwiftUI

/// L'écran de quelqu'un qui n'a pas encore de club : en créer un, ou en chercher un.
///
/// Sortie de `ClubView` au quatrième morceau de la découpe. Tout passe par le magasin — créer,
/// chercher, charger les clubs proposés — donc elle ne demande que lui et les deux champs de
/// saisie. Voir « Chantier 38 » dans `PROGRESS.md`.
struct ClubSetupCard: View {
    let magasin: ClubStore
    @Binding var newClubName: String
    @Binding var clubQuery: String

    var body: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreSections) {
            VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                HZPhrase(texte: String(localized: "Tu en seras l'administratrice"),
                         titre: String(localized: "Créer un club"))
                HZChampDeRecherche(invite: String(localized: "Nom du club"), texte: $newClubName,
                                   avecLoupe: false)
                HZBoutonPilule(libelle: String(localized: "Créer"), etendu: true) {
                    Task { if await magasin.createClub(nom: newClubName) { newClubName = "" } }
                }
                .opacity(peutCreer ? HZHub.opaciteNormale : HZHub.opaciteEteinte)
                .disabled(!peutCreer)
            }

            VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                HZTitreDeSection(titre: String(localized: "Rejoindre un club"))
                HZChampDeRecherche(invite: String(localized: "Chercher par son nom"), texte: $clubQuery,
                                   enRecherche: magasin.clubSearchEnCours)
                let rienDeTape = clubQuery.trimmingCharacters(in: .whitespaces).isEmpty
                if !magasin.clubSearchEnCours, !rienDeTape, magasin.clubResultats.isEmpty {
                    HZPhrase(texte: String(localized: "Aucun club ouvert ne porte ce nom."))
                }
                if rienDeTape, !magasin.clubSuggestions.isEmpty {
                    Text("Ou rejoins-en un ouvert")
                        .hzTexte(.c13, .semi)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                }
                LazyVStack(spacing: 0) {
                    let clubs = rienDeTape ? magasin.clubSuggestions : magasin.clubResultats
                    ForEach(Array(clubs.enumerated()), id: \.element.id) { rang, club in
                        ligneDUnClubARejoindre(club, dernier: rang == clubs.count - 1)
                    }
                }
            }
            .task { await magasin.chargerLesClubsSuggeres() }
        }
    }

    private var peutCreer: Bool {
        !newClubName.trimmingCharacters(in: .whitespaces).isEmpty && !magasin.isLoading
    }

    private func ligneDUnClubARejoindre(_ trouve: ClubSearchResult, dernier: Bool) -> some View {
        Button(action: { Task { if await magasin.joinClub(trouve) { clubQuery = "" } } }) {
            HZLigneDeListe(titre: trouve.name, sousTitre: ligneDuClubTrouve(trouve), filet: !dernier) {
                HZVignette {
                    HZIcone(dessin: .groupe, cote: HZHub.coteDeLIcone, couleur: HZCouleur.blanc)
                }
            } queue: {
                HZPilule(texte: String(localized: "Rejoindre"), style: .etiquetteGrasse,
                         fond: HZCouleur.encre)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(magasin.isLoading)
    }

    private func ligneDuClubTrouve(_ trouve: ClubSearchResult) -> String {
        let membres = Pluriel.choisir(trouve.memberCount,
                                      String(localized: "\(trouve.memberCount) membre"),
                                      String(localized: "\(trouve.memberCount) membres"))
        var morceaux: [String] = []
        if trouve.seancePrevue == true {
            morceaux.append(String(localized: "Une séance prévue"))
        } else if trouve.actifRecemment == true {
            morceaux.append(String(localized: "Actif ces jours-ci"))
        }
        if let ville = trouve.city, !ville.isEmpty { morceaux.append(ville) }
        morceaux.append(membres)
        return morceaux.joined(separator: " · ")
    }
}
