import SwiftUI

/// UNE COLONNE DE LA RANGÉE DES SEPT JOURS DU PLAN, sur le noir : une initiale, et dessous un point à
/// la couleur du jour.
///
/// Le jour choisi se lit à DEUX choses — son initiale passe en blanc et en gras, son point s'allonge
/// en pilule — pour que la couleur ne porte pas seule ce qui est choisi. Les autres jours sont des
/// points ronds, à la couleur de leur séance : on lit la forme de la semaine avant d'avoir lu un mot.
///
/// # ELLE NE PORTE PAS LE BOUTON
///
/// La rangée était d'abord un composant à part entière, avec ses boutons et une fermeture reçue en
/// paramètre. Sur le simulateur, ces boutons existaient, étaient touchables, aux bons cadres — et
/// leur action ne partait JAMAIS (un compteur écrit à la première ligne de la fonction restait à
/// zéro), alors que « Déplacer », le retour et la carte du jour, dont l'action est écrite dans la
/// vue, répondaient. Le bouton est donc posé par l'écran, et ce composant ne dessine que la colonne.
/// Elle occupe un septième de l'écran sur toute la hauteur de la rangée : bien plus que la pastille
/// qu'elle dessine.
struct HZColonneDeJour: View {
    let initiale: String
    let point: Color
    let choisi: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text(initiale)
                .hzTexte(.c12, choisi ? .gras : .semi)
                .foregroundStyle(choisi ? HZCouleur.blanc : HZCouleur.secondaireSurSombre)
            Spacer(minLength: 0)
            // Le point qui n'est pas choisi remonte d'un point : le canvas le pose ainsi, et la
            // pilule, plus haute, garde le bas de la colonne.
            Capsule()
                .fill(point)
                .frame(width: choisi ? HZColonneDeJour.pastilleChoisie.width : HZColonneDeJour.point,
                       height: choisi ? HZColonneDeJour.pastilleChoisie.height : HZColonneDeJour.point)
                .padding(.bottom, choisi ? 0 : HZColonneDeJour.remonteeDuPoint)
        }
        .frame(maxWidth: .infinity)
        .frame(height: HZPlan.rangeeDesJours)
        .contentShape(Rectangle())
    }

    static let point: CGFloat = 8
    static let pastilleChoisie = CGSize(width: 22, height: 10)
    static let remonteeDuPoint: CGFloat = 1
}

/// LE MOUVEMENT DU CARROUSEL DU PLAN : 340 ms, la courbe du canvas — `cubic-bezier(0.2, 0.8, 0.2, 1)`,
/// qui part vite et se pose doucement.
enum HZCarrousel {
    static let animation = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.34)
    /// Au-delà de ce déplacement horizontal, un geste LENT change de carte.
    static let seuilDeGlissement: CGFloat = 40
    /// La carte se met à suivre le doigt dès ce déplacement. Plus bas que le seuil du changement :
    /// c'est ce qui lui fait suivre le doigt, au lieu de sauter d'un cran à la fin du geste — le
    /// défaut de la première version, où rien ne bougeait avant que le doigt se lève.
    static let seuilDeDebut: CGFloat = 8
    /// Au bout de la rangée (lundi vers la gauche, dimanche vers la droite) la carte suit le doigt à
    /// ce rapport : elle résiste, et le doigt sent qu'il n'y a plus de carte.
    static let resistanceAuBout: CGFloat = 0.3
    /// Un geste rapide peut sauter des cartes, pas toute la semaine.
    static let sautMaximal = 2

    /// Le déplacement de la carte pendant le geste.
    static func decalage(_ deplacement: CGFloat, auBout: Bool) -> CGFloat {
        auBout ? deplacement * resistanceAuBout : deplacement
    }

    /// Combien de cartes le geste fait passer, signé : positif vers la carte suivante (le doigt va
    /// vers la gauche), négatif vers la précédente.
    ///
    /// Deux gestes changent de carte : un geste LENT qui dépasse `seuilDeGlissement`, et un geste
    /// RAPIDE dont la course prévue (`prevu`, ce que le doigt aurait parcouru en continuant) dépasse
    /// la moitié d'un pas. Le second peut sauter jusqu'à `sautMaximal` cartes. Un geste plus court et
    /// plus lent que cela ramène la carte où elle était.
    static func pas(deplacement: CGFloat, prevu: CGFloat, pasDeCarte: CGFloat) -> Int {
        guard pasDeCarte > 0 else { return 0 }
        var cartes = Int((-prevu / pasDeCarte).rounded())
        if cartes == 0, abs(deplacement) > seuilDeGlissement {
            cartes = deplacement < 0 ? 1 : -1
        }
        return max(-sautMaximal, min(sautMaximal, cartes))
    }
}
