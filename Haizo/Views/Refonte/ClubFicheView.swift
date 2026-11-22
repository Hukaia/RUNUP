import SwiftUI

/// LA FICHE D'UN CLUB, avant d'y entrer : ce qu'il montre de lui, et le bon bouton selon la façon
/// dont il accueille.
///
/// Une feuille, comme le reste de ce qu'on ouvre par-dessus une liste. La carte en aplat de couleur
/// est celle de la découverte, en plus haut ; dessous, la présentation écrite par le club, sa
/// prochaine séance quand il est ouvert, puis UN bouton :
///
///   · ouvert           « Rejoindre » ;
///   · sur demande      « Demander à rejoindre », puis « Demande envoyée » (qu'on peut annuler) ;
///   · sur code         « Entrer le code ».
///
/// Le bouton est décidé par `ClubBoutonDAdhesion.pour`, testé à part. La fiche montre tout de suite
/// ce qu'elle sait déjà (le nom, la ville, les membres, le mode) et charge le reste : un état de
/// chargement, un état d'erreur qui se relance, jamais une présentation inventée.
///
/// Elle ne rejoint pas pour son appelant : elle appelle `onRejoint` une fois l'adhésion faite, et
/// l'appelant fait ce qui lui revient (relire son club, ouvrir l'onglet Club).
struct ClubFicheView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let depart: ClubFicheOuverte
    let onRejoint: () async -> Void

    private enum Chargement: Equatable {
        case enCours
        case pret
        case panne(String)
    }

    @State private var chargement: Chargement = .enCours
    @State private var apercu: ClubPreview?
    @State private var demandeEnvoyee: Bool
    @State private var enAction = false
    @State private var message: String?
    @State private var codeDemande = false
    @State private var codeSaisi = ""

    init(depart: ClubFicheOuverte, onRejoint: @escaping () async -> Void) {
        self.depart = depart
        self.onRejoint = onRejoint
        _demandeEnvoyee = State(initialValue: depart.requestPending)
        _apercu = State(initialValue: depart.apercu)
        // Une fiche déjà chargée (le chemin du code) n'a rien à attendre.
        _chargement = State(initialValue: depart.apercu == nil ? .enCours : .pret)
    }

    private var service: ClubService { ClubService(auth: appState.auth) }

    // MARK: - Ce que la fiche dit du club

    private var mode: ClubJoinMode { apercu?.mode ?? depart.mode }
    private var nom: String { apercu?.name ?? depart.name }
    private var ville: String? { apercu?.city ?? depart.city }
    private var membres: Int { apercu?.memberCount ?? depart.memberCount }

    private var bouton: ClubBoutonDAdhesion {
        ClubBoutonDAdhesion.pour(mode: mode, demandeEnvoyee: demandeEnvoyee,
                                 dejaDansUnClub: apercu?.alreadyInClub == true,
                                 codeConnu: depart.code != nil)
    }

    // MARK: - La feuille

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Club")) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    HZCarteDeDecouverte(nom: nom,
                                        detail: ClubLigne.detail(ville: ville, membres: membres),
                                        mode: mode, demandeEnvoyee: demandeEnvoyee,
                                        couleur: HZIntensite.pourClub(id: depart.id).couleur,
                                        hauteur: HZFil.hauteurDeLaCarteDeClub)
                    contenu
                }
                .padding(.horizontal, HZEspace.marge)
            }
            .scrollIndicators(.hidden)
        }
        .task { await charger() }
    }

    @ViewBuilder private var contenu: some View {
        switch chargement {
        case .enCours:
            ProgressView()
                .tint(HZCouleur.encre)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HZExplorer.attente)
        case .panne(let phrase):
            VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
                HZPhrase(texte: phrase)
                HZBoutonPilule(libelle: String(localized: "Réessayer"), hauteur: .petite,
                               fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre) {
                    Task { await charger() }
                }
            }
        case .pret:
            VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                presentation
                prochaineSeance
                adhesion
            }
        }
    }

    // MARK: - La présentation et la prochaine séance

    @ViewBuilder private var presentation: some View {
        if let texte = apercu?.description, !texte.isEmpty {
            Text(texte)
                .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)
        } else if apercu != nil {
            // Il manque une présentation, et on le dit : ce n'est pas un défaut de la fiche, c'est ce
            // que le club a (ou n'a pas encore) écrit.
            HZPhrase(texte: String(localized: "Ce club n'a pas encore écrit sa présentation."))
        }
    }

    @ViewBuilder private var prochaineSeance: some View {
        if let seance = apercu?.nextSession {
            HZPlaque {
                Text("Prochaine séance")
                    .hzTexte(.c13, .semi)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                Text(verbatim: seance.title)
                    .hzAffichage(.section)
                    .foregroundStyle(HZCouleur.encre)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: ligneDeSeance(seance))
                    .hzParagraphe(.c14, .semi, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// « mardi 24 novembre à 18:30 · Stade Charléty · chaque semaine » : quand, où, et si elle revient.
    private func ligneDeSeance(_ seance: ClubPreviewSession) -> String {
        var morceaux = [seance.startsAt.formatted(.dateTime.weekday(.wide).day().month(.wide).hour().minute())]
        if let lieu = seance.location, !lieu.isEmpty { morceaux.append(lieu) }
        if seance.repeatsWeekly == true { morceaux.append(String(localized: "Chaque semaine")) }
        return morceaux.joined(separator: " · ")
    }

    // MARK: - Le bouton

    private var adhesion: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            switch bouton {
            case .dejaMembre:
                HZPhrase(texte: String(localized: "Tu fais déjà partie d'un club. Quitte-le pour en rejoindre un autre."))
            case .rejoindre, .rejoindreAvecLeCode:
                HZPhrase(texte: depart.code != nil
                         ? String(localized: "Le code est bon. Tu peux rejoindre ce club.")
                         : mode.precisionDuVisiteur)
                boutonPrincipal(bouton) { Task { await rejoindre() } }
            case .demander:
                HZPhrase(texte: mode.precisionDuVisiteur)
                boutonPrincipal(bouton) { Task { await demander() } }
            case .demandeEnvoyee:
                HZPhrase(texte: Accord.selon(
                    f: String(localized: "Le club a reçu ta demande. Tu seras prévenue dès qu'elle sera acceptée."),
                    m: String(localized: "Le club a reçu ta demande. Tu seras prévenu dès qu'elle sera acceptée.")))
                // L'état d'abord, dit en gris et non tapable ; le geste qui reste est de la retirer.
                HZBoutonPilule(libelle: String(localized: "Demande envoyée"),
                               fond: HZCouleur.surfaceClaire, couleur: HZCouleur.secondaireSurClair,
                               etendu: true) {}
                    .disabled(true)
                HZBoutonPilule(libelle: String(localized: "Annuler la demande"),
                               fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre, etendu: true) {
                    Task { await annuler() }
                }
                .opacity(enAction ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
                .disabled(enAction)
            case .entrerLeCode:
                champDuCode
            }
            if let message {
                Text(message)
                    .hzParagraphe(.c14, .semi, interligne: HZBandeauDuCoach.interligne)
                    .foregroundStyle(HZCouleur.encre)
                    .padding(HZEspace.groupe)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HZCouleur.surfaceClaire,
                                in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
            }
        }
    }

    /// Le bouton principal : noir, toute la largeur, éteint pendant l'appel.
    @ViewBuilder private func boutonPrincipal(_ bouton: ClubBoutonDAdhesion, geste: @escaping () -> Void) -> some View {
        if let libelle = bouton.libelle {
            HZBoutonPilule(libelle: libelle, etendu: true, action: geste)
                .opacity(enAction ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
                .disabled(enAction)
        }
    }

    /// « Entrer le code » : le bouton d'abord, puis le champ où le taper. Le code n'est jamais
    /// montré ailleurs qu'à la personne qui a créé le club : on le reçoit d'elle.
    @ViewBuilder private var champDuCode: some View {
        HZPhrase(texte: mode.precisionDuVisiteur)
        if codeDemande {
            HZChampDeTexte(titre: String(localized: "Code d'invitation"), invite: "",
                           texte: $codeSaisi, majuscules: .characters)
            HZBoutonPilule(libelle: String(localized: "Rejoindre"), etendu: true) {
                Task { await rejoindre() }
            }
            .opacity(enAction || !ClubCode.estComplet(codeSaisi) ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
            .disabled(enAction || !ClubCode.estComplet(codeSaisi))
        } else {
            HZBoutonPilule(libelle: String(localized: "Entrer le code"), etendu: true) {
                codeDemande = true
            }
        }
    }

    // MARK: - Les gestes

    private func charger() async {
        // La fiche d'un club trouvé par son code est déjà là : le serveur ne la rend qu'à qui en a
        // donné le code, et la relire ne dirait rien de plus.
        if depart.apercu != nil { chargement = .pret; return }
        // En démonstration, il n'y a pas de serveur : la fiche montre ce que la carte savait.
        if Demonstration.enCours { chargement = .pret; return }
        chargement = .enCours
        do {
            let fiche = try await service.clubPreview(id: depart.id)
            apercu = fiche
            demandeEnvoyee = fiche.requestPending == true
            chargement = .pret
        } catch {
            chargement = .panne(ClubAdhesionErreur.phrase(pour: error))
        }
    }

    private func rejoindre() async {
        guard !enAction else { return }
        enAction = true
        message = nil
        defer { enAction = false }
        let code = depart.code ?? (codeDemande ? ClubCode.normaliser(codeSaisi) : nil)
        do {
            _ = try await service.joinClub(clubId: depart.id, code: code)
            await onRejoint()
            dismiss()
        } catch {
            message = ClubAdhesionErreur.phrase(pour: error)
            // Le club a changé de mode depuis la fiche : le bouton affiché mentirait. On relit.
            if ClubAdhesionErreur.faitRelireLaFiche(error), depart.apercu == nil { await charger() }
        }
    }

    private func demander() async {
        guard !enAction else { return }
        enAction = true
        message = nil
        defer { enAction = false }
        do {
            try await service.requestJoin(clubId: depart.id)
            demandeEnvoyee = true
            Haptics.success()
        } catch {
            message = ClubAdhesionErreur.phrase(pour: error)
            if ClubAdhesionErreur.faitRelireLaFiche(error), depart.apercu == nil { await charger() }
        }
    }

    private func annuler() async {
        guard !enAction else { return }
        enAction = true
        message = nil
        defer { enAction = false }
        do {
            try await service.cancelJoinRequest(clubId: depart.id)
            demandeEnvoyee = false
        } catch {
            message = ClubAdhesionErreur.phrase(pour: error)
        }
    }
}
