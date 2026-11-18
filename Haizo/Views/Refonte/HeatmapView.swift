import SwiftUI
import SwiftData
import MapKit

/// "Mes routes" — every GPS-tracked run overlaid on one map, Strava-heatmap-style but purely
/// personal: no shared segments, no comparison with anyone else, just where she's already run and
/// where she hasn't. Built from `RunRecord.route` already stored for the share-card trace and
/// History's mini-maps — no new data collection needed.
struct HeatmapView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \RunRecord.date, order: .reverse) private var runs: [RunRecord]

    @State private var parcours: [Parcours] = []
    @State private var camera: MapCameraPosition = .automatic
    @State private var periode: HZPeriode = .year
    @State private var prepare = false

    private struct Parcours: Identifiable {
        let id: PersistentIdentifier
        let points: [CLLocationCoordinate2D]
        let kilometres: Double
    }

    /// Le début de la période, sur l'horloge de la scène : cet écran est photographié.
    private var debut: Date {
        Calendar.current.date(byAdding: .day, value: -periode.days, to: Demonstration.maintenant) ?? .distantPast
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
        .task(id: "\(runs.count)-\(periode.days)") {
            preparer()
            prepare = true
        }
    }

    // MARK: - La carte

    /// Les tracés dans la couleur d'accent, translucides : là où l'on repasse, ils s'ajoutent, et la
    /// carte devient la carte de chaleur.
    private var carte: some View {
        Map(position: $camera) {
            ForEach(parcours) { trace in
                MapPolyline(coordinates: trace.points)
                    .stroke(HZCouleur.accent.opacity(HZHub.opaciteDUnTrace),
                            style: StrokeStyle(lineWidth: HZHub.traitDeLaCarte, lineCap: .round, lineJoin: .round))
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .ignoresSafeArea()
    }

    // MARK: - Le retour et les périodes

    private var commandes: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            HZBoutonRond(dessin: .retour, nom: String(localized: "Retour"), diametre: .filtre,
                         fond: HZCouleur.blanc, couleur: HZCouleur.encre,
                         trait: HZBoutonRond.traitDuRetour) { appState.go(.stats) }
                .shadow(color: HZCouleur.encre.opacity(HZHub.opaciteDeLOmbre), radius: HZHub.flouDeLOmbre,
                        y: HZHub.decalageDeLOmbre)
            HStack(spacing: HZEspace.entrePilules) {
                ForEach(HZPeriode.allCases) { valeur in
                    HZFiltre(libelle: valeur.libelle, actif: periode == valeur,
                             margeVerticale: HZFiltre.margeDePeriode) {
                        Haptics.selection()
                        periode = valeur
                    }
                }
            }
        }
        .padding(.horizontal, HZEspace.marge)
        .padding(.top, HZEspace.haut)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - La petite feuille, avec deux chiffres

    private var feuille: some View {
        VStack(alignment: .leading, spacing: HZEspace.entreTuiles) {
            if prepare && parcours.isEmpty {
                HZPhrase(texte: String(localized: "La carte se remplit après ta première course suivie au GPS."),
                         titre: String(localized: "Aucun parcours"))
            } else {
                Text("Mes routes")
                    .hzAffichage(.section)
                    .foregroundStyle(HZCouleur.encre)
                HStack(spacing: HZEspace.entreTuiles) {
                    HZTuileChiffre(libelle: Pluriel.choisir(parcours.count,
                                                            String(localized: "parcours tracké"),
                                                            String(localized: "parcours trackés")),
                                   valeur: "\(parcours.count)")
                    HZTuileChiffre(libelle: String(localized: "Kilomètres"),
                                   valeur: String(format: "%.0f", locale: Locale.current,
                                                  parcours.reduce(0) { $0 + $1.kilometres }))
                }
            }
        }
        .padding(.horizontal, HZEspace.marge)
        .padding(.top, HZEspace.marge)
        .padding(.bottom, HZHub.basDePage)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HZCouleur.blanc, in: UnevenRoundedRectangle(topLeadingRadius: HZRayon.feuille,
                                                                topTrailingRadius: HZRayon.feuille,
                                                                style: .circular))
    }

    private func preparer() {
        var minLat = Double.infinity, maxLat = -Double.infinity
        var minLng = Double.infinity, maxLng = -Double.infinity
        var traces: [Parcours] = []

        for run in runs where debut < run.date {
            let route = run.route
            guard route.count > 1 else { continue }
            var points: [CLLocationCoordinate2D] = []
            points.reserveCapacity(route.count)
            for point in route {
                minLat = min(minLat, point.lat); maxLat = max(maxLat, point.lat)
                minLng = min(minLng, point.lng); maxLng = max(maxLng, point.lng)
                points.append(CLLocationCoordinate2D(latitude: point.lat, longitude: point.lng))
            }
            traces.append(Parcours(id: run.persistentModelID, points: points, kilometres: run.distanceKm))
        }

        parcours = traces
        guard !traces.isEmpty, minLat.isFinite, minLng.isFinite else {
            return
        }
        camera = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / HZHub.moitieDeLEtendue,
                                           longitude: (minLng + maxLng) / HZHub.moitieDeLEtendue),
            span: MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * HZHub.margeDuCadrage, HZHub.cadrageMinimal),
                                   longitudeDelta: max((maxLng - minLng) * HZHub.margeDuCadrage, HZHub.cadrageMinimal))
        ))
    }
}
