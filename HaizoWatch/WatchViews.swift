import SwiftUI

// Les jetons de la montre. Le système HZ de l'iPhone (`HZCouleur`, `HZPolice`, `HZForme`) vit dans
// `Haizo/DesignSystem`, que cette cible ne compile pas : elle n'a besoin que de cette poignée de
// valeurs, recopiées d'après lui, par rôle. Même règle que sur l'iPhone : des aplats, aucun
// dégradé, aucune ombre, aucun verre ; des pilules et des disques noirs ou blancs ; l'accent n'est
// qu'une touche — un anneau, une barre, un chiffre — jamais une surface.
//
// UNE VUE DE CE FICHIER NE PORTE PAS DE NOMBRE : toute taille, tout espace, tout rayon se
// déclare ici. Les tailles de l'écran de course, elles, viennent de `WatchRunMetrics`
// (Haizo/Shared), calculées sur la hauteur que le système donne.
private enum WT {

    // MARK: Les couleurs

    /// `HZCouleur.noirFranc` : le noir franc, qui sur un écran OLED éteint les pixels. C'est le
    /// fond de la montre, comme celui du panneau de la course en direct de l'iPhone.
    static let fond = Color(hex: 0x000000)
    /// `HZCouleur.surfaceSombre` : une pilule ou un bouton posé sur le fond.
    static let surface = Color(hex: 0x1C1C1E)
    /// `HZCouleur.filetSombre` : un filet, ou le rail d'une barre.
    static let filet = Color(hex: 0x2C2C2E)
    /// `HZCouleur.pointEteint` : le point d'un état éteint.
    static let pointEteint = Color(hex: 0x3A3A3C)
    /// `HZCouleur.secondaireSurSombre` : un texte secondaire est un jeton opaque, jamais une
    /// opacité.
    static let secondaire = Color(hex: 0xA1A1A6)
    static let blanc = Color(hex: 0xFFFFFF)
    /// LE ROSE DE LA MONTRE RESTE `#FF0A78` — décision de Charlotte, qui ne le rapproche pas du
    /// `#FF2E6E` de l'iPhone. Mais il ne couvre plus de surface : il reste sur la barre de
    /// progression, l'anneau du bilan et les chiffres clés (l'allure).
    static let rose = Color(hex: 0xFF0A78)

    // MARK: Les polices

    /// Passe par `DisplayFont` (Haizo/Shared) : même famille que l'app et le widget, décidée à un
    /// seul endroit. Les grands chiffres et les titres sont en 700, serrés (`serre`) ; le texte
    /// courant en 600 ou 500.
    static func gras(_ taille: CGFloat) -> Font { .custom("\(DisplayFont.family)-Bold", size: taille) }
    static func semi(_ taille: CGFloat) -> Font { .custom("\(DisplayFont.family)-SemiBold", size: taille) }
    static func moyen(_ taille: CGFloat) -> Font { DisplayFont.font(taille) }

    /// L'interlettrage d'un chiffre ou d'un titre : quatre centièmes du corps, dans la mesure de
    /// l'iPhone (−6 sur 100, −1,2 sur 28). Jamais positif : il n'y a plus de capitales à espacer.
    static let serrage: CGFloat = 0.04
    static func serre(_ taille: CGFloat) -> CGFloat { -taille * serrage }

    /// Anciennement figé sur `fr_FR`, ce qui imposait la virgule décimale à TOUT le monde : une
    /// utilisatrice anglophone ou hispanophone voyait « 3,25 km » là où son système écrit
    /// « 3.25 km ». Le séparateur décimal suit maintenant les réglages de la montre.
    static var locale: Locale { .current }

    // MARK: Les corps (hors écran de course, dont `WatchRunMetrics` donne les tailles)

    enum Corps {
        static let titre: CGFloat = 22
        static let etiquette: CGFloat = 12
        static let precision: CGFloat = 12
        static let chiffresDeSeance: CGFloat = 13
        static let erreur: CGFloat = 11
        static let bouton: CGFloat = 16
        static let distance: CGFloat = 34
        static let uniteDeDistance: CGFloat = 11
        static let chiffreDeBilan: CGFloat = 18
        static let uniteDeBilan: CGFloat = 10
    }

