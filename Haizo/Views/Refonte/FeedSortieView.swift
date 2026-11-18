import SwiftUI

/// UNE SORTIE D'UN FIL : l'en-tête (avatar, nom, provenance), l'affiche (tracé et distance en très
/// grand), allure / temps / dénivelé, Bravo et Commenter. Sans distance (un badge, une séance sans
/// mesure), ce n'est pas une sortie : une ligne sur la surface claire.
///
/// Le fil, l'onglet Activité du club et les amis la dessinent de la même façon ; ce qui change d'un
/// écran à l'autre, ce sont les actions, qu'il passe ici.
struct FeedSortieView: View {
    @Environment(AppState.self) private var appState

    let item: FeedItem
    let estLaMienne: Bool
    let applaudir: () -> Void
    let commenter: () -> Void
    let modifier: () -> Void
    let supprimer: () -> Void
    let signaler: () -> Void
    let bloquer: () -> Void

    var body: some View {
        if let km = item.distanceKm, km > HZFil.kilometreMinimum {
            HZSortieDuFil(
                nom: item.nomComplet, sousTitre: sousTitre, titre: titre,
                record: item.isPersonalRecord, recordLibelle: String(localized: "Record"),
                distance: String(format: "%.1f", locale: Locale.current, km),
                unite: String(localized: "kilomètres"),
                trace: HZSortieDuFil<EmptyView, EmptyView>.normaliser(
                    (item.routePreview ?? []).map { (lat: $0.lat, lng: $0.lng) }),
                photo: item.photoUrl.flatMap { $0.isEmpty ? nil : URL(string: $0) },
                mesures: mesures,
                bravo: item.kudos > 0 ? "\(item.kudos)" : String(localized: "Bravo"),
                bravoFait: item.kudoedByMe,
                commentaires: item.commentsCount > 0 ? "\(item.commentsCount)" : String(localized: "Commenter"),
                aimePar: aimePar,
                dernierCommentaire: item.lastComment.map { (auteur: $0.nomComplet, texte: $0.text) },
                ouvrirLaPersonne: { if !estLaMienne { appState.ouvrirLeProfil(item.userId) } },
                ouvrirLaSortie: { appState.ouvrirLaSortie(item.id) },
                applaudir: applaudir,
                commenter: commenter,
                avatar: { avatar },
                menu: { menu })
        } else {
            // Une note : une phrase, pas un bloc.
            VStack(alignment: .leading, spacing: HZFil.sousLIdentite) {
                HStack(spacing: HZFil.ecartDeLIdentite) {
                    avatar
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.nomComplet)
                            .hzTexte(.c16, .gras)
                            .foregroundStyle(HZCouleur.encre)
                        Text(sousTitre)
                            .hzTexte(.c13, .medium)
                            .foregroundStyle(HZCouleur.secondaireSurClair)
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    menu
                }
                HZNoteDuFil(texte: item.localizedText)
            }
        }
    }

    private var provenance: String? {
        switch item.source {
        case "club": return String(localized: "ton club")
        case "amis": return String(localized: "tu la suis")
        case "moi": return String(localized: "toi")
        default: return nil
        }
    }

    private var sousTitre: String {
        [item.createdAt.relativeDescription, provenance].compactMap { $0 }.joined(separator: " · ")
    }

    /// Le titre que l'autrice a donné à sa sortie, et rien d'autre : le canvas n'a pas de titre,
    /// mais ce sont ses mots, ils passent avant les nôtres.
    private var titre: String? {
        guard let propre = item.title?.trimmingCharacters(in: .whitespacesAndNewlines), !propre.isEmpty
        else { return nil }
        return propre
    }

    private var avatar: some View {
        HZPhotoDePersonne(urlString: item.avatarUrl, base64DataURI: item.avatarBase64,
                          initiales: AccueilModele.initiales(prenom: item.name, nom: item.lastName ?? ""),
                          cote: HZFil.tailleDeLAvatar)
    }

    private var menu: some View {
        Menu {
            if estLaMienne {
                Button("Modifier ma sortie", action: modifier)
                Button("Supprimer cette activité", role: .destructive, action: supprimer)
            } else {
                Button("Signaler cette activité", action: signaler)
                Button("Bloquer \(item.name)", role: .destructive, action: bloquer)
            }
        } label: {
            HZIcone(dessin: .options, cote: HZFil.coteDuBravo, couleur: HZCouleur.secondaireSurClair)
                .frame(width: HZBoutonRond.zoneTactile, height: HZBoutonRond.zoneTactile)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(String(localized: "Plus d'actions"))
    }

    /// « Aimé par Camille et 3 autres » : DEUX noms et pas trois — trois prénoms tenaient sur une
    /// ligne, trois noms complets non, et la ligne n'a jamais prétendu dire QUI a applaudi : ces
    /// noms sont un échantillon, pas les trois derniers.
    private var aimePar: String? {
        let noms = Array(item.kudosNames.prefix(HZFil.nomsDApplaudisseurs))
        guard !noms.isEmpty else { return nil }
        var elements = noms
        switch max(0, item.kudos - noms.count) {
        case 0: break
        case 1: elements.append(String(localized: "une autre personne"))
        case let autres: elements.append(String(localized: "\(autres) autres"))
        }
        return String(localized: "Aimé par \(ListFormatter.localizedString(byJoining: elements))")
    }

    /// Allure (ou vitesse), temps, dénivelé — seulement ce qui a été mesuré : pas de « 0 m » ni de
    /// « --:-- » qui feraient passer une absence de mesure pour une mesure.
    private var mesures: [HZMesure] {
        var colonnes: [HZMesure] = []
        if item.disciplineAffichee.seLitEnAllure, let allure = item.avgPace, !allure.isEmpty {
            colonnes.append(HZMesure(valeur: allure, libelle: String(localized: "Allure")))
        }
        if let secondes = item.durationSeconds, secondes > 0 {
            colonnes.append(HZMesure(valeur: PaceModel.formatTotalDuration(secondes),
                                     libelle: String(localized: "Temps")))
        }
        if let denivele = item.elevationGainM, denivele > 0 {
            colonnes.append(HZMesure(valeur: String(localized: "\(denivele) m"),
                                     libelle: String(localized: "Dénivelé")))
        }
        return colonnes
    }
}
