import SwiftUI

/// Les quatre accents de l'app (`HZAccent`), recopiés à la main : l'`@Observable` `ThemeStore` de
/// l'app vit dans son processus, le widget ne pourrait jamais en recevoir les mises à jour, et sa
/// cible ne compile pas `Haizo/DesignSystem`. Ce qui voyage de l'app au widget, c'est l'identifiant
/// du thème (`DailyGoalsSnapshot.accentThemeID`) ; ce fichier le traduit en couleur.
///
/// # LE MÊME REPLI QUE L'APP
///
/// L'app a retiré quatre de ses huit anciens thèmes le 19 novembre. Un identifiant enregistré peut
/// donc être l'un des anciens, et `HZAccent.depuis(ancienTheme:)` décide ce qu'il devient :
/// « cyan », « lime » et « vert » deviennent le vert, « violet » et « bleu » se retrouvent, et
/// tout le reste — ambre, corail, magenta, un identifiant inconnu — revient au rose. Ce widget
/// faisait autrement : il dessinait encore les huit teintes, donc un téléphone réglé sur « lime »
/// affichait un anneau lime sous une app verte.
///
/// # UNE VALEUR PAR ACCENT, SUR CLAIR COMME SUR SOMBRE
///
/// L'app n'a plus de variante « sur clair » : un accent n'a qu'une valeur. La table claire qui
/// assombrissait le rose de 10 % pour tomber sur `#F0225F` a disparu avec elle.
///
/// # LE ROSE
///
/// Le rose de la montre et du widget reste `#FF0A78` (`WG.rose`), décision de Charlotte, contre
/// `#FF2E6E` dans l'app. Les trois autres sont ceux de l'app, au bit près.
enum WidgetAccentPalette {
    /// La couleur de l'accent. Un seul tableau de trois valeurs identiques est rendu par
    /// `ringColors` : l'anneau est mono-accent, comme celui de l'accueil.
    static func accent(themeID: String) -> Color {
        switch themeID {
        case "violet": return Color(hex: 0x7B3FE4)
        case "bleu": return Color(hex: 0x2F6BFF)
        case "cyan", "lime", "vert": return Color(hex: 0x12A56B)
        default: return WG.rose
        }
    }

    /// La couleur de l'anneau, trois fois — `DailyGoalsBarsView.fillColors` rend le même tableau.
    static func ringColors(themeID: String, isLight: Bool) -> [Color] {
        Array(repeating: accent(themeID: themeID), count: 3)
    }
}
