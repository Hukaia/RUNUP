import Foundation

/// Les tailles de l'écran de course de la montre, dérivées de la hauteur réellement disponible.
///
/// # Pourquoi ces tailles ne sont pas écrites dans la vue
///
/// Cet écran ne peut être regardé par personne. Il n'y a ni simulateur ni montre dans
/// l'environnement où il est écrit, et la personne qui décide n'en a pas non plus — elle court
/// avec une Garmin. Un écran que personne ne peut regarder ne doit pas pouvoir déborder, et la
/// seule façon de s'en assurer sans le voir est de rendre son encombrement CALCULABLE.
///
/// D'où ce type, sans SwiftUI, avec deux responsabilités : donner à la vue chaque taille, et
/// donner au test la hauteur que l'empilement occupera. Les deux lisent les mêmes valeurs — une
/// taille modifiée déplace le calcul du même coup, et le test le dit.
///
/// # Ce que le calcul vaut, et ce qu'il ne vaut pas
///
/// La hauteur d'une ligne de texte est ESTIMÉE, pas mesurée : Inter occupe environ 1,211 fois sa
/// taille de point (0,969 de montée, 0,242 de descente). C'est une bonne approximation du moteur
/// de rendu, pas le moteur de rendu. D'où la marge de sécurité conservée sur chaque décision
/// plutôt qu'un ajustement au point près, qu'une estimation ne mérite pas.
///
/// Les marges système de watchOS, elles, ne sont pas estimées du tout : la vue lit la hauteur que
/// le système lui donne, quelle qu'elle soit. C'est précisément ce qui permet de ne pas avoir à
/// les deviner.
struct WatchRunMetrics {
    /// La hauteur pour laquelle l'écran a été dessiné — la zone utile d'un boîtier 45 mm. Toutes
    /// les tailles ci-dessous sont exprimées en proportion d'elle.
    static let referenceHeight: CGFloat = 214

    /// Ce qu'on garde libre entre le bas de l'empilement et le bord, pour absorber l'écart entre
    /// la hauteur estimée d'une ligne et celle que le rendu produira.
    static let safetyMargin: CGFloat = 6

    let availableHeight: CGFloat
    /// Plafonné à 1 : au-delà on gonflerait un dessin validé à sa taille, sur un Ultra par exemple.
    /// Planché à 0,55 : en dessous, les planchers de lisibilité dominent et la proportion ne veut
    /// plus rien dire.
    let scale: CGFloat

    init(availableHeight: CGFloat) {
        self.availableHeight = availableHeight
        self.scale = min(1, max(0.55, availableHeight / Self.referenceHeight))
    }

    // MARK: Les tailles
    //
    // La refonte (aplats, chiffres gras et serrés, libellés en casse de phrase) a changé ce que
    // l'empilement contient, et le budget a été refait avec lui. Ce qui entre : un filet au-dessus
    // des trois mesures (5 points, le dessin de l'écran de course de l'iPhone), des libellés d'un
    // demi-point de plus que les petites capitales qu'ils remplacent, des boutons de 40 au lieu de
    // 34. Ce qui sort : le héros passe de 46 à 42 — il est maintenant en graisse 700, plus large
    // à corps égal, et c'est sur lui que la place se reprend.
    //
    // Mesuré avec le même calcul que `WatchRunMetricsTests` (balayage de 140 à 240 points) : sur
    // un 45 mm l'écran garde quatorze points de libre, sur un 40 mm dix, la légende de progression
    // survit partout.
    //
    // Les planchers ne protègent pas les mêmes choses que l'échelle. Un grand chiffre peut
    // rétrécir beaucoup et rester lisible — c'est le plus gros objet de l'écran. Un libellé de
    // 8 points, non : sous ce seuil il cesse d'être un mot pour devenir une texture grise.

    var spacing: CGFloat { 5 * scale }
    var horizontalPadding: CGFloat { 4 }

    var statusDot: CGFloat { max(5, 6 * scale) }
    var statusText: CGFloat { max(8, 10.5 * scale) }

