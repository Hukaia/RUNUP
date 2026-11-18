import SwiftUI

/// LES SPLITS : un kilomètre par ligne, son numéro, une barre relative au plus rapide et au plus lent
/// de CETTE sortie, son temps. La dernière, en accent.
///
/// Les barres balaient l'une après l'autre au lieu d'apparaître toutes dessinées : « révélé, pas
/// déversé ». La longueur vient de `SplitsView.fractions`, la même mesure que partagent la page d'une
/// sortie et le résumé : deux écrans ne décrivent pas deux fois la même course.
struct HZSplits: View {
    let splits: [String]
    /// Les barres se remplissent quand il passe à vrai ; l'écran qui le porte décide quand.
    let revealed: Bool
    let reduceMotion: Bool

    var body: some View {
        let fractions = SplitsView.fractions(splits)
        VStack(spacing: HZSplits.entreLesLignes) {
            ForEach(splits.indices, id: \.self) { index in
                ligne(index, splits[index], fractions[index], derniere: index == splits.count - 1)
            }
        }
    }

    private func ligne(_ index: Int, _ temps: String, _ fraction: Double, derniere: Bool) -> some View {
        HStack(spacing: HZEspace.entreTuiles) {
            // Deux chiffres ne tiennent pas dans une largeur courte : les splits 10, 11 et 12 se
            // repliaient sur deux lignes. Le numéro rétrécit plutôt que de se plier.
            Text("\(index + 1)")
                .hzTexte(.c13, .medium, tabulaire: true)
                .foregroundStyle(HZCouleur.secondaireSurClair)
                .minimumScaleFactor(HZSplits.reductionDuNumero)
                .frame(width: HZSplits.largeurDuNumero, alignment: .trailing)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: HZSplits.rayonDeLaBarre, style: .circular)
                        .fill(HZCouleur.surfaceClaire)
                    RoundedRectangle(cornerRadius: HZSplits.rayonDeLaBarre, style: .circular)
                        .fill(derniere ? HZCouleur.accent : HZCouleur.encre)
                        .frame(width: geo.size.width * fraction * (revealed ? HZSplits.pleine : 0))
                        .animation(reduceMotion ? nil
                                   : .easeOut(duration: HZSplits.dureeDuBalayage)
                                       .delay(Double(index) * HZSplits.decalageParLigne),
                                   value: revealed)
                }
            }
            .frame(height: HZSplits.hauteurDeLaBarre)
            .accessibilityHidden(true)
            // Largeur minimale, pas fixe : un « m:ss » tient à la taille de texte par défaut, mais les
            // tailles d'accessibilité ont besoin que la ligne grandisse plutôt que de tronquer le temps.
            Text(temps)
                .hzTexte(.c15, .semi, tabulaire: true)
                .foregroundStyle(HZCouleur.encre)
                .frame(minWidth: HZSplits.largeurDuTemps, alignment: .trailing)
        }
        // La barre ne porte aucune valeur VoiceOver, et « dernier split » n'existait qu'en couleur :
        // un seul élément, avec un libellé et une valeur explicites.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(derniere
            ? String(localized: "Split \(index + 1), dernier")
            : String(localized: "Split \(index + 1)"))
        .accessibilityValue(temps)
    }

    static let entreLesLignes: CGFloat = 6
    static let largeurDuNumero: CGFloat = 22
    static let reductionDuNumero: CGFloat = 0.7
    static let hauteurDeLaBarre: CGFloat = 22
    static let rayonDeLaBarre: CGFloat = 6
    static let largeurDuTemps: CGFloat = 44
    static let dureeDuBalayage: Double = 0.5
    static let decalageParLigne: Double = 0.04
    static let pleine: Double = 1
}
