import SwiftUI

/// Un ordre de tracé, dans la boîte de l'icône. Les nombres sont ceux du canvas.
enum HZTrace {
    case depart(CGFloat, CGFloat)
    case ligne(CGFloat, CGFloat)
    /// Deux points de contrôle, puis l'arrivée.
    case courbe(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)
    case fermer
    /// Origine, largeur, hauteur.
    case ellipse(CGFloat, CGFloat, CGFloat, CGFloat)
    /// Origine, largeur, hauteur, rayon.
    case rectangle(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)
}

/// UNE ICÔNE DU CANVAS : sa boîte, sa façon d'être dessinée, et ses tracés.
///
/// Les vingt-neuf dessins vivent dans `HZDessins.swift`, qui est ENGENDRÉ — voir
/// `ci_scripts/icones.py` pour la raison de ne plus prendre des SF Symbols ici.
struct HZDessin {
    /// Le côté de la boîte dans laquelle les tracés sont écrits : 24, ou 14 pour le triangle
    /// de lecture.
    let boite: CGFloat
    /// Rempli, ou tracé au trait.
    let plein: Bool
    let bout: CGLineCap
    let joint: CGLineJoin
    let traces: [HZTrace]

    func chemin(cote: CGFloat) -> Path {
        let e = cote / boite
        var chemin = Path()
        for trace in traces {
            switch trace {
            case let .depart(x, y):
                chemin.move(to: CGPoint(x: x * e, y: y * e))
            case let .ligne(x, y):
                chemin.addLine(to: CGPoint(x: x * e, y: y * e))
            case let .courbe(x1, y1, x2, y2, x, y):
                chemin.addCurve(to: CGPoint(x: x * e, y: y * e),
                                control1: CGPoint(x: x1 * e, y: y1 * e),
                                control2: CGPoint(x: x2 * e, y: y2 * e))
            case .fermer:
                chemin.closeSubpath()
            case let .ellipse(x, y, largeur, hauteur):
                chemin.addEllipse(in: CGRect(x: x * e, y: y * e,
                                             width: largeur * e, height: hauteur * e))
            case let .rectangle(x, y, largeur, hauteur, rayon):
                chemin.addRoundedRect(in: CGRect(x: x * e, y: y * e,
                                                 width: largeur * e, height: hauteur * e),
                                      cornerSize: CGSize(width: rayon * e, height: rayon * e))
            }
        }
        return chemin
    }
}

/// Dessine une icône du canvas, à la taille et au trait demandés.
///
/// `trait` est donné DANS LA BOÎTE DE 24, comme le canvas l'écrit (`stroke-width="2.2"`), et non
/// en points d'écran : la même icône s'y montre à 16, 18, 20 et 22 points avec la même valeur
/// écrite, et c'est cette valeur-là qu'on reproduit.
///
/// Elle est toujours muette pour VoiceOver : c'est la commande qui la porte qui a un nom.
struct HZIcone: View {
    let dessin: HZDessin
    var cote: CGFloat = 22
    var trait: CGFloat = 2
    var couleur: Color

    var body: some View {
        let chemin = dessin.chemin(cote: cote)
        Group {
            if dessin.plein {
                chemin.fill(couleur)
            } else {
                chemin.stroke(couleur, style: StrokeStyle(lineWidth: trait * cote / dessin.boite,
                                                          lineCap: dessin.bout,
                                                          lineJoin: dessin.joint))
            }
        }
        .frame(width: cote, height: cote)
        .accessibilityHidden(true)
    }
}
