import SwiftUI

/// The "3 daily goals" widget — one ring, split into 3 arc segments, instead of 3 separate bars.
///
/// Apple's is 3 CONCENTRIC full rings in fixed Move/Exercise/Stand colors; this is a SINGLE ring
/// split into 3 gapped arc segments — a different principle, not just a different palette. The
/// concentric-ring look is also reserved for the system Activity control by Apple's Human
/// Interface Guidelines, and app review rejects lookalikes under guideline 5.2.5, so staying
/// single-ring isn't just aesthetic. Each goal gets 120° of the circle minus a small gap on
/// either side, so the 3 goals stay distinct even though they share one ring.
///
/// L'ANNEAU EST MONO-ACCENT DEPUIS LE 16 NOVEMBRE. Il portait trois teintes et un balayage
/// dégradé par arc, repris du brillant des anneaux d'Apple ; le brief de direction artistique
/// interdit l'un et l'autre. Ce qui sépare les trois objectifs, ce sont les écarts et l'ordre,
/// et la légende qui les nomme. `fillColor` ci-dessous est la seule couleur, et toute légende
/// (`RingsView`, `HomeView`) la lit là plutôt que d'en garder une copie.
///
/// Drawn in a fixed 100×100 space then `scaleEffect`-ed to `size`, so stroke width and gaps stay
/// in the same proportion to the ring at every size this is used at.
struct DailyGoalsBarsView: View {
    /// Un objectif de la journée : son rang d'origine dans [Séance, Calories, Pas], et où il en
    /// est. Le rang voyage avec l'objectif au lieu d'être sa position dans le tableau.
    ///
    /// Il servait à choisir une couleur parmi trois ; depuis que l'anneau est mono-accent, ce
    /// n'est plus l'anneau qui le lit. Il reste parce que c'est l'identité de l'objectif, et que
    /// la légende du widget, elle, s'en sert encore pour savoir quelle ligne elle écrit — une
    /// journée de repos n'affiche que deux arcs, et le deuxième est « calories », pas
    /// « séance ».
    struct Goal: Equatable {
        var slot: Int
        var progress: Double
    }

    /// Les objectifs RÉELLEMENT en jeu, dans l'ordre. Deux un jour de repos, trois sinon.
    var goals: [Goal]
    var size: CGFloat = 96
    /// When true, the ring fills up from empty the first time this view appears instead of
    /// snapping straight to `progress` — used on `RingsView`'s hero widget so opening "Ta journée"
    /// reads as the ring filling in front of you, not a static picture.
    var animateOnAppear: Bool = false
    /// Le trait de l'anneau, en proportion de sa valeur normale.
    ///
    /// 15 % du diamètre a été calibré sur un anneau de 96 points. Le même POURCENTAGE sur un
    /// anneau héros de plus de deux cents points donne un trait de trente-cinq points : la piste
    /// vide devient alors la plus grosse masse de l'écran, et un matin à 0/2 se lit comme un
    /// grand beignet gris. La valeur par défaut ne bouge pas — seul l'appelant qui pose l'anneau
    /// en grand demande un trait plus fin.
    var strokeScale: CGFloat = 1

    /// L'anneau est-il posé sur une carte de nuit ?
    ///
    /// Il apparaît sur DEUX écrans — en résumé sur l'accueil, en sujet sur la Journée — et depuis
    /// que la Journée le pose sur la nuit, ses deux encres doivent suivre le fond et non le thème.
    /// La piste est « du noir à 9 % » en thème clair : sur `#14131E` elle disparaît, et avec elle
    /// tout le travail documenté plus bas pour qu'un anneau vide se lise vide. Les remplissages,
    /// eux, portaient la correction calculée pour le blanc — le cyan y perd 49 % de son éclat.
    ///
    /// Un booléen plutôt que des couleurs passées à la main : l'appelant ne choisit pas une
    /// palette, il dit sur quel fond il est. C'est la même règle que `RUColor.surLaNuit`.
    var surLaNuit: Bool = false

