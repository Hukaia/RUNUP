import CoreText
import SwiftUI
import UIKit

/// LA FONTE DE LA REFONTE : Archivo, variable, sur deux axes.
///
/// Le canvas du 17 novembre compose tout avec elle, en deux registres seulement :
///
///     affichage    largeur 125 %, graisse 800, interlettrage serré
///     interface    largeur 100 %, graisses 500, 600, 700
///
/// # CE QUE LE CANVAS ÉCRIT, ET CE QU'IL MONTRE
///
/// Il ne charge que QUATRE faces de la fonte : 500, 600 et 700 en largeur 100, et 800 en largeur
/// 125. Un navigateur à qui l'on demande autre chose rend la plus proche de celles qu'il a. Deux
/// conséquences, vérifiées en rendant le canvas avec ces quatre faces et pas une de plus :
///
///   · un texte dont la graisse n'est PAS écrite (les sous-titres de 13, les bulles du coach)
///     demande 400 et s'affiche en 500 ;
///   · les deux chiffres écrits en 800 sans largeur d'affichage — « 15 000 » dans les réglages,
///     « 8/10 » sur le profil — s'affichent en 700.
///
/// La référence est ce qu'on VOIT. Il n'y a donc ni 400 ni 800 d'interface ici.
///
/// # POURQUOI PASSER PAR UIKit
///
/// `Font.custom(_:size:)` prend un NOM et une taille. Il ne sait rien d'un axe de variation, et
/// Archivo n'a pas d'instance nommée en largeur 125 : ses neuf instances vont de Thin à Black,
/// toutes en largeur 100. La largeur d'affichage ne s'obtient donc qu'en réglant l'axe `wdth`
/// soi-même, ce que seul un descripteur CoreText permet.
///
/// Les deux axes sont désignés par leur étiquette de quatre lettres lue comme un entier — c'est
/// la forme que `kCTFontVariationAttribute` attend, et elle n'a pas de constante nommée.
///
/// Vérifié sur le fichier embarqué, pas sur la foi de sa page : `wght` 100 → 900, `wdth`
/// 62 → 125, chiffres tabulaires présents (`tnum`), interligne naturel 1,088 sans espace ajouté.
enum HZPolice {
    static let famille = "Archivo"

    /// « wght », en quatre octets.
    private static let axeDeGraisse = 0x7767_6874
    /// « wdth », en quatre octets.
    private static let axeDeLargeur = 0x7764_7468

    static let largeurDInterface: CGFloat = 100
    static let largeurDAffichage: CGFloat = 125
    static let graisseDAffichage: CGFloat = 800

    /// La hauteur de ligne naturelle de la fonte, en multiple de son corps : 878 + 210 sur 1000.
    /// C'est ce que CSS appelle `line-height: normal`, et ce que SwiftUI donne sans rien demander.
    static let interligneNaturel: CGFloat = 1.088

    /// De combien un texte d'INTERFACE a le droit de grandir avec le réglage « Taille du texte »
    /// d'iOS. L'affichage, lui, ne grandit pas : un « 500 » de 128 points occupe déjà la largeur
    /// de l'écran.
    ///
    /// 1,3 × et pas les 2,0 × de l'ancien système : celui-ci avait gagné son plafond écran par
    /// écran, en réorganisant chaque mise en page aux grandes tailles et en la photographiant.
    /// Ce travail est à refaire pour chaque écran de la refonte. D'ici là, le plafond reste là où
    /// les hauteurs fixes du canvas — pilule de 40, ligne de 64 — tiennent encore.
    static let plafondDInterface: CGFloat = 1.3

    // MARK: - Les deux registres

    static func affichage(_ taille: CGFloat) -> Font {
        Font(uiFonte(taille: taille, graisse: graisseDAffichage, largeur: largeurDAffichage,
                     tabulaire: true) as CTFont)
    }

    static func texte(_ corps: HZCorps, _ graisse: HZGraisse, tabulaire: Bool = false) -> Font {
        Font(uiFonte(taille: aLEchelle(corps.rawValue), graisse: graisse.rawValue,
                     largeur: largeurDInterface, tabulaire: tabulaire) as CTFont)
    }


    // MARK: - La fabrication

