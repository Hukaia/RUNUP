import SwiftUI

/// The app's logo mark — "Stride Bars": 4 rounded-cap strokes of increasing height (stride/
/// cadence, reading left→right as acceleration) on a rounded-square tile filled with the brand
/// gradient. Geometry ported 1:1 from the design handoff's 100×100 SVG viewBox (see LOGO.md) —
/// deliberately not a progress-ring glyph or parallel bars, both dropped in the handoff for
/// reading too close to existing marks (Apple Fitness rings / adidas stripes).
struct AppMarkView: View, Animatable {
    var size: CGFloat = HZMarque.coteParDefaut
    var radius: CGFloat? = nil
    var color: Color = .white
    /// L'avancement du TRACÉ des quatre barres : 0 = la tuile nue, 1 = la marque entière.
    ///
    /// Par défaut 1, donc tous les appels existants — barre d'onglets, notification, en-tête —
    /// rendent exactement ce qu'ils rendaient. Seul le lancement s'en sert pour faire naître la
    /// marque trait par trait, et il le fait sur CETTE géométrie plutôt que sur une copie : les
    /// quatre couples de coordonnées ci-dessous viennent de la maquette, et deux exemplaires
    /// auraient divergé au premier ajustement.
    var drawn: Double = 1

    var animatableData: Double {
        get { drawn }
        set { drawn = newValue }
    }

    /// Le fond de la tuile. `nil` — le cas par défaut — rend le dégradé de marque.
    ///
    /// # Pourquoi ce paramètre existe
    ///
    /// Point 3 du brief du 15 novembre : « l'icône du coach devient le pictogramme des quatre
    /// barres en noir sur `#F3EEF4` ». Il ne vise pas la marque — partout ailleurs, cette tuile
    /// EST la signature de l'app, et un logo garde son dessin. Il vise le seul endroit où elle ne
    /// signe rien : à côté de « Ton coach », elle sert de PORTRAIT D'INTERLOCUTEUR. Une icône
    /// d'application en guise de visage, c'est ce qui fait lire « une app me parle » plutôt que
    /// « quelqu'un me répond ».
    ///
    /// LA VALEUR EST `card2`, PAS `#F3EEF4`, et la décision est déjà écrite dans `ChipView` le
    /// 16 novembre : `#F3EEF4` est une lavande FROIDE, les fonds clairs de l'app sont chauds
    /// depuis le 12 novembre, et `check_jetons_de_texte.py` tient la règle « la famille du
    /// fond ». On garde la direction du brief — une surface déclarée, opaque — et la famille de
    /// la page.
    var fond: Color? = nil

    private var remplissage: AnyShapeStyle {
        if let fond { return AnyShapeStyle(fond) }
        // Le dégradé du logo, JAMAIS la couleur d'accentuation : voir `HZMarque.degrade`.
        return AnyShapeStyle(HZMarque.degrade)
    }

    private var cornerRadius: CGFloat { radius ?? size * HZMarque.rayonRelatif }
    private var glyphSize: CGFloat { size * HZMarque.glypheRelatif }

    /// (x1, y1, x2, y2, lineWidth, opacity) in the design's 100×100 viewBox.
    private static let bars = HZMarque.barres

    /// Où en est la barre `index` quand la marque entière en est à `d`.
    ///
    /// Les quatre tracés se chevauchent au lieu de se succéder : à 0,18 d'écart pour 0,46 de
    /// durée, la deuxième part quand la première est à 40 %. Bout à bout, on compterait les
    /// barres ; en se chevauchant, on lit une accélération — ce que le logo raconte déjà par ses
    /// hauteurs croissantes.
    static func progress(ofBar index: Int, at d: Double) -> Double {
        let depart = Double(index) * HZMarque.decalageDesBarres
        let duree = HZMarque.dureeDUneBarre
        return min(max((d - depart) / duree, 0), 1)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(remplissage)
            .frame(width: size, height: size)
            .overlay(
                ZStack {
                    ForEach(Array(Self.bars.enumerated()), id: \.offset) { index, bar in
                        let scale = glyphSize / HZMarque.grilleDuGlyphe
                        Path { path in
                            path.move(to: CGPoint(x: bar.0 * scale, y: bar.1 * scale))
                            path.addLine(to: CGPoint(x: bar.2 * scale, y: bar.3 * scale))
                        }
                        // La barre part du BAS (y = 88) vers le haut : couper le chemin à sa
                        // longueur la fait donc POUSSER, ce qui est exactement la lecture voulue
                        // — quatre foulées qui montent, de gauche à droite.
                        .trim(from: 0, to: Self.progress(ofBar: index, at: drawn))
                        .stroke(color.opacity(bar.5), style: StrokeStyle(lineWidth: bar.4 * scale, lineCap: .round))
                    }
                }
                .frame(width: glyphSize, height: glyphSize)
            )
    }
}

/// Le mot de la marque, dessiné — et non composé dans la fonte de l'interface.
///
/// # POURQUOI UNE IMAGE PLUTÔT QU'UN `Text`
///
/// Jusqu'au 16 novembre, quatre écrans composaient le nom en capitales dans Instrument Sans,
/// avec un `tracking` réglé à la main. Ce n'était pas le logo : c'était son NOM, composé dans
/// la fonte de l'app. Un logo est un dessin ; il ne se retape pas, et surtout il ne suit
/// pas la fonte de l'interface le jour où elle change — ce qui est arrivé deux fois cette
/// semaine, Bebas puis Inter puis Instrument Sans.
///
/// Le kit de marque livre le mot en minuscules. C'est la forme retenue : les rondes du `a` et du
/// `o` portent une identité que les capitales effacent.
///
/// # POURQUOI UNE IMAGE *TEMPLATE*
///
/// Le mot paraît sur plusieurs fonds et en plusieurs encres : l'encre de marque sur le
/// lancement, du blanc sur une image de course, de l'encre sur une carte de partage claire. Une
/// image template ne porte que la forme et prend la couleur qu'on lui donne par `foregroundStyle`.
///
/// Ce n'est pas une licence : le kit lui-même livre la même forme en deux encres. La forme est
/// la marque, la couleur est le contexte.
///
/// # LA HAUTEUR EST CELLE DU KIT, PAS UNE VALEUR CHOISIE À L'ŒIL
///
/// Mesuré sur `haizo_A_white.png` : le mot fait **0,835 fois la hauteur du symbole**. Dans
/// `AppMarkView`, les barres occupent **0,59** de la tuile — `glyphSize` vaut `size * HZMarque.glypheRelatif` et
/// les barres traversent 95 % de leur zone de dessin. Le mot vaut donc `0,835 × 0,59 ≈ 0,49`
/// fois la tuile qui l'accompagne, et c'est la seule constante de ce fichier.
struct MotDeMarque: View {
    /// La taille de la tuile `AppMarkView` à côté de laquelle le mot est posé.
    var tuile: CGFloat

    /// Le rapport mesuré sur le kit — voir le commentaire en tête.
    static let hauteurRelative: CGFloat = HZMarque.hauteurDuMot

    var body: some View {
        Image("haizo-mot")
            .resizable()
            .scaledToFit()
            .frame(height: tuile * Self.hauteurRelative)
            // Le mot est une image, pas du texte : sans ceci, VoiceOver ne dirait rien là où
            // il lisait le nom.
            .accessibilityLabel(Text(verbatim: "Haizo"))
    }
}
