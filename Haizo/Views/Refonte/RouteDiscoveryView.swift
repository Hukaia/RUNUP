import SwiftUI
import MapKit
import UIKit

/// LA CARTE DES ITINÉRAIRES : la vraie carte en plein écran, une pilule flottante en haut, et une
/// feuille blanche en bas (coins de 30) où les itinéraires défilent en cartes horizontales — la grande
/// carte d'Explorer, en plus étroite.
///
/// Rien de la logique ne bouge : la recherche suit la zone visible, les filtres de distance, la
/// permission de localisation, la feuille de détail d'un itinéraire.
struct RouteDiscoveryView: View {
    @Environment(AppState.self) private var appState

    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var searchedRegion: MKCoordinateRegion?
    @State private var routes: [SharedRoute] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var selected: SharedRoute?
    @State private var filter: DistanceFilter = .all
    @State private var permission = LocationPermission()
    @Environment(\.openURL) private var openURL

    private enum DistanceFilter: String, CaseIterable, Identifiable {
        case all, short, ten, long
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all: return String(localized: "Toutes")
            case .short: return String(localized: "≤ 6 km")
            case .ten: return String(localized: "6–15 km")
            case .long: return String(localized: "15 km +")
            }
        }
        var bounds: (min: Double?, max: Double?) {
            switch self {
            case .all: return (nil, nil)
            case .short: return (nil, HZHub.distanceCourte)
            case .ten: return (HZHub.distanceCourte, HZHub.distanceLongue)
            case .long: return (HZHub.distanceLongue, nil)
            }
        }
    }

    /// Faut-il proposer de chercher ici ? Oui dès que la carte a bougé de plus d'un tiers de la zone
    /// déjà cherchée : plus tôt, le bouton clignoterait à chaque effleurement.
    private var regionMovedSinceSearch: Bool {
        guard let visible = visibleRegion else { return false }
        guard let searched = searchedRegion else { return true }
        let dLat = abs(visible.center.latitude - searched.center.latitude)
        let dLng = abs(visible.center.longitude - searched.center.longitude)
        return dLat > searched.span.latitudeDelta / HZHub.tiers || dLng > searched.span.longitudeDelta / HZHub.tiers
    }

    var body: some View {
        ZStack(alignment: .top) {
            carte
            VStack(spacing: 0) {
                commandes
                Spacer(minLength: 0)
                feuille
            }
        }
        .background(HZCouleur.blanc)
        .sheet(item: $selected) { route in
            RouteDetailSheet(route: route) { updated in
                if let index = routes.firstIndex(where: { $0.id == updated.id }) { routes[index] = updated }
            }
            .hzFeuille()
        }
        .task { if routes.isEmpty { await search() } }
    }

    // MARK: - La carte

    private var carte: some View {
        Map(position: $camera) {
            UserAnnotation()
            ForEach(routes) { route in
                let coordinates = route.drawableCoordinates
                if coordinates.count > 1 {
                    MapPolyline(coordinates: coordinates)
                        .stroke(HZCouleur.accent,
                                style: StrokeStyle(lineWidth: route.id == selected?.id ? HZHub.traitDeLaCarteChoisie
                                                                                       : HZHub.traitDeLaCarte,
                                                   lineCap: .round, lineJoin: .round))
                }
                Annotation(route.name, coordinate: route.startCoordinate) {
                    Button { selected = route } label: {
                        Text(route.distanceKm.map { String(format: "%.0f", $0) } ?? "?")
                            .hzTexte(.c13, .gras, tabulaire: true)
                            .foregroundStyle(HZCouleur.blanc)
                            .frame(width: HZHub.cotePuce, height: HZHub.cotePuce)
                            .background(Circle().fill(HZCouleur.encre))
                            .overlay(Circle().strokeBorder(HZCouleur.blanc, lineWidth: HZHub.liseDesAvatars))
                            .frame(width: HZBoutonRond.zoneTactile, height: HZBoutonRond.zoneTactile)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(route.name)
                }
            }
        }
        .mapControls {
            if permission.isGranted { MapUserLocationButton() }
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            visibleRegion = context.region
        }
        .task { if !Demonstration.enCours { permission.requestIfNeeded() } }
        .ignoresSafeArea()
    }

    // MARK: - La pilule flottante

    private var commandes: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            HStack(spacing: HZEspace.entreCommandes) {
                HZBoutonRond(dessin: .retour, nom: String(localized: "Retour"), diametre: .filtre,
                             fond: HZCouleur.blanc, couleur: HZCouleur.encre,
                             trait: HZBoutonRond.traitDuRetour) { appState.go(.profile) }
                    .shadow(color: HZCouleur.encre.opacity(HZHub.opaciteDeLOmbre), radius: HZHub.flouDeLOmbre,
                            y: HZHub.decalageDeLOmbre)
                pilule
            }
            if permission.isRefused {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                } label: {
                    Text("Localisation refusée · Activer")
                        .hzTexte(.c14, .semi)
                        .foregroundStyle(HZCouleur.encre)
                        .padding(.horizontal, HZEspace.groupe)
                        .frame(height: HZDiametre.filtre.rawValue)
                        .background(HZCouleur.blanc, in: Capsule())
                        .shadow(color: HZCouleur.encre.opacity(HZHub.opaciteDeLOmbre), radius: HZHub.flouDeLOmbre,
                                y: HZHub.decalageDeLOmbre)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, HZEspace.marge)
        .padding(.top, HZEspace.haut)
    }

    /// Chercher ici : la pilule dit où l'on en est (la recherche tourne, la carte a bougé, ce qu'on a
    /// trouvé) et lance la recherche quand on la touche.
    private var pilule: some View {
        Button {
            Haptics.selection()
            Task { await search() }
        } label: {
            HStack(spacing: HZEspace.entrePilules) {
                HZIcone(dessin: .recherche, cote: HZHub.loupe, trait: HZAmorceDeRecherche.trait,
                        couleur: HZCouleur.encre)
                Text(libelleDeLaPilule)
                    .hzTexte(.c15, .semi)
                    .foregroundStyle(HZCouleur.encre)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, HZAmorceDeRecherche.marge)
            .frame(height: HZDiametre.filtre.rawValue)
            .background(HZCouleur.blanc, in: Capsule())
            .shadow(color: HZCouleur.encre.opacity(HZHub.opaciteDeLOmbre), radius: HZHub.flouDeLOmbre,
                    y: HZHub.decalageDeLOmbre)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private var libelleDeLaPilule: String {
        if isLoading { return String(localized: "Recherche des itinéraires…") }
        if regionMovedSinceSearch { return String(localized: "Chercher dans cette zone") }
        return Pluriel.choisir(routes.count,
                               String(localized: "\(routes.count) itinéraire par ici"),
                               String(localized: "\(routes.count) itinéraires par ici"))
    }

    // MARK: - La feuille

    private var feuille: some View {
        VStack(alignment: .leading, spacing: HZEspace.sousUnTitre) {
            filtres
            contenu
        }
        .padding(.top, HZEspace.marge)
        .padding(.bottom, HZHub.basDePage)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HZCouleur.blanc, in: UnevenRoundedRectangle(topLeadingRadius: HZRayon.feuille,
                                                                topTrailingRadius: HZRayon.feuille,
                                                                style: .circular))
    }

    private var filtres: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HZEspace.entrePilules) {
                ForEach(DistanceFilter.allCases) { option in
                    HZFiltre(libelle: option.label, actif: filter == option, fond: .clair) {
                        filter = option
                        Haptics.selection()
                        Task { await search() }
                    }
                }
            }
            .padding(.horizontal, HZEspace.marge)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var contenu: some View {
        if isLoading && routes.isEmpty {
            phrase(String(localized: "Recherche des itinéraires…"))
        } else if let loadError {
            phrase(String(localized: "Impossible de charger les itinéraires — \(loadError)."))
        } else if routes.isEmpty {
            phrase(Accord.selon(
                f: String(localized: "Personne n'a encore partagé d'itinéraire par ici. Publie le tien après ta prochaine sortie et tu seras la première."),
                m: String(localized: "Personne n'a encore partagé d'itinéraire par ici. Publie le tien après ta prochaine sortie et tu seras le premier.")))
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: HZEspace.entreTuiles) {
                    ForEach(routes) { route in
                        carteDItineraire(route)
                    }
                }
                .padding(.horizontal, HZEspace.marge)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func phrase(_ texte: String) -> some View {
        HZPhrase(texte: texte).padding(.horizontal, HZEspace.marge)
    }

    private func carteDItineraire(_ route: SharedRoute) -> some View {
        let points = route.drawableCoordinates.map { (lat: $0.latitude, lng: $0.longitude) }
        return VStack(alignment: .leading, spacing: HZExplorer.sousLaCarte) {
            HZCarteDItineraire(distance: route.distanceKm.map { Distances.km($0) } ?? "—",
                               pastille: nil,
                               trace: HZMiniatureDeSortie.normaliser(points) ?? [],
                               nom: route.name) { selected = route }
            VStack(alignment: .leading, spacing: 0) {
                Text(route.name).hzTexte(.c15, .gras).foregroundStyle(HZCouleur.encre)
                if !route.subtitleLine.isEmpty {
                    Text(route.subtitleLine)
                        .hzTexte(.c13, .medium)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                }
            }
            .lineLimit(1)
        }
        .frame(width: HZHub.largeurDeLaCarteDItineraire, alignment: .leading)
    }

    // MARK: - La recherche

    private func search() async {
        // En démonstration, ce que la graine a posé : il n'y a pas de serveur à interroger.
        if Demonstration.enCours {
            routes = appState.cachedExplorerRoutes ?? []
            if let cadre = HZHub.cadre(de: routes.map(\.startCoordinate)) { camera = .region(cadre) }
            searchedRegion = visibleRegion
            isLoading = false
            return
        }
        guard let region = visibleRegion ?? camera.region else { return }
        isLoading = true
        loadError = nil
        // On cherche un peu plus large que ce qui est à l'écran : l'itinéraire à cheval sur le bord
        // fait partie de la zone.
        let latPad = region.span.latitudeDelta * HZHub.debordDeLaZone
        let lngPad = region.span.longitudeDelta * HZHub.debordDeLaZone
        let bounds = filter.bounds
        do {
            let found = try await ClubService(auth: appState.auth).fetchRoutesNearby(
                minLat: region.center.latitude - latPad,
                maxLat: region.center.latitude + latPad,
                minLng: region.center.longitude - lngPad,
                maxLng: region.center.longitude + lngPad,
                distMin: bounds.min,
                distMax: bounds.max
            )
            routes = found
            searchedRegion = region
        } catch {
            loadError = PanneReseau.motif(pour: error)
        }
        isLoading = false
    }
}

