import WidgetKit
import SwiftUI

struct DailyGoalsEntry: TimelineEntry {
    let date: Date
    let snapshot: DailyGoalsSnapshot
    /// La course en cours, s'il y en a une ET qu'elle est encore fraîche à `date`.
    ///
    /// Décidé à la construction de l'entrée et non à l'affichage : une entrée de widget est une
    /// image figée pour un INSTANT donné, et le `timeline` en pose une dans le futur, juste après
    /// la péremption. C'est ce qui fait revenir l'anneau tout seul même si plus aucun rechargement
    /// n'est accordé — sans quoi la péremption aurait eu besoin, pour s'appliquer, de la chose
    /// même dont son absence est le symptôme.
    var course: LiveRunWidgetSnapshot? = nil
}

struct DailyGoalsProvider: TimelineProvider {
    /// Montré dans la galerie de widgets — « rose » correspond à `ThemeStore.accentParDefaut` dans la
    /// cible de l'app, et `isLightMode: true` au thème par défaut depuis le 9 novembre 2026. Un
    /// aperçu de galerie doit montrer ce que l'app montre à quelqu'un qui vient de l'installer.
    private static let placeholderSnapshot = DailyGoalsSnapshot(
        progress: [1, 0.6, 0.3], streak: 4, accentThemeID: "rose", isLightMode: true,
        dailyGoalsDone: 2, dailyGoalsTotal: 3, activeCaloriesRemaining: 110, stepsRemaining: 2400,
        weekStrip: [
            WidgetWeekDay(letter: "L", isDone: true, isToday: false),
            WidgetWeekDay(letter: "M", isDone: true, isToday: false),
            WidgetWeekDay(letter: "M", isDone: false, isToday: false),
            WidgetWeekDay(letter: "J", isDone: false, isToday: true),
            WidgetWeekDay(letter: "V", isDone: false, isToday: false),
            WidgetWeekDay(letter: "S", isDone: false, isToday: false),
            WidgetWeekDay(letter: "D", isDone: false, isToday: false)
        ],
        heroNombre: "45′", heroTitre: String(localized: "Footing"),
        heroMesures: "45 min · 5:30/km · Z2"
    )

    func placeholder(in context: Context) -> DailyGoalsEntry {
        DailyGoalsEntry(date: .now, snapshot: Self.placeholderSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyGoalsEntry) -> Void) {
        // `.empty`, not the demo placeholder — outside the gallery, fabricated "2/3 bouclés"
        // numbers on a fresh install would be the exact fake-data the app refuses everywhere else.
        completion(DailyGoalsEntry(date: .now, snapshot: DailyGoalsSnapshot.load() ?? .empty))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyGoalsEntry>) -> Void) {
        let snapshot = DailyGoalsSnapshot.load() ?? .empty

        // UNE COURSE EN COURS PREND TOUTE LA PLACE. Annoncer « 2/3 bouclés » pendant qu'elle
        // court, c'est répondre à une question que personne ne pose à ce moment-là.
        if let course = LiveRunWidgetSnapshot.load(), course.estFraiche(a: .now) {
            completion(Timeline(
                entries: [
                    DailyGoalsEntry(date: .now, snapshot: snapshot, course: course),
                    // Et l'anneau revient de lui-même à la péremption. Cette seconde entrée est
                    // tout l'intérêt du procédé : elle n'a besoin d'aucun rechargement pour
                    // s'afficher, donc une app tuée en pleine sortie ne laisse pas un chrono
                    // tourner indéfiniment sur l'écran d'accueil.
                    DailyGoalsEntry(date: course.perimeeA, snapshot: snapshot)
                ],
                policy: .after(course.perimeeA)))
            return
        }

        let entry = DailyGoalsEntry(date: .now, snapshot: snapshot)
        // The app calls `WidgetCenter.shared.reloadAllTimelines()` itself the moment anything
        // actually changes (`AppState.publishWidgetSnapshot`) — this hourly fallback only covers
        // the rare case that never fires (app force-quit mid-sync, etc.), not the normal path.
        var entries = [entry]
        // A second entry at midnight flips the footer date/"today" dot on time — WidgetKit defers
        // budgeted `.after` reloads overnight, so without it the widget showed yesterday's date
        // well into the morning.
        if let midnight = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) {
            entries.append(DailyGoalsEntry(date: midnight, snapshot: snapshot))
        }
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }
}

