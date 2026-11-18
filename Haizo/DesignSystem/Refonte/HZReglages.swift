import SwiftUI

/// LES PIÈCES DES RÉGLAGES : un groupe sur la surface claire, ses lignes, l'interrupteur noir, le
/// compteur à deux boutons et la pastille de couleur. Les mesures sont celles du canvas « Réglages ».

/// Le titre d'une section, au-dessus du groupe qu'il nomme.
struct HZGroupeDeReglages<Contenu: View>: View {
    let titre: String
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        VStack(alignment: .leading, spacing: HZReglages.sousUnTitre) {
            Text(titre)
                .hzTexte(.c13, .gras)
                .foregroundStyle(HZCouleur.secondaireSurClair)
            VStack(alignment: .leading, spacing: 0) {
                contenu()
            }
            .padding(.horizontal, HZEspace.groupe)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HZCouleur.surfaceClaire,
                        in: RoundedRectangle(cornerRadius: HZRayon.groupe, style: .circular))
        }
    }
}

/// Une ligne de groupe : son titre, une précision éventuelle, ce qui la termine.
///
/// Sans précision, la ligne a une hauteur fixe, comme au canvas. Avec une précision, elle prend la
/// hauteur de son texte et une marge verticale : une phrase qui passe à la ligne ne doit pas être
/// coupée par une hauteur qu'on lui a imposée.
struct HZLigneDeReglage<Queue: View>: View {
    let titre: String
    var precision: String? = nil
    var hauteur: CGFloat = HZReglages.hauteurDeLigne
    var filet: Bool = true
    @ViewBuilder var queue: () -> Queue

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: HZEspace.tuile) {
                VStack(alignment: .leading, spacing: HZReglages.entreTitreEtPrecision) {
                    Text(titre)
                        .hzTexte(.c16, .semi)
                        .foregroundStyle(HZCouleur.encre)
                    if let precision {
                        Text(precision)
                            .hzParagraphe(.c13, .medium, interligne: HZReglages.interligne)
                            .foregroundStyle(HZCouleur.secondaireSurClair)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                queue()
            }
            .padding(.vertical, precision == nil ? 0 : HZReglages.margeDUneLigneALaPrecision)
            .frame(minHeight: hauteur)
            if filet {
                Rectangle()
                    .fill(HZCouleur.filetGroupe)
                    .frame(height: HZMesuresDeLigne.filet)
            }
        }
    }
}

/// L'interrupteur du canvas : une capsule noire de 52 sur 32, un bouton blanc de 26. Éteint, la
/// capsule est grise et le bouton à gauche. C'est un `Toggle` de SwiftUI, donc VoiceOver l'annonce
/// comme tel : seule sa peinture change.
struct HZStyleDInterrupteur: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            Capsule()
                .fill(configuration.isOn ? HZCouleur.encre : HZCouleur.contour)
                .frame(width: HZReglages.largeurDInterrupteur, height: HZReglages.hauteurDInterrupteur)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(HZCouleur.blanc)
                        .frame(width: HZReglages.boutonDInterrupteur, height: HZReglages.boutonDInterrupteur)
                        .padding(.horizontal, HZReglages.margeDuBouton)
                }
                .frame(minWidth: HZBoutonRond.zoneTactile, minHeight: HZBoutonRond.zoneTactile)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: HZReglages.dureeDeBascule), value: configuration.isOn)
    }
}

/// Un nombre qu'on règle au pas : moins, la valeur, plus.
struct HZCompteur: View {
    let valeur: String
    let nomDuMoins: String
    let nomDuPlus: String
    let moins: () -> Void
    let plus: () -> Void

    var body: some View {
        HStack(spacing: HZEspace.entreTuiles) {
            bouton("−", nom: nomDuMoins, action: moins)
            Text(verbatim: valeur)
                .hzTexte(.c17, .gras, tabulaire: true)
                .frame(minWidth: HZReglages.largeurDeLaValeur)
                .multilineTextAlignment(.center)
            bouton("+", nom: nomDuPlus, action: plus)
        }
    }

