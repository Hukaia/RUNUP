import SwiftUI
import UIKit
import SwiftData
import CoreLocation

/// LE RÉSUMÉ DE LA SORTIE, refait d'après le canvas « Résumé » : la carte du tracé en haut avec trois
/// commandes, et la feuille blanche dessous : la date, la distance en très grand, le titre, deux
/// tuiles, la phrase du record, puis « Partager » et « Détail ».
///
/// C'est aussi l'entrée de la mécanique du plan adaptatif : donner son ressenti recalcule la séance
/// suivante. Le canvas n'a pas ce bouton ; il reste, en accent et pleine largeur, au-dessus de
/// « Partager » : c'est l'action qui compte de l'écran, et sa seule grande surface d'accent. Tout ce
/// que l'écran faisait reste :
/// les splits, le profil d'élévation, la carte à partager et ses styles, la vidéo, l'export GPX, la
/// publication de l'itinéraire. Ce qui change est ce qu'on voit, pas ce qu'on calcule.
struct RecapView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \RunRecord.date) private var allRuns: [RunRecord]
    /// Set when opened from History to browse an old run: nil for the normal just-finished flow, which
    /// reads `appState.lastRun` instead. Le ressenti ne s'applique qu'au palier de difficulté de la
    /// semaine EN COURS (voir `DebriefSheet`/`AdaptivePlanEngine.tierDelta`) : redonner le sien sur une
    /// course d'une semaine passée fausserait en silence l'adaptation de celle-ci. Le bouton est donc
    /// masqué dès que cette valeur est posée.
    var historicalRun: RunRecord? = nil
    @State private var showDebrief = false
    @State private var fermetureSansRessenti = false
    /// Le tracé en grand. Voir `RouteZoomView` : la carte du fond est inerte par nécessité, et c'est
    /// cette feuille-là qui la rend manipulable sans disputer le défilement.
    @State private var tracePleinEcran = false
    /// La carte de partage (le tracé et trois chiffres sur fond transparent, voir `RunShareCardView`),
    /// rendue hors écran une fois peu après l'apparition : une feuille de partage veut un objet prêt.
    @State private var shareImage: Image?
    @State private var shareRenderFailed = false
    /// Fait balayer les barres des splits l'une après l'autre : posé à l'apparition.
    @State private var splitsRevealed = false
    /// La couleur du texte de la carte de partage, rendue à nouveau sur-le-champ quand on en touche une.
    @State private var shareTextColor: ShareCardTextColor = .blanc
    @State private var showPublishRoute = false

    // MARK: La vidéo de la course
    //
    /// Le fichier fabriqué, quand il l'est. Un fichier temporaire : la feuille de partage le recopie
    /// où il faut.
    @State private var videoURL: URL?
    @State private var videoAvancement: Double = 0
    /// Gardée pour pouvoir l'ANNULER en quittant l'écran : trois cent soixante rasterisations
    /// continueraient sinon à tourner derrière un écran que personne ne regarde plus.
    @State private var videoEnCours: Task<Void, Never>?

    private var run: RunRecord? { historicalRun ?? appState.lastRun }
    private var isHistorical: Bool { historicalRun != nil }

    /// Closes back to wherever this was opened from: a sheet over History just dismisses, while the
    /// just-finished flow (presented via `appState.go(.recap)`, not a sheet) has nothing to dismiss and
    /// needs the tab switched back to Home instead.
    private func closeRecap() {
        if isHistorical {
            dismiss()
        } else if run?.debriefedAt == nil {
            // FERMER SANS RESSENTI N'EST PAS ANODIN, ET RIEN NE LE DISAIT. La sortie est
            // enregistrée, mais ses XP, la série et la publication au club ne partent qu'au
            // ressenti (`DebriefSheet.valider`). La croix ramenait à l'accueil sans un mot, et le
            // rattrapage, dans l'historique, ne dure que jusqu'à la fin de la semaine.
            fermetureSansRessenti = true
        } else {
            appState.go(.home)
        }
    }

    /// A genuine personal record vs every OTHER real run on file — pace (2 km+ runs only, same
    /// honest floor `StatsView.bestRecentPerformance` uses so a short jog can't "beat" a real
    /// long run's pace by comparison quirk) or raw distance. Never true against an empty history:
    /// there's nothing to have beaten yet, so a first-ever run is just a first run, not a record.
    private func isPersonalRecord(_ run: RunRecord) -> Bool {
        // Dans la MÊME discipline : à 25 km/h, la première sortie vélo battrait d'un coup le
        // record d'allure et celui de distance, et aucune course ne les reprendrait jamais.
        let priorRuns = allRuns.only(run.discipline).filter { $0 !== run }
        let priorBestPace = priorRuns.filter { $0.distanceKm >= HZResume.distanceMinimaleDUnRecord }.compactMap { PaceModel.parseSecPerKm($0.avgPace) }.min()
        let priorBestDistance = priorRuns.map(\.distanceKm).max() ?? 0
        var isPaceRecord = false
        if run.distanceKm >= HZResume.distanceMinimaleDUnRecord, let pace = PaceModel.parseSecPerKm(run.avgPace), let priorBestPace {
            isPaceRecord = pace < priorBestPace
        }
        let isDistanceRecord = run.distanceKm > 0 && priorBestDistance > 0 && run.distanceKm > priorBestDistance
        return isPaceRecord || isDistanceRecord
    }

    /// A best time on a familiar loop, even when it's nowhere near an all-time PR — "same route"
    /// is a real (if approximate) match: starts within 150 m of each other and total distance
    /// within 15%, both GPS facts, not a guess about which streets were actually run.
    private func isRoutePersonalRecord(_ run: RunRecord) -> Bool {
        guard let first = run.route.first, run.distanceKm >= 1, let pace = PaceModel.parseSecPerKm(run.avgPace) else { return false }
        let startLocation = CLLocation(latitude: first.lat, longitude: first.lng)
        // Dans la même discipline : une sortie vélo partie du même trottoir, sur une distance
        // voisine, passerait le test de « même itinéraire » et raflerait le record à 25 km/h —
        // qu'aucune course ne reprendrait jamais.
        let similarRuns = allRuns.only(run.discipline).filter { other in
            guard other !== run, let otherFirst = other.route.first, other.distanceKm > 0 else { return false }
            let start = CLLocation(latitude: otherFirst.lat, longitude: otherFirst.lng)
            guard startLocation.distance(from: start) < HZResume.rayonDuMemeDepart else { return false }
            let ratio = other.distanceKm / run.distanceKm
            return ratio > HZResume.rapportMinimal && ratio < HZResume.rapportMaximal
        }
        guard let priorBestPace = similarRuns.compactMap({ PaceModel.parseSecPerKm($0.avgPace) }).min() else { return false }
        return pace < priorBestPace
    }

    private enum RecordKind { case overall, route }
    private func recordKind(for run: RunRecord) -> RecordKind? {
        if isPersonalRecord(run) { return .overall }
        if isRoutePersonalRecord(run) { return .route }
        return nil
    }

    // MARK: - La page

    var body: some View {
        if let run {
            ScrollView {
                VStack(alignment: .leading, spacing: -HZRayon.feuille) {
                    carte(run)
                    feuille(run)
                }
            }
            .scrollIndicators(.hidden)
            .background(HZCouleur.blanc)
            .ignoresSafeArea(edges: .top)
            .statusBarHidden()
            .sheet(isPresented: $showPublishRoute) {
                PublishRouteSheet(run: run)
                    .hzFeuille(detents: [.large], gereSonBas: true)
            }
            .sheet(isPresented: $showDebrief) {
                DebriefSheet(run: run)
                    .hzFeuille(detents: [.medium, .large], gereSonBas: true)
            }
            .confirmationDialog("Fermer sans donner ton ressenti ?", isPresented: $fermetureSansRessenti,
                                titleVisibility: .visible) {
                Button("Donner mon ressenti") { showDebrief = true }
                Button("Fermer quand même") { appState.go(.home) }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Ta sortie est enregistrée. Tes XP, ta série et la publication au club attendent ton ressenti : tu peux encore le donner depuis l'historique, jusqu'à dimanche.")
            }
            // UN ÉCRAN ENTIER, ET PAS UNE FEUILLE. Une feuille se referme en la tirant vers le bas, et
            // c'est exactement le geste qu'on fait pour déplacer une carte : les deux se disputeraient
            // le même glissement, et tirer la carte vers le bas refermerait l'écran qu'on vient d'ouvrir.
            .fullScreenCover(isPresented: $tracePleinEcran) {
                RouteZoomView(run: run)
            }
            .onAppear {
                splitsRevealed = true
                if recordKind(for: run) != nil { Haptics.success() }
                guard shareImage == nil else { return }
                // `ImageRenderer` vit sur l'acteur principal : le rendu ne peut pas en sortir, mais il
                // n'a pas à tourner pendant la transition d'entrée, quand il faisait saccader l'écran à
                // la fin de chaque course.
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(HZResume.attenteAvantLeRendu))
                    renderShareCard(for: run)
                }
            }
            // `ImageRenderer` vit sur l'acteur principal : trois cent soixante rasterisations feraient
            // dix secondes d'écran qui répond mal, pour un fichier que personne n'attend. Le rendu sait
            // s'annuler (voir `RunVideoRenderer`), il suffisait de le lui demander.
            .onDisappear { videoEnCours?.cancel() }
        } else {
            Color.clear.onAppear { closeRecap() }
        }
    }

    // MARK: - La carte, avec ses trois commandes

    private func carte(_ run: RunRecord) -> some View {
        ZStack(alignment: .top) {
            HZCouleur.surfaceClaire
            if !run.route.isEmpty {
                RunRouteMapView(route: run.route)
            } else {
                // Pas de GPS derrière cette sortie (saisie à la main, « marquer comme faite ») : une forme
                // décorative plutôt qu'une carte vide.
                Canvas { context, size in
                    var path = Path()
                    path.move(to: CGPoint(x: size.width * HZResume.departX, y: size.height * HZResume.departY))
                    path.addCurve(
                        to: CGPoint(x: size.width * HZResume.arriveeX, y: size.height * HZResume.arriveeY),
                        control1: CGPoint(x: size.width * HZResume.controleUnX, y: size.height * HZResume.controleUnY),
                        control2: CGPoint(x: size.width * HZResume.controleDeuxX, y: size.height * HZResume.controleDeuxY)
                    )
                    context.stroke(path, with: .color(HZCouleur.accent),
                                   style: StrokeStyle(lineWidth: HZLive.traitDuTrace, lineCap: .round))
                }
            }
            HStack {
                HZBoutonRond(dessin: .fermer, nom: String(localized: "Fermer"), diametre: .outil,
                             fond: HZCouleur.noir) { closeRecap() }
                Spacer(minLength: 0)
                Text("Sortie terminée")
                    .hzTexte(.c14, .gras)
                    .foregroundStyle(HZCouleur.blanc)
                    .padding(.horizontal, HZEspace.groupe)
                    .frame(height: HZDiametre.outil.rawValue)
                    .background(HZCouleur.noir, in: Capsule())
                Spacer(minLength: 0)
                if !run.route.isEmpty {
                    Button { tracePleinEcran = true } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(HZPolice.texte(.c14, .gras))
                            .foregroundStyle(HZCouleur.blanc)
                            .frame(width: HZDiametre.outil.rawValue, height: HZDiametre.outil.rawValue)
                            .background(HZCouleur.noir, in: Circle())
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Agrandir le tracé"))
                } else {
                    // Rien à agrandir : une place vide garde le titre au centre.
                    Color.clear.frame(width: HZDiametre.outil.rawValue, height: HZDiametre.outil.rawValue)
                }
            }
            .padding(.top, HZEspace.haut)
            .padding(.horizontal, HZEspace.marge)
        }
        .frame(maxWidth: .infinity)
        .frame(height: HZResume.carte)
        .clipped()
    }

    // MARK: - La feuille

    private func feuille(_ run: RunRecord) -> some View {
        HZFeuille(retrait: .ample) {
            Text(dateDeLaSortie(run))
                .hzTexte(.c15, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)
            HStack(alignment: .firstTextBaseline, spacing: HZEspace.entreCommandes) {
                Text(verbatim: String(format: "%.2f", locale: Locale.current, run.distanceKm))
                    .hzAffichage(.resume)
                    .hzVedette()
                    .lineLimit(1)
                    .minimumScaleFactor(HZResume.reductionDeLaDistance)
                    .padding(.leading, -HZResume.debordDeLaDistance)
                Text(verbatim: "km").hzTexte(.c20, .gras)
            }
            .padding(.top, HZResume.sousLaDate)
            Text(verbatim: run.titreAffiche)
                .hzTexte(.c20, .gras)
                .padding(.top, HZResume.sousLaDistance)

            mesures(run)
                .padding(.top, HZResume.sousLeTitre)

            if let kind = recordKind(for: run) {
                recordBanner(kind)
                    .padding(.top, HZEspace.entreTuiles)
            }

            actions(run)
                .padding(.top, HZEspace.groupe)

            // Seulement quand de vrais temps par km existent : une saisie à la main ou une sortie GPS de
            // moins d'un kilomètre n'en a pas, et `buildRunRecord` n'en fabrique plus.
            if !run.splits.isEmpty {
                HZTitreDeSection(titre: String(localized: "Splits par km"))
                    .padding(.top, HZEspace.entreSections)
                HZSplits(splits: run.splits, revealed: splitsRevealed, reduceMotion: reduceMotion)
                    .padding(.top, HZEspace.sousUnTitre)
            }

            if ElevationProfileView.hasData(run.route) {
                HZTitreDeSection(titre: String(localized: "Profil d'élévation"))
                    .padding(.top, HZEspace.entreSections)
                elevationCard(run)
                    .padding(.top, HZEspace.sousUnTitre)
            }

            partage(run)
                .padding(.top, HZEspace.entreSections)
        }
        .padding(.bottom, HZResume.basDePage)
    }

    private func dateDeLaSortie(_ run: RunRecord) -> String {
        // Capitale de début de phrase, posée par le format de la date : elle suit la langue.
        run.date.formatted(Date.FormatStyle(capitalizationContext: .beginningOfSentence)
            .weekday(.wide).day().month(.wide))
    }

    /// Toutes les mesures de la sortie dans UNE carte : allure et durée en grand, puis ce qui les complète
    /// sur une seconde rangée, séparées par un filet. Cinq boîtes de tailles différentes faisaient brouillon.
    private func mesures(_ run: RunRecord) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                cellule(run.discipline.seLitEnAllure ? String(localized: "Allure moyenne")
                                                      : String(localized: "Vitesse moyenne"),
                        run.rythmeEcrit, grande: true)
                filetVertical
                cellule(String(localized: "Durée"), PaceModel.formatDuration(Double(run.durationSeconds)), grande: true)
            }
            filetHorizontal
            HStack(spacing: 0) {
                cellule(String(localized: "FC moy."), run.avgHeartRate > 0 ? "\(run.avgHeartRate)" : "—", grande: false)
                filetVertical
                cellule("kcal", "\(run.kcal)", grande: false)
                filetVertical
                cellule("D+ (m)", run.elevationGainM > 0 ? "+\(run.elevationGainM)" : "—", grande: false)
            }
        }
        .background(HZCouleur.surfaceClaire, in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
        .opacity(splitsRevealed ? HZResume.opacitePleine : 0)
        .animation(reduceMotion ? nil : .easeOut(duration: HZResume.dureeDEntree), value: splitsRevealed)
    }

    private func cellule(_ libelle: String, _ valeur: String, grande: Bool) -> some View {
        VStack(alignment: .leading, spacing: HZLive.entreCibleEtValeur) {
            Text(libelle)
                .hzTexte(.c13, .semi)
                .foregroundStyle(HZCouleur.secondaireSurClair)
            Text(verbatim: valeur)
                .hzAffichage(grande ? .mesure : .chiffreDeLigne)
                .lineLimit(1)
                .minimumScaleFactor(HZLive.reductionDeLAllure)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, HZEspace.groupe)
        .padding(.vertical, HZEspace.tuile)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(libelle), \(valeur)")
    }

    private var filetHorizontal: some View {
        Rectangle().fill(HZCouleur.filetGroupe)
            .frame(height: HZMesuresDeLigne.filet)
    }

    private var filetVertical: some View {
        Rectangle().fill(HZCouleur.filetGroupe)
            .frame(width: HZMesuresDeLigne.filet)
            .padding(.vertical, HZEspace.tuile)
    }

    private func recordBanner(_ kind: RecordKind) -> some View {
        HStack(spacing: HZEspace.entreTuiles) {
            HZIcone(dessin: .trophee, cote: HZResume.coteDuTrophee, couleur: HZCouleur.blanc)
                .frame(width: HZResume.disqueDuTrophee, height: HZResume.disqueDuTrophee)
                .background(HZCouleur.encre, in: Circle())
            Text(kind == .overall ? String(localized: "Nouveau record personnel !")
                                  : String(localized: "Meilleur temps sur ce parcours !"))
                .hzParagraphe(.c14, .medium, interligne: HZLive.interligne)
                .foregroundStyle(HZCouleur.encre)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, HZEspace.groupe)
        .padding(.vertical, HZEspace.tuile)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HZCouleur.surfaceClaire, in: RoundedRectangle(cornerRadius: HZRayon.bandeau, style: .circular))
    }

    // MARK: Les actions

    /// Le ressenti d'abord : c'est l'action de l'ÉCRAN, celle qui nourrit le plan. Puis, comme au canvas,
    /// Partager et Détail.
    private func actions(_ run: RunRecord) -> some View {
        VStack(spacing: HZEspace.entreCommandes) {
            if !isHistorical {
                HZBoutonPilule(libelle: String(localized: "Donner mon ressenti"), hauteur: .grande,
                               fond: HZCouleur.accent, couleur: HZCouleur.encreSurAccent, etendu: true) {
                    Haptics.selection()
                    showDebrief = true
                }
                .accessibilityIdentifier("recap-ressenti")
            }
            HStack(spacing: HZEspace.entreCommandes) {
                partager
                if !isHistorical {
                    // « Historique », et non « Détail » : le détail de CETTE sortie (ses kilomètres, son
                    // dénivelé) est plus bas sur cet écran même, et le bouton ouvre la liste des sorties.
                    HZBoutonPilule(libelle: String(localized: "Historique"), hauteur: .grande,
                                   fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre) {
                        appState.go(.history)
                    }
                }
            }
        }
    }

    /// Le partage de la carte : actif quand l'image est rendue, éteint avant (la section est TOUJOURS
    /// là, pour qu'elle ne surgisse pas en cours de défilement sous le doigt).
    @ViewBuilder private var partager: some View {
        if let shareImage {
            ShareLink(item: shareImage, preview: SharePreview("Ma course sur Haizo", image: shareImage)) {
                libelleDePartage
            }
            .buttonStyle(.plain)
        } else {
            libelleDePartage.opacity(HZResume.opaciteEteinte)
        }
    }

    private var libelleDePartage: some View {
        HStack(spacing: HZEspace.entrePilules) {
            HZIcone(dessin: .partager, cote: HZResume.cotePartage, couleur: HZCouleur.blanc)
            Text("Partager").hzTexte(.c16, .gras).foregroundStyle(HZCouleur.blanc)
        }
        .frame(maxWidth: .infinity)
        .frame(height: HZHauteurDeBouton.grande.rawValue)
        .background(HZCouleur.encre, in: Capsule())
        .contentShape(Capsule())
    }

    // MARK: L'élévation

    private func elevationCard(_ run: RunRecord) -> some View {
        let altitudes = run.route.compactMap(\.altitude)
        let minAlt = altitudes.min() ?? 0
        let maxAlt = altitudes.max() ?? 0
        return VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            ElevationProfileView(route: run.route, lineColor: HZCouleur.accent)
                .frame(height: HZResume.hauteurDeLElevation)
                // La forme de la montée n'a rien à dire à VoiceOver : les chiffres dessous, eux, sont
                // combinés dans le libellé de cette carte.
                .accessibilityHidden(true)
            HStack {
                Text(verbatim: "\(Int(minAlt.rounded())) m")
                Spacer()
                Text("+\(run.elevationGainM) m D+").foregroundStyle(HZCouleur.encre)
                Spacer()
                Text(verbatim: "\(Int(maxAlt.rounded())) m")
            }
            .hzTexte(.c13, .semi, tabulaire: true)
            .foregroundStyle(HZCouleur.secondaireSurClair)
        }
        .padding(HZEspace.groupe)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HZCouleur.surfaceClaire, in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Profil d'élévation, de \(Int(minAlt.rounded())) à \(Int(maxAlt.rounded())) mètres, dénivelé positif \(run.elevationGainM) mètres"))
    }

    // MARK: La carte à partager

    /// L'aperçu est la carte telle qu'on la partagera : au format story, sur un fond qui la fait lire
    /// (elle est transparente : sombre pour le texte blanc, gris clair pour le noir). Les styles la
    /// rendent à nouveau.
    private func partage(_ run: RunRecord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HZTitreDeSection(titre: String(localized: "Partage ta course"))
            Group {
                if let shareImage {
                    shareImage
                        .resizable()
                        .scaledToFit()
                } else if shareRenderFailed {
                    // `ImageRenderer.uiImage` peut revenir nil sous pression mémoire : sans ceci le
                    // rond tournait sans fin et le partage restait éteint pour de bon.
                    VStack(spacing: HZEspace.entreCommandes) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(HZPolice.texte(.c20, .semi))
                            .accessibilityHidden(true)
                        HZBoutonPilule(libelle: String(localized: "Réessayer"), hauteur: .petite,
                                       fond: shareTextColor.encreSurApercu,
                                       couleur: shareTextColor.fondDeLApercu) { renderShareCard(for: run) }
                    }
                    .foregroundStyle(shareTextColor.encreSurApercu)
                } else {
                    ProgressView().tint(shareTextColor.encreSurApercu)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: HZResume.hauteurDeLApercu)
            .background(shareTextColor.fondDeLApercu, in: RoundedRectangle(cornerRadius: HZRayon.carteDuFil, style: .circular))
            .padding(.top, HZEspace.sousUnTitre)

            HStack(spacing: HZEspace.entrePilules) {
                ForEach(ShareCardTextColor.allCases) { style in
                    HZFiltre(libelle: style.label, actif: shareTextColor == style, fond: .clair) {
                        shareTextColor = style
                        renderShareCard(for: run)
                    }
                }
            }
            .padding(.top, HZEspace.entreCommandes)

            autresSorties(run)
                .padding(.top, HZEspace.groupe)
        }
    }

    /// Ce qu'on peut faire de plus de la sortie, en une seule liste : la vidéo, l'export, la publication.
    /// L'itinéraire n'est proposé que s'il y a vraiment quelque chose à publier : un compte pour en être
    /// l'autrice, et un tracé qui survit au rognage des extrémités. Une ligne qui annoncerait « trop court »
    /// serait une fausse promesse. Si rien n'est possible, la liste n'existe pas.
    @ViewBuilder
    private func autresSorties(_ run: RunRecord) -> some View {
        let video = peutFaireUneVideo(run)
        let gpx = GPXExporter.fileURL(for: run)
        let itineraire = appState.auth.isSignedIn && RouteGeometry.shareablePayload(run.route) != nil
        if video || gpx != nil || itineraire {
            VStack(spacing: 0) {
                if video {
                    ligneVideo(for: run)
                }
                if let gpx {
                    if video { filetHorizontal }
                    ShareLink(item: gpx) {
                        ligneDAction(dessin: .partager, titre: String(localized: "Exporter en GPX"))
                    }
                    .buttonStyle(.plain)
                }
                if itineraire {
                    if video || gpx != nil { filetHorizontal }
                    Button {
                        Haptics.selection()
                        showPublishRoute = true
                    } label: {
                        ligneDAction(dessin: .itineraire, titre: String(localized: "Publier l'itinéraire"))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Publier l'itinéraire"))
                }
            }
            .background(HZCouleur.surfaceClaire, in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
        }
    }

    private func ligneDAction(dessin: HZDessin, titre: String) -> some View {
        HStack(spacing: HZEspace.entreCommandes) {
            HZIcone(dessin: dessin, cote: HZResume.cotePartage, couleur: HZCouleur.encre)
            Text(titre)
                .hzTexte(.c16, .semi)
                .frame(maxWidth: .infinity, alignment: .leading)
            HZChevron()
        }
        .foregroundStyle(HZCouleur.encre)
        .padding(.horizontal, HZEspace.groupe)
        .frame(minHeight: HZResume.hauteurDeLaLigne)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// Trois états, une seule ligne : à faire, en train de se faire, à partager.
    @ViewBuilder
    private func ligneVideo(for run: RunRecord) -> some View {
        if let videoURL {
            ShareLink(item: videoURL) {
                ligneDAction(dessin: .partager, titre: String(localized: "Partager la vidéo"))
            }
            .buttonStyle(.plain)
        } else if videoEnCours != nil {
            VStack(alignment: .leading, spacing: HZEspace.entrePilules) {
                HStack(spacing: HZEspace.entreCommandes) {
                    HZIcone(dessin: .lecture, cote: HZResume.cotePartage, couleur: HZCouleur.encre)
                    Text(String(localized: "Je fabrique ta vidéo…")).hzTexte(.c16, .semi)
                }
                // L'avancement est réel, image par image : c'est la seule chose qui dise que l'app
                // travaille plutôt qu'elle ne bloque.
                Capsule()
                    .fill(HZCouleur.filetGroupe)
                    .frame(height: HZResume.hauteurDeLaJauge)
                    .overlay(alignment: .leading) {
                        GeometryReader { geo in
                            Capsule().fill(HZCouleur.accent)
                                .frame(width: geo.size.width * min(max(videoAvancement, 0), HZLive.progressionPleine))
                        }
                    }
            }
            .foregroundStyle(HZCouleur.encre)
            .padding(.horizontal, HZEspace.groupe)
            .padding(.vertical, HZMesuresDeLigne.margeDeSortie)
            .frame(minHeight: HZResume.hauteurDeLaLigne)
        } else {
            Button {
                Haptics.selection()
                lanceLaVideo(for: run)
            } label: {
                ligneDAction(dessin: .lecture, titre: String(localized: "Faire ma vidéo"))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Le rendu de la carte

    private func renderShareCard(for run: RunRecord) {
        let renderer = ImageRenderer(content: RunShareCardView(
            run: run,
            textColor: shareTextColor,
            isPersonalRecord: recordKind(for: run) != nil
        ))
        renderer.scale = HZResume.echelleDeRendu // retina-quality output at the card's 360×640pt logical size
        // `isOpaque` defaults to false, which is exactly what the card needs — anything left
        // unpainted in the view keeps its alpha in the rendered UIImage, so the PNG layers
        // cleanly over any photo.
        guard let uiImage = renderer.uiImage else {
            shareRenderFailed = true
            return
        }
        shareRenderFailed = false
        shareImage = Image(uiImage: uiImage)
    }

    /// Y a-t-il de quoi faire une vidéo ?
    ///
    /// Le MÊME test que la publication d'itinéraire juste au-dessus, et pour la même raison : un
    /// bouton qui ouvrirait un échec « ce parcours est trop court » serait une fausse promesse.
    /// On ne construit pas le déroulé pour le savoir — il rejouerait le dénivelé sur six cents
    /// points à chaque évaluation du corps de la vue.
    /// En paramètre et non lu sur `self` : `run` est OPTIONNEL ici — c'est la dernière course ou
    /// celle de l'historique — et le corps de la vue l'a déjà déballé là où ce test sert.
    private func peutFaireUneVideo(_ run: RunRecord) -> Bool {
        run.durationSeconds > 0 && run.distanceKm > 0
            && RouteGeometry.shareablePayload(run.route) != nil
    }

    private func lanceLaVideo(for run: RunRecord) {
        videoAvancement = 0
        // `@MainActor in`, comme le rendu de la carte juste au-dessus : `RunVideoRenderer` y est
        // isolé, et c'est là que vivent les `@State` qu'on écrit en chemin. Sans l'annotation,
        // la tâche n'hérite pas de l'acteur et chaque ligne après un `await` serait ailleurs.
        videoEnCours = Task { @MainActor in
            do {
                let url = try await RunVideoRenderer.fabrique(run) { part in
                    videoAvancement = part
                }
                videoURL = url
                Haptics.success()
                Analytics.shared.track(.runVideoMade, [
                    "discipline": .string(run.discipline.rawValue)
                ])
            } catch RunVideoRenderer.Echec.annulee {
                // Elle a quitté l'écran : rien à dire, et surtout pas une alerte sur un écran
                // qu'elle ne regarde plus.
            } catch {
                appState.toast(String(localized: "La vidéo n'a pas pu être fabriquée. Réessaie."))
            }
            videoEnCours = nil
        }
    }
}