/// L'anneau de l'accueil, posé sur l'écran d'accueil.
///
/// La passe précédente avait retiré l'anneau au profit d'un chiffre plat, au motif qu'un widget
/// doit se lire comme un tableau d'affichage et non comme une carte de l'app. Le résultat s'est
/// avéré terne à l'usage : hors du chiffre coloré, tout était gris sur noir, l'œil n'avait qu'un
/// seul point d'accroche, et la version moyenne répétait quatre fois la même cellule.
///
/// Le pari est inverse ici — le widget est un morceau de l'app posé sur le téléphone. Il dessine
/// donc L'ANNEAU DE L'ACCUEIL, pas une imitation : `RingSegmentGeometry` est le fichier partagé
/// que `DailyGoalsBarsView` utilise déjà, écrit exactement pour ça (son en-tête annonce un
/// `WidgetRingView` qui avait disparu, et que voici de retour). Découpe, écart entre arcs, sens de
/// rotation et plage du dégradé viennent tous de là : ils ne peuvent plus diverger.
struct WidgetRingView: View {
    /// Le rang d'origine dans [Séance, Calories, Pas] et l'avancement. Le rang voyage avec
    /// l'objectif plutôt que d'être sa position : un jour de repos n'a que deux objectifs, et sans
    /// lui « calories » hériterait de la couleur de la séance.
    struct Goal { var slot: Int; var progress: Double }

    var goals: [Goal]
    var size: CGFloat
    var colors: [Color]
    var isLight: Bool

    private static let canvas: CGFloat = 100
    /// Plus épais que les 15 % de l'app, et c'est voulu : l'anneau est ici dessiné à 64-96 points
    /// au lieu de 96-180. Le même POURCENTAGE donnerait un trait visuellement plus grêle, la
    /// surface du disque croissant au carré du rayon là où le trait ne croît que linéairement.
    private static let stroke: CGFloat = 17

    var body: some View {
        ZStack {
            ForEach(Array(goals.enumerated()), id: \.offset) { i, goal in
                let color = colors[min(max(0, goal.slot), colors.count - 1)]
                let seg = RingSegmentGeometry.segment(at: i, count: goals.count)
                let pct = max(0, min(1, goal.progress))
                let fillEnd = seg.trimStart + (seg.trimEnd - seg.trimStart) * pct

                // La piste est GRISE, comme celle de l'anneau de l'accueil — voir le long
                // commentaire des opacités dans `DailyGoalsBarsView`. Une piste teintée à côté
                // d'un remplissage de la même couleur ne se distingue pas de lui : à 0/3, l'anneau
                // se lisait plein. Sur un widget vu à bout de bras, c'est encore plus vrai que
                // dans l'app, et il n'y a même pas de légende à côté pour rattraper.
                // Un rail en jeton opaque (`filetGroupe` sur blanc, `filetSombre` sur noir) : un texte
                // ou un rail ne se fait plus par une opacité posée sur le fond.
                Circle()
                    .trim(from: seg.trimStart, to: seg.trimEnd)
                    .stroke(isLight ? WG.filetClair : WG.filetSombre,
                            style: StrokeStyle(lineWidth: Self.stroke, lineCap: .round))

                // UN APLAT, COMME DANS L'APP. Le balayage dégradé et son dernier arrêt pris
                // sur la couleur du voisin sont partis le 16 novembre, en même temps que ceux
                // de `DailyGoalsBarsView` : ils servaient à relier trois teintes, et il n'y en
                // a plus qu'une. L'anneau du widget et celui de l'app doivent rester le même
                // dessin — sinon l'écran d'accueil et l'app se contredisent.
                Circle()
                    .trim(from: seg.trimStart, to: fillEnd)
                    .stroke(color, style: StrokeStyle(lineWidth: Self.stroke, lineCap: .round))
            }
        }
        // Le `trim` d'un cercle démarre à 3 heures : on tourne pour que le premier arc parte de midi.
        .rotationEffect(.degrees(-90))
        .frame(width: Self.canvas, height: Self.canvas)
        .scaleEffect(size / Self.canvas)
        .frame(width: size, height: size)
        // La légende à côté énonce les trois mêmes valeurs en toutes lettres : annoncer l'anneau
        // ferait entendre deux fois la même chose à qui l'écoute.
        .accessibilityHidden(true)
    }
}

