import SwiftUI

/// Les mesures d'une ligne de liste. Hors de la vue : une structure générique ne peut pas
/// porter de constante.
enum HZMesuresDeLigne {
    static let ecart: CGFloat = 12
    /// Une sortie, dans « Dernières sorties ».
    static let margeDeSortie: CGFloat = 12
    /// Une destination, dans le profil.
    static let margeDeDestination: CGFloat = 11
    static let filet: CGFloat = 1
    /// La vignette carrée d'une sortie.
    static let vignette: CGFloat = 48
    /// Le tracé dans la vignette, et son trait — plus gras que celui d'une commande, parce
    /// qu'il est seul sur un carré noir de 48.
    static let trace: CGFloat = 26
    static let traitDuTrace: CGFloat = 2.4
    static let chevron: CGFloat = 18
    static let traitDuChevron: CGFloat = 2.2
}

/// LA LIGNE DE LISTE : ce qui l'illustre, un titre et son sous-titre, et ce qui la termine.
///
/// La tête et la queue sont laissées à l'appelant — une vignette de tracé ou un disque d'icône
/// d'un côté, un chiffre ou un chevron de l'autre — parce que le canvas ne les fait pas varier
/// par hasard : une sortie se termine par sa distance, une destination par un chevron.
struct HZLigneDeListe<Tete: View, Queue: View>: View {
    let titre: String
    var sousTitre: String? = nil
    var graisse: HZGraisse = .semi
    var marge: CGFloat = HZMesuresDeLigne.margeDeSortie
    /// Le filet sous la ligne. La dernière d'une liste n'en porte pas.
    var filet: Bool = true
    @ViewBuilder var tete: () -> Tete
    @ViewBuilder var queue: () -> Queue

    var body: some View {
        HStack(spacing: HZMesuresDeLigne.ecart) {
            tete()
            VStack(alignment: .leading, spacing: 0) {
                Text(titre)
                    .hzTexte(.c16, graisse)
                    .foregroundStyle(HZCouleur.encre)
                if let sousTitre {
                    Text(sousTitre)
                        .hzTexte(.c13, .medium)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            queue()
        }
        .padding(.vertical, marge)
        .overlay(alignment: .bottom) {
            if filet {
                Rectangle()
                    .fill(HZCouleur.filetFeuille)
                    .frame(height: HZMesuresDeLigne.filet)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Le chevron au bout d'une ligne qui mène quelque part.
struct HZChevron: View {
    var body: some View {
        HZIcone(dessin: .chevron, cote: HZMesuresDeLigne.chevron,
                trait: HZMesuresDeLigne.traitDuChevron, couleur: HZCouleur.chevron)
    }
}

/// La valeur d'une sortie et ce qui la qualifie, alignées à droite : « 8,9 km » sur « 6:14/km ».
struct HZValeurDeLigne: View {
    let valeur: String
    let precision: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(valeur)
                .hzTexte(.c16, .gras, tabulaire: true)
                .foregroundStyle(HZCouleur.encre)
            Text(precision)
                .hzTexte(.c13, .medium, tabulaire: true)
                .foregroundStyle(HZCouleur.secondaireSurClair)
        }
        .lineLimit(1)
    }
}

/// Ce qu'un jour de la semaine est devenu, ou va devenir.
enum HZEtatDeJour {
    /// Une séance faite : un point plein.
    case fait
    /// Aujourd'hui : un anneau, plus grand que les autres.
    case aujourdhui
    /// Une séance à venir : un petit anneau.
    case aVenir
    /// Rien de prévu : un point éteint.
    case repos
}

/// LA SEMAINE EN SEPT POINTS, sur l'accent.
///
/// Elle remplace le ruban à barres de l'ancien accueil. Le canvas ne montre plus la charge de
/// chaque jour, seulement son état : c'est la porte vers le plan, pas un graphique.
///
/// Les initiales sont écrites dans l'encre de l'accent — la règle du rose — et l'état se lit par
/// la FORME du point autant que par sa teinte : plein, anneau, grand anneau, éteint.
struct HZSemaineEnPoints: View {
    /// Sept initiales et sept états, du lundi au dimanche.
    let jours: [(initiale: String, etat: HZEtatDeJour)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(jours.enumerated()), id: \.offset) { _, jour in
                // Le point vit dans une case de la hauteur du plus grand des quatre : petit ou
                // grand, son centre reste à la même hauteur d'un jour à l'autre.
                VStack(spacing: HZSemaineEnPoints.sousLInitiale) {
                    Text(jour.initiale)
                        .hzTexte(.c12, .gras)
                        .foregroundStyle(HZCouleur.encreSurAccent)
                    point(jour.etat)
                        .frame(height: HZSemaineEnPoints.grandPoint)
                }
                .frame(maxWidth: .infinity)
                .frame(height: HZSemaineEnPoints.hauteur, alignment: .top)
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func point(_ etat: HZEtatDeJour) -> some View {
        switch etat {
        case .fait:
            Circle().fill(HZCouleur.blanc)
                .frame(width: HZSemaineEnPoints.point, height: HZSemaineEnPoints.point)
        case .aujourdhui:
            Circle().strokeBorder(HZCouleur.blanc, lineWidth: HZSemaineEnPoints.anneauDuJour)
                .frame(width: HZSemaineEnPoints.grandPoint, height: HZSemaineEnPoints.grandPoint)
        case .aVenir:
            Circle().strokeBorder(HZCouleur.blanc, lineWidth: HZSemaineEnPoints.anneau)
                .frame(width: HZSemaineEnPoints.point, height: HZSemaineEnPoints.point)
        case .repos:
            Circle().fill(HZCouleur.pointSurCouleur)
                .frame(width: HZSemaineEnPoints.point, height: HZSemaineEnPoints.point)
        }
    }

    static let hauteur: CGFloat = 38
    static let sousLInitiale: CGFloat = 5
    static let point: CGFloat = 8
    static let grandPoint: CGFloat = 14
    static let anneau: CGFloat = 2
    static let anneauDuJour: CGFloat = 3
}
