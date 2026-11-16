import Foundation
import SwiftData

/// A bell-icon notification. Mirrors `notifs` in app.jsx.
@Model
final class AppNotification {
    /// SF Symbol name, or "mark" to render the AppMark glyph instead.
    var icon: String
    /// RGB color, stored as `Int` — SwiftData/Core Data has no unsigned-integer attribute type.
    var colorHex: Int

    /// L'ACCENT, POUR CEUX QUI N'ONT RIEN À DIRE DE PLUS.
    ///
    /// Les couleurs de cloche étaient écrites en dur, une par site d'appel, et elles ne
    /// s'accordaient avec rien : `0xC9FF3B` pour une séance terminée — un vert qui disait
    /// « bien » là où il n'y a rien à juger — et `0xFF3B6B` pour un encouragement ou un
    /// commentaire, c'est-à-dire un rose VOISIN de l'accent sans être lui. Deux roses à un
    /// écran d'intervalle, dont un seul est la marque.
    ///
    /// Un `Int` et pas un `Color` : ce champ est persisté par SwiftData, et la valeur doit
    /// survivre à un changement de thème sans se relire. C'est aussi pourquoi elle ne suit PAS
    /// le nuancier choisi — une notification posée il y a trois jours garderait de toute façon
    /// la couleur du jour où elle a été écrite.
    ///
    /// TROIS VALEURS, PAS NEUF. Le relevé du 16 novembre en trouvait neuf, toutes écrites en
    /// dur : trois roses voisins, deux verts, un orange, un violet, un turquoise et un ambre.
    /// Ce qu'une cloche a besoin de dire tient en trois registres — c'est arrivé, c'est à
    /// surveiller, c'est cassé — et les deux derniers seuls méritent une couleur.
    static let accent = 0xF0225F

    /// CE QU'IL FAUT SURVEILLER, et rien d'autre. Une paire de chaussures en fin de vie, une
    /// séance allégée : l'app signale un écart, elle ne le reproche pas. C'est le seul emploi
    /// d'ambre qui vaille, et c'est celui que l'écran des stats lui donne déjà.
    static let avertissement = 0xFFB03D

    /// UNE PANNE DONT ON S'EST RELEVÉ. L'app fermée pendant une sortie, des kilomètres
    /// récupérés : ce n'est ni une réussite ni un avertissement, c'est un incident réparé. Il
    /// garde une couleur à lui parce que c'est le seul message que personne n'attend.
    static let incident = 0x38E0D0
    var title: String
    var text: String
    var timestamp: Date
    var read: Bool

    init(icon: String, colorHex: Int, title: String, text: String, timestamp: Date = .now, read: Bool = false) {
        self.icon = icon
        self.colorHex = colorHex
        self.title = title
        self.text = text
        self.timestamp = timestamp
        self.read = read
    }
}