struct DailyGoalsWidgetView: View {
    @Environment(\.widgetFamily) private var familleDuSysteme
    let snapshot: DailyGoalsSnapshot
    /// La date de l'entrée : un rendu de widget est une image figée, `.now` au moment où le corps
    /// s'évalue n'est pas la bonne horloge.
    var entryDate: Date = .now
    var course: LiveRunWidgetSnapshot? = nil
    /// Imposée seulement par le rendu en image (`HaizoWidgetTests`) : `widgetFamily` est en lecture
    /// seule, hors de WidgetKit rien ne la fixe. Vide dans le widget lui-même.
    var familleImposee: WidgetFamily? = nil
    private var family: WidgetFamily { familleImposee ?? familleDuSysteme }

    /// « Dimanche 15 novembre » — la date, avec la seule première lettre en capitale.
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return f
    }()

    private var dateDuJour: String {
        let texte = Self.dateFormatter.string(from: entryDate)
        return texte.prefix(1).capitalized + texte.dropFirst()
    }

    /// L'accent qu'elle a réellement choisi dans l'app, jamais une couleur fixe — et trois fois
    /// le même depuis que l'anneau est mono-accent, comme `DailyGoalsBarsView.fillColors`.
    private var colors: [Color] { WidgetAccentPalette.ringColors(themeID: snapshot.accentThemeID, isLight: false) }
    private var accent: Color { colors[0] }

    // LE WIDGET EST TOUJOURS NOIR, comme l'en-tête de l'accueil de l'app, qui l'est dans les deux
    // modes : un fond blanc le ferait ressembler à une carte de l'app et non à son affiche. Les
    // jetons de l'app, RECOPIÉS et pas lus (`WG`) : la cible du widget ne compile pas
    // `Haizo/DesignSystem`, pour la raison écrite en tête de `WidgetAccentPalette`.
    private var bg: Color { WG.noir }

    /// Les objectifs réellement en jeu : deux un jour de repos, trois sinon. L'anneau se partage
    /// alors en deux arcs plutôt que d'en dessiner un troisième qui ne pourra jamais se remplir.
    private var goals: [WidgetRingView.Goal] {
        let p = snapshot.progress
        let all = (0..<3).map { WidgetRingView.Goal(slot: $0, progress: p[safe: $0] ?? 0) }
        return snapshot.isRestDay ? Array(all.dropFirst()) : all
    }

    /// La séance du jour est-elle connue ? Un instantané écrit avant les champs de la séance n'en a
    /// pas : le widget retombe alors sur l'anneau seul, plutôt que d'inventer un grand chiffre.
    private var aUneSeance: Bool { snapshot.heroNombre != nil && snapshot.heroTitre != nil }

    var body: some View {
        Group {
            if let course {
                // `widgetURL` et non un `Link` : sur un widget, c'est la zone entière qui doit
                // répondre. Pendant une course on touche son écran d'accueil en bougeant, parfois
                // avec un gant — viser une pastille serait le mauvais geste à proposer.
                runBody(course)
                    .widgetURL(URL(string: "runup://live"))
            } else {
                switch family {
                case .systemMedium: mediumBody
                default: smallBody
                }
            }
        }
        .containerBackground(for: .widget) { course == nil ? bg : runBackground }
    }

    // MARK: Une course en cours

    /// Le fond passe au noir franc — celui du panneau de la séance en direct de l'app, qui se lit
    /// au soleil et en courant. Il passait à l'accent plein : c'est exactement ce que la refonte
    /// a retiré partout, où l'accent n'est plus une surface mais une touche (ici le point d'état).
    private var runBackground: Color { WG.noirFranc }

    @ViewBuilder private func runBody(_ course: LiveRunWidgetSnapshot) -> some View {
        switch family {
        case .systemMedium: runMedium(course)
        default: runSmall(course)
        }
    }

    /// Le chrono, et rien qui lui dispute la place.
    ///
    /// `Text(timerInterval:)` et non une valeur republiée : le système le fait avancer lui-même,
    /// sans rechargement et sans réveiller l'app. C'est la seule façon qu'un widget d'écran
    /// d'accueil ait un chrono juste — WidgetKit ne rationne que les rechargements, pas
    /// l'écoulement du temps.
    @ViewBuilder private func chrono(_ course: LiveRunWidgetSnapshot, size: CGFloat) -> some View {
        if course.isPaused {
            // En pause, le temps est FIGÉ. Un chrono auto-porté continuerait d'avancer, et rien
            // ne viendrait le démentir avant la republication suivante — quatre-vingt-dix
            // secondes de mensonge, sur le chiffre le plus regardé de l'écran.
            Text(TimeFormat.horloge(course.elapsedSeconds))
                .font(WG.police(size))
                .tracking(WG.serre(size))
                .monospacedDigit()
        } else {
            Text(timerInterval: course.startedAt...Date.distantFuture, countsDown: false)
                .font(WG.police(size))
                .tracking(WG.serre(size))
                .monospacedDigit()
        }
    }

    /// L'état de la course : un point d'accent allumé (éteint en pause) et un mot en casse de
    /// phrase. C'est la touche d'accent de l'écran ; le reste est blanc sur noir.
    private func runEyebrow(_ course: LiveRunWidgetSnapshot) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(course.isPaused ? WG.pointEteintSombre : colors[0])
                .frame(width: 6, height: 6)
            Text(course.isPaused ? String(localized: "En pause") : String(localized: "En direct"))
                .font(WG.police(WG.Corps.etiquette, .semi))
        }
        .foregroundColor(WG.secondaireSurSombre)
    }

    private func runMetric(_ valeur: String, _ unite: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(valeur)
                .font(WG.police(WG.Corps.chiffre))
                .monospacedDigit()
                .foregroundColor(WG.blanc)
            Text(verbatim: unite)
                .font(WG.police(WG.Corps.etiquette, .semi))
                .foregroundColor(WG.secondaireSurSombre)
        }
    }

    private func runSmall(_ course: LiveRunWidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            runEyebrow(course)
            Spacer(minLength: 0)
            chrono(course, size: WG.Corps.chronoPetit).foregroundColor(WG.blanc)
            runMetric(TimeFormat.distance(km: course.distanceKm), "km")
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Course en cours, \(TimeFormat.distance(km: course.distanceKm)) kilomètres"))
    }

    private func runMedium(_ course: LiveRunWidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                runEyebrow(course)
                Spacer(minLength: 6)
                Text(course.sessionTitle)
                    .font(WG.police(WG.Corps.etiquette, .semi))
                    .foregroundColor(WG.secondaireSurSombre)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 4)
            chrono(course, size: WG.Corps.chronoMoyen).foregroundColor(WG.blanc)
            Spacer(minLength: 4)
            HStack(spacing: 18) {
                runMetric(TimeFormat.distance(km: course.distanceKm), "km")
                // L'unité vient de la discipline : « /km » à pied, « km/h » à vélo. Le même
                // défaut avait été trouvé deux fois sur l'écran verrouillé, écrit en dur.
                runMetric(course.rythmeValeur, course.discipline.rythmeUnite)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Course en cours, \(TimeFormat.distance(km: course.distanceKm)) kilomètres"))
    }

    // MARK: La séance du jour

    /// LE WIDGET EST L'ACCUEIL EN MINIATURE : la semaine en points, le grand chiffre de la séance du
    /// jour dans l'accent, son titre, ses mesures, et l'anneau des objectifs. Il était un tableau
    /// d'objectifs — un anneau et des libellés gris — à côté d'une app qui est une affiche.
    ///
    /// Petit : la semaine et la série en haut, le grand nombre, le titre. Rien d'autre : 158 points
    /// de large ne portent pas l'anneau en plus, qui attend le moyen. Quand la séance n'est pas
    /// connue (instantané ancien), l'anneau prend sa place.
    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: WG.Forme.ecart) {
                semaine
                Spacer(minLength: 0)
                if snapshot.streak > 0 { serie }
            }
            // Un Spacer de chaque côté : la séance est centrée dans la hauteur qui reste sous la
            // semaine, et ne colle plus au bord bas du widget.
            Spacer(minLength: 0)
            if aUneSeance {
                affiche(avecMesures: true)
            } else {
                HStack {
                    Spacer(minLength: 0)
                    anneau(taille: WG.Forme.anneauDuPetit)
                    Spacer(minLength: 0)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(WG.Forme.margeDuWidget)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibiliteDeLaSeance)
    }

    /// Moyen : la même affiche à gauche, l'anneau des objectifs à droite, la date en haut.
    private var mediumBody: some View {
        VStack(alignment: .leading, spacing: WG.Forme.ecart) {
            HStack(spacing: WG.Forme.ecart) {
                semaine
                Spacer(minLength: 0)
                if snapshot.streak > 0 { serie }
                Text(dateDuJour)
                    .font(WG.police(WG.Corps.texte, .semi))
                    .foregroundColor(WG.secondaireSurSombre)
                    .lineLimit(1)
                    .minimumScaleFactor(WG.Forme.reductionDuChrono)
            }
            HStack(alignment: .center, spacing: WG.Forme.ecartDeColonnes) {
                if aUneSeance {
                    affiche(avecMesures: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                VStack(spacing: WG.Forme.ecart - 2) {
                    anneau(taille: WG.Forme.anneauDuMoyen)
                    Text("bouclés")
                        .font(WG.police(WG.Corps.legende, .semi))
                        .foregroundColor(WG.secondaireSurSombre)
                }
                .frame(maxWidth: aUneSeance ? nil : .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, WG.Forme.margeDuWidgetMoyen)
        .padding(.vertical, WG.Forme.margeDuWidget)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibiliteDeLaSeance)
    }

    /// Le grand nombre dans l'accent, son préfixe (« 5 × ») au-dessus, le titre dessous, puis les
    /// mesures. Le préfixe prend une ligne : avec lui, les mesures sautent, faute de place.
    private func affiche(avecMesures: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let prefixe = snapshot.heroPrefixe {
                Text(prefixe)
                    .font(WG.police(WG.Corps.titre))
                    .foregroundColor(WG.blanc)
                    .lineLimit(1)
            }
            Text(snapshot.heroNombre ?? "")
                .font(WG.affichage(WG.Corps.grandNombre))
                .tracking(WG.serre(WG.Corps.grandNombre))
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(WG.Forme.reductionDuGrandNombre)
                // Mesuré contre la largeur qu'on lui laisse, et collé au bord gauche : sans cadre,
                // un nombre plus large que la colonne était centré sur elle et sortait des deux côtés.
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(snapshot.heroTitre ?? "")
                .font(WG.police(WG.Corps.titre))
                .tracking(WG.serre(WG.Corps.titre))
                .foregroundColor(WG.blanc)
                .lineLimit(1)
                .minimumScaleFactor(WG.Forme.reductionDuChrono)
                .padding(.top, WG.Forme.ecart - 2)
            if avecMesures, snapshot.heroPrefixe == nil, let ligne = ligneSecondaire {
                Text(ligne)
                    .font(WG.police(WG.Corps.legende, .semi))
                    .foregroundColor(WG.secondaireSurSombre)
                    .lineLimit(1)
                    .minimumScaleFactor(WG.Forme.reductionDuChrono)
                    .padding(.top, 2)
            }
        }
    }

    /// « Fait » quand la séance l'est, sinon ses mesures.
    private var ligneSecondaire: String? {
        snapshot.heroFaite ? String(localized: "Fait") : snapshot.heroMesures
    }

    /// L'anneau des objectifs, avec ce qui est bouclé écrit dedans.
    private func anneau(taille: CGFloat) -> some View {
        WidgetRingView(goals: goals, size: taille, colors: colors, isLight: false)
            .overlay {
                Text("\(snapshot.dailyGoalsDone)/\(snapshot.dailyGoalsTotal)")
                    .font(WG.police(WG.Corps.chiffreDeLAnneau))
                    .tracking(WG.serre(WG.Corps.chiffreDeLAnneau))
                    .foregroundColor(WG.blanc)
            }
    }

    /// LA SEMAINE EN POINTS, comme sur l'accueil : un point allumé (blanc) par jour bouclé, un point
    /// éteint sinon, un anneau blanc pour aujourd'hui.
    ///
    /// LE JOUR COURANT VIENT DE LA DATE, PAS DE L'INSTANTANÉ : l'écran dit « Dimanche » à partir de
    /// `entryDate`, que le système tient à jour ; la pastille du jour lisait `state == .today` dans
    /// l'instantané publié, figé au dernier passage dans l'app. Deux parties du même widget, deux
    /// jours différents. Le rang se déduit donc de la date (`WidgetWeekDay.rangDuJour`).
    private var semaine: some View {
        HStack(spacing: WG.Forme.ecartDesPoints) {
            ForEach(Array(snapshot.weekStrip.enumerated()), id: \.offset) { rang, jour in
                if rang == WidgetWeekDay.rangDuJour(entryDate) {
                    Circle()
                        .stroke(WG.blanc, lineWidth: WG.Forme.traitDuJour)
                        .frame(width: WG.Forme.pointDeLaSemaine, height: WG.Forme.pointDeLaSemaine)
                } else {
                    Circle()
                        .fill(jour.isDone ? WG.blanc : WG.pointEteintSombre)
                        .frame(width: WG.Forme.pointDeLaSemaine, height: WG.Forme.pointDeLaSemaine)
                }
            }
        }
    }

    /// La série : une pastille sombre, la flamme dans l'accent, le nombre en blanc.
    private var serie: some View {
        HStack(spacing: 2) {
            Image(systemName: "flame.fill").font(.system(size: 9)).foregroundColor(accent)
            Text("\(snapshot.streak)").font(WG.police(WG.Corps.legende)).foregroundColor(WG.blanc)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(WG.surfaceSombre, in: Capsule())
    }

    private var accessibiliteDeLaSeance: Text {
        let seance = [snapshot.heroNombre, snapshot.heroTitre, snapshot.heroMesures]
            .compactMap { $0 }.joined(separator: ", ")
        let objectifs = String(localized: "\(snapshot.dailyGoalsDone) sur \(snapshot.dailyGoalsTotal) objectifs bouclés")
        return Text(seance.isEmpty ? objectifs : seance + ". " + objectifs)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct DailyGoalsWidget: Widget {
    let kind = "DailyGoalsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyGoalsProvider()) { entry in
            DailyGoalsWidgetView(snapshot: entry.snapshot, entryDate: entry.date, course: entry.course)
        }
        .configurationDisplayName("Aujourd'hui")
        .description(Text("La séance du jour et tes objectifs, d'un coup d'œil."))
        .supportedFamilies([.systemSmall, .systemMedium])
        // LES MARGES SONT LES NÔTRES. Depuis iOS 17 le système en pose déjà (16 points sur un petit
        // widget) autour du contenu, et la vue y ajoutait les siennes : le grand nombre ne disposait
        // que de ~98 points sur 158, et débordait. Désactivées, les marges de `Forme` sont les
        // seules, et la maquette (130 points utiles) dit vrai.
        .contentMarginsDisabled()
    }
}