    var hero: CGFloat { 42 * scale }
    var heroGap: CGFloat { 2 * scale }
    var heroLabel: CGFloat { max(8, 10.5 * scale) }

    var progressTop: CGFloat { 5 * scale }
    /// Non mise à l'échelle : quatre points est déjà l'épaisseur minimale d'une barre visible.
    var progressBar: CGFloat { 4 }
    var progressGap: CGFloat { 3 * scale }
    var progressCaption: CGFloat { max(7.5, 9.5 * scale) }

    var secondaryValue: CGFloat { 16 * scale }
    var secondaryGap: CGFloat { 1 * scale }
    var secondaryUnit: CGFloat { max(7, 9 * scale) }
    /// Ce qui sépare le filet des trois mesures de leurs chiffres.
    var secondaryTop: CGFloat { 5 * scale }

    var buttonTop: CGFloat { 2 }
    /// Plancher à 30 : c'est une cible tactile qu'on vise en courant, pas une décoration. 44 n'est
    /// atteignable sur aucun boîtier sans reprendre le héros, qui est ce qu'on vient lire ; la
    /// capsule fait en revanche la moitié de la largeur de l'écran, ce qui compense en surface.
    var buttonHeight: CGFloat { max(30, 40 * scale) }
    var buttonIcon: CGFloat { max(13, 16 * scale) }

    // MARK: L'arbitrage

    /// La légende sous la barre — « Séance · 85 % » — est le premier élément sacrifié quand la
    /// place manque, et le seul.
    ///
    /// La barre porte déjà l'information ; le pourcentage n'en est que la version chiffrée. Tout
    /// le reste de l'écran est soit le chiffre qu'on est venu lire, soit un bouton dont on a
    /// besoin. Sur un 40 mm, cette ligne est ce qui sépare un écran juste d'un écran rogné.
    var showsProgressCaption: Bool {
        height(showsProgress: true, showsCaption: true) + Self.safetyMargin <= availableHeight
    }

    // MARK: L'encombrement

    /// Inter : 0,969 de montée + 0,242 de descente ≈ 1,211 fois la taille de point. La montre est
    /// maintenant en Archivo, dont la ligne naturelle fait 1,088 : on garde 1,211 exprès, comme une
    /// borne haute — l'écran de course n'occupera jamais PLUS que ce que ce calcul annonce.
    private static let interLineFactor: CGFloat = 1.211

    static func sansLine(_ size: CGFloat) -> CGFloat { size * interLineFactor }

    /// Les grands chiffres passent par `DisplayFont`, qui applique son facteur de compensation
    /// avant de demander la police : c'est cette taille-là qui occupe la place.
    static func displayLine(_ size: CGFloat) -> CGFloat {
        DisplayFont.pointSize(for: size) * interLineFactor
    }

    /// La hauteur qu'occupera l'empilement, dans une composition donnée.
    ///
    /// La même arithmétique que le `VStack` de la vue : les blocs, plus un espacement entre
    /// chaque paire. Les deux `Spacer` n'y figurent pas — ils valent zéro dès que la place manque,
    /// et c'est le seul cas qui nous intéresse ici.
    func height(showsProgress: Bool, showsCaption: Bool) -> CGFloat {
        var blocks: [CGFloat] = [
            Self.sansLine(statusText),
            Self.displayLine(hero) + heroGap + Self.sansLine(heroLabel),
        ]
        if showsProgress {
            var progress = progressTop + progressBar
            if showsCaption { progress += progressGap + Self.sansLine(progressCaption) }
            blocks.append(progress)
        }
        blocks.append(secondaryTop + Self.displayLine(secondaryValue) + secondaryGap + Self.sansLine(secondaryUnit))
        blocks.append(buttonTop + buttonHeight)
        return blocks.reduce(0, +) + spacing * CGFloat(blocks.count - 1)
    }

    /// L'encombrement réel, une fois l'arbitrage de la légende appliqué.
    func height(showsProgress: Bool) -> CGFloat {
        height(showsProgress: showsProgress, showsCaption: showsProgress && showsProgressCaption)
    }
}