    /// What's actually drawn — starts at 0 when `animateOnAppear` is set, then springs to
    /// `progress` in `onAppear`. `.trim`'s `from`/`to` are themselves animatable, so
    /// `.animation(value:)` on the trimmed shape interpolates smoothly with no custom `Shape`
    /// needed (unlike the old bar geometry, which did need one).
    @State private var displayedProgress: [Double]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Cet `init` est écrit à la main pour amorcer `displayedProgress` — ce qui veut dire qu'une
    // nouvelle propriété n'apparaît PAS toute seule dans l'initialiseur, contrairement au
    // mémberwise que Swift fabrique. `strokeScale` ajouté sans toucher ici a donné « Extra
    // argument 'strokeScale' in call » sur l'unique site d'appel qui s'en sert.
    init(goals: [Goal], size: CGFloat = 96, animateOnAppear: Bool = false,
         strokeScale: CGFloat = 1, surLaNuit: Bool = false) {
        self.goals = goals
        self.size = size
        self.animateOnAppear = animateOnAppear
        self.strokeScale = strokeScale
        self.surLaNuit = surLaNuit
        _displayedProgress = State(initialValue: animateOnAppear ? goals.map { _ in 0 } : goals.map(\.progress))
    }

    /// LA COULEUR DE L'ANNEAU, ET IL N'Y EN A PLUS QU'UNE.
    ///
    /// Exposée pour que les vues qui montrent les mêmes trois objectifs — les pastilles de
    /// légende de `RingsView`, les libellés de `HomeView` — la lisent ici au lieu d'en garder
    /// une deuxième copie qui dérive.
    ///
    /// ELLE ÉTAIT TROIS : `[rose, violet, cyan]`, sur l'argument « trois objectifs différents
    /// méritent trois signaux différents ». Le brief du 15 novembre tranche l'inverse —
    /// « anneau mono-accent » — et le prix est connu et accepté : la pastille de légende ne
    /// désigne plus son arc, elle le PUCE. Ce qui identifie les trois objectifs reste ce qui
    /// les identifiait déjà vraiment, et que le commentaire de la piste grise disait déjà :
    /// la légende les nomme en toutes lettres, deux centimètres à droite, dans l'ordre où
    /// l'anneau les dessine.
    static var fillColor: Color { RUColor.rose }

    /// La même, sur la nuit : sans la correction calculée pour le fond blanc.
    static var fillColorSurLaNuit: Color { AccentTheme.current.primary }

    /// Les trois, en tableau, pour les appelants qui indexent par objectif.
    ///
    /// Trois fois la même valeur : c'est voulu, et c'est ce qui fait qu'aucun appelant n'a eu à
    /// changer de forme le jour où l'anneau est passé mono-accent. Le jour où il repasserait à
    /// trois teintes, c'est ici que ça se déciderait, et nulle part ailleurs.
    static var fillColors: [Color] { Array(repeating: fillColor, count: 3) }
    static var fillColorsSurLaNuit: [Color] { Array(repeating: fillColorSurLaNuit, count: 3) }

    private static let canvasSize: CGFloat = 100
    /// 15 % du diamètre. C'était 12 %, aligné sur le widget après une comparaison côte à côte —
    /// mais cette comparaison datait d'un anneau de 72 pt sur l'accueil. À 96 pt, le même
    /// POURCENTAGE donne un anneau visuellement plus grêle : la surface du disque croît au carré
    /// du rayon là où le trait ne croît que linéairement, donc le trait occupe proportionnellement
    /// moins de l'objet qu'on regarde. 15 % rend à l'anneau agrandi le corps qu'il avait à 72.
    ///
    /// Reste en dessous des 20 % d'origine, jugés « boueux » à l'époque, et le widget garde sa
    /// propre valeur : il est vu à 40 pt dans une grille d'icônes, pas à 96 sur une carte.
    private static let strokeWidth: CGFloat = 15
    /// La piste doit dire « objectif pas encore atteint », donc rester nettement en dessous du
    /// remplissage. Elle était à 0,36 en clair, calibrée quand l'anneau faisait 72 pt : à 96 pt,
    /// une journée à 0/3 dessinait un anneau rose et lavande PLEIN, qui contredisait sa propre
    /// légende « 0/2 bouclés ». Un anneau vide doit se lire vide — c'est la seule chose que cet
    /// écran a à dire quand rien n'est fait.
    ///
    /// Le clair reste un peu au-dessus du sombre : une couleur saturée à faible opacité se dilue
    /// davantage sur du blanc que sur du noir.
    /// J'avais descendu le clair à 0,15 pour qu'un anneau vide cesse de se lire comme plein. C'était
    /// trop : à cette valeur la piste disparaît sur du blanc, et l'anneau ne se lit plus que par
    /// ses arcs remplis — donc comme un trait fin et brisé au lieu d'un anneau. 0,26 garde la
    /// distinction rempli / pas rempli tout en redonnant à l'anneau son corps.
    /// ── La piste devient NEUTRE ────────────────────────────────────────────────────────────
    ///
    /// Les quatre réglages ci-dessus cherchaient tous la même chose par le même moyen : faire
    /// qu'un anneau vide se lise vide, en baissant l'opacité d'une piste TEINTÉE. 0,36, puis
    /// 0,15, puis 0,26. Vu sur un vrai téléphone, à 0/3, l'anneau se lit toujours plein à
    /// quatre-vingt-dix pour cent.
    ///
    /// C'est que le problème n'est pas l'opacité, c'est la couleur. Une piste rose pâle posée à
    /// côté d'un remplissage rose, ce sont deux roses : l'œil voit un anneau continu, il ne voit
    /// pas où l'un s'arrête et où l'autre commence. Aucune opacité ne répare ça — plus haut on
    /// lit « plein », plus bas on ne lit plus d'anneau du tout.
    ///
    /// Une piste GRISE règle les deux d'un coup : rempli et pas rempli deviennent deux choses
    /// différentes, et l'anneau garde son corps. L'argument d'origine — « une piste teintée
    /// rappelle à quel objectif l'arc appartient, comme les anneaux d'Apple » — ne tient pas ici :
    /// la légende nomme les trois objectifs en toutes lettres à côté, avec leur pastille de
    /// couleur. L'information est déjà là, deux centimètres à droite.
    ///
    /// Au passage, c'est trois éléments roses de moins sur un écran qui en comptait seize.
    private static let lightTrackOpacity = 0.09
    private static let darkTrackOpacity = 0.10

