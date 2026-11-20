import CoreText
import SwiftUI

/// Les jetons du widget et de la Live Activity : ceux de l'app, recopiés par rôle.
///
/// L'extension ne compile pas `Haizo/DesignSystem` (voir `WidgetAccentPalette`), donc elle ne peut
/// pas lire `HZCouleur` ni `HZPolice`. Elle en recopie ce dont elle a besoin, avec la même règle :
/// des aplats, aucun dégradé, aucune ombre ; un texte secondaire est un gris OPAQUE, jamais une
/// opacité ; l'accent est une touche (un anneau, une barre, un point, un symbole) et jamais le fond.
///
/// Le widget et la Live Activity étaient les deux seules surfaces encore dessinées dans l'ancien
/// système : Instrument Sans, des libellés en capitales espacées, un fond rose plein pendant une
/// course, des textes à 42 ou 55 % d'opacité. Ils suivent maintenant l'app.
enum WG {

    // MARK: Les couleurs

    /// `HZCouleur.noirFranc` : le fond d'une course, de la Live Activity et du widget en mode sombre.
    static let noirFranc = Color(hex: 0x000000)
    static let blanc = Color(hex: 0xFFFFFF)
    /// `HZCouleur.encre` : le texte sur le blanc.
    static let encre = Color(hex: 0x111111)
    /// `HZCouleur.surfaceSombre` : une pastille posée sur le noir.
    static let surfaceSombre = Color(hex: 0x1C1C1E)
    /// `HZCouleur.surfaceClaire` : une pastille posée sur le blanc.
    static let surfaceClaire = Color(hex: 0xF4F4F6)
    /// `HZCouleur.filetSombre` : le rail d'une barre ou d'un anneau, sur le noir.
    static let filetSombre = Color(hex: 0x2C2C2E)
    /// `HZCouleur.filetGroupe` : le rail d'une barre ou d'un anneau, sur le blanc.
    static let filetClair = Color(hex: 0xE4E4E8)
    /// `HZCouleur.pointEteint` : le point d'un jour sans séance, sur le noir.
    static let pointEteintSombre = Color(hex: 0x3A3A3C)
    /// `HZCouleur.contour` : le même point, sur le blanc.
    static let pointEteintClair = Color(hex: 0xDCDCE0)
    /// `HZCouleur.secondaireSurClair` et `.secondaireSurSombre`.
    static let secondaireSurClair = Color(hex: 0x6E6E73)
    static let secondaireSurSombre = Color(hex: 0xA1A1A6)

    /// LE ROSE DE LA MONTRE ET DU WIDGET RESTE `#FF0A78` — décision de Charlotte, qui ne le
    /// rapproche pas du `#FF2E6E` de l'app. C'est la seule valeur de ce fichier qui ne soit pas
    /// celle de l'app ; les trois autres accents le sont (`WidgetAccentPalette`).
    static let rose = Color(hex: 0xFF0A78)

    // MARK: La fonte

    /// ARCHIVO, comme l'app (`HZPolice`) : le même fichier variable, que cette cible embarque et
    /// enregistre dans son `UIAppFonts`. Un axe de graisse, réglé par CoreText — `Font.custom` ne
    /// sait pas régler un axe — et la largeur 100 (la largeur d'affichage de l'iPhone, 125 %,
    /// n'entre pas dans un widget de 158 points).
    ///
    /// Une famille introuvable ne lève rien : CoreText rend la police système. Ce qui garde cette
    /// fonction honnête, c'est `check_fonts.py` (le fichier est-il enregistré et livré ?) et la
    /// capture, seul endroit où l'on voit le résultat.
    enum Graisse: CGFloat {
        case moyen = 500, semi = 600, gras = 700
    }

    static func police(_ taille: CGFloat, _ graisse: Graisse = .gras) -> Font {
        let descripteur = CTFontDescriptorCreateWithAttributes([
            kCTFontFamilyNameAttribute: famille,
            kCTFontVariationAttribute: [axeDeGraisse: graisse.rawValue, axeDeLargeur: largeur],
        ] as CFDictionary)
        return Font(CTFontCreateWithFontDescriptor(descripteur, taille, nil))
    }

    private static let famille = "Archivo"
    /// « wght » et « wdth », lus comme un entier de quatre octets : la forme que
    /// `kCTFontVariationAttribute` attend, et qui n'a pas de constante nommée.
    private static let axeDeGraisse = 0x7767_6874
    private static let axeDeLargeur = 0x7764_7468
    private static let largeur: CGFloat = 100

    /// L'interlettrage d'un grand chiffre : quatre centièmes du corps, dans la mesure de l'app.
    /// Jamais positif : il n'y a plus de capitales à espacer.
    static let serrage: CGFloat = 0.04
    static func serre(_ taille: CGFloat) -> CGFloat { -taille * serrage }

    // MARK: Les corps

    /// Les corps que le widget et la Live Activity emploient, nommés par rôle.
    enum Corps {
        static let minuscule: CGFloat = 9.5
        static let petit: CGFloat = 10
        static let etiquette: CGFloat = 10.5
        static let legende: CGFloat = 11
        static let texte: CGFloat = 12
        static let valeur: CGFloat = 13
        static let titre: CGFloat = 15
        static let chiffre: CGFloat = 17
        static let chiffreDeCourse: CGFloat = 18
        static let grandChiffre: CGFloat = 24
        static let chronoLive: CGFloat = 26
        static let chronoPetit: CGFloat = 30
        static let chronoMoyen: CGFloat = 40
    }
}
