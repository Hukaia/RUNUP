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

/// LE MOUVEMENT DU CARROUSEL DU PLAN, quand c'est la rangée des jours qui le commande : 340 ms, la courbe du
/// canvas, `cubic-bezier(0.2, 0.8, 0.2, 1)`, qui part vite et se pose doucement. Le geste du doigt, lui, est
/// le défilement natif du système (voir `PlanSemaineView.carrousel`) : il n'a plus de seuil ni de résistance
/// à lui, c'est le système qui en décide.
enum HZCarrousel {
    static let animation = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.34)
}
