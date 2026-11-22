import SwiftUI

/// LES COULEURS DE LA REFONTE — relevées dans le canvas du 17 novembre 2026, à la valeur près.
///
/// # LE SEUL JEU DE JETONS
///
/// La refonte a refait les écrans un par un, à partir de composants neufs, pendant que l'ancien
/// système tournait à côté. Le dernier écran refait, l'ancien système a été supprimé le
/// 19 novembre : ces jetons sont maintenant les seuls.
///
/// # CE QUE LE CANVAS NE DESSINE PAS
///
/// Il montre un interrupteur « Clair / Sombre » dans les réglages et un seul rendu de chaque
/// écran. Les jetons ci-dessous sont donc ceux de ce rendu-là. Ils sont nommés par RÔLE et non
/// par teinte, pour que la seconde ambiance se pose ici le jour où elle sera dessinée, sans
/// toucher une vue.
enum HZCouleur {

    // MARK: - L'accent, et son encre

    /// LE SEUL JETON D'ACCENT. Quatre choix, pas un de plus — voir `HZAccent`.
    static var accent: Color { HZAccent.courant.couleur }

    /// Ce qui s'écrit EN PETIT sur l'accent. Voir `HZAccent.encre` pour la règle.
    static var encreSurAccent: Color { HZAccent.courant.encre }

    // MARK: - Les noirs

    /// Le fond des écrans sombres : plan, stats, coach, club, profil.
    static let noir = Color(hex: 0x0B0B0C)
    /// La barre flottante, les boutons pleins, et le texte sur une feuille blanche.
    static let encre = Color(hex: 0x111111)
    /// Une surface posée sur le noir : bouton rond, pilule, tuile, carte de repos.
    static let surfaceSombre = Color(hex: 0x1C1C1E)
    /// Un filet ou un segment éteint sur le noir.
    static let filetSombre = Color(hex: 0x2C2C2E)
    /// Le point d'un jour de repos, dans la rangée de la semaine.
    static let pointEteint = Color(hex: 0x3A3A3C)
    /// Le panneau de la séance en direct : un noir franc, plus profond que `noir`, parce qu'il
    /// se lit au soleil et en courant.
    static let noirFranc = Color(hex: 0x000000)

    // MARK: - Les clairs

    static let blanc = Color(hex: 0xFFFFFF)
    /// Une surface posée sur la feuille blanche : tuile, groupe, bandeau, champ.
    static let surfaceClaire = Color(hex: 0xF4F4F6)
    /// Le filet entre deux lignes, directement sur la feuille.
    static let filetFeuille = Color(hex: 0xF0F0F2)
    /// Le filet entre deux lignes, à l'intérieur d'un groupe gris — et la gorge d'un sélecteur.
    static let filetGroupe = Color(hex: 0xE4E4E8)
    /// Le contour d'une pilule vide, et la gorge d'une barre de progression.
    static let contour = Color(hex: 0xDCDCE0)

    // MARK: - Les textes secondaires

    /// Sur clair.
    static let secondaireSurClair = Color(hex: 0x6E6E73)
    /// Sur sombre.
    static let secondaireSurSombre = Color(hex: 0xA1A1A6)
    /// Le chevron au bout d'une ligne de liste.
    static let chevron = Color(hex: 0x8E8E93)
    /// L'icône d'une entrée éteinte de la barre flottante.
    static let ongletEteint = Color(hex: 0xC7C7CC)

    // MARK: - Sur une couleur pleine

    /// LE VOILE : un noir à 26 %, posé sur l'accent ou sur une teinte d'intensité. C'est lui qui
    /// porte les petits textes blancs — pastille, bouton rond, champ de recherche — et c'est ce
    /// qui rend la règle du rose tenable : jamais de petit texte blanc à même l'accent.
    static let voile = Color(hex: 0x000000, opacity: 0.26)
    /// Le point d'un jour sans séance, sur l'accent.
    static let pointSurCouleur = Color(hex: 0x000000, opacity: 0.28)
    /// Le filet d'une carte-affiche, au-dessus de sa rangée de chiffres.
    static let filetSurCouleur = Color(hex: 0xFFFFFF, opacity: 0.4)
}

