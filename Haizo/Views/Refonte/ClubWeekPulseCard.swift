import SwiftUI

/// LE CLUB CETTE SEMAINE : les kilomètres cumulés, et qui a couru.
struct ClubWeekPulseCard: View {
    let magasin: ClubStore

    var body: some View {
        let kilometres = magasin.board.weekStats?.totalKm ?? 0
        let actifs = (magasin.board.weekly ?? []).filter { $0.weekKm > 0 }
        VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
            if kilometres > 0 {
                HZTuileChiffre(libelle: String(localized: "Le club cette semaine"),
                               valeur: String(format: "%.1f km", locale: Locale.current, kilometres))
            } else {
                HZPhrase(texte: String(localized: "Personne n'a encore couru cette semaine."),
                         titre: String(localized: "Le club cette semaine"))
            }
            if !actifs.isEmpty {
                HStack(spacing: HZEspace.entreCommandes) {
                    HZPileDAvatars(
                        personnes: actifs.map {
                            HZPileDAvatars.Personne(id: $0.id, initiales: HZInitiales.de($0.name, $0.lastName),
                                                    urlString: $0.avatarUrl, base64: $0.avatarBase64)
                        },
                        total: actifs.count, fondDuLise: HZCouleur.blanc)
                    Text(Pluriel.choisir(actifs.count,
                                         String(localized: "\(actifs.count) membre a couru"),
                                         String(localized: "\(actifs.count) membres ont couru")))
                        .hzTexte(.c14, .medium)
                        .foregroundStyle(HZCouleur.secondaireSurClair)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Pluriel.choisir(actifs.count,
                                                    String(localized: "\(actifs.count) membre a couru cette semaine"),
                                                    String(localized: "\(actifs.count) membres ont couru cette semaine")))
            }
        }
    }
}