    static func uiFonte(taille: CGFloat, graisse: CGFloat, largeur: CGFloat,
                        tabulaire: Bool) -> UIFont {
        var attributs: [UIFontDescriptor.AttributeName: Any] = [
            .family: famille,
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): [
                axeDeGraisse: graisse,
                axeDeLargeur: largeur,
            ],
        ]
        if tabulaire {
            attributs[.featureSettings] = [[
                UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector,
            ]]
        }
        return UIFont(descriptor: UIFontDescriptor(fontAttributes: attributs), size: taille)
    }

    /// Même mécanisme que `RUFont` : la catégorie vient de `TextSizeStore`, pour que le
    /// changement de réglage invalide les vues qui ont dessiné du texte.
    /// La taille réelle d'un corps de texte, une fois le réglage de l'utilisateur appliqué.
    static func taille(_ corps: HZCorps) -> CGFloat { aLEchelle(corps.rawValue) }

    private static func aLEchelle(_ taille: CGFloat) -> CGFloat {
        let traits = UITraitCollection(preferredContentSizeCategory: TextSizeStore.shared.category)
        let voulue = UIFontMetrics(forTextStyle: .body).scaledValue(for: taille, compatibleWith: traits)
        return min(voulue, taille * plafondDInterface)
    }

    // MARK: - Le contrôle, pour la planche

    /// CE QUE LA FONTE A VRAIMENT DONNÉ. Une fonte variable mal déclarée ne plante pas : UIKit
    /// rend la fonte système à la place, sans un mot, et tout l'écran change de dessin. Et un axe
    /// ignoré ne plante pas davantage : le texte sort en largeur 100.
    ///
    /// Les deux se mesurent : la famille résolue se lit, et « 500 » doit être plus large en
    /// largeur 125 qu'en largeur 100. La planche affiche ce constat, pour qu'il soit sur la
    /// capture et non dans une supposition.
    static var constat: (famille: String, largeurActive: Bool, graisseActive: Bool) {
        func largeur(_ police: UIFont) -> CGFloat {
            ("500" as NSString).size(withAttributes: [.font: police]).width
        }
        let etroite = uiFonte(taille: 100, graisse: 800, largeur: 100, tabulaire: false)
        let large = uiFonte(taille: 100, graisse: 800, largeur: 125, tabulaire: false)
        let maigre = uiFonte(taille: 100, graisse: 300, largeur: 100, tabulaire: false)
        return (large.familyName,
                largeur(large) > largeur(etroite) * 1.05,
                largeur(etroite) > largeur(maigre) * 1.02)
    }
}

/// Les corps du texte d'interface. Huit, et le canvas n'en emploie pas d'autre.
/// LA LIGNE, TELLE QUE LE CANVAS LA COMPTE.
///
/// Le canvas est du HTML, rendu par Chromium, et Chromium ne compte pas une ligne comme SwiftUI :
///
/// - il ARRONDIT à l'entier l'ascendante et la descendante de la fonte. À 12 points, Archivo fait
///   10,5 + 2,5 : Chromium compte 11 + 3 = 14 de haut, SwiftUI 13,06, puis 13,33 une fois calé
///   sur le pixel. À 13 points, 14 contre 14,33. Une ligne n'est jamais de la même hauteur d'un
///   côté et de l'autre, et l'écart se cumule du haut de l'écran jusqu'en bas ;
/// - quand l'interligne est PLUS PETIT que le texte (0,92 pour un grand chiffre), il coupe la
///   différence en deux et ARRONDIT LA DEMI-MARGE VERS LE BAS. Un grand chiffre y descend d'un
///   point de moins qu'au centrage naïf.
///
/// Mesuré le 17 novembre sur la planche de l'étape 1 : les points de la semaine à 0,7 pt trop
/// haut, les tuiles de stats à 0,33 pt trop hautes chacune (86,33 contre 86,00), le « 500 » et
/// le « 118 » à 1,0 pt trop bas. Une seule cause, quatre symptômes.
///
/// Les deux ratios sont ceux de la table `hhea` du fichier de fonte (878 et 210 sur 1000).
enum HZLigne {
    static let ascendante: CGFloat = 0.878
    static let descendante: CGFloat = 0.210

    static func haut(_ taille: CGFloat) -> CGFloat { (ascendante * taille).rounded() }
    static func bas(_ taille: CGFloat) -> CGFloat { (descendante * taille).rounded() }

    /// `line-height: normal` : la hauteur d'une ligne sans interligne imposé.
    static func normale(_ taille: CGFloat) -> CGFloat { haut(taille) + bas(taille) }

    /// La distance du haut d'une boîte de ligne à sa ligne de base, pour une boîte de `hauteur`.
    static func base(taille: CGFloat, hauteur: CGFloat) -> CGFloat {
        haut(taille) + ((hauteur - normale(taille)) / HZLigne.moitie).rounded(.down)
    }

    static let moitie: CGFloat = 2
}

enum HZCorps: CGFloat {
    case c12 = 12, c13 = 13, c14 = 14, c15 = 15, c16 = 16, c17 = 17, c20 = 20, c24 = 24
}