    private var stroke: CGFloat { Self.strokeWidth * strokeScale }

    var body: some View {
        ZStack {
            ForEach(Array(goals.enumerated()), id: \.offset) { i, _ in
                let color = surLaNuit ? Self.fillColorSurLaNuit : Self.fillColor
                let seg = RingSegmentGeometry.segment(at: i, count: goals.count)
                let pct = max(0, min(1, i < displayedProgress.count ? displayedProgress[i] : 0))
                let fillEnd = seg.trimStart + (seg.trimEnd - seg.trimStart) * pct

                // La piste : la longueur totale du segment, en gris neutre — voir le long
                // commentaire sur les opacités plus haut. Ce n'est plus une teinte de la couleur
                // de l'arc, et c'est le changement qui fait qu'un anneau vide se lit enfin vide.
                Circle()
                    .trim(from: seg.trimStart, to: seg.trimEnd)
                    .stroke(
                        (RUColor.isLight && !surLaNuit ? Color.black : Color.white)
                            .opacity(RUColor.isLight && !surLaNuit ? Self.lightTrackOpacity
                                                                   : Self.darkTrackOpacity),
                        style: StrokeStyle(lineWidth: stroke, lineCap: .round)
                    )

                // LE REMPLISSAGE : UN APLAT D'ACCENT.
                //
                // C'était un `AngularGradient` à trois arrêts, dont le dernier était la couleur
                // du VOISIN : chaque arc gardait sa teinte sur ses quatre premiers cinquièmes
                // puis virait vers celle de l'arc suivant, pour que l'anneau se lise comme un
                // seul ruban qui change de couleur plutôt que comme trois bâtons posés en
                // cercle. Tout ce mécanisme servait à réconcilier trois couleurs. Avec une
                // seule, il n'a plus rien à réconcilier : il ne restait qu'un éclaircissement
                // décoratif de l'accent vers sa version vive, et le brief du 15 novembre
                // l'interdit.
                //
                // L'effet « ça s'éclaire en se remplissant » disparaît avec lui. Ce qui dit
                // qu'un objectif avance reste ce qui le disait : la LONGUEUR de l'arc.
                Circle()
                    .trim(from: seg.trimStart, to: fillEnd)
                    .stroke(color, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.9), value: pct)
            }
        }
        // A circle's own trim starts at 3 o'clock; rotate so segment 0 starts at 12, going clockwise.
        // No lift shadow — the widget's ring doesn't have one, and at hero size the shadow was a
        // big part of the smeared "ghost ring" look in the screenshot that prompted this change.
        .rotationEffect(.degrees(-90))
        .frame(width: Self.canvasSize, height: Self.canvasSize)
        .scaleEffect(size / Self.canvasSize)
        .frame(width: size, height: size)
        .onAppear {
            if animateOnAppear { displayedProgress = goals.map(\.progress) }
        }
        .onChange(of: goals) { _, newValue in
            displayedProgress = newValue.map(\.progress)
        }
    }
}

#Preview {
    DailyGoalsBarsView(goals: [.init(slot: 0, progress: 1), .init(slot: 1, progress: 0.6), .init(slot: 2, progress: 0.12)], size: 180)
        .padding()
        .background(RUColor.pageBackground)
}