    private func bouton(_ signe: String, nom: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: signe)
                .hzTexte(.c20, .semi)
                .foregroundStyle(HZCouleur.encre)
                .frame(width: HZDiametre.pas.rawValue, height: HZDiametre.pas.rawValue)
                .background(HZCouleur.blanc, in: Circle())
                .frame(minWidth: HZBoutonRond.zoneTactile, minHeight: HZBoutonRond.zoneTactile)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: HZDiametre.pas.rawValue, height: HZDiametre.pas.rawValue)
        .accessibilityLabel(nom)
    }
}

/// Le choix clair ou sombre : une piste grise, la valeur choisie dans une pastille blanche.
struct HZChoixADeux: View {
    let premier: String
    let second: String
    /// Vrai quand le premier est choisi.
    let premierChoisi: Bool
    let choisir: (Bool) -> Void

    var body: some View {
        HStack(spacing: 0) {
            segment(premier, choisi: premierChoisi) { choisir(true) }
            segment(second, choisi: !premierChoisi) { choisir(false) }
        }
        .padding(HZReglages.margeDeLaPiste)
        .background(HZCouleur.filetGroupe, in: Capsule())
    }

    private func segment(_ libelle: String, choisi: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(libelle)
                .hzTexte(.c14, .gras)
                .foregroundStyle(choisi ? HZCouleur.encre : HZCouleur.secondaireSurClair)
                .padding(.horizontal, HZEspace.tuile)
                .padding(.vertical, HZReglages.margeVerticaleDuSegment)
                .background(choisi ? HZCouleur.blanc : HZCouleur.blanc.opacity(0), in: Capsule())
                .frame(minHeight: HZBoutonRond.zoneTactile)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(choisi ? .isSelected : [])
    }
}

/// Une pastille de couleur. Choisie, elle porte un anneau noir détaché d'un interstice : l'anneau
/// déborde de la pastille sans changer la place qu'elle prend.
struct HZPastilleDeCouleur: View {
    let couleur: Color
    let nom: String
    let choisie: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(couleur)
                .frame(width: HZReglages.diametreDePastille, height: HZReglages.diametreDePastille)
                .overlay {
                    if choisie {
                        Circle()
                            .strokeBorder(HZCouleur.encre, lineWidth: HZReglages.traitDeAnneau)
                            .frame(width: HZReglages.diametreDePastille + HZReglages.debordDeAnneau,
                                   height: HZReglages.diametreDePastille + HZReglages.debordDeAnneau)
                    }
                }
                .frame(minWidth: HZBoutonRond.zoneTactile, minHeight: HZBoutonRond.zoneTactile)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: HZReglages.diametreDePastille, height: HZReglages.diametreDePastille)
        .accessibilityLabel(nom)
        .accessibilityAddTraits(choisie ? .isSelected : [])
    }
}

/// UNE CARTE D'OFFRE : le noir, le nom de l'offre en grand, un bouton blanc à droite.
struct HZCarteDOffre: View {
    let etat: String
    let titre: String
    let bouton: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: HZReglages.entreTitreEtPrecision) {
                    Text(etat)
                        .hzTexte(.c13, .semi)
                        .foregroundStyle(HZCouleur.secondaireSurSombre)
                    Text(titre)
                        .hzAffichage(.offre)
                        .foregroundStyle(HZCouleur.blanc)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Text(bouton)
                    .hzTexte(.c14, .gras)
                    .foregroundStyle(HZCouleur.noir)
                    .padding(.horizontal, HZEspace.groupe)
                    .frame(height: HZReglages.hauteurDuBoutonDOffre)
                    .background(HZCouleur.blanc, in: Capsule())
            }
            .padding(HZReglages.margeDeLOffre)
            .frame(maxWidth: .infinity, minHeight: HZReglages.hauteurDeLOffre, alignment: .bottom)
            .background(HZCouleur.noir,
                        in: RoundedRectangle(cornerRadius: HZRayon.offre, style: .circular))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