/// Les graisses du texte d'interface. Trois : voir l'en-tête de `HZPolice`.
enum HZGraisse: CGFloat {
    case medium = 500, semi = 600, gras = 700
}

/// UN STYLE D'AFFICHAGE : un corps, son interlettrage, et sa hauteur de ligne.
///
/// # CE N'EST PAS UNE ÉCHELLE, C'EST UNE TABLE
///
/// Le canvas compose trente-deux titres et chiffres différents, et l'interlettrage n'y suit pas
/// le corps par une règle : 40 points se serrent de 2 dans une tuile et de 1,5 devant un nombre.
/// Chaque style est donc relevé tel quel, et nommé par ce qu'il sert.
///
/// # LA HAUTEUR DE LIGNE
///
/// Le canvas serre ses grands chiffres à 0,92 fois leur corps : moins que la hauteur naturelle
/// de la fonte. CSS y parvient en centrant le dessin dans une boîte plus basse que lui, et
/// laisse déborder. `hzAffichage` fait la même chose — une boîte de la hauteur voulue, le texte
/// centré dedans à sa taille réelle — parce que la fonte n'ajoute aucun espace entre ses lignes
/// et que les deux centrages coïncident alors exactement.
struct HZAffichage: Equatable {
    let taille: CGFloat
    let interlettrage: CGFloat
    /// En multiple du corps, comme le canvas l'écrit. `nil` : la hauteur naturelle.
    let interligne: CGFloat?

    init(_ taille: CGFloat, _ interlettrage: CGFloat, _ interligne: CGFloat? = nil) {
        self.taille = taille
        self.interlettrage = interlettrage
        self.interligne = interligne
    }

    var fonte: Font { HZPolice.affichage(taille) }
}

extension HZAffichage {
    // Les très grands chiffres, un par écran.
    /// Stats : le total de kilomètres.
    static let total = HZAffichage(156, -9, 0.92)
    /// Accueil : le nombre de la séance du jour.
    static let seance = HZAffichage(128, -7, 0.92)
    /// Plan : le nombre d'une carte-affiche.
    static let carte = HZAffichage(112, -5, 0.92)
    /// Plan : le même, pour le jour en cours, dont les chiffres ronds se serrent d'un cran.
    static let carteDuJour = HZAffichage(112, -6, 0.92)
    /// Plan : une durée de quatre signes, « 1h20 ».
    static let carteLongue = HZAffichage(84, -4, 0.92)
    /// Résumé : la distance de la sortie.
    static let resume = HZAffichage(104, -6, 0.95)
    /// En direct : l'allure.
    static let direct = HZAffichage(100, -6, 0.95)
    /// Fil du club : la distance d'une sortie.
    static let fil = HZAffichage(76, -4, 1)
    /// Explorer : la distance du parcours mis en avant.
    static let heros = HZAffichage(64, -3.5, 1)
    /// Stats : un record.
    static let record = HZAffichage(52, -2.5, 1)
    /// Accueil : la durée d'une séance à venir.
    static let tuile = HZAffichage(46, -2, 1)
    /// Explorer : la distance d'une course.
    static let tuileDeCourse = HZAffichage(44, -2, 1)

    // Ce qui précède un grand chiffre.
    /// Accueil : « 5 × ».
    static let prefixeDeSeance = HZAffichage(44, -1.5, 1)
    /// Plan : le même, sur une carte.
    static let prefixeDeCarte = HZAffichage(40, -1.5, 1)

    // Les chiffres de tuile.
    /// Coach, et l'allure moyenne des stats.
    static let chiffre = HZAffichage(40, -2, 1)
    /// Stats : les quatre tuiles.
    static let chiffreDeTuile = HZAffichage(36, -1.6, 1)
    /// Profil : les trois totaux.
    static let chiffreDeProfil = HZAffichage(34, -1.5, 1)
    /// Résumé : allure et durée.
    static let mesure = HZAffichage(30, -1.4)
    /// En direct : temps, kilomètres, cardio.
    static let chiffreDuDirect = HZAffichage(28, -1.2)
    /// Une valeur en bout de ligne : cible, temps possibles, mesures du fil.
    static let chiffreDeLigne = HZAffichage(22, -0.8)
    /// Coach : la séance du jour, « 5×500 ».
    static let seanceDuCoach = HZAffichage(21, -1, 1)
    /// Coach : la durée d'une proposition, dans sa vignette.
    static let duree = HZAffichage(20, -1)
    /// Profil : la marque d'un badge.
    static let badge = HZAffichage(17, -0.6)

