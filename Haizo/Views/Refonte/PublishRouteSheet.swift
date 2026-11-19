import SwiftUI
import CoreLocation
import PhotosUI
import MapKit

/// Publier une sortie déjà courue comme itinéraire, pour quelqu'un qui débarque dans la ville.
///
/// L'écran a deux rôles, et le second compte autant que le premier : recueillir un nom, et **dire
/// exactement ce qui part**. Publier un tracé GPS est le seul geste de cette app qui expose la
/// position réelle de quelqu'un ; le faire accepter sans l'expliquer serait obtenir un
/// consentement qui n'en est pas un. D'où l'aperçu du tracé ROGNÉ — celui qui partira, pas celui
/// qui a été couru — et la phrase qui nomme les 300 mètres retirés de chaque côté.
struct PublishRouteSheet: View {
    var run: RunRecord
    /// Appelé après une publication réussie, pour que l'écran appelant puisse le signaler.
    var onPublished: (String?) -> Void = { _ in }

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var locality: String?
    @State private var countryCode: String?
    @State private var isPublishing = false
    @State private var errorMessage: String?
    @State private var photoItem: PhotosPickerItem?
    /// Vrai le temps de décoder, réduire et encoder l'image choisie — voir `loadPhoto`.
    @State private var chargementPhoto = false
    /// L'aperçu affiché ici, et le JPEG encodé prêt à partir. Les deux, parce que redimensionner
    /// à l'envoi ferait attendre au moment où l'on appuie sur « publier ».
    @State private var photoPreview: UIImage?
    @State private var photoDataURI: String?

    /// Le tracé tel qu'il sera publié. Calculé une fois, et c'est LUI qui est dessiné : montrer le
    /// tracé complet avec une promesse de rognage demanderait de croire l'app sur parole.
    private var payload: (points: [RunRecord.RoutePoint], preview: [RunRecord.RoutePoint])? {
        RouteGeometry.shareablePayload(run.route)
    }

    private var canPublish: Bool {
        payload != nil && !name.trimmingCharacters(in: .whitespaces).isEmpty && !isPublishing
    }

