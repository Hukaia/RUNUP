import SwiftUI

/// « REJOINDRE AVEC UN CODE » : la seule façon de trouver un club sur code.
///
/// Un club sur code n'apparaît dans aucune recherche ni aucune suggestion : c'est ce qu'il promet à
/// son propriétaire. On y entre en tapant le code qu'il vous a donné. Le serveur reconnaît le code
/// et rend la fiche du club ; la feuille bascule alors sur cette fiche (`ClubFicheView`), où le code
/// est déjà vérifié et où il ne reste qu'à rejoindre.
///
/// Un code qui ne mène à rien reçoit une seule réponse, « Aucun club ne correspond à ce code » :
/// le serveur ne dit pas si le club existe sous un autre mode.
struct ClubCodeSheet: View {
    @Environment(AppState.self) private var appState

    /// Appelée une fois le club rejoint, comme pour la fiche.
    let onRejoint: () async -> Void

    @State private var code = ""
    @State private var enCours = false
    @State private var message: String?
    @State private var trouve: ClubFicheOuverte?

    private var peutContinuer: Bool { ClubCode.estComplet(code) && !enCours }

    var body: some View {
        if let trouve {
            ClubFicheView(depart: trouve, onRejoint: onRejoint)
        } else {
            saisie
        }
    }

    private var saisie: some View {
        HZFeuilleModale(titre: String(localized: "Rejoindre avec un code")) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                    HZPhrase(texte: String(localized: "Un club sur code n'apparaît dans aucune recherche. Demande son code à la personne qui l'a créé."))
                    HZChampDeTexte(titre: String(localized: "Code d'invitation"), invite: "",
                                   texte: $code, majuscules: .characters)
                    if let message {
                        Text(message)
                            .hzParagraphe(.c14, .semi, interligne: HZBandeauDuCoach.interligne)
                            .foregroundStyle(HZCouleur.encre)
                            .padding(HZEspace.groupe)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(HZCouleur.surfaceClaire,
                                        in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
                    }
                    HZBoutonPilule(libelle: String(localized: "Continuer"), etendu: true) {
                        Task { await chercher() }
                    }
                    .opacity(peutContinuer ? HZHub.opaciteNormale : HZHub.opaciteEteinte)
                    .disabled(!peutContinuer)
                }
                .padding(.horizontal, HZEspace.marge)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func chercher() async {
        guard peutContinuer else { return }
        enCours = true
        message = nil
        defer { enCours = false }
        let normalise = ClubCode.normaliser(code)
        do {
            let fiche = try await ClubService(auth: appState.auth).clubPreview(code: normalise)
            trouve = ClubFicheOuverte(fiche, code: normalise)
        } catch {
            message = ClubAdhesionErreur.phraseDuCode(pour: error)
        }
    }
}

/// LA LIGNE QUI MÈNE À LA SAISIE DU CODE, sous une liste de clubs : un club sur code n'est dans
/// aucune liste, donc c'est la seule porte qui y mène. Partagée par la découverte (Explorer) et la
/// carte « Rejoindre un club » du Club.
struct ClubLigneDuCode: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HZLigneDeListe(titre: String(localized: "Rejoindre avec un code"),
                           sousTitre: String(localized: "Pour un club qui ne se trouve pas par son nom"),
                           marge: HZMesuresDeLigne.margeDeDestination, filet: false) {
                HZIcone(dessin: .groupe, cote: HZProfil.coteDeLIconeDeDestination, couleur: HZCouleur.encre)
                    .frame(width: HZProfil.disqueDeDestination, height: HZProfil.disqueDeDestination)
                    .background(HZCouleur.surfaceClaire, in: Circle())
            } queue: {
                HZChevron()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
