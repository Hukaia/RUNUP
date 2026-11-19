import SwiftUI
import MapKit

/// Un itinéraire en grand : son tracé complet, ce que son autrice en dit, et les deux gestes qui
/// comptent — le garder pour plus tard, ou l'ouvrir dans Plans pour s'y rendre.
///
/// Le tracé complet n'est chargé qu'ici. La liste de découverte n'a que des aperçus d'une vingtaine
/// de points : afficher cinquante tracés complets sur une carte coûterait plusieurs mégaoctets pour
/// dessiner des gribouillis de quelques millimètres.
struct RouteDetailSheet: View {
    var route: SharedRoute
    /// Remonte l'itinéraire modifié (enregistré ou non) pour que la liste appelante se mette à
    /// jour sans refaire une requête.
    var onChanged: (SharedRoute) -> Void = { _ in }

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var detailed: SharedRoute?
    @State private var isSaving = false
    @State private var reportPresented = false
    @State private var reportReason = ""
    @State private var commentaires: [CommentItem] = []
    @State private var brouillon = ""
    @State private var envoiEnCours = false
    @State private var cibleSignalee: ReportTarget?

    private var current: SharedRoute { detailed ?? route }

    var body: some View {
        HZFeuilleModale(titre: current.name) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    carte
                    mesures
                    if let notes = current.notes, !notes.isEmpty { notesCard(notes) }
                    actions
                    ceQuOnEnSait
                    reportButton
                }
                .padding(.horizontal, HZEspace.marge)
            }
        }
        .task {
            await loadFullTrace()
            await chargerLesCommentaires()
        }
        .alert("Signaler cet itinéraire", isPresented: $reportPresented) {
            TextField("Pourquoi ?", text: $reportReason)
            Button("Envoyer") { report() }
            Button("Annuler", role: .cancel) { cibleSignalee = nil; reportReason = "" }
        } message: {
            Text("Ce signalement sera examiné. Merci de préciser ce qui pose problème.")
        }
    }

    // MARK: - Morceaux

    /// La carte d'abord — c'est elle qu'on voit quand la feuille n'est qu'à demi ouverte — puis
    /// la photo du coin, et qui a partagé.
    private var carte: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            map
            photo
            if let author = current.authorName {
                Text(String(localized: "Partagé par \(author)"))
                    .hzTexte(.c14, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
            }
        }
    }

    @ViewBuilder
    private var photo: some View {
        if let photoUrl = current.photoUrl, let url = URL(string: photoUrl) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                HZCouleur.surfaceClaire
            }
            .frame(height: HZFeuillesDuFil.hauteurDeLaPhotoDeFiche)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: HZRayon.tuile, style: .circular))
            .accessibilityLabel(Text("Photo du parcours"))
        }
    }

    private var map: some View {
        let coordinates = current.drawableCoordinates
        return Map(initialPosition: .region(regionFitting(coordinates))) {
            if coordinates.count > 1 {
                MapPolyline(coordinates: coordinates)
                    .stroke(HZCouleur.accent,
                            style: StrokeStyle(lineWidth: HZHub.traitDeLaCarte, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: HZFeuillesDuFil.hauteurDeLaCarte)
        .clipShape(RoundedRectangle(cornerRadius: HZRayon.tuile, style: .circular))
        .allowsHitTesting(false)
        .accessibilityLabel(Text("Tracé de l'itinéraire"))
    }

    private let colonnes = Array(repeating: GridItem(.flexible(), spacing: HZEspace.entreTuiles, alignment: .top),
                                 count: HZFeuillesDuFil.colonnesDeMesures)

    private var mesures: some View {
        LazyVGrid(columns: colonnes, spacing: HZEspace.entreTuiles) {
            if let km = current.distanceKm {
                HZTuileChiffre(libelle: String(localized: "km"),
                               valeur: String(format: "%.1f", locale: Locale.current, km), format: .resume)
            }
            if let elevation = current.elevationGainM, elevation > 0 {
                HZTuileChiffre(libelle: String(localized: "D+"), valeur: "\(elevation)", format: .resume)
            }
            // Le temps de la personne qui a publié, pas un objectif : le libellé le dit, sinon la
            // carte d'entraide devient un classement déguisé.
            if let seconds = current.durationSeconds, seconds > 0 {
                HZTuileChiffre(libelle: String(localized: "Son temps"),
                               valeur: PaceModel.formatDuration(Double(seconds)), format: .resume)
            }
            HZTuileChiffre(libelle: String(localized: "Gardé"), valeur: "\(current.savesCount)", format: .resume)
        }
    }

    private func notesCard(_ notes: String) -> some View {
        HZPlaque {
            Text(notes)
                .hzParagraphe(.c15, .medium, interligne: HZBandeauDuCoach.interligne)
                .foregroundStyle(HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actions: some View {
        VStack(spacing: HZEspace.entreCommandes) {
            HZBoutonPilule(libelle: current.saved ? String(localized: "Retirer de mes itinéraires")
                                                  : String(localized: "Garder cet itinéraire"),
                           etendu: true) {
                toggleSaved()
            }
            .opacity(isSaving ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
            .disabled(isSaving)

            // Le départ affiché est celui du tracé rogné, donc à ~300 m de chez son autrice. C'est
            // exactement ce qu'il faut ouvrir dans Plans : le point où l'itinéraire commence pour
            // qui le découvre, pas le pas de porte de quelqu'un.
            HZBoutonPilule(libelle: String(localized: "M'y rendre"), fond: HZCouleur.surfaceClaire,
                           couleur: HZCouleur.encre, etendu: true) {
                let placemark = MKPlacemark(coordinate: current.startCoordinate)
                let item = MKMapItem(placemark: placemark)
                item.name = current.name
                item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
            }
        }
    }

    // MARK: - Ce qu'on en sait

    /// CE QUE LE TRACÉ NE DIT PAS.
    ///
    /// Un itinéraire se gardait déjà — le marque-page, qui est sa forme d'approbation. Ce qui lui
    /// manquait, c'était de pouvoir DIRE quelque chose : « attention aux racines après le pont »,
    /// « fermé en hiver », « la fontaine au kilomètre 4 marche ». Un itinéraire est un lieu, et ce
    /// qu'on en sait vaut souvent autant que son dessin.
    ///
    /// Le titre n'est pas « Commentaires » : on ne vient pas commenter un parcours, on vient dire
    /// ce qu'on en sait. Le mot change ce qu'on écrit.
    private var ceQuOnEnSait: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            HZTitreDeSection(titre: String(localized: "Ce qu'on en sait"))

            if commentaires.isEmpty {
                HZPhrase(texte: String(localized: "Personne n'a encore rien dit sur ce parcours."))
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(commentaires) { commentaire in
                        ligneDeCommentaire(commentaire)
                    }
                }
            }

            HZSaisie(texte: $brouillon, invite: String(localized: "Écris ce que tu sais de ce parcours…"),
                     nomDuBouton: String(localized: "Envoyer"), peutEnvoyer: peutEnvoyer) {
                if peutEnvoyer { Task { await envoyer() } }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var peutEnvoyer: Bool {
        !brouillon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !envoiEnCours
    }

    private func ligneDeCommentaire(_ commentaire: CommentItem) -> some View {
        HZLigneDeCommentaire(
            nom: commentaire.nomComplet,
            date: commentaire.createdAt.relativeDescription,
            texte: commentaire.text,
            photo: HZPhotoDePersonne(urlString: commentaire.avatarUrl, base64DataURI: commentaire.avatarBase64,
                                     initiales: String(commentaire.name.prefix(1))),
            nomDuProfil: String(localized: "Voir le profil de \(commentaire.name)"),
            ouvrir: { appState.ouvrirLeProfil(commentaire.userId) })
        .contextMenu {
            Button("Signaler ce commentaire") {
                cibleSignalee = ReportTarget(targetType: "route_comment",
                                             targetId: commentaire.id,
                                             displayName: commentaire.nomComplet)
                reportReason = ""
                reportPresented = true
            }
        }
    }

    private func chargerLesCommentaires() async {
        commentaires = (try? await ClubService(auth: appState.auth)
            .fetchRouteComments(routeId: route.id)) ?? []
    }

    private func envoyer() async {
        let propre = brouillon.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !propre.isEmpty else { return }
        envoiEnCours = true
        do {
            try await ClubService(auth: appState.auth).postRouteComment(routeId: route.id, text: propre)
            brouillon = ""
            await chargerLesCommentaires()
            Haptics.impact(.light)
        } catch ClubServiceError.badResponse(let code, _) where code == HZHub.refuse {
            appState.toast(String(localized: "Ce texte a été refusé par le filtre de contenu. Reformule-le."))
        } catch {
            appState.toast(String(localized: "Impossible de publier — \(PanneReseau.motif(pour: error))."))
        }
        envoiEnCours = false
    }

    private var reportButton: some View {
        Button { reportPresented = true } label: {
            Text("Signaler cet itinéraire")
                .hzTexte(.c14, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .frame(maxWidth: .infinity, minHeight: HZBoutonRond.zoneTactile)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    /// Ajuste la carte au parcours, avec 30 % de marge pour que le tracé ne colle pas aux bords.
    private func regionFitting(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(center: current.startCoordinate,
                                      span: MKCoordinateSpan(latitudeDelta: HZFeuillesDuFil.etendueSansTrace,
                                                         longitudeDelta: HZFeuillesDuFil.etendueSansTrace))
        }
        let lats = coordinates.map(\.latitude)
        let lngs = coordinates.map(\.longitude)
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLng = lngs.min()!, maxLng = lngs.max()!
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / HZHub.moitieDeLEtendue, longitude: (minLng + maxLng) / HZHub.moitieDeLEtendue),
            span: MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * HZHub.margeDuCadrage, HZFeuillesDuFil.etendueMinimale),
                                   longitudeDelta: max((maxLng - minLng) * HZHub.margeDuCadrage, HZFeuillesDuFil.etendueMinimale))
        )
    }

    private func loadFullTrace() async {
        guard current.points == nil else { return }
        if let full = try? await ClubService(auth: appState.auth).fetchRoute(id: route.id) {
            detailed = full
        }
    }

    private func toggleSaved() {
        isSaving = true
        let target = !current.saved
        Task {
            do {
                let count = try await ClubService(auth: appState.auth)
                    .setRouteSaved(routeId: current.id, saved: target)
                var updated = current
                updated.saved = target
                updated.savesCount = count
                detailed = updated
                onChanged(updated)
                Haptics.impact(.light)
            } catch {
                appState.toast(String(localized: "Impossible de mettre à jour — réessaie."))
            }
            isSaving = false
        }
    }

    /// La même alerte sert pour l'itinéraire ET pour un commentaire : `cibleSignalee` dit lequel.
    /// Nil veut dire l'itinéraire — c'est le bouton en pied de page, qui n'en désigne pas d'autre.
    private func report() {
        let reason = reportReason.trimmingCharacters(in: .whitespacesAndNewlines)
        let cible = cibleSignalee
        cibleSignalee = nil
        reportReason = ""
        guard !reason.isEmpty else { return }
        Task {
            try? await ClubService(auth: appState.auth).report(
                targetType: cible?.targetType ?? "route",
                targetId: cible?.targetId ?? current.id,
                reason: reason
            )
            appState.toast(String(localized: "Signalement envoyé"))
        }
    }
}