/// LES TROIS TEINTES D'INTENSITÉ, et la teinte claire de leur point.
///
/// Le brief du 15 novembre en fixait six. Le canvas du 17 n'en garde que trois, et c'est lui qui
/// fait foi : une séance qui n'est ni facile, ni de récupération, ni longue se lit par ce qui est
/// écrit dessus, pas par une couleur de plus.
///
/// Le point est plus clair que la carte parce qu'il vit sur le noir, à huit points de diamètre :
/// la teinte de la carte y disparaîtrait.
enum HZIntensite: CaseIterable {
    /// L'endurance, le footing facile.
    case facile
    /// La récupération.
    case recuperation
    /// La sortie longue.
    case longue

    var couleur: Color {
        switch self {
        case .facile: return Color(hex: 0x177A50)
        case .recuperation: return Color(hex: 0x2B6CB8)
        case .longue: return Color(hex: 0x6B35D6)
        }
    }

    var point: Color {
        switch self {
        case .facile: return Color(hex: 0x2FB37A)
        case .recuperation: return Color(hex: 0x5AA9E6)
        case .longue: return Color(hex: 0x9B6BF2)
        }
    }
}

/// LA COULEUR DE L'APP : QUATRE CHOIX, UN SEUL JETON.
///
/// La décision D1 — « les huit thèmes d'accent restent », tenue les 9, 11 et 15 novembre — est
/// renversée par le brief de refonte du 17 : « 4 choix seulement, un seul token accent.
/// Supprimer l'habillage Teinté et les autres couleurs. »
///
/// # LA RÈGLE DU ROSE EST UNE RÈGLE DU ROSE
///
/// Le canvas l'écrit ainsi, dans chacun de ses écrans :
///
///     ink = accent === '#FF2E6E' ? '#2B0011' : '#FFFFFF'
///
/// (`#FF2E6E` est le rose du canvas ; depuis le 22 novembre le rose de l'app est `#FC105E`, celui du
/// logo — le contraste de l'encre sombre dessus vaut 4,8:1, le blanc seul 3,9:1 : la règle tient.)
///
/// L'encre sombre n'accompagne donc QUE le rose. Sur le violet, le bleu et le vert, les petits
/// libellés restent blancs. Ce n'est pas un oubli à corriger : le rose est le seul des quatre
/// assez clair pour qu'un petit texte blanc y devienne illisible.
enum HZAccent: String, CaseIterable, Identifiable {
    case rose, violet, bleu, vert

    var id: String { rawValue }

    var couleur: Color {
        switch self {
        case .rose: return Color(hex: 0xFC105E)
        case .violet: return Color(hex: 0x7B3FE4)
        case .bleu: return Color(hex: 0x2F6BFF)
        case .vert: return Color(hex: 0x12A56B)
        }
    }

    var encre: Color {
        self == .rose ? Color(hex: 0x2B0011) : HZCouleur.blanc
    }

    /// Le nom lu par VoiceOver sur la pastille.
    var nom: String {
        switch self {
        case .rose: return String(localized: "Rose")
        case .violet: return String(localized: "Violet")
        case .bleu: return String(localized: "Bleu")
        case .vert: return String(localized: "Vert")
        }
    }

    /// Le choix en cours. Il est lu dans `ThemeStore`, le réglage que l'app porte déjà et que le
    /// profil synchronise : la refonte ne crée pas une seconde mémoire pour la même préférence.
    static var courant: HZAccent { depuis(ancienTheme: ThemeStore.shared.themeID) }

    /// HUIT ANCIENS THÈMES, QUATRE COULEURS. Les trois qui portent le même nom se retrouvent ;
    /// le cyan et le lime, qui étaient des verts, deviennent le vert ; l'ambre, le corail et le
    /// magenta n'ont pas d'équivalent et reviennent au rose, la couleur de la marque.
    ///
    /// Personne ne perd son réglage en silence pour autant : la valeur enregistrée n'est pas
    /// réécrite ici. Elle le sera à l'écran des réglages, quand la personne choisira.
    static func depuis(ancienTheme id: String) -> HZAccent {
        switch id {
        case "violet": return .violet
        case "bleu": return .bleu
        case "cyan", "lime", "vert": return .vert
        default: return .rose
        }
    }
}
