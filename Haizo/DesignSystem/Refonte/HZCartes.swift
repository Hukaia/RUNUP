import SwiftUI

/// Une mesure sous une carte-affiche : sa valeur, et ce qu'elle mesure.
struct HZMesure: Identifiable {
    let valeur: String
    let libelle: String
    var id: String { libelle + "·" + valeur }
}

/// LA CARTE-AFFICHE : un jour, écrit comme une affiche.
///
/// Une couleur pleine, la date en haut, et la séance écrite EN TRÈS GRAND — le nombre qui la
/// résume, avec ce qui le précède quand il y a lieu (« 5 × » devant « 500 »). C'est l'objet du
/// plan, où l'on en glisse une par jour, et le haut de l'accueil en est la version plein écran.
///
/// `encreSecondaire` est la couleur des petits libellés posés à même le fond : l'encre de
/// l'accent sur la carte du jour, le blanc sur les teintes d'intensité et sur le noir.
struct HZCarteAffiche: View {
    let jour: String
    let etiquette: String
    var prefixe: String = ""
    let nombre: String
    var style: HZAffichage = .carte
    let titre: String
    var mesures: [HZMesure] = []
    var fond: Color = HZCouleur.accent
    var encreSecondaire: Color = HZCouleur.blanc

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(jour)
                    .hzTexte(.c15, .gras)
                    .foregroundStyle(encreSecondaire)
                    .lineLimit(1)
                Spacer(minLength: HZEspace.entrePilules)
                HZPilule(texte: etiquette)
            }
            Spacer(minLength: 0)
            // La ligne du préfixe garde sa hauteur même vide : le nombre ne remonte pas d'une
            // carte à l'autre quand on les fait glisser.
            Text(prefixe)
                .hzAffichage(.prefixeDeCarte)
            Text(nombre)
                .hzAffichage(style)
                .padding(.leading, HZCarteAffiche.rattrapageOptique)
            Text(titre)
                .hzTexte(.c20, .gras)
                .lineLimit(1)
                .padding(.top, HZCarteAffiche.sousLeNombre)
            HStack(alignment: .top, spacing: 0) {
                ForEach(colonnes) { mesure in
                    VStack(alignment: .leading, spacing: HZCarteAffiche.entreValeurEtLibelle) {
                        Text(mesure.valeur)
                            .hzTexte(.c24, .gras, tabulaire: true)
                        Text(mesure.libelle)
                            .hzTexte(.c13, .gras)
                            .foregroundStyle(encreSecondaire)
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, HZEspace.tuile)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(HZCouleur.filetSurCouleur)
                    .frame(height: HZCarteAffiche.filet)
            }
            .padding(.top, HZCarteAffiche.avantLesMesures)
        }
        .foregroundStyle(HZCouleur.blanc)
        .padding(.horizontal, HZEspace.margeDeTitre)
        .padding(.vertical, HZCarteAffiche.margeVerticale)
        .frame(width: HZCarteAffiche.largeur, height: HZCarteAffiche.hauteur, alignment: .leading)
        .background(fond, in: RoundedRectangle(cornerRadius: HZRayon.carte, style: .circular))
        .accessibilityElement(children: .combine)
    }

    /// Toujours trois colonnes, pour que la première garde sa place quand il n'y en a qu'une.
    private var colonnes: [HZMesure] {
        let vides = (mesures.count..<max(mesures.count, HZCarteAffiche.nombreDeColonnes)).map {
            HZMesure(valeur: "", libelle: String(repeating: " ", count: $0 + 1))
        }
        return Array((mesures + vides).prefix(HZCarteAffiche.nombreDeColonnes))
    }

    static let largeur: CGFloat = 318
    static let hauteur: CGFloat = 430
    static let margeVerticale: CGFloat = 22
    /// Les grands chiffres d'Archivo portent un blanc à gauche de leur dessin : le canvas les
    /// tire de quatre points pour qu'ils s'alignent sur le titre.
    static let rattrapageOptique: CGFloat = -4
    static let sousLeNombre: CGFloat = 10
    static let avantLesMesures: CGFloat = 18
    static let entreValeurEtLibelle: CGFloat = 2
    static let filet: CGFloat = 1
    static let nombreDeColonnes = 3
}

/// Les formats d'une tuile de couleur.
enum HZFormatDeTuile {
    /// Une séance à venir, sur l'accueil.
    case seance
    /// Une course, dans Explorer.
    case course
    /// Un record, dans les stats.
    case record
    /// Un objectif, dans le plan : le nom en grand sur trois lignes au plus, une précision en haut.
    case objectif

    var largeur: CGFloat { self == .record || self == .objectif ? 150 : 160 }

    var hauteur: CGFloat {
        switch self {
        case .seance: return 190
        case .course, .record: return 150
        case .objectif: return 170
        }
    }

    var style: HZAffichage {
        switch self {
        case .seance: return .tuile
        case .course: return .tuileDeCourse
        case .record: return .record
        case .objectif: return .titreDeTuile
        }
    }

