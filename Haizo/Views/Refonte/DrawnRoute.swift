import SwiftUI

/// Le tracé d'une course qui se REDESSINE, du départ à l'arrivée, avec la tête qui avance dessus.
///
/// # POURQUOI
///
/// `RouteThumbnail` pose le tracé d'un coup, déjà fini. C'est juste pour une vignette de 52
/// points au bout d'une ligne d'historique. Ça ne l'est plus quand le tracé est le SUJET de
/// l'écran — la fin de course, la carte du fil — parce qu'un parcours posé d'un bloc est une
/// forme, alors qu'un parcours qui se dessine est un RÉCIT : on voit la boucle partir, hésiter au
/// carrefour, revenir. C'est la seule chose à l'écran qui raconte quelque chose que la personne a
/// vraiment fait.
///
/// # LA TÊTE EST CE QUI FAIT LA DIFFÉRENCE
///
/// Un trait qui s'allonge se lit comme un chargement. Le même trait avec un point à son extrémité
/// se lit comme un déplacement — l'œil suit la tête, pas la longueur.
///
/// Elle était DEUX cercles, un net et un flou derrière, jusqu'au 16 novembre. Le flou est parti
/// avec le halo du trait : ce qui fait le déplacement, c'est que le point avance, pas qu'il
/// brille. Un seul disque blanc net, donc, et rien dans un calque à part.
///
/// # LA GÉOMÉTRIE N'EST PAS RECOPIÉE
///
/// `RouteGeometry.normalized` et `.decimated` font déjà le cadrage et l'allègement pour
/// `RouteThumbnail`. Les refaire ici donnerait deux tracés légèrement différents pour la même
/// course, visibles côte à côte dans l'historique.
struct DrawnRoute: View, Animatable {
    var route: [RunRecord.RoutePoint]
    var lineWidth: CGFloat = HZMarque.traitDuTrace
    /// Le tracé est un aplat : une seule couleur, un trait net. Il a eu un dégradé d'accent ; la
    /// refonte l'a retiré avec le halo.
    var couleur: Color = HZCouleur.accent
    /// Plus de sommets qu'une vignette : à pleine largeur, 60 points donnent une ligne brisée.
    var targetPoints: Int = HZMarque.pointsDuTrace
    /// Marque le départ d'un anneau creux une fois le tracé fini.
    var showsStart = true
    /// 0 = rien, 1 = le tracé entier. Animable par l'appelant.
    var progress: Double

    /// SANS CECI, LE TRACÉ SAUTE AU LIEU DE SE DESSINER. `withAnimation` interpole les propriétés
    /// ANIMABLES d'une vue ; un `Double` stocké n'en est pas une, et SwiftUI se contenterait de
    /// réévaluer le corps une fois, avec la valeur finale. Déclarer la vue `Animatable` et
    /// exposer `progress` comme sa donnée animable fait redessiner le `Canvas` à chaque image
    /// intermédiaire — c'est là, et seulement là, que le dessin existe.
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private var points: [CGPoint] {
        RouteGeometry.decimated(RouteGeometry.normalized(route), keeping: targetPoints)
    }