    // Les titres.
    /// Profil : le prénom.
    static let prenom = HZAffichage(36, -1.6, 1.05)
    /// Plan : « Ta semaine ».
    static let titreDePage = HZAffichage(34, -1.4, 1.1)
    /// Club : le nom du club, sur sa carte.
    static let titreDeCarte = HZAffichage(34, -1.6, 1)
    /// Réglages : le titre de l'écran.
    static let titreDeReglages = HZAffichage(32, -1.2)
    /// Réglages : « Haizo Plus ».
    static let offre = HZAffichage(30, -1.2, 1)
    /// Profil : les initiales, dans l'avatar.
    static let initiales = HZAffichage(30, -1)
    /// Le titre d'un écran d'onglet : Stats, Club.
    static let titreDEcran = HZAffichage(26, -0.8)
    /// Coach : le même, au-dessus d'un sous-titre.
    static let titreDuCoach = HZAffichage(26, -0.8, 1.1)
    /// Plan : le nom d'un objectif, sur sa tuile.
    static let titreDeTuile = HZAffichage(24, -1, 1.05)
    /// Le titre d'une section, dans une feuille.
    static let section = HZAffichage(22, -0.6)
}

private struct HZAffichageModifier: ViewModifier {
    let style: HZAffichage

    func body(content: Content) -> some View {
        let compose = content
            .font(style.fonte)
            .tracking(style.interlettrage)
        if let interligne = style.interligne {
            compose.hzLigne(taille: style.taille, hauteur: style.taille * interligne)
        } else {
            compose
        }
    }
}

extension View {
    /// Compose un texte dans un style d'affichage : fonte, interlettrage, et hauteur de ligne
    /// quand le style en fixe une. Voir `HZAffichage`.
    func hzAffichage(_ style: HZAffichage) -> some View {
        modifier(HZAffichageModifier(style: style))
    }
}

/// UNE BOÎTE DE LIGNE : une hauteur imposée, et la ligne de base posée là où Chromium la pose.
///
/// La ligne de base est placée par un guide d'alignement, pas par un centrage : SwiftUI arrondit
/// à sa façon la hauteur propre du texte, et un centrage hériterait de cet arrondi. Le guide
/// dit seulement « la ligne de base est à tant du haut de la boîte », quelle que soit la
/// hauteur que SwiftUI donne au texte.
private struct HZBoiteDeLigne: ViewModifier {
    let taille: CGFloat
    let hauteur: CGFloat

    func body(content: Content) -> some View {
        content
            .lineLimit(1)
            .fixedSize(horizontal: false, vertical: true)
            .alignmentGuide(.top) { dimensions in
                dimensions[.firstTextBaseline] - HZLigne.base(taille: taille, hauteur: hauteur)
            }
            .frame(height: hauteur, alignment: .top)
    }
}

extension View {
    /// Une ligne unique de `hauteur`, dont la base tombe là où elle tombe dans le canvas.
    func hzLigne(taille: CGFloat, hauteur: CGFloat) -> some View {
        modifier(HZBoiteDeLigne(taille: taille, hauteur: hauteur))
    }

    /// Un texte d'interface sur UNE ligne, de la hauteur que le canvas lui donne.
    ///
    /// Un paragraphe qui peut passer à la ligne n'emploie pas ceci : il reste en
    /// `.font(HZPolice.texte(…))`, et son interligne est celui du canvas, écran par écran.
    func hzTexte(_ corps: HZCorps, _ graisse: HZGraisse, tabulaire: Bool = false) -> some View {
        let taille = HZPolice.taille(corps)
        return font(HZPolice.texte(corps, graisse, tabulaire: tabulaire))
            .hzLigne(taille: taille, hauteur: HZLigne.normale(taille))
    }
}

extension View {
    /// Un paragraphe, avec l'interligne du canvas.
    ///
    /// `line-height: 1.35` en CSS donne à CHAQUE ligne 1,35 fois la taille, la différence étant
    /// coupée en deux, au-dessus et au-dessous du texte. `lineSpacing` de SwiftUI n'ajoute de
    /// l'espace qu'ENTRE les lignes : un paragraphe de deux lignes y perd deux demi-marges, et
    /// tout ce qui le suit remonte d'autant (2 points sur le bandeau du coach). La demi-marge du
    /// haut et du bas est donc rendue par un remplissage.
    func hzParagraphe(_ corps: HZCorps, _ graisse: HZGraisse, interligne: CGFloat) -> some View {
        let taille = HZPolice.taille(corps)
        let police = HZPolice.uiFonte(taille: taille, graisse: graisse.rawValue,
                                      largeur: HZPolice.largeurDInterface, tabulaire: false)
        let ecart = max(0, taille * interligne - police.lineHeight)
        return font(HZPolice.texte(corps, graisse))
            .lineSpacing(ecart)
            .padding(.vertical, ecart / HZLigne.moitie)
    }
}
