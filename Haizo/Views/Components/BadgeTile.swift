import SwiftUI

/// L'hexagone d'un badge — surface, contour, symbole, état débloqué.
///
/// Il existait en TROIS COPIES identiques au caractère près : deux dans le Club, une dans le
/// Profil. C'est l'audit qui les a comptées, en constatant qu'un même défaut — une couleur
/// d'accent noyée à 22 % dans la surface, donc du brun pour l'ambre et de l'olive pour le lime —
/// devait être corrigé trois fois. Il l'a été, mais laisser trois copies revient à parier que la
/// prochaine correction les trouvera toutes.
///
/// LA COULEUR EST AU CONTOUR, ENTIÈRE. C'est la règle du dépôt : un accent ne se dilue pas. La
/// surface est neutre pour tout le monde, et « débloqué » se lit à trois signes qui ne dépendent
/// d'aucune teinte — le contour vif, l'opacité pleine, le symbole net.
struct BadgeTile: View {
    /// Le nom d'un symbole SF, pas un émoji : il prend la couleur du badge et la graisse du
    /// reste de l'app, là où un émoji est dessiné par le système dans son propre style.
    let symbole: String
    let earned: Bool
    let color: Color
    /// Le diamètre, quand l'appelant en impose un. Sinon la pastille prend la place qu'on lui
    /// donne et reste carrée — c'est ce dont une grille a besoin pour aligner ses colonnes.
    ///
    /// LES SOIXANTE-QUATRE DU BRIEF SONT UN DÉFAUT, PAS UNE IMPOSITION. Deux des trois
    /// appelants passent déjà leur taille, parce qu'une grille de badges et une rangée de
    /// profil n'ont pas la même place ; le troisième laissait la tuile s'étirer. Poser 64 ici
    /// donne au cas non spécifié la valeur du brief, sans aller contredire les grilles qui
    /// savent ce qu'elles font.
    var side: CGFloat? = 64
    var tailleDuSymbole: CGFloat = 24
    /// Un badge verrouillé s'efface, sans disparaître : on doit pouvoir lire ce qui reste à faire.
    var lockedOpacity: Double = 0.35

    var body: some View {
        // ── UN CERCLE, PLUS UN HEXAGONE ─────────────────────────────────────────────────────
        //
        // Le brief du 15 novembre : « les badges deviennent des cercles de 64 ». L'hexagone
        // était la seule forme de l'app qui n'était ni un rectangle arrondi ni un cercle — un
        // sixième vocabulaire pour dire « récompense », là où la médaille est déjà ronde depuis
        // qu'il y a des médailles.
        //
        // LE CONTOUR RESTE, et c'est lui qui porte la distinction. Un badge décroché a le
        // contour de sa couleur, un badge verrouillé le filet gris : c'est la même information
        // qu'avant, sur une forme de moins.
        Circle()
            .fill(RUColor.card2)
            .overlay(Circle().stroke(earned ? color : RUColor.line,
                                     lineWidth: RUSpacing.hairline))
            .modifier(TailleDuBadge(side: side))
            // Le symbole prend la COULEUR DU BADGE quand il est gagné, et le gris du texte
            // secondaire sinon : un badge verrouillé doit se lire comme « pas encore », pas
            // comme une version délavée de lui-même.
            .overlay(
                Image(systemName: symbole)
                    // HORS ÉCHELLE, ET POUR LA RAISON DES INITIALES D'UN AVATAR : la
                    // taille suit le côté de l'hexagone, en continu. Ce n'est pas un cran, c'est
                    // une proportion.
                    .font(RUFont.icone(horsEchelle: tailleDuSymbole, weight: .semibold))
                    .foregroundColor(earned ? color : RUColor.text2)
            )
            .opacity(earned ? 1 : lockedOpacity)
    }
}

/// `frame` fixe ou rapport carré, selon que l'appelant impose un côté. Écrit en modificateur
/// plutôt qu'en `if` dans le corps : un `if` produirait deux vues d'identité différente, et
/// l'animation d'apparition d'une grille sauterait au premier changement d'état.
private struct TailleDuBadge: ViewModifier {
    let side: CGFloat?

    func body(content: Content) -> some View {
        if let side {
            content.frame(width: side, height: side)
        } else {
            content.aspectRatio(1, contentMode: .fit)
        }
    }
}