    // MARK: Les espaces

    enum Espace {
        static let entre: CGFloat = 6
        static let margeDePage: CGFloat = 4
        static let margeDePilule: CGFloat = 10
        static let hauteurDePilule: CGFloat = 4
        static let sousLeDisque: CGFloat = 4
        static let entreBoutons: CGFloat = 6
        static let entreMesures: CGFloat = 14
        static let sousLeFilet: CGFloat = 6
        static let dansLAnneau: CGFloat = 14
        static let entreLEtatEtLePoint: CGFloat = 6
        static let entreValeurEtUnite: CGFloat = 2
    }

    // MARK: Les formes

    enum Forme {
        /// Le bouton de départ : un disque blanc. Bien au-dessus des 44 points de cible minimale.
        static let disque: CGFloat = 72
        /// Le triangle de lecture dans ce disque : le corps du symbole. Noir sur le blanc.
        static let lectureDuDepart: CGFloat = 28
        /// Le filet au-dessus des mesures. Les glyphes des boutons de la course, eux, suivent
        /// `m.buttonIcon`, que `WatchRunMetrics` met à l'échelle de l'écran.
        static let filet: CGFloat = 1
        static let anneau: CGFloat = 108
        static let traitDeLAnneau: CGFloat = 5
        static let hauteurDeBouton: CGFloat = 44
    }

    /// Un nombre qui rétrécit avant de se couper : une durée tronquée est une durée fausse.
    enum Reduction {
        static let titre: CGFloat = 0.7
        static let chiffre: CGFloat = 0.5
        static let mesure: CGFloat = 0.6
        static let libelle: CGFloat = 0.8
    }

    /// Le bouton qu'on touche s'enfonce un peu — la mesure de `HZStyleDAppui` sur l'iPhone.
    enum Appui {
        static let echelle: CGFloat = 0.96
        static let opacite: Double = 0.88
    }
}

/// L'enfoncement d'un bouton plein. Sans lui, `.plain` ne montre rien au doigt qui touche.
private struct WTAppui: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? WT.Appui.echelle : 1)
            .opacity(configuration.isPressed ? WT.Appui.opacite : 1)
    }
}

// MARK: - Start

/// L'écran d'attente : la séance du jour telle que l'iPhone l'a poussée (titre, allure cible,
/// durée), ou le cadre « course libre » quand il n'a rien synchronisé — jamais une fausse séance.
///
/// Un titre, un grand disque BLANC portant le triangle de lecture noir, et sous lui le mot
/// « Courir ». Le rose n'y couvre plus rien : il ne reste que sur les chiffres de la séance
/// (allure, durée). L'anneau pointillé qui entourait l'ancien bouton est parti avec lui : il ne
/// suivait rien, il n'était que décoration.
///
/// # LA PHRASE DU BAS DOIT TENIR À L'ÉCRAN
///
/// Mesuré sur la capture requise par l'App Store, dans les trois langues : un ancien dessin (un
/// anneau de 118 points sur les 248 de l'écran) coupait « Cours à ta sensation — ta séance arrive
/// de l'iPhone. » en deux par le bord bas. L'écran est dans un `ScrollView`, donc la phrase était
/// atteignable — en faisant défiler une montre, c'est-à-dire jamais, et c'est cette image-là
/// qu'Apple et les clientes voient sur la fiche. Le disque fait 72 points : la pile entière —
/// étiquette, titre sur une ligne, disque, mot, phrase sur deux lignes — mesure environ 185
/// points (estimés, pas mesurés : aucune montre ici), sous les 214 d'un 45 mm. Sur un 40 mm elle
/// défile un peu, et la phrase prend la hauteur qu'il lui faut (`fixedSize`) au lieu de celle
/// qu'on lui laisse.
struct WatchStartView: View {
    @Environment(WatchWorkoutManager.self) private var workout