    var body: some View {
        HZFeuilleModale(titre: String(localized: "Partager cet itinéraire")) {
            ScrollView {
                VStack(alignment: .leading, spacing: HZEspace.entreSections) {
                    HZPhrase(texte: String(localized: "Quelqu'un qui arrive dans le coin verra ton parcours et pourra le suivre."))

                    if let payload {
                        trimmedPreview(payload.points)
                        privacyNote
                        photoSection
                    } else {
                        tooShortNote
                    }

                    champs

                    if let errorMessage { HZAvisDeFeuille(texte: errorMessage) }
                }
                .padding(.horizontal, HZEspace.marge)
            }
            // Le geste pour lequel cette feuille est ouverte, épinglé.
            //
            // SEUL LE GESTE PRINCIPAL MONTE DANS LE BAS, et « Annuler » n'a plus de bouton : la
            // croix de la feuille le remplace.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HZBasDeFeuille {
                    HZBoutonPilule(libelle: isPublishing ? String(localized: "Publication…")
                                                         : String(localized: "Publier l'itinéraire"),
                                   etendu: true) { publish() }
                        .opacity(canPublish ? HZHub.opaciteNormale : HZHub.opaciteEteinte)
                        .disabled(!canPublish)
                }
            }
        }
        .task { await resolveLocality() }
        .onAppear { if name.isEmpty { name = placeholderName } }
    }

    // MARK: - Morceaux

    private var champs: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            HZChampDeTexte(titre: String(localized: "Nom de l'itinéraire"), invite: placeholderName,
                           texte: $name)
            HZChampDeTexte(titre: String(localized: "Ce qu'il faut savoir (optionnel)"),
                           invite: String(localized: "Plat, le long du fleuve. Ça grimpe au km 3."),
                           texte: $notes, lignes: HZFeuillesDuFil.lignesDesNotes)
        }
    }

    private func trimmedPreview(_ points: [RunRecord.RoutePoint]) -> some View {
        let coordonnees = points.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
        return Map(initialPosition: .region(HZHub.cadre(de: coordonnees) ?? MKCoordinateRegion())) {
            if coordonnees.count > 1 {
                MapPolyline(coordinates: coordonnees)
                    .stroke(HZCouleur.accent,
                            style: StrokeStyle(lineWidth: HZHub.traitDeLaCarte, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: HZFeuillesDuFil.hauteurDeLApercu)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: HZRayon.tuile, style: .circular))
        .allowsHitTesting(false)
        .accessibilityLabel(Text("Aperçu du tracé qui sera publié"))
    }

    /// La photo est ce qui donne envie d'y aller ; le tracé dit seulement où c'est. Optionnelle,
    /// et présentée comme telle : la rendre obligatoire ferait abandonner la moitié des
    /// publications sur une sortie faite de nuit ou sous la pluie.
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
            Text("Une photo du coin (optionnel)")
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)

            if let photoPreview {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: photoPreview)
                        .resizable()
                        .scaledToFill()
                        .frame(height: HZFeuillesDuFil.hauteurDeLaPhotoAjoutee)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: HZRayon.tuile, style: .circular))
                    HZBoutonRond(dessin: .fermer, nom: String(localized: "Retirer la photo"), diametre: .outil,
                                 cote: HZHub.coteDeLaCroix, trait: HZHub.traitDeLaCroix) {
                        self.photoPreview = nil
                        self.photoDataURI = nil
                        self.photoItem = nil
                    }
                    .padding(HZEspace.entrePilules)
                }
            } else {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack(spacing: HZEspace.entrePilules) {
                        if chargementPhoto { ProgressView().controlSize(.small).tint(HZCouleur.encre) }
                        Text(chargementPhoto ? String(localized: "Préparation…")
                                             : String(localized: "Ajouter une photo"))
                            .hzTexte(HZHauteurDeBouton.moyenne.corps, .gras)
                            .foregroundStyle(HZCouleur.encre)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: HZHauteurDeBouton.moyenne.rawValue)
                    .background(HZCouleur.surfaceClaire, in: Capsule())
                    .contentShape(Capsule())
                }
                // Choisir une seconde photo pendant que la première se prépare écraserait l'état
                // en cours de route.
                .disabled(chargementPhoto)
            }
        }
        .onChange(of: photoItem) { _, item in Task { await loadPhoto(item) } }
    }

    private var privacyNote: some View {
        // Le chiffre est repris de la constante, pas recopié : si le rognage change un jour,
        // cette phrase ne peut pas devenir un mensonge.
        HZAvisDeFeuille(texte: Accord.selon(
            f: String(localized: "Les \(Int(RouteGeometry.sharingTrimMeters)) premiers et derniers mètres sont retirés avant l'envoi : personne ne verra d'où tu es partie ni où tu es rentrée. C'est le tracé ci-dessus qui sera publié, pas celui que tu as couru."),
            m: String(localized: "Les \(Int(RouteGeometry.sharingTrimMeters)) premiers et derniers mètres sont retirés avant l'envoi : personne ne verra d'où tu es parti ni où tu es rentré. C'est le tracé ci-dessus qui sera publié, pas celui que tu as couru.")),
                        graisse: .medium)
    }

    private var tooShortNote: some View {
        HZAvisDeFeuille(texte: String(localized: "Cette sortie est trop courte pour être partagée : une fois les extrémités retirées, il ne resterait pas assez de tracé pour être utile."),
                        graisse: .medium)
    }

    /// « Boucle de 8 km » — un nom déjà rempli, que l'utilisatrice n'a qu'à corriger. Un champ vide
    /// est ce qui fait abandonner une publication.
    private var placeholderName: String {
        let km = Int(run.distanceKm.rounded())
        if let locality { return String(localized: "\(km) km à \(locality)") }
        return String(localized: "Parcours de \(km) km")
    }

    // MARK: - Actions

    /// Le géocodage inverse se fait ICI, sur l'appareil, et seul le nom de la ville part au
    /// serveur. Ça évite un fournisseur de géocodage côté serveur, sa clé d'API et son coût par
    /// requête — et ça n'envoie pas une coordonnée de plus que nécessaire.
    private func resolveLocality() async {
        guard let first = payload?.points.first else { return }
        let location = CLLocation(latitude: first.lat, longitude: first.lng)
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first else { return }
        locality = placemark.locality ?? placemark.administrativeArea
        countryCode = placemark.isoCountryCode
        if name.isEmpty || name == String(localized: "Parcours de \(Int(run.distanceKm.rounded())) km") {
            name = placeholderName
        }
    }

    /// Redimensionnée et encodée dès la sélection : 1080 px sur le côté long, qualité 0,6, ce qui
    /// tient sous les 500 ko que `api/activities/routePhoto` accepte tout en restant net en plein
    /// écran. Même chaîne que la photo de profil, à l'échelle près.
    ///
    /// L'ATTENTE SE VOIT, ET L'ÉCHEC SE DIT.
    ///
    /// Le bouton affichait « Ajouter une photo » pendant tout le temps du décodage, du
    /// redimensionnement et de l'encodage — une à deux secondes sur une photo de douze
    /// mégapixels, pendant lesquelles l'écran ne bougeait pas. Le geste naturel est alors
    /// d'appuyer une seconde fois.
    ///
    /// Et les trois `guard` sortaient en silence. Une photo restée sur iCloud, un format que
    /// `UIImage` ne sait pas lire, un encodage qui échoue : dans les trois cas, rien ne se
    /// passait et rien ne le disait — exactement le défaut du chantier 2, sur un autre écran.
    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        chargementPhoto = true
        errorMessage = nil
        defer { chargementPhoto = false }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            errorMessage = String(localized: "Impossible de lire cette photo. Choisis-en une autre.")
            return
        }
        let resized = image.resized(maxDimension: HZFeuillesDuFil.coteMaxDUnePhoto)
        guard let jpeg = resized.jpegData(compressionQuality: HZFeuillesDuFil.qualiteDUnePhoto) else {
            errorMessage = String(localized: "Impossible de préparer cette photo. Choisis-en une autre.")
            return
        }
        photoPreview = resized
        photoDataURI = "data:image/jpeg;base64," + jpeg.base64EncodedString()
    }

    private func publish() {
        guard canPublish else { return }
        isPublishing = true
        errorMessage = nil
        let service = ClubService(auth: appState.auth)
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                let id = try await service.publishRoute(
                    name: trimmedName,
                    notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                    route: run.route,
                    distanceKm: run.distanceKm,
                    elevationGainM: run.elevationGainM,
                    durationSeconds: run.durationSeconds,
                    locality: locality,
                    countryCode: countryCode
                )
                // La photo part APRÈS, et son échec ne remet pas la publication en cause : un
                // itinéraire sans photo reste utile, une publication perdue ne l'est pas.
                if let id, let photoDataURI {
                    _ = try? await service.setRoutePhoto(routeId: id, dataURI: photoDataURI)
                }
                isPublishing = false
                appState.toast(String(localized: "Itinéraire publié"))
                onPublished(id)
                dismiss()
            } catch {
                isPublishing = false
                errorMessage = PanneReseau.phrase(pour: error)
            }
        }
    }
}