@Observable
final class LocationPermission: NSObject {
    private let manager = CLLocationManager()
    private(set) var status: CLAuthorizationStatus = .notDetermined
    /// Où elle est, une fois demandé (`requestPosition`) : un seul relevé, pas de suivi. Sert Explorer à
    /// chercher des itinéraires autour d'elle.
    private(set) var coordinate: CLLocationCoordinate2D?

    /// `nonisolated`, et le réglage repoussé sur l'acteur principal — voir le raisonnement écrit
    /// en long dans `LocationService.init`. C'est ici que le compilateur a refusé net
    /// l'affectation depuis un contexte non isolé, et il avait raison.
    nonisolated override init() {
        super.init()
        surLActeurPrincipal { [self] in reglageInitial() }
    }

    private func reglageInitial() {
        manager.delegate = self
        status = manager.authorizationStatus
    }

    var isGranted: Bool { status == .authorizedWhenInUse || status == .authorizedAlways }
    var isRefused: Bool { status == .denied || status == .restricted }

    /// Ne redemande jamais : passé le premier refus, iOS n'affiche plus rien et l'appel est un
    /// coup dans l'eau. C'est aux Réglages de reprendre la main à partir de là.
    func requestIfNeeded() {
        guard status == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    fileprivate func majDuStatut() {
        status = manager.authorizationStatus
    }

    /// Un relevé de position, si l'autorisation le permet. Un seul : le résultat arrive dans
    /// `coordinate`.
    func requestPosition() {
        guard isGranted else { return }
        manager.requestLocation()
    }

    fileprivate func majDeLaPosition(latitude: Double, longitude: Double) {
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension LocationPermission: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        surLActeurPrincipal { [self] in majDuStatut() }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let derniere = locations.last else { return }
        let latitude = derniere.coordinate.latitude
        let longitude = derniere.coordinate.longitude
        surLActeurPrincipal { [self] in majDeLaPosition(latitude: latitude, longitude: longitude) }
    }

    /// Obligatoire dès qu'on appelle `requestLocation`. Un échec laisse `coordinate` vide : Explorer le
    /// dit honnêtement au lieu de deviner où elle est.
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

