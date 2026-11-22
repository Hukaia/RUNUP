import SwiftUI

/// LA DÉCOUVERTE DES CLUBS ET SA FICHE : les mesures, la carte en aplat, la ligne d'une demande.
///
/// Rien n'y est nouveau dans son dessin. La carte reprend `HZCarteDeClub` (un aplat plein, le nom
/// en grand en bas à gauche, une pilule voilée en haut) et la couleur vient de la palette
/// d'intensité, la seule que le canvas dessine pour une surface de couleur. Le mode d'adhésion —
/// Ouvert, Sur demande, Sur code — est dit dans une pilule : un club qu'on ne rejoint pas d'un
/// appui le dit avant qu'on ait touché quoi que ce soit.
enum HZClubs {
    /// Plus basse que la carte du club (214) : on en voit plusieurs à la fois, on n'en habite qu'une.
    static let hauteurDeLaCarte: CGFloat = 168
    static let lignesDuNom = 2
    static let retraitDuNom: CGFloat = 0.6
    static let sousLeNom: CGFloat = 6
    /// Du champ de recherche à la première carte.
    static let sousLaRecherche: CGFloat = 14
    /// Le code d'invitation, en grand, dans la gestion du club : tabulaire, en affichage.
    static let reductionDuCode: CGFloat = 0.6
}

extension HZIntensite {
    /// La teinte d'un club : l'une des trois de la palette, toujours la même pour le même club.
    /// Le choix est `ClubTeinte.indice`, qui ne dépend que de l'identifiant.
    static func pourClub(id: String) -> HZIntensite {
        let teintes = HZIntensite.allCases
        return teintes[ClubTeinte.indice(pour: id, parmi: teintes.count)]
    }
}

/// LA CARTE D'UN CLUB À DÉCOUVRIR : un aplat de couleur, la pilule de son mode et, quand on a déjà
/// demandé à le rejoindre, une seconde pilule blanche qui le dit. Le nom en grand, puis la ville et
/// le nombre de membres.
///
/// Sans `action`, c'est l'en-tête de la fiche : la même carte, plus haute, qui ne mène nulle part.
struct HZCarteDeDecouverte: View {
    let nom: String
    let detail: String
    let mode: ClubJoinMode
    var demandeEnvoyee: Bool = false
    let couleur: Color
    var hauteur: CGFloat = HZClubs.hauteurDeLaCarte
    var action: (() -> Void)? = nil

    var body: some View {
        if let action {
            Button(action: action) { carte }
                .buttonStyle(.plain)
        } else {
            carte
        }
    }

    private var carte: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: HZEspace.entrePilules) {
                HZPilule(texte: mode.libelle)
                if demandeEnvoyee {
                    HZPilule(texte: String(localized: "Demande envoyée"), style: .etiquetteGrasse,
                             fond: HZCouleur.blanc, couleur: HZCouleur.noir)
                }
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
            Text(verbatim: nom)
                .hzAffichage(.titreDeCarte)
                .foregroundStyle(HZCouleur.blanc)
                .lineLimit(HZClubs.lignesDuNom)
                .minimumScaleFactor(HZClubs.retraitDuNom)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: detail)
                .hzTexte(.c15, .semi)
                .foregroundStyle(HZCouleur.blanc)
                .lineLimit(1)
                .minimumScaleFactor(HZClubs.retraitDuNom)
                .padding(.top, HZClubs.sousLeNom)
        }
        .padding(HZFil.margeDeLaCarteDeClub)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: hauteur)
        .background(couleur, in: RoundedRectangle(cornerRadius: HZRayon.carteDeClub, style: .circular))
        .contentShape(RoundedRectangle(cornerRadius: HZRayon.carteDeClub, style: .circular))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: phraseAccessible))
    }

    /// Ce que VoiceOver lit : le nom, la ville et les membres, le mode, et la demande envoyée.
    private var phraseAccessible: String {
        var morceaux = [nom, detail, mode.libelle]
        if demandeEnvoyee { morceaux.append(String(localized: "Demande envoyée")) }
        return morceaux.joined(separator: ", ")
    }
}

/// UNE DEMANDE POUR REJOINDRE MON CLUB : qui, depuis quand, et les deux seules réponses possibles.
///
/// Les boutons sont sous la ligne et non à sa droite : un nom et deux pilules ne tiennent pas côte
/// à côte sur 390 points, et un nom tronqué est un nom faux. Accepter est noir, refuser est gris :
/// ni l'un ni l'autre n'est dans la couleur d'accent, qui reste aux surfaces et aux chiffres.
struct HZLigneDeDemande: View {
    let nom: String
    let photo: HZPhotoDePersonne
    /// « Il y a 2 h » : depuis quand elle attend.
    let depuis: String
    var enCours: Bool = false
    var filet: Bool = true
    let accepter: () -> Void
    let refuser: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: HZEspace.entreCommandes) {
                HStack(spacing: HZMesuresDeLigne.ecart) {
                    photo
                    VStack(alignment: .leading, spacing: 0) {
                        Text(verbatim: nom)
                            .hzTexte(.c16, .semi)
                            .foregroundStyle(HZCouleur.encre)
                        Text(verbatim: depuis)
                            .hzTexte(.c13, .medium)
                            .foregroundStyle(HZCouleur.secondaireSurClair)
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(spacing: HZEspace.entreCommandes) {
                    HZBoutonPilule(libelle: String(localized: "Accepter"), hauteur: .petite,
                                   etendu: true, action: accepter)
                    HZBoutonPilule(libelle: String(localized: "Refuser"), hauteur: .petite,
                                   fond: HZCouleur.surfaceClaire, couleur: HZCouleur.encre,
                                   etendu: true, action: refuser)
                }
                .opacity(enCours ? HZHub.opaciteEteinte : HZHub.opaciteNormale)
                .disabled(enCours)
            }
            .padding(.vertical, HZMesuresDeLigne.margeDeSortie)
            if filet {
                Rectangle()
                    .fill(HZCouleur.filetFeuille)
                    .frame(height: HZMesuresDeLigne.filet)
            }
        }
    }
}
