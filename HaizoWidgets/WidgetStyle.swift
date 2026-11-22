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

    /// `HZCouleur.noir` : le fond de l'en-tête de l'accueil, et du widget d'accueil — le même noir que
    /// l'app pose derrière sa séance du jour.
    static let noir = Color(hex: 0x0B0B0C)
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

    /// `HZAccent.rose` : le rose de l'app, `#FC105E` depuis le 22 novembre (celui du logo). Il valait `#FF2E6E` du 20 au 22 novembre, et `#FF0A78` avant
    /// (décision de Charlotte de le laisser), puis elle a demandé de l'aligner sur l'app : les
    /// quatre accents de ce fichier sont désormais ceux de l'app, au bit près.
    static let rose = Color(hex: 0xFC105E)

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
        fabrique(taille, graisse: graisse.rawValue, largeur: largeur)
    }

    /// LA FONTE D'AFFICHAGE de l'app (`HZPolice.affichage`) : graisse 800, largeur 125 %. Pour le très
    /// grand chiffre seulement — celui de la séance du jour sur le widget d'accueil, comme sur
    /// l'accueil de l'app. Sa largeur ne tient que pour trois ou quatre signes : le widget la
    /// réduit (`minimumScaleFactor`) plutôt que de la couper.
    static func affichage(_ taille: CGFloat) -> Font {
        fabrique(taille, graisse: graisseDAffichage, largeur: largeurDAffichage)
    }

    private static func fabrique(_ taille: CGFloat, graisse: CGFloat, largeur: CGFloat) -> Font {
        let descripteur = CTFontDescriptorCreateWithAttributes([
            kCTFontFamilyNameAttribute: famille,
            kCTFontVariationAttribute: [axeDeGraisse: graisse, axeDeLargeur: largeur],
        ] as CFDictionary)
        return Font(CTFontCreateWithFontDescriptor(descripteur, taille, nil))
    }

    private static let famille = "Archivo"
    /// « wght » et « wdth », lus comme un entier de quatre octets : la forme que
    /// `kCTFontVariationAttribute` attend, et qui n'a pas de constante nommée.
    private static let axeDeGraisse = 0x7767_6874
    private static let axeDeLargeur = 0x7764_7468
    private static let largeur: CGFloat = 100
    private static let graisseDAffichage: CGFloat = 800
    private static let largeurDAffichage: CGFloat = 125

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
        /// Le très grand chiffre de la séance du jour, sur le widget d'accueil.
        static let grandNombre: CGFloat = 62
        /// Le chiffre dans l'anneau des objectifs.
        static let chiffreDeLAnneau: CGFloat = 22
        static let chronoPetit: CGFloat = 30
        static let chronoMoyen: CGFloat = 40
        /// Le chrono de la Live Activity, en fonte d'affichage (largeur 125 %) : un seul chiffre qui
        /// domine l'écran verrouillé. 46 et non plus : la pile (en-tête, chrono, barre, tuiles) doit
        /// tenir sous les 158 points que `WidgetRenduTests` impose à la carte.
        static let chronoAffichage: CGFloat = 46
        /// Le chiffre d'une tuile (distance, allure) de la Live Activity.
        static let valeurDeTuile: CGFloat = 22
    }

    // MARK: Les formes de la Live Activity

    /// Mesurées sur une maquette rendue avec le vrai fichier Archivo, à la taille d'une carte
    /// d'écran verrouillé (359 points de large) : la carte fait 138 points de haut, sous les 160
    /// que le système accorde avant de couper.
    enum Forme {
        static let rayonDeTuile: CGFloat = 14
        static let ecart: CGFloat = 8
        static let ecartDeColonnes: CGFloat = 14
        static let margeHorizontale: CGFloat = 18
        /// La marge haute et basse de la carte de la Live Activity : serrée, la carte est haute.
        static let margeVerticaleSerree: CGFloat = 12
        /// Entre les quatre rangées de la carte (état, chrono, barre, tuiles).
        static let ecartDeLaCarte: CGFloat = 6
        static let tuileHorizontale: CGFloat = 12
        static let tuileVerticale: CGFloat = 6
        static let hauteurDeBarre: CGFloat = 6
        static let pointDEtat: CGFloat = 6
        static let reductionDuChrono: CGFloat = 0.6
        /// Le grand nombre peut rétrécir jusqu'à la moitié avant d'être coupé.
        static let reductionDuGrandNombre: CGFloat = 0.5
        static let margeDuWidget: CGFloat = 14
        static let margeDuWidgetMoyen: CGFloat = 16
        static let ecartDesPoints: CGFloat = 5
        static let pointDeLaSemaine: CGFloat = 7
        static let traitDuJour: CGFloat = 2
        /// 78 et non 84 : à 84, « bouclés » touchait le bas de l'anneau (rendu CI du 21 novembre) et la
        /// pile, avec l'écart qu'on lui rend, ne tient plus dans les 158 points d'un moyen.
        static let anneauDuMoyen: CGFloat = 78
        static let anneauDuPetit: CGFloat = 74
    }
}
