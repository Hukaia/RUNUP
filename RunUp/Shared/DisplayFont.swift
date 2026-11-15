import SwiftUI

/// La police de RunUp, nommée et dimensionnée en un seul endroit.
///
/// Trois cibles l'utilisent — l'app, le widget, la montre — et chacune écrivait son nom PostScript
/// en dur, vingt fois en tout. Une chaîne `.custom` introuvable ne lève aucune erreur : elle
/// retombe en silence sur la police système. En oublier une, c'était donc livrer un widget dans une
/// autre police que l'app sans le moindre avertissement.
///
/// Ce fichier vit dans `RunUp/Shared`, compilé par les trois cibles. Il ne dépend que de SwiftUI.
enum DisplayFont {
    /// La famille de TOUTE l'app — titrage et texte courant confondus.
    ///
    /// Il n'y a plus de police de titrage. Six familles ont été essayées avant celle-ci — Bebas
    /// en capitales d'affiche, Bricolage ExtraBold, DM Sans en 800 puis en 700, Poppins, Archivo.
    ///
    /// Le motif du refus a fini par se voir dans ce qu'elles avaient toutes : une VOIX. Bebas
    /// était une condensée d'affiche, Bricolage une grotesque à caractère, Poppins une géométrique
    /// ronde, Archivo une grotesque sportive. Les trois références finalement apportées — trois
    /// captures d'apps que personne n'aurait décrites par leur typographie — utilisent toutes la
    /// police système d'iOS ou son équivalent : une grotesque neutre, sans particularité, à
    /// grande hauteur d'x. Ce n'était donc pas « quelle voix », c'était « pas de voix ».
    ///
    /// Inter est cette grotesque-là, dessinée pour les interfaces à l'écran, et c'est le sosie le
    /// plus proche de SF Pro qui se distribue en fichier.
    ///
    /// # Pourquoi pas la police système directement
    ///
    /// C'est littéralement ce que montrent les références, et ce serait un fichier de moins à
    /// charger. Mais `.system` ne donne pas la même police partout : sur watchOS il rend SF
    /// Compact, une autre famille. L'app et la montre afficheraient deux typographies
    /// différentes, sans que rien ne le signale — exactement la panne silencieuse que
    /// `ci_scripts/check_fonts.py` a été écrit pour rendre impossible. Un fichier livré aux trois
    /// cibles rend le même dessin sur les trois.
    static let family = "InstrumentSans"

    /// Le nom PostScript, pas le nom de famille : c'est celui-là que `Font.custom` attend.
    static let postScriptName = "\(family)-Medium"

    /// Les 27 tailles de l'app ont été dessinées contre Bebas Neue, une condensée. Chaque famille
    /// qui lui a succédé est plus large à taille de point égale, d'où ce facteur de compensation :
    /// sans lui, les titres débordent de leurs gabarits.
    ///
    /// 1,09 pour Inter, et ce chiffre ne dit PAS que les titres rapetissent : il les laisse
    /// exactement là où ils étaient. Inter a une hauteur de capitale de 0,728 em contre 0,686 pour
    /// Archivo — 6 % de plus. Sans baisser le facteur d'autant (1,16 × 0,943 ≈ 1,09), le même
    /// nombre de points aurait donné des titres 6 % plus grands.
    ///
    /// Le facteur suit la hauteur de capitale, pas la taille de point, parce que c'est elle qui
    /// décide de la taille PERÇUE d'un titre ou d'un grand chiffre. C'est cette taille perçue-là
    /// qui a été validée ; changer de police ne devait pas la changer.
    ///
    /// Le même multiplicateur qu'au corps s'applique toujours des deux côtés — voir
    /// `RUFont.bodySizeFactor` — pour qu'aucun titre ne passe sous le texte qu'il coiffe.
    ///
    /// Inter est 4,9 % plus large qu'Archivo ; au facteur réduit, une ligne occupe donc 1 % de
    /// plus qu'avant. Rien à reprendre dans les gabarits.
    ///
    /// # INSTRUMENT SANS, 15 NOVEMBRE 2026 : 1,101
    ///
    /// Même méthode, même mesure, appliquée à la famille suivante. Relevé sur les fichiers :
    /// Instrument Sans a une hauteur de capitale de 0,7200 em contre 0,7275 pour Inter, soit
    /// **1,0 % de moins**. Pour que la taille PERÇUE d'un titre ne bouge pas, le facteur monte
    /// d'autant : 1,09 × (0,7275 / 0,7200) = 1,101.
    ///
    /// Sa hauteur d'x, elle, est 6,6 % plus basse (0,5100 contre 0,5459) et une vraie chaîne —
    /// « Charlotte 14,1 6:18 » — occupe 3,8 % de moins. Le texte courant paraîtra donc un peu
    /// plus petit à taille de point égale, et les lignes tiendront dans un peu moins de largeur.
    /// C'est assumé : l'échelle qui suit est donnée en points rendus, et la capture tranchera
    /// s'il faut monter d'un cran.
    static let sizeFactor: CGFloat = 1.101

    /// La taille de point à demander pour retrouver l'encombrement dessiné à l'origine.
    static func pointSize(for designSize: CGFloat) -> CGFloat { designSize * sizeFactor }

    /// La police à taille fixe, pour le widget et la montre — qui n'ont pas le mécanisme Dynamic
    /// Type plafonné de l'app (`RUFont.scaled`) et n'en veulent pas : un widget est un carré, il
    /// ne peut pas grandir avec le réglage de taille du texte.
    static func font(_ designSize: CGFloat) -> Font {
        .custom(postScriptName, size: pointSize(for: designSize))
    }
}