    private var connectivity: WatchConnectivityManager { .shared }

    private var subtitleText: String {
        switch (connectivity.sessionPace, connectivity.sessionDurationMinutes) {
        case let (pace?, minutes?): return "\(pace) /km · \(minutes) min"
        case let (pace?, nil): return "\(pace) /km"
        case let (nil, minutes?): return "\(minutes) min"
        case (nil, nil): return ""
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: WT.Espace.entre) {
                Text("Aujourd'hui")
                    .font(WT.semi(WT.Corps.etiquette))
                    .foregroundStyle(WT.blanc)
                    .lineLimit(1)
                    .minimumScaleFactor(WT.Reduction.libelle)
                    .padding(.horizontal, WT.Espace.margeDePilule)
                    .padding(.vertical, WT.Espace.hauteurDePilule)
                    .background(WT.surface, in: Capsule())

                // `Text(String)` ne traduit PAS (contrairement à `Text("littéral")`), d'où le
                // `String(localized:)` explicite sur le repli.
                Text(connectivity.sessionTitle ?? String(localized: "Course libre"))
                    .font(WT.gras(WT.Corps.titre))
                    .tracking(WT.serre(WT.Corps.titre))
                    .foregroundStyle(WT.blanc)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(WT.Reduction.titre)

                Button(action: { workout.start() }) {
                    VStack(spacing: WT.Espace.sousLeDisque) {
                        ZStack {
                            Circle().fill(WT.blanc)
                            if workout.state == .starting {
                                ProgressView().tint(WT.fond)
                            } else {
                                Image(systemName: "play.fill")
                                    .font(.system(size: WT.Forme.lectureDuDepart, weight: .bold))
                                    .foregroundStyle(WT.fond)
                            }
                        }
                        .frame(width: WT.Forme.disque, height: WT.Forme.disque)

                        Text("Courir")
                            .font(WT.gras(WT.Corps.bouton))
                            .foregroundStyle(WT.blanc)
                            .lineLimit(1)
                            .minimumScaleFactor(WT.Reduction.libelle)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(WTAppui())
                .disabled(workout.state == .starting)

                if !subtitleText.isEmpty {
                    // Les chiffres de la séance : la touche de rose de cet écran.
                    Text(subtitleText)
                        .font(WT.gras(WT.Corps.chiffresDeSeance))
                        .monospacedDigit()
                        .foregroundStyle(WT.rose)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Cours à ta sensation — ta séance arrive de l'iPhone.")
                        .font(WT.moyen(WT.Corps.precision))
                        .foregroundStyle(WT.secondaire)
                        .multilineTextAlignment(.center)
                        // La phrase prend la hauteur qu'il lui faut, au lieu de celle qu'on lui
                        // laisse. Sans ça, une langue plus longue que les trois d'aujourd'hui
                        // repasserait sous le bord sans que la mise en page bouge d'un point.
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let message = workout.errorMessage {
                    Text(message)
                        .font(WT.semi(WT.Corps.erreur))
                        .foregroundStyle(WT.rose)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, WT.Espace.margeDePage)
            .frame(maxWidth: .infinity)
        }
        .background(WT.fond)
    }
}

// MARK: - Live run

/// L'écran de course : UN chiffre, énorme, gras et serré, et trois petits sous lui — l'écran de
/// course de l'iPhone, à l'échelle du poignet.
///
/// La version d'avant mettait le chrono dans un anneau et alignait quatre métriques en 2 × 2. Six
/// chiffres se disputaient l'écran : en courant, on cherche le sien et on ne le trouve pas du
/// premier coup d'œil. C'est le seul écran de l'app qu'on lit le bras qui balance, à trois
/// secondes près — il n'a de valeur que s'il se lit sans s'arrêter.
///
/// Ce qui est affiché vient de `WatchConnectivityManager.runLayout`, choisi dans les réglages du
/// téléphone : le héros et les trois secondaires. La montre ne décide de rien, elle rend.
///
/// # CE QUI EST BLANC, CE QUI EST ROSE
///
/// Tous les chiffres sont blancs, sauf l'allure, qui est le chiffre clé et garde le rose. La barre
/// de progression est rose sur un rail gris sombre : c'est la touche d'accent de l'écran. En
/// pause, le héros et la barre passent au gris secondaire — le rose s'éteint avec le chrono.
/// Les boutons sont des capsules : la pause est BLANCHE (c'est l'action), l'arrêt est une surface
/// sombre — comme sur l'iPhone, jamais dans la couleur d'accent.
struct WatchRunView: View {
    @Environment(WatchWorkoutManager.self) private var workout

    private var connectivity: WatchConnectivityManager { .shared }
    private var layout: WatchRunLayout { connectivity.runLayout }

    /// Avancement dans la séance — `nil`, donc barre masquée, pour une course libre sans objectif
    /// réel synchronisé depuis le téléphone. Même politique que partout ailleurs : pas de
    /// progression inventée.
    ///
    /// Toujours la DURÉE, quel que soit le héros choisi. C'est le seul objectif qu'une séance
    /// porte : elles sont définies en minutes, jamais en kilomètres. Une barre qui suivrait la
    /// distance avancerait vers un but qui n'existe pas.
    private var progressFraction: Double? {
        guard let minutes = connectivity.sessionDurationMinutes, minutes > 0 else { return nil }
        return max(0, min(1, workout.elapsedSeconds / Double(minutes * 60)))
    }

    private var enPause: Bool { workout.state == .paused }

    private func value(_ metric: RunMetric) -> String {
        switch metric {
        case .time: return workout.elapsedLabel
        case .distance: return String(format: "%.2f", locale: WT.locale, workout.distanceMeters / 1000)
        case .pace: return workout.paceLabel
        case .heartRate: return workout.heartRate.map(String.init) ?? "--"
        case .calories: return "\(Int(workout.activeCalories.rounded()))"
        }
    }

    /// Blanc partout, sauf l'allure : le chiffre clé garde le rose.
    private func tint(_ metric: RunMetric) -> Color {
        metric == .pace ? WT.rose : WT.blanc
    }

    var body: some View {
        // La hauteur vient du système, elle n'est pas devinée : `WatchRunMetrics` en dérive
        // toutes les tailles, et le test qui l'accompagne vérifie que l'empilement tient sur
        // chaque boîtier depuis le 40 mm. C'est la seule garantie possible pour un écran que
        // personne ici ne peut regarder.
        GeometryReader { screen in
            stack(WatchRunMetrics(availableHeight: screen.size.height))
        }
        .background(WT.fond)
    }

    /// L'empilement est construit pour que son encombrement soit exactement celui que calcule
    /// `WatchRunMetrics.height` : cinq blocs, un espacement entre chaque paire. Les deux `Spacer`
    /// portent EUX-MÊMES cet espacement comme minimum, et le `VStack` extérieur n'en met pas : un
    /// `VStack(spacing:)` en ajoute aussi de chaque côté d'un `Spacer`, et l'écran aurait compté
    /// quatre espacements de plus que le test.
    private func stack(_ m: WatchRunMetrics) -> some View {
        VStack(spacing: 0) {
            etat(m)

            Spacer(minLength: m.spacing)

            VStack(spacing: m.spacing) {
                heros(m)
                if let fraction = progressFraction {
                    progression(fraction, m)
                }
            }

            Spacer(minLength: m.spacing)

            VStack(spacing: m.spacing) {
                mesures(m)
                commandes(m)
            }
        }
        .padding(.horizontal, m.horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: L'état

    /// Un point et un mot, à gauche. « EN COURS » et « EN PAUSE » restent écrits en capitales et
    /// ne sont pas au catalogue : c'est la dette nommée de `check_majuscules.py`, que cette
    /// refonte n'a pas le droit de lever seule. Elle ne les espace plus.
    private func etat(_ m: WatchRunMetrics) -> some View {
        HStack(spacing: WT.Espace.entreLEtatEtLePoint) {
            Circle()
                .fill(enPause ? WT.pointEteint : WT.blanc)
                .frame(width: m.statusDot, height: m.statusDot)
            Text(enPause ? "EN PAUSE" : "EN COURS")
                .font(WT.semi(m.statusText))
                .foregroundStyle(enPause ? WT.secondaire : WT.blanc)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    // MARK: Le héros

    private func heros(_ m: WatchRunMetrics) -> some View {
        VStack(alignment: .leading, spacing: m.heroGap) {
            Text(value(layout.hero))
                .font(WT.gras(m.hero))
                .tracking(WT.serre(m.hero))
                .monospacedDigit()
                .foregroundStyle(enPause ? WT.secondaire : tint(layout.hero))
                .lineLimit(1)
                .minimumScaleFactor(WT.Reduction.chiffre)
                .contentTransition(.numericText())
            Text(LocalizedStringKey(layout.hero.nameKey))
                .font(WT.semi(m.heroLabel))
                .foregroundStyle(WT.secondaire)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Le nom et le chiffre se lisent d'un trait.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: La progression

    private func progression(_ fraction: Double, _ m: WatchRunMetrics) -> some View {
        VStack(alignment: .leading, spacing: m.progressGap) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(WT.filet)
                    Capsule()
                        .fill(enPause ? WT.secondaire : WT.rose)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: m.progressBar)
            // Sacrifiée quand la place manque, et seule à l'être : la barre au-dessus dit
            // déjà la même chose, en moins précis.
            if m.showsProgressCaption {
                Text("Séance · \(Int((fraction * 100).rounded())) %")
                    .font(WT.semi(m.progressCaption))
                    .foregroundStyle(WT.secondaire)
                    .lineLimit(1)
            }
        }
        .padding(.top, m.progressTop)
    }

    // MARK: Les trois mesures

    /// Sous un filet, comme les mesures de l'écran de course de l'iPhone : le chiffre, puis son
    /// libellé en gris.
    private func mesures(_ m: WatchRunMetrics) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(layout.secondary, id: \.self) { metric in
                VStack(alignment: .leading, spacing: m.secondaryGap) {
                    Text(value(metric))
                        .font(WT.gras(m.secondaryValue))
                        .tracking(WT.serre(m.secondaryValue))
                        .monospacedDigit()
                        .foregroundStyle(tint(metric))
                        .lineLimit(1)
                        .minimumScaleFactor(WT.Reduction.mesure)
                    // `Text(String)` ne consulte PAS le catalogue — seul `Text(LocalizedStringKey)`
                    // le fait. Sans ça, « Temps » restait français même catalogue chargé.
                    Text(LocalizedStringKey(metric.unitKey))
                        .font(WT.semi(m.secondaryUnit))
                        .foregroundStyle(WT.secondaire)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, m.secondaryTop)
        .overlay(alignment: .top) {
            Rectangle().fill(WT.filet).frame(height: WT.Forme.filet)
        }
    }

    // MARK: Les commandes

    private func commandes(_ m: WatchRunMetrics) -> some View {
        HStack(spacing: WT.Espace.entreBoutons) {
            // La pause est l'action : une capsule blanche, le glyphe noir.
            Button(action: { workout.togglePause() }) {
                Image(systemName: enPause ? "play.fill" : "pause.fill")
                    .font(.system(size: m.buttonIcon, weight: .bold))
                    .foregroundStyle(WT.fond)
                    .frame(maxWidth: .infinity)
                    .frame(height: m.buttonHeight)
                    .background(WT.blanc, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(WTAppui())
            .accessibilityLabel(enPause ? "Reprendre" : "Mettre en pause")

            // Terminer : une surface sombre et un carré blanc, comme sur l'iPhone.
            Button(action: { workout.end() }) {
                Image(systemName: "stop.fill")
                    .font(.system(size: m.buttonIcon, weight: .bold))
                    .foregroundStyle(WT.blanc)
                    .frame(maxWidth: .infinity)
                    .frame(height: m.buttonHeight)
                    .background(WT.surface, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(WTAppui())
            .accessibilityLabel("Terminer la course")
        }
        .padding(.top, m.buttonTop)
    }
}

// MARK: - Summary

/// L'écran d'après la course : un seul grand chiffre, la distance, dans un anneau rose achevé,
/// puis les autres chiffres sous un filet — et où l'histoire continue, puisque l'iPhone a reçu la
/// course (transfert en file, il arrive même si le téléphone est hors de portée) et en fait le
/// bilan.
///
/// Le rose est sur l'anneau et sur l'allure ; le reste est blanc ou gris. Le bouton « OK » est
/// une capsule blanche, comme les boutons de l'iPhone : noir ou blanc, jamais l'accent.
struct WatchSummaryView: View {
    @Environment(WatchWorkoutManager.self) private var workout

    private var distanceLabel: String {
        String(format: "%.2f", locale: WT.locale, workout.distanceMeters / 1000)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: WT.Espace.entre) {
                Text("✓ Terminé")
                    .font(WT.semi(WT.Corps.etiquette))
                    .foregroundStyle(WT.blanc)
                    .lineLimit(1)
                    .minimumScaleFactor(WT.Reduction.libelle)
                    .padding(.horizontal, WT.Espace.margeDePilule)
                    .padding(.vertical, WT.Espace.hauteurDePilule)
                    .background(WT.surface, in: Capsule())

                ZStack {
                    Circle()
                        .stroke(WT.rose, style: StrokeStyle(lineWidth: WT.Forme.traitDeLAnneau, lineCap: .round))

                    VStack(spacing: 0) {
                        Text(distanceLabel)
                            .font(WT.gras(WT.Corps.distance))
                            .tracking(WT.serre(WT.Corps.distance))
                            .monospacedDigit()
                            .foregroundStyle(WT.blanc)
                            .lineLimit(1)
                            .minimumScaleFactor(WT.Reduction.chiffre)
                        Text(verbatim: "km")
                            .font(WT.semi(WT.Corps.uniteDeDistance))
                            .foregroundStyle(WT.secondaire)
                    }
                    .padding(.horizontal, WT.Espace.dansLAnneau)
                }
                .frame(width: WT.Forme.anneau, height: WT.Forme.anneau)
                .accessibilityElement(children: .combine)

                HStack(alignment: .top, spacing: WT.Espace.entreMesures) {
                    metric(value: workout.elapsedLabel, unit: "Temps")
                    metric(value: workout.paceLabel, unit: "/km", accent: WT.rose)
                    metric(value: workout.avgHeartRate.map(String.init) ?? "--", unit: "bpm moy")
                }
                .padding(.top, WT.Espace.sousLeFilet)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .top) {
                    Rectangle().fill(WT.filet).frame(height: WT.Forme.filet)
                }

                Text("Ton bilan t'attend sur l'iPhone")
                    .font(WT.moyen(WT.Corps.precision))
                    .foregroundStyle(WT.secondaire)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: { workout.reset() }) {
                    Text("OK")
                        .font(WT.gras(WT.Corps.bouton))
                        .foregroundStyle(WT.fond)
                        .frame(maxWidth: .infinity)
                        .frame(height: WT.Forme.hauteurDeBouton)
                        .background(WT.blanc, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(WTAppui())
            }
            .padding(.horizontal, WT.Espace.margeDePage)
        }
        .background(WT.fond)
    }

    private func metric(value: String, unit: String, accent: Color = WT.blanc) -> some View {
        VStack(spacing: WT.Espace.entreValeurEtUnite) {
            Text(value)
                .font(WT.gras(WT.Corps.chiffreDeBilan))
                .tracking(WT.serre(WT.Corps.chiffreDeBilan))
                .monospacedDigit()
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(WT.Reduction.mesure)
            Text(LocalizedStringKey(unit))
                .font(WT.semi(WT.Corps.uniteDeBilan))
                .foregroundStyle(WT.secondaire)
                .lineLimit(1)
                .minimumScaleFactor(WT.Reduction.libelle)
        }
    }
}
