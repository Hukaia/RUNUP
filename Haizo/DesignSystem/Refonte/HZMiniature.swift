import SwiftUI

/// LE TRACÉ D'UNE SORTIE, en miniature : le vrai parcours, en blanc, dans la vignette noire d'une
/// liste.
///
/// Le canvas dessine à la main une forme par sortie. L'app, elle, a le parcours enregistré : c'est
/// lui qui se dessine. Même épaisseur, mêmes bouts ronds que le tracé du canvas (2,4 dans une
/// boîte de 48), et le tracé est mis à l'échelle pour remplir la boîte sans se déformer.
///
/// # LE REPÈRE
///
/// Latitude et longitude ne sont pas à la même échelle : un degré de longitude vaut `cos(latitude)`
/// degrés de latitude. Sans cette correction, un parcours s'étire vers l'est ou l'ouest d'autant
/// plus qu'on s'éloigne de l'équateur, et la boucle d'un parc devient une ellipse. La correction
/// est celle du milieu du tracé — à l'échelle d'une sortie, la différence avec une projection
/// complète ne se voit pas.
///
/// # SANS PARCOURS
///
/// Une sortie sur tapis, ou dont le GPS n'a rien enregistré, n'a pas de tracé. La vignette montre
/// alors le dessin d'itinéraire du canvas plutôt qu'une case vide.
struct HZMiniatureDeSortie: View {
    /// Latitude et longitude, dans l'ordre du parcours.
    let points: [(lat: Double, lng: Double)]

    var body: some View {
        if let normalises = HZMiniatureDeSortie.normaliser(points) {
            Canvas { contexte, taille in
                var chemin = Path()
                let cote = min(taille.width, taille.height)
                let origine = CGPoint(x: (taille.width - cote) / HZMiniatureDeSortie.moitie,
                                      y: (taille.height - cote) / HZMiniatureDeSortie.moitie)
                for (indice, point) in normalises.enumerated() {
                    let position = CGPoint(x: origine.x + point.x * cote, y: origine.y + point.y * cote)
                    if indice == 0 { chemin.move(to: position) } else { chemin.addLine(to: position) }
                }
                contexte.stroke(chemin, with: .color(HZCouleur.blanc),
                                style: StrokeStyle(lineWidth: HZMiniatureDeSortie.trait,
                                                   lineCap: .round, lineJoin: .round))
            }
            .frame(width: HZMiniatureDeSortie.cote, height: HZMiniatureDeSortie.cote)
            .accessibilityHidden(true)
        } else {
            HZIcone(dessin: .itineraire, cote: HZMesuresDeLigne.trace,
                    trait: HZMesuresDeLigne.traitDuTrace, couleur: HZCouleur.blanc)
        }
    }

    /// Les points ramenés dans [0, 1] × [0, 1], le nord en haut, ou `nil` s'il n'y a pas de forme
    /// à dessiner (moins de deux points, ou tous au même endroit).
    ///
    /// Le tracé est AUSSI RÉDUIT à `pointsMaximum` : un parcours d'une heure compte des milliers
    /// de points, et une vignette de 28 points de côté n'en distingue pas plus d'une centaine.
    static func normaliser(_ points: [(lat: Double, lng: Double)]) -> [CGPoint]? {
        guard points.count >= 2 else { return nil }
        let pas = max(1, points.count / pointsMaximum)
        let retenus = points.enumerated().filter { $0.offset % pas == 0 || $0.offset == points.count - 1 }
            .map { $0.element }

        let lats = retenus.map { $0.lat }
        let lngs = retenus.map { $0.lng }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLng = lngs.min(), let maxLng = lngs.max() else { return nil }
        let milieu = (minLat + maxLat) / moitie
        let echelle = cos(milieu * .pi / demiTour)
        let largeur = (maxLng - minLng) * echelle
        let hauteur = maxLat - minLat
        let plusGrand = max(largeur, hauteur)
        guard plusGrand > 0 else { return nil }

        // Centré dans le carré : un parcours long et fin ne colle pas au bord haut.
        let decalageX = (plusGrand - largeur) / moitie
        let decalageY = (plusGrand - hauteur) / moitie
        return retenus.map { point in
            CGPoint(x: (decalageX + (point.lng - minLng) * echelle) / plusGrand,
                    y: (decalageY + (maxLat - point.lat)) / plusGrand)
        }
    }

    private static let pointsMaximum = 120
    private static let moitie: Double = 2
    private static let demiTour: Double = 180
    /// Le tracé tient dans une boîte plus petite que la vignette, comme dans le canvas (26 × 30
    /// dans 48).
    static let cote: CGFloat = 28
    static let trait: CGFloat = 2.4
}
