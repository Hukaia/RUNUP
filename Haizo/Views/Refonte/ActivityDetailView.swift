import SwiftUI

/// LA SORTIE DÉROULÉE.
///
/// # CE QUI MANQUAIT
///
/// Le fil montrait quatre chiffres d'une course — km, allure, temps, D+ — et c'était un
/// cul-de-sac : on ne pouvait pas l'OUVRIR. Chez Strava, chaque sortie du fil mène à sa page, où
/// se trouvent les kilomètres un par un, le profil du terrain, le cœur. Ces données existaient
/// déjà sur l'appareil de qui avait couru ; elles n'en sortaient simplement jamais.
///
/// # POURQUOI UN APPEL À PART
///
/// Les splits et les altitudes d'une sortie pèsent plus que tout le reste de sa carte, et le fil
/// en charge cinquante d'un coup. On ne paie ce poids que pour la sortie qu'on ouvre vraiment —
/// d'où `api/activities/detail` plutôt que trois champs de plus dans le fil.
///
/// # CE QU'ELLE DIT QUAND IL N'Y A RIEN À DIRE
///
/// Une sortie publiée avant ces champs, une séance saisie à la main, une course sans montre
/// cardio : la page le DIT, au lieu d'afficher des zéros qui passeraient pour des mesures. Une
/// absence de mesure et une mesure nulle ne sont pas la même phrase — c'est la règle de toute
/// l'app, et c'est ici qu'elle se voit le plus.
struct ActivityDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var activityId: String

    @State private var sortie: ActivityDetail?
    @State private var enChargement = true
    @State private var erreur: String?
    @State private var splitsRevelees = false
    @State private var commentairesOuverts = false

    private var clubService: ClubService { ClubService(auth: appState.auth) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: -HZRayon.feuille) {
                carte
                feuille
            }
        }
        .scrollIndicators(.hidden)
        .background(HZCouleur.blanc)
        .ignoresSafeArea(edges: .top)
        .statusBarHidden()
        .task { await charger() }
        .sheet(isPresented: $commentairesOuverts) {
            ActivityCommentsSheet(
                activityId: activityId,
                currentUserId: appState.auth.currentUser?.id,
                clubService: clubService,
                onCommentPosted: { Task { await charger() } },
                onReport: { _ in },
                onBlock: { _ in }
            )
            .hzFeuille(detents: [.large], gereSonBas: true)
        }
    }

    // MARK: - La carte, avec son retour

    /// Une photo si la personne en a posé une, sinon le tracé sur la vraie carte, sinon rien : un
    /// bandeau noir assez haut pour porter le retour.
    private var carte: some View {
        ZStack(alignment: .top) {
            if let sortie, let url = urlDeLaPhoto(sortie) {
                HZCouleur.surfaceClaire
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .accessibilityElement()
                .accessibilityLabel("Photo de la sortie")
            } else if let sortie, sortie.route.count > 1 {
                HZCouleur.surfaceClaire
                RunRouteMapView(route: sortie.route, lineWidth: HZLive.traitDuTrace, lineColor: HZCouleur.accent)
                    .accessibilityElement()
                    .accessibilityLabel("Tracé de la sortie")
            } else {
                HZCouleur.noir
            }
            HStack {
                HZBoutonRond(dessin: .retour, nom: String(localized: "Retour"), diametre: .outil,
                             fond: HZCouleur.noir, trait: HZBoutonRond.traitDuRetour) { dismiss() }
                Spacer(minLength: 0)
            }
            .padding(.top, HZEspace.haut)
            .padding(.horizontal, HZEspace.marge)
        }
        .frame(maxWidth: .infinity)
        .frame(height: carteVisible ? HZResume.carte : HZResume.hauteurSansCarte)
        .clipped()
    }

    private var carteVisible: Bool {
        guard let sortie else { return false }
        return urlDeLaPhoto(sortie) != nil || sortie.route.count > 1
    }

    private func urlDeLaPhoto(_ s: ActivityDetail) -> URL? {
        guard let brut = s.photoUrl, !brut.isEmpty else { return nil }
        return URL(string: brut)
    }

    // MARK: - La feuille

    private var feuille: some View {
        HZFeuille(retrait: .ample) {
            if enChargement {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, HZFil.enAttente)
            } else if let erreur {
                HZPhrase(texte: String(localized: "Impossible d'ouvrir cette sortie — \(erreur)."))
            } else if let sortie {
                contenu(sortie)
            }
        }
        .padding(.bottom, HZResume.basDePage)
        .frame(minHeight: HZHub.hauteurMiniDeLaFeuille, alignment: .top)
    }

    @ViewBuilder
    private func contenu(_ s: ActivityDetail) -> some View {
        auteur(s)
        if let km = s.distanceKm, km > 0 {
            HStack(alignment: .firstTextBaseline, spacing: HZEspace.entreCommandes) {
                Text(verbatim: String(format: "%.2f", locale: Locale.current, km))
                    .hzAffichage(.resume)
                    .hzVedette()
                    .lineLimit(1)
                    .minimumScaleFactor(HZResume.reductionDeLaDistance)
                    .padding(.leading, -HZResume.debordDeLaDistance)
                Text(verbatim: "km").hzTexte(.c20, .gras)
            }
            .padding(.top, HZResume.sousLeTitre)
        }
        Text(s.localizedText)
            .hzTexte(.c20, .gras)
            .foregroundStyle(HZCouleur.encre)
            .lineLimit(HZHub.lignesDUnTitre)
            .padding(.top, HZResume.sousLaDistance)
        if let titre = s.title, !titre.isEmpty {
            Text(titre)
                .hzParagraphe(.c16, .gras, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, HZEspace.entrePilules)
        }
        if let note = s.note, !note.isEmpty {
            Text(note)
                .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, HZEspace.entrePilules)
        }
        tuiles(s).padding(.top, HZResume.sousLeTitre)
        actions(s).padding(.top, HZEspace.groupe)
        if s.splits.count > 1 { courbeDAllure(s).padding(.top, HZEspace.entreSections) }
        if !s.splits.isEmpty { kilometres(s).padding(.top, HZEspace.entreSections) }
        if ElevationProfileView.hasData(s.route) { profil(s).padding(.top, HZEspace.entreSections) }
        if !s.aDuDetail {
            HZPhrase(texte: String(localized: "Cette sortie n'a pas de détail enregistré : pas de temps au kilomètre, pas de profil, pas de cardio."))
                .padding(.top, HZEspace.entreSections)
        }
    }

    /// Qui a couru, quand, et si c'est un record.
    private func auteur(_ s: ActivityDetail) -> some View {
        HStack(spacing: HZEspace.entreCommandes) {
            Button(action: { if !s.isMine { appState.ouvrirLeProfil(s.userId) } }) {
                HStack(spacing: HZEspace.entreCommandes) {
                    HZPhotoDePersonne(imageData: s.isMine ? appState.profile.avatarImageData : nil,
                                      urlString: s.avatarUrl, base64DataURI: s.avatarBase64,
                                      initiales: HZInitiales.de(s.name, s.lastName))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(s.nomComplet).hzTexte(.c16, .gras).foregroundStyle(HZCouleur.encre)
                        Text(s.createdAt.relativeDescription)
                            .hzTexte(.c13, .medium)
                            .foregroundStyle(HZCouleur.secondaireSurClair)
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(s.isMine ? Text(s.nomComplet)
                                         : Text(String(localized: "Voir le profil de \(s.nomComplet)")))
            if s.isPersonalRecord {
                HZPilule(texte: String(localized: "Record"), style: .etiquetteGrasse, fond: HZCouleur.encre)
            }
        }
    }

    // MARK: - Les mesures

    /// Allure et durée en grand ; ce qui a été mesuré en plus (cardio, calories, dénivelé) en petit —
    /// jamais une case pour une mesure qui n'existe pas.
    @ViewBuilder private func tuiles(_ s: ActivityDetail) -> some View {
        let grandes = [(String(localized: "Allure moyenne"), s.avgPace),
                       (String(localized: "Durée"), s.durationDisplay)]
            .compactMap { libelle, valeur in valeur.flatMap { $0.isEmpty ? nil : (libelle, $0) } }
        let petites = petitesMesures(s)
        VStack(spacing: HZEspace.entreTuiles) {
            if !grandes.isEmpty {
                HStack(spacing: HZEspace.entreTuiles) {
                    ForEach(grandes, id: \.0) { tuile in HZTuileChiffre(libelle: tuile.0, valeur: tuile.1, format: .resume) }
                }
            }
            if !petites.isEmpty {
                HStack(spacing: HZEspace.entreTuiles) {
                    ForEach(petites, id: \.0) { tuile in HZTuileChiffre(libelle: tuile.0, valeur: tuile.1, format: .resume) }
                }
            }
        }
        .opacity(splitsRevelees ? HZResume.opacitePleine : 0)
        .animation(reduceMotion ? nil : .easeOut(duration: HZResume.dureeDEntree), value: splitsRevelees)
    }

    private func petitesMesures(_ s: ActivityDetail) -> [(String, String)] {
        var out: [(String, String)] = []
        if let fc = s.avgHeartRate { out.append((String(localized: "FC moy."), "\(fc)")) }
        if let kcal = s.kcal { out.append(("kcal", "\(kcal)")) }
        if let dplus = s.elevationGainM, dplus > 0 { out.append(("D+ (m)", "+\(dplus)")) }
        return out
    }

    // MARK: - Applaudir, commenter

    private func actions(_ s: ActivityDetail) -> some View {
        HStack(spacing: HZEspace.entreCommandes) {
            Button(action: { Task { await applaudir() } }) {
                HStack(spacing: HZBoutonPilule.ecart) {
                    HZIcone(dessin: .coeur, cote: HZFil.coteDuBravo,
                            couleur: s.kudoedByMe ? HZCouleur.accent : HZCouleur.encre)
                    Text(s.kudos > 0 ? "\(s.kudos)" : String(localized: "Bravo"))
                        .hzTexte(.c14, .gras)
                        .foregroundStyle(HZCouleur.encre)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, HZHauteurDeBouton.moyenne.marge)
                .frame(height: HZHauteurDeBouton.moyenne.rawValue)
                .background(HZCouleur.surfaceClaire, in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(s.kudoedByMe ? "Retirer ton applaudissement" : "Applaudir cette séance")
            .accessibilityValue("\(s.kudos)")

            Button(action: { commentairesOuverts = true }) {
                HStack(spacing: HZBoutonPilule.ecart) {
                    HZIcone(dessin: .bulle, cote: HZFil.coteDuBravo, couleur: HZCouleur.encre)
                    Text(s.commentsCount > 0 ? "\(s.commentsCount)" : String(localized: "Commenter"))
                        .hzTexte(.c14, .gras)
                        .foregroundStyle(HZCouleur.encre)
                }
                .padding(.horizontal, HZHauteurDeBouton.moyenne.marge)
                .frame(height: HZHauteurDeBouton.moyenne.rawValue)
                .background(HZCouleur.surfaceClaire, in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Commenter")
            .accessibilityValue("\(s.commentsCount)")
            Spacer(minLength: 0)
        }
    }

    // MARK: - La courbe d'allure et les kilomètres

    /// La carte « Allure moyenne » de Stats, appliquée aux kilomètres de cette sortie : une valeur par
    /// kilomètre, 0 en haut pour le plus rapide.
    private func courbeDAllure(_ s: ActivityDetail) -> some View {
        let secondes = s.splits.compactMap { PaceModel.parseSecPerKm($0) }
        return VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Allure moyenne"))
            HZCarteDAllure(allure: s.avgPace ?? "—", ecart: nil,
                           valeurs: HZAllures.normalisees(s.splits),
                           record: nil,
                           pireAllure: secondes.max().map { TimeFormat.allure(secondesParKm: $0) },
                           meilleureAllure: secondes.min().map { TimeFormat.allure(secondesParKm: $0) })
        }
    }

    /// Les kilomètres, en lignes de liste : le numéro à gauche, le temps à droite, le plus rapide en
    /// gras accent.
    private func kilometres(_ s: ActivityDetail) -> some View {
        let secondes = s.splits.map { PaceModel.parseSecPerKm($0) }
        let meilleur = secondes.compactMap { $0 }.min()
        return VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Splits par km"))
            LazyVStack(spacing: 0) {
                ForEach(Array(s.splits.enumerated()), id: \.offset) { index, temps in
                    HZLigneDeListe(titre: String(localized: "Kilomètre \(index + 1)"),
                                   filet: index < s.splits.count - 1) {
                        EmptyView()
                    } queue: {
                        HStack(spacing: HZEspace.entrePilules) {
                            if let meilleur, secondes[index] == meilleur {
                                HZPilule(texte: String(localized: "Le plus rapide"), style: .etiquette,
                                         fond: HZCouleur.accent, couleur: HZCouleur.encreSurAccent)
                            }
                            Text(temps)
                                .hzAffichage(.chiffreDeLigne)
                                .foregroundStyle(HZCouleur.encre)
                        }
                        .fixedSize()
                    }
                }
            }
        }
    }

    private func profil(_ s: ActivityDetail) -> some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Profil d'élévation"))
            ElevationProfileView(route: s.route, lineColor: HZCouleur.accent)
                .frame(height: HZResume.hauteurDeLElevation)
                .padding(HZEspace.groupe)
                .background(HZCouleur.surfaceClaire,
                            in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
                .accessibilityHidden(true)
        }
    }

    // MARK: - Les données

    private func charger() async {
        if Demonstration.enCours {
            sortie = appState.cachedActivityDetail
            enChargement = false
            reveler()
            return
        }
        enChargement = true
        erreur = nil
        do {
            sortie = try await clubService.fetchActivityDetail(id: activityId)
            reveler()
        } catch {
            erreur = PanneReseau.motif(pour: error)
        }
        enChargement = false
    }

    private func reveler() {
        guard !splitsRevelees else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: HZResume.dureeDEntree)) { splitsRevelees = true }
    }

    private func applaudir() async {
        guard let courante = sortie else { return }
        let avant = courante.kudoedByMe
        sortie?.kudoedByMe = !avant
        sortie?.kudos += avant ? -1 : 1
        Haptics.impact(.light)
        do {
            let maintenant = try await clubService.toggleKudos(activityId: activityId)
            sortie?.kudoedByMe = maintenant
        } catch {
            sortie?.kudoedByMe = avant
            sortie?.kudos = courante.kudos
        }
    }
}
