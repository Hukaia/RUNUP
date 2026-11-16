import SwiftUI

/// Standard card surface: barely-there white fill, hairline border, generous radius. Class `.card`.
struct CardBackground: ViewModifier {
    var radius: CGFloat = RUSpacing.radiusCard
    var fill: Color = RUColor.card

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            // L'OMBRE DU BRIEF : 0 2px 12px rgba(0,0,0,0.06).
            //
            // SwiftUI compte son `radius` comme la MOITIÉ du flou CSS — 12 px de flou donnent
            // donc 6. Le décalage vertical, lui, se lit tel quel.
            //
            // Elle était à `radius: 14, y: 6` et ne vivait qu'en habillage teinté, parce qu'elle
            // devait y séparer une carte d'un fond coloré à elle seule. Celle-ci fait autre
            // chose : elle pose une feuille sur une table. Resserrée, presque transparente, et
            // partout.
            //
            // CE QUE ÇA DÉFAIT, ET POURQUOI C'EST ASSUMÉ. Le 12 novembre, l'ombre avait été
            // retirée au profit du filet, avec un argument qui tenait : « sur du papier, une
            // ombre portée empile du gris sur un fond déjà gris ». Il tenait pour une ombre à
            // 16 % posée sur un fond teinté. À 6 % sur du blanc, ce n'est plus du gris empilé,
            // c'est un bord qui s'adoucit — et c'est la seule chose que le brief demande.
            .shadow(color: RUColor.cardShadow, radius: 6, x: 0, y: 2)
    }
}

extension View {
    /// UNE CARTE QUAND LA SECTION A QUELQUE CHOSE À MONTRER, RIEN QUAND ELLE EST VIDE.
    ///
    /// L'argument écrit dans `ClubView.challengeCard` tient : « une carte VIDE occupait cent
    /// points de haut pour dire qu'il n'y avait rien à dire », et deux de ces cadres se
    /// suivaient en tête d'un club qui démarre. Mais il avait été appliqué SANS CONDITION — les
    /// sections qui ont du contenu ont perdu leur surface en même temps que les autres.
    ///
    /// Le résultat se voit sur l'Aperçu d'un club actif : quatre sections de texte posées à même
    /// le fond, et pour seule carte blanche celle du niveau, tout en bas. Une page dont une
    /// section sur cinq a une surface ne se lit pas comme un parti pris, mais comme un écran
    /// qu'on a oublié de finir.
    ///
    /// Une condition, donc, plutôt qu'un choix unique pour les deux états.
    @ViewBuilder
    func ruCarteSiPleine(_ pleine: Bool) -> some View {
        if pleine {
            self.padding(RUSpacing.cardPadding).ruCard()
        } else {
            self
        }
    }

    func ruCard(radius: CGFloat = RUSpacing.radiusCard, fill: Color = RUColor.card) -> some View {
        modifier(CardBackground(radius: radius, fill: fill))
    }

    // ── LA CARTE « HÉROS » N'EXISTE PLUS ────────────────────────────────────────────────────
    //
    // `ruHeroCard` posait un lavis d'accent sous sept cartes : la forme du jour, la relance du
    // coach, le résumé du programme, la reprise après un objectif. C'était la DEUXIÈME surface
    // de l'app, et le brief du 15 novembre n'en veut qu'une — « une seule carte : blanche,
    // rayon 20, ombre 0 2px 12px, pas de contour ».
    //
    // CE QU'ELLE SERVAIT, ET CE QUI LE SERT MAINTENANT. Elle disait « celle-ci compte plus que
    // les autres ». Une couleur de fond est la façon la plus coûteuse de le dire : elle ajoute
    // une surface au vocabulaire pour hiérarchiser DEUX cartes dans un écran qui en porte cinq.
    // La hiérarchie se dit par la place — la première carte sous l'en-tête — et par la taille
    // du chiffre qu'elle porte. Les deux étaient déjà vraies ; le lavis les redisait.
    //
    // `heroSurface` n'est plus posé nulle part après ce commit : quatre écrans le peignaient
    // encore À LA MAIN, hors du composant, et la suppression de `ruHeroCard` ne les aurait pas
    // touchés. Un lavis écrit en direct est exactement ce qui fait survivre une surface qu'on
    // croit avoir retirée.
}
