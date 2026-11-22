import SwiftUI

/// L'écran de quelqu'un qui n'a pas encore de club : en créer un, ou en chercher un.
///
/// Sortie de `ClubView` au quatrième morceau de la découpe. Tout passe par le magasin — créer,
/// chercher, charger les clubs proposés — donc elle ne demande que lui et les deux champs de
/// saisie. Voir « Chantier 38 » dans `PROGRESS.md`.
///
/// ON Y CHOISIT COMMENT ON ENTRERA DANS SON CLUB avant de le créer (ouvert, sur demande, sur code),
/// et on rejoint celui d'un autre par sa FICHE : toucher une ligne l'ouvre, et c'est la fiche qui
/// porte le bon bouton selon le mode du club. Un club sur code ne figure pas dans la liste : on y
/// entre avec son code.
struct ClubSetupCard: View {
    let magasin: ClubStore
    @Binding var newClubName: String
    @Binding var clubQuery: String

    @State private var modeDuNouveauClub: ClubJoinMode = .open
    @State private var ficheOuverte: ClubFicheOuverte?
    @State private var codeOuvert = false

    var body: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreSections) {
            VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                HZPhrase(texte: String(localized: "Tu en seras l'administratrice"),
                         titre: String(localized: "Créer un club"))
                HZChampDeRecherche(invite: String(localized: "Nom du club"), texte: $newClubName,
                                   avecLoupe: false)
                choixDuMode
                HZBoutonPilule(libelle: String(localized: "Créer"), etendu: true) {
                    Task {
                        if await magasin.createClub(nom: newClubName, mode: modeDuNouveauClub) { newClubName = "" }
                    }
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
                    HZPhrase(texte: String(localized: "Aucun club ne porte ce nom. Un club sur code se rejoint avec son code."))
                }
                if rienDeTape, !magasin.clubSuggestions.isEmpty {
                    Text("Ou rejoins-en un")
                        .hzTexte(.c13, .semi)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                }
                LazyVStack(spacing: 0) {
                    let clubs = rienDeTape ? magasin.clubSuggestions : magasin.clubResultats
                    ForEach(Array(clubs.enumerated()), id: \.element.id) { rang, club in
                        ligneDUnClubARejoindre(club, dernier: rang == clubs.count - 1)
                    }
                }
                ClubLigneDuCode { codeOuvert = true }
            }
            .task { await magasin.chargerLesClubsSuggeres() }
        }
        // La fiche et la saisie du code, portées par le corps de la carte : toujours à l'écran quand
        // on peut les demander.
        .sheet(item: $ficheOuverte) { fiche in
            ClubFicheView(depart: fiche, onRejoint: apresAdhesion)
                .hzFeuille(detents: [.large])
        }
        .sheet(isPresented: $codeOuvert) {
            ClubCodeSheet(onRejoint: apresAdhesion)
                .hzFeuille(detents: [.large])
        }
    }

    /// Une fois le club rejoint : le magasin relit son club (la carte disparaît alors d'elle-même) et
    /// la recherche se vide, pour qu'elle ne réapparaisse pas remplie si on quitte ce club un jour.
    private func apresAdhesion() async {
        await magasin.adopterLAdhesion()
        clubQuery = ""
    }

    /// Comment on entrera dans le club qu'on crée. Ouvert d'abord : c'est ce que le club était
    /// jusqu'ici, et ce qui fait venir du monde. Le propriétaire peut changer d'avis à tout moment
    /// depuis la gestion du club.
    private var choixDuMode: some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            Text("Comment on y entre")
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)
            ScrollView(.horizontal) {
                HStack(spacing: HZEspace.entrePilules) {
                    ForEach(ClubJoinMode.allCases) { mode in
                        HZFiltre(libelle: mode.libelle, actif: modeDuNouveauClub == mode, fond: .clair) {
                            Haptics.selection()
                            modeDuNouveauClub = mode
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            Text(modeDuNouveauClub.precisionDuProprietaire)
                .hzParagraphe(.c14, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var peutCreer: Bool {
        !newClubName.trimmingCharacters(in: .whitespaces).isEmpty && !magasin.isLoading
    }

    /// Toucher la ligne ouvre la fiche du club ; la pilule dit comment on y entre.
    private func ligneDUnClubARejoindre(_ trouve: ClubSearchResult, dernier: Bool) -> some View {
        Button(action: { ficheOuverte = ClubFicheOuverte(trouve) }) {
            HZLigneDeListe(titre: trouve.name, sousTitre: ligneDuClubTrouve(trouve), filet: !dernier) {
                HZVignette {
                    HZIcone(dessin: .groupe, cote: HZHub.coteDeLIcone, couleur: HZCouleur.blanc)
                }
            } queue: {
                HZPilule(texte: trouve.requestPending == true ? String(localized: "Demande envoyée")
                                                              : trouve.mode.libelle,
                         style: .etiquetteGrasse,
                         fond: trouve.requestPending == true ? HZCouleur.surfaceClaire : HZCouleur.encre,
                         couleur: trouve.requestPending == true ? HZCouleur.encre : HZCouleur.blanc)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(magasin.isLoading)
    }

    private func ligneDuClubTrouve(_ trouve: ClubSearchResult) -> String {
        let detail = ClubLigne.detail(ville: trouve.city, membres: trouve.memberCount)
        if trouve.seancePrevue == true {
            return "\(String(localized: "Une séance prévue")) · \(detail)"
        }
        if trouve.actifRecemment == true {
            return "\(String(localized: "Actif ces jours-ci")) · \(detail)"
        }
        return detail
    }
}