    /// Le chiffre est plus près du bord bas que le libellé du bord haut : le canvas le pose à
    /// douze points, le reste à quatorze.
    var sousLeChiffre: CGFloat { self == .record || self == .objectif ? 14 : 12 }
}

/// LA TUILE DE COULEUR : un libellé en haut, un grand chiffre en bas.
struct HZTuile: View {
    let libelle: String
    let valeur: String
    var format: HZFormatDeTuile = .seance
    var fond: Color
    var encreDuLibelle: Color = HZCouleur.blanc
    var graisseDuLibelle: HZGraisse = .semi

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(libelle)
                .hzTexte(.c13, graisseDuLibelle)
                .foregroundStyle(encreDuLibelle)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(valeur)
                .hzAffichage(format.style)
                .foregroundStyle(HZCouleur.blanc)
                // Une durée de plus de quatre signes (« 1h20 ») remplit les 132 points de la
                // tuile : elle rétrécit plutôt que de se couper — une durée tronquée est une durée
                // fausse. Le canvas, lui, laisse le texte déborder sous le bord de la tuile.
                .minimumScaleFactor(HZTuile.retrait)
        }
        .padding(.top, HZEspace.tuile)
        .padding(.horizontal, HZEspace.tuile)
        .padding(.bottom, format.sousLeChiffre)
        .frame(width: format.largeur, height: format.hauteur, alignment: .leading)
        .background(fond, in: RoundedRectangle(cornerRadius: HZRayon.tuile, style: .circular))
        .accessibilityElement(children: .combine)
    }

    static let retrait: CGFloat = 0.8
}

/// UNE TUILE ET SA LÉGENDE : la tuile de couleur, puis dessous le titre et sa précision.
///
/// C'est « Jeudi · 50' · Sortie avec le club · récupération » de l'accueil. Elle vivait en privé
/// dans la planche ; l'accueil réel en a besoin, et deux copies finissent par diverger.
struct HZTuileLegendee: View {
    let libelle: String
    let valeur: String
    let titre: String
    let precision: String
    var fond: Color
    var encreDuLibelle: Color = HZCouleur.blanc
    var graisseDuLibelle: HZGraisse = .semi

    var body: some View {
        VStack(alignment: .leading, spacing: HZAction.ecart) {
            HZTuile(libelle: libelle, valeur: valeur, fond: fond, encreDuLibelle: encreDuLibelle,
                    graisseDuLibelle: graisseDuLibelle)
            VStack(alignment: .leading, spacing: 0) {
                Text(titre)
                    .hzTexte(.c15, .gras)
                    .foregroundStyle(HZCouleur.encre)
                Text(precision)
                    .hzTexte(.c13, .medium)
                    .foregroundStyle(HZCouleur.secondaireSurClair)
            }
            .lineLimit(1)
        }
        .frame(width: HZFormatDeTuile.seance.largeur, alignment: .leading)
    }
}

/// Où une tuile de chiffre est posée.
enum HZFormatDeChiffre {
    /// La grille des stats.
    case stats
    /// Les deux mesures du résumé de sortie.
    case resume

    var style: HZAffichage { self == .stats ? .chiffreDeTuile : .mesure }
    var rayon: CGFloat { self == .stats ? HZRayon.groupe : HZRayon.mesure }
    var ecart: CGFloat { self == .stats ? 4 : 2 }
    var margeVerticale: CGFloat { self == .stats ? HZEspace.groupe : HZEspace.tuile }
}

/// LA TUILE DE CHIFFRE : ce qu'on mesure, puis sa valeur, sur une surface claire.
///
/// `sombre` en fait la tuile noire des stats — celle de la série en cours, la seule des quatre
/// qui dise quelque chose d'aujourd'hui.
struct HZTuileChiffre: View {
    let libelle: String
    let valeur: String
    var format: HZFormatDeChiffre = .stats
    var sombre: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: format.ecart) {
            Text(libelle)
                .hzTexte(.c13, .semi)
                .foregroundStyle(sombre ? HZCouleur.secondaireSurSombre : HZCouleur.secondaireSurClair)
                .lineLimit(1)
            Text(valeur)
                .hzAffichage(format.style)
                .foregroundStyle(sombre ? HZCouleur.blanc : HZCouleur.encre)
                .lineLimit(1)
                .minimumScaleFactor(HZTuileChiffre.retrait)
        }
        .padding(.horizontal, HZEspace.groupe)
        .padding(.vertical, format.margeVerticale)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sombre ? HZCouleur.noir : HZCouleur.surfaceClaire,
                    in: RoundedRectangle(cornerRadius: format.rayon, style: .circular))
        .accessibilityElement(children: .combine)
    }

    /// « 12h25 » tient dans une demi-largeur ; une valeur plus longue rétrécit avant de se couper.
    static let retrait: CGFloat = 0.7
}