    var body: some View {
        Canvas { context, size in
            let pts = points
            guard pts.count > 1 else { return }

            // Dessiné dans le plus grand carré centré, comme `RouteThumbnail` : `normalized` rend
            // un carré, l'étirer sur un rectangle défairait sa correction de rapport de forme.
            let inset = lineWidth * HZMarque.deux
            let side = max(min(size.width, size.height) - inset * HZMarque.deux, 1)
            let originX = (size.width - side) / HZMarque.deux
            let originY = (size.height - side) / HZMarque.deux
            func place(_ p: CGPoint) -> CGPoint {
                CGPoint(x: originX + p.x * side, y: originY + p.y * side)
            }

            var full = Path()
            full.move(to: place(pts[0]))
            for p in pts.dropFirst() { full.addLine(to: place(p)) }

            let t = min(max(progress, 0), 1)
            let shading = GraphicsContext.Shading.color(couleur)

            // Le chemin déjà parcouru. `trimmedPath` coupe à la longueur, pas au nombre de
            // segments : la tête avance donc à vitesse constante, quelle que soit la densité des
            // points — dense dans les virages, clairsemée en ligne droite.
            let drawn = full.trimmedPath(from: 0, to: t)

            // La trace fantôme du reste du parcours. Sans elle, l'œil ne sait pas où ça va et le
            // dessin se lit comme une barre de progression. Avec elle, on voit la forme à remplir.
            context.stroke(full, with: .color(HZCouleur.blanc.opacity(HZMarque.opaciteDuFond)),
                           style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

            // LE HALO EST PARTI. Il doublait le trait d'une copie floutée à 1,6 fois sa largeur :
            // c'est précisément la lueur que le brief du 15 novembre interdit — « pas de halo,
            // pas de glow, un trait net de 4 » — et sur un tracé dense il empâtait les virages
            // au lieu de les montrer. Le trait passe de 3 à 4 points, qui est ce que le halo
            // donnait vraiment à lire.
            context.stroke(drawn, with: shading,
                           style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

            if showsStart, t > HZMarque.seuilDeDepart {
                let start = place(pts[0])
                let r = lineWidth * HZMarque.rayonDeLaTete
                context.stroke(Path(ellipseIn: CGRect(x: start.x - r, y: start.y - r,
                                                      width: r * HZMarque.deux, height: r * HZMarque.deux)),
                               with: .color(HZCouleur.blanc.opacity(HZMarque.opaciteDeLaTete)),
                               lineWidth: lineWidth * HZMarque.traitDuContour)
            }

            // La tête. Elle disparaît une fois arrivée : un point lumineux qui reste au bout d'un
            // tracé fini n'est plus un déplacement, c'est une pastille de notification.
            if t > HZMarque.debutDeLaTete && t < HZMarque.finDeLaTete {
                let head = headPoint(of: full, at: t) ?? place(pts[0])
                // LA LUEUR EST PARTIE AUSSI, ET LA TÊTE RESTE. Ce qui fait lire un déplacement
                // plutôt qu'un chargement, c'est qu'un point AVANCE au bout du trait, pas qu'il
                // brille : un disque blanc net sur un tracé d'accent se détache sans flou.
                let r = lineWidth * HZMarque.rayonDuPoint
                context.fill(Path(ellipseIn: CGRect(x: head.x - r, y: head.y - r,
                                                    width: r * HZMarque.deux, height: r * HZMarque.deux)),
                             with: .color(HZCouleur.blanc))
            }
        }
    }

    /// Où se trouve l'extrémité du chemin déjà parcouru.
    ///
    /// Obtenue en découpant une tranche très courte juste avant `t` et en prenant son coin : un
    /// segment d'un millième de la longueur est trop petit pour qu'on distingue son coin de son
    /// milieu, et c'est beaucoup moins de calcul que de reparcourir les points pour cumuler les
    /// longueurs à chaque image.
    private func headPoint(of path: Path, at t: Double) -> CGPoint? {
        let slice = path.trimmedPath(from: max(0, t - HZMarque.pasDeTangente), to: t)
        let box = slice.boundingRect
        guard !box.isNull, box.width.isFinite, box.height.isFinite else { return nil }
        return CGPoint(x: box.midX, y: box.midY)
    }
}

/// `DrawnRoute` qui se dessine tout seul en apparaissant.
///
/// Séparé pour que l'appelant qui a déjà une progression à lui — un curseur de lecture, un
/// défilement — puisse piloter `DrawnRoute` directement sans se battre contre une animation
/// interne qu'il n'a pas demandée.
struct SelfDrawingRoute: View {
    var route: [RunRecord.RoutePoint]
    var lineWidth: CGFloat = HZMarque.traitDuTrace
    var couleur: Color = HZCouleur.accent
    var targetPoints: Int = HZMarque.pointsDuTrace
    var showsStart = true

    @State private var progress: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        DrawnRoute(route: route, lineWidth: lineWidth, couleur: couleur,
                   targetPoints: targetPoints, showsStart: showsStart, progress: progress)
            .onAppear {
                guard progress == 0 else { return }
                if reduceMotion { progress = 1 } else {
                    withAnimation(HZMouvement.trace) { progress = 1 }
                }
            }
    }
}
