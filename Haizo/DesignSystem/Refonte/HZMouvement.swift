import SwiftUI

/// LE MOUVEMENT DE L'APP : QUELQUES RÉGLAGES, PAS UNE COLLECTION.
///
/// Il a remplacé le mouvement de l'ancien système. Chaque réglage garde la raison qu'il avait :
///
///   • `ecran`   — le changement d'écran. 0,22 s d'`easeOut` : assez court pour ne pas se faire
///                 attendre, assez long pour que le fond vide des deux écrans croisés se couvre.
///   • `chiffre` — un chiffre qui change (chrono, allure). 0,18 s : sous les 200 ms au-delà
///                 desquelles un chrono se met à trembler au lieu de défiler.
///   • `ressort` — ce qui arrive à l'écran et se pose (une carte, une pastille).
///   • `glisse`  — une valeur qui se parcourt (une barre qui avance), sans rebond : elle ne remplace
///                 rien, elle montre une quantité qui se remplit.
///   • `trace`   — un tracé qui se dessine. Plus long, parce que ce n'est pas une transition : il doit
///                 seulement être fini avant qu'on ait besoin de le lire.
///   • `choix`   — le cadran de discipline qui s'ouvre sous le doigt, avec un léger rebond.
///
/// « Réduire les animations » ne veut pas dire des animations plus courtes : la valeur doit SAUTER.
/// C'est `respecter`.
enum HZMouvement {
    static let ecran = Animation.easeOut(duration: 0.22)
    static let chiffre = Animation.easeOut(duration: 0.18)
    static let ressort = Animation.spring(duration: 0.28, bounce: 0.12)
    static let glisse = Animation.spring(duration: 0.50, bounce: 0)
    static let trace = Animation.timingCurve(0.22, 0.61, 0.36, 1, duration: 0.70)
    static let choix = Animation.spring(duration: 0.26, bounce: 0.26)

    /// De combien une page ouverte depuis une autre se décale en entrant : petit, parce que
    /// translater une page entière oblige le système à composer deux calques plein cadre pendant
    /// qu'il construit déjà l'écran qui arrive.
    static let decalageDePage: CGFloat = 28

    /// La même animation, ou AUCUNE si la personne a demandé moins de mouvement.
    static func respecter(_ reduireLeMouvement: Bool, _ animation: Animation) -> Animation? {
        reduireLeMouvement ? nil : animation
    }
}

extension AppScreen {
    /// La transition de CET écran. Chaque écran emporte la sienne : une page ouverte depuis une
    /// autre entre par la droite et sort par la droite, la racine d'un onglet ne bouge pas — elle
    /// se fond. Rien ne se croise, parce qu'un seul des deux écrans se déplace.
    var transitionDecran: AnyTransition {
        // UN ONGLET SE FOND, ET RIEN D'AUTRE. Il passait en plus par une échelle de 0,98 : pendant
        // qu'une vue est mise à l'échelle, SwiftUI ne la laisse plus déborder sous la barre d'état,
        // donc l'écran entrait soixante points trop bas, une bande blanche au-dessus de son en-tête,
        // puis remontait d'un coup à la fin de l'animation. C'est le « sursaut » que Charlotte a
        // filmé (23 novembre). Un fondu ne déplace rien, donc rien ne peut sauter.
        guard !estRacineDOnglet else { return .opacity }
        return .asymmetric(
            insertion: .opacity.combined(with: .offset(x: HZMouvement.decalageDePage)),
            removal: .opacity.combined(with: .offset(x: HZMouvement.decalageDePage))
        )
    }
}
