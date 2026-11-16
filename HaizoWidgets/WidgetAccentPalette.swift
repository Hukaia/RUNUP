import SwiftUI

/// Mirrors just the hex triples from the app's `AccentTheme.all`
/// (`Haizo/DesignSystem/AccentTheme.swift`) — duplicated by hand rather than shared across the
/// app/widget target boundary, since the live `ThemeStore`/`RUColor` machinery is an in-process
/// `@Observable` singleton the widget's separate process could never actually receive live updates
/// from anyway. Keep in sync by hand if `AccentTheme.all`'s hex values ever change.
enum WidgetAccentPalette {
    private static let swatches: [String: (primary: UInt32, light: UInt32, tail: UInt32)] = [
        "rose": (0xFF0A78, 0xFF4D9E, 0x7C5CFF),
        "violet": (0x7C5CFF, 0xA78BFF, 0xFF0A78),
        "bleu": (0x3D8BFF, 0x8AB8FF, 0x7C5CFF),
        "cyan": (0x2FD9C4, 0x7CF0E4, 0x3D8BFF),
        "lime": (0x9FE83D, 0xDFFF8C, 0x2FD9C4),
        "amber": (0xFFB03D, 0xFFD08A, 0xFF4D9E),
        "corail": (0xFF5A3D, 0xFF9478, 0xFFB03D),
        "magenta": (0xD633B8, 0xF07ADB, 0x7C5CFF)
    ]

    /// LE CLAIR N'EST PAS LA TABLE BRUTE, ET C'EST CE QUI A DÉRIVÉ.
    ///
    /// `swatches` ci-dessus recopie `AccentTheme.all`, et `check_accent.py` le vérifie. Mais
    /// l'app n'affiche PAS `all` en thème clair : elle affiche `AccentTheme.resolvedOnLight`,
    /// qui remplace le rose par la valeur de la maquette — `#F0225F` depuis le 15 novembre — et
    /// descend les autres nuanciers au seuil de contraste. Le miroir était donc exact sur la
    /// table qu'il copiait, et faux sur ce qui est dessiné : le widget rendait un rose
    /// `#FF0A78` assombri de 10 %, l'app `#F0225F`. Deux roses voisins, sur deux écrans qu'on
    /// voit l'un après l'autre.
    ///
    /// Les valeurs claires de la maquette sont donc recopiées ici aussi, et le repli — un
    /// assombrissement de 10 % — reste ce qu'il était pour les nuanciers que la maquette ne
    /// fixe pas. Ce n'est pas la dichotomie de contraste de l'app, et c'est volontaire : ce
    /// fichier existe parce que la cible du widget ne compile pas `Haizo/DesignSystem`.
    private static let mockupLight: [String: UInt32] = ["rose": 0xF0225F]

    /// La couleur de l'anneau, trois fois — l'anneau est mono-accent depuis le 16 novembre, et
    /// `DailyGoalsBarsView.fillColors` rend le même tableau de trois valeurs identiques.
    static func ringColors(themeID: String, isLight: Bool) -> [Color] {
        let swatch = swatches[themeID] ?? swatches["rose"]!
        let accent: Color
        if isLight {
            accent = mockupLight[themeID].map { Color(hex: $0) }
                ?? Color(hex: swatch.primary).darkened(0.10)
        } else {
            accent = Color(hex: swatch.primary)
        }
        return Array(repeating: accent, count: 3)
    }
}
